//######################################################################
//# Purpose: Change the Hardcoded loading & retrieval of Shield prefix #
//#          to Lua based code                                         #
//######################################################################

MaxShield = 10;
function EnableCustomShields() {//Pre-VC9 Client support not completed
  
  //===========================================================//
  // Find first inject & return locations - table loading area //
  //===========================================================//
  
  //Step 1a - Find address of _가드 (Guard's suffix)
  var offset = exe.findString("_\xB0\xA1\xB5\xE5", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Guard not found";
  
  //Step 1b - Find where it is loaded to table which is the inject location
  var code = " C7 AB 04" + offset.packToHex(4); //MOV DWORD PTR DS:[reg32_A + 4], OFFSET <guard suffix>
  var type = 2;
  
  var hookReq = exe.findCode(code, PTYPE_HEX, true, "\xAB");//VC9+ Clients
  
  if (hookReq === -1) {
    code = code.replace("C7 AB 04", " 6A 03 8B AB C7 00");//PUSH 3 ;
                                                          //MOV ECX, reg32_A
                                                          //MOV DWORD PTR DS:[EAX], OFFSET <guard suffix>
    type = 1;
  
    hookReq = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (hookReq === -1)
    return "Failed in Step 1 - Guard reference missing";
  
  //Step 1c - Extract the register that points to the location to store the suffix.
  if (type === 1) {
    var regPush = " 83 E8 04 50";//SUB EAX, 4 and PUSH EAX
  }
  else {
    var regPush = exe.fetchHex(hookReq + 1, 1).replace("4", "5");//PUSH reg32_A
  }
 
  //Step 1d - Find the address of _버클러 (Buckler's suffix)
  offset = exe.findString("_\xB9\xF6\xC5\xAC\xB7\xAF", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Buckler not found";
  
  //Step 1e - Find where its loaded to table.
  if (type === 1)
    code = " C7 00" + offset.packToHex(4); //MOV DWORD PTR DS:[EAX], OFFSET <buckler suffix>
  else
    code = " C7 AB 08" + offset.packToHex(4); //MOV DWORD PTR DS:[reg32_A + 8], OFFSET <buckler suffix>
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", hookReq, hookReq + 0x38);
  if (offset === -1)
    return "Failed in Step 1 - Buckler reference missing";
  
  //Step 1f - Return address is after code.
  var retReq = offset + code.hexlength();
    
  //Step 2a -  Allocate space considering maximum code size possible
  var funcName = "ReqShieldName\x00";
  var free = exe.findZeros(funcName.length + 0xB + 0x3D + 0x12);
  if (free === -1)
    return "Failed in Part 2 - Not enough free space";
  
  //Step 2b - Construct code.
  code = 
    funcName.toHex()
  + " 60"             //PUSHAD
  + " BF 01 00 00 00" //MOV EDI, 1
  + " BB" + MaxShield.packToHex(4) //MOV EBX, finalValue
  ;
  
  code += GenLuaCaller(free + code.hexlength(), funcName, exe.Raw2Rva(free), "d>s", " 57");
  
  code +=
    " 8A 08"          //MOV CL, BYTE PTR DS:[EAX]
  + " 84 C9"          //TEST CL, CL
  + " 74 07"          //JE SHORT addr
  + " 8B 4C 24 20"    //MOV ECX, DWORD PTR SS:[ESP+20]
  + " 89 04 B9"       //MOV DWORD PTR DS:[EDI*4+ECX],EAX
  + " 47"             //INC EDI; addr
  + " 39 DF"          //CMP EDI,EBX
  + " 7E"             //JLE SHORT addr2; to start of generate
  ;

  code += (funcName.length + 0xB - (code.hexlength() + 1)).packToHex(1);

  code +=
    " 61"             //POPAD
  + " 83 C4 04"       //ADD ESP, 4
  + " E9"             //JMP retReq  
  ;
  
  code += (exe.Raw2Rva(retReq) - exe.Raw2Rva(free + code.hexlength() + 4)).packToHex(4);

  //Step 2c - Insert the code
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);
  
  //Step 2c - Create regPush & JMP at hookReq to the code
  code = regPush + " E9";
  code += (exe.Raw2Rva(free + funcName.length) - exe.Raw2Rva(hookReq + code.hexlength() + 4)).packToHex(4);
  
  exe.replace(hookReq, code, PTYPE_HEX);
  
  //=========================//
  // Inject Lua file loading //
  //=========================//
  
  var retVal = InjectLuaFiles(
    "Lua Files\\DataInfo\\jobName", 
    [
      "Lua Files\\DataInfo\\ShieldTable",
      "Lua Files\\DataInfo\\ShieldTable_F"
    ]
  );
  if (typeof(retVal) === "string")
    return retVal;
  
  //========================================================//
  // Find second inject location - CSession::GetShieldType. //
  //========================================================//
  
  //Step 3a - Find location where the GetShieldType is called - there are multiple matches but all of them are same
  code = 
    " 3D D0 07 00 00" //CMP EAX, 7D0
  + " 7E AB"          //JLE SHORT addr1
  + " 50"             //PUSH EAX
  + " B9 AB AB AB 00" //MOV ECX, g_session; Note: this is the reference value for all the tables
  + " E8"             //CALL CSession::GetShieldType
  ;
  
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (offsets.length === 0)
    return "Failed in Step 3 - GetShieldType call missing";

  //Step 3b - Find call to CSession::GetWeaponType before one of the locations.
  for (var i = 0; i < offsets.length; i++) {
    offset = exe.find("E8 AB AB AB AB 85 C0", PTYPE_HEX, true, "\xAB", offsets[i] - 0x40, offsets[i]);//CALL CSession::GetWeaponType followed by TEST EAX, EAX
    
    if (offset === -1)
      offset = exe.find("E8 AB AB AB AB 33 AB 85 C0", PTYPE_HEX, true, "\xAB", offsets[i] - 0x40, offsets[i]);//XOR reg32_A, reg32_A added before TEST
    
    if (offset !== -1)
      break;
  }
  
  if (offset === -1)
    return "Failed in Step 3 - GetWeaponType call missing";
  
  //Step 3c - Change the CALL to following so that GetShieldType is always called
  //  NOP
  //  POP EAX
  //  OR EAX, -1
  exe.replace(offset, " 90 58 83 C8 FF", PTYPE_HEX);
  
  //Step 3d - Extract RAW address of GetShieldType function
  offset = offsets[0] + code.hexlength();
  var hookMap = offset + 4 + exe.fetchDWord(offset);
  
  //Step 4a - Allocate space for code considering max size
  funcName = "GetShieldID\x00";
  free = exe.findZeros(funcName.length + 0x5 + 0x3D + 0x4);
  if (free === -1)
    return "Failed in Part 4 - Not enough free space";
  
  //Step 4b - Construct code
  code = 
    funcName.toHex()
  + " 52"             //PUSH EDX
  + " 8B 54 24 08"    //MOV EDX, DWORD PTR SS:[ESP+8]
  ;
  
  code += GenLuaCaller(free + code.hexlength(), funcName, exe.Raw2Rva(free), "d>d", " 52");
  
  code += 
    " 5A"             //POP EDX
  + " C2 04 00"       //RETN 4
  ;
  
  //Step 4c - Insert the code
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);
  
  //Step 4d - Create a JMP at hookMap to the code
  exe.replace(hookMap, "E9" + (exe.Raw2Rva(free + funcName.length) - exe.Raw2Rva(hookMap + 5)).packToHex(4), PTYPE_HEX); 

  //Step 5a - Find PUSH 5 before hookReq and replace with MaxShield if its there
  code =
    " 50"    //PUSH EAX
  + " 6A 05" //PUSH 5
  + " 8B"    //MOV ECX, reg32_A
  ;
  offset = exe.find(code, PTYPE_HEX, false, "", hookReq - 0x30, hookReq);
  
  if (offset !== -1) {
    exe.replace(offset + 2, MaxShield.packToHex(1), PTYPE_HEX);
  }
  else {
    //Step 5b - Find Register assignment to 5 and replace with MaxShield
    code =
      " 05 00 00 00" //MOV reg32_A, 5
    + " 2B"          //SUB reg32_A, reg32_B
    ;
    
    offset = exe.find(code, PTYPE_HEX, false, "", hookReq - 0x60, hookReq);
    if (offset === -1)
      return "Failed in Step 5 - No Allocator PUSHes found";
   
    exe.replace(offset, MaxShield.packToHex(4), PTYPE_HEX);

    //Step 5c - Find EAX comparison with 5 before assignment and replace with MaxShield
    code =
      " 83 F8 05" //CMP EAX, 5
    + " 73"       //JAE SHORT addr
    ;
    
    offset = exe.find(code, PTYPE_HEX, false, "", offset - 0x10, offset);
    if (offset === -1)
      return "Failed in Step 5 - Comparison Missing";
   
    exe.replace(offset + 2, MaxShield.packToHex(1), PTYPE_HEX);
  }

  return true;
}