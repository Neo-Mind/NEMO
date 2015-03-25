function EnableCustomShields() {
  ///////////////////////////////////////////////////////
  // GOAL: Modify the hardcoded Shield prefix table    //
  //       assignments to load them using Lua function //
  //       instead.                                    //
  ///////////////////////////////////////////////////////
  
  var max = 10;
  //--- Find first function insert location (function for storing the shield suffixes in memory) and accompanying values needed ---//
  //Step 1a - Locate _가드 (Guard's suffix)
  var offset = exe.findString("_가드", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Guard not found";
  
  //Step 1b - Find location where it is referenced (moved to memory location)
  var code = " C7 AB 04" + offset.packToHex(4) + " 8B"; //MOV DWORD PTR DS:[E*X+4],OFFSET <guard suffix>
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1 - Guard reference missing";
  
  //Step 1c - Insert location comes 18 bytes before offset.
  var insReq = offset - 18;
  
  //Step 1d - Extract Default String used (Null byte starting)
  var zeroS = exe.fetchDWord(insReq + 8);

  //--- Find second function insert location (function for mapping storage id from item id) ---//
  //Step 2a - Find location where the original mapping function is called
  code = " 3D D0 07 00 00 7E AB 50 B9 AB AB AB AB E8 AB AB AB AB 89 86";
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 2";
  
  //Step 2b - Function is called after 13 bytes from offset (including call opcode = 14)
  var insMap = offset + 13 + 5 + exe.fetchDWord(offset + 14);
  
  //--- Find offsets & function locations for using in lua function ---//
  //Step 3a - Find offset of ReqJobName 
  offset = exe.findString("ReqJobName", RVA);
  if (offset === -1)
    return "Failed in Step 3 - ReqJobName not found";
  
  //Step 3b - Find its reference
  offset = exe.findCode(" 68" + offset.packToHex(4), PTYPE_HEX, " ");
  if (offset === -1)
    return "Failed in Step 3 - ReqJobName reference missing";
  
  //Step 3c - Find offset of ReqAccName
  var offset2 = exe.findString("ReqAccName", RVA);
  if (offset2 === -1)
    return "Failed in Step 3 - ReqAccName not found";
  
  //Step 3d - Find its reference
  offset2 = exe.findCode(" 68" + offset2.packToHex(4), PTYPE_HEX, " ");
  if (offset2 === -1)
    return "Failed in Step 3 - ReqAccName reference missing";
  
  //Step 3e - All values are x bytes from pushed location - x varies based on compiler version
  if (exe.getClientDate() > 20130605) {
    var stringAlloc = offset + 13 + exe.fetchDWord(offset +  9);
    var dsOff = exe.fetchDWord(offset + 22);
    var luaFnCaller = offset + 35 + exe.fetchDWord(offset + 31);
    var esiDiff = exe.fetchDWord(offset2 + 24);
  }
  else {
    var stringAlloc = exe.fetchDWord(offset + 7);
    var dsOff = exe.fetchDWord(offset + 21);
    var luaFnCaller = offset + 35 + exe.fetchDWord(offset + 31);//interestingly same offset but code is different
    var esiDiff = exe.fetchDWord(offset2 + 29);
  }
  
  //Step 3f - Get offset of d>d and d>s
  var OFDS = exe.findString("d>s", RVA).packToHex(4);
  var OFDD = exe.findString("d>d", RVA).packToHex(4);
  
  //--- Create lua caller codes ---//
  //Step 4a - Code for GetShieldID
  code =
      " 55"                   //PUSH EBP
    + " 8B EC"                //MOV EBP, ESP
    + " 60"                   //PUSHAD - lazy boy
    + " 8B 7D 08"             //MOV EDI, DWORD PTR SS:[EBP + 8]
    + " C7 45 08 00 00 00 00" //MOV DWORD PTR SS:[EBP + 8],0
    + " 8D 55 08"             //LEA EDX,[EBP + 8]
    + " 52"                   //PUSH EDX
    + " 57"                   //PUSH EDI
    + " 68" + OFDD            //PUSH OFFSET d>d
    + " 83 EC 1C"             //SUB ESP,1C
    + " 89 E1"                //MOV ECX,ESP
    ;
  if (exe.getClientDate() > 20130605) {
    code +=
        " 31 C0"                //XOR EAX,EAX
      + " 6A 0B"                //PUSH 0B - Length of GetShieldID
      + " C7 41 14 0F 00 00 00" //MOV DWORD PTR DS:[ECX+14],0F
      + " 89 41 10"             //MOV DWORD PTR DS:[ECX+10],EAX
      ;
  }
      
  code += " 68 00 00 00 00";  //PUSH OFFSET GetShieldID
  var gsLoc = code.length - 4*3;
  
  if (exe.getClientDate() > 20130605) {
    code +=
        " 88 01"          //MOV BYTE PTR DS:[ECX],AL
      + " E8 00 00 00 00" //CALL FN01 - String allocator
      ;
    var fn1Loc1 = code.length - 4*3;
  }
  else {
    code += " FF 15" + stringAlloc.packToHex(4);  //CALL DWORD PTR DS:[FN01] - String allocator
    var fn1loc1 = false;
  }
  
  var fn2Loc1 = code.length + 8*3;
  code +=
      " 8B 0D" + dsOff.packToHex(4) //MOV ECX,DWORD PTR DS:[RG01]
    + " 51"             //PUSH ECX
    + " E8 00 00 00 00" //CALL FN02 - Lua Function Caller
    + " 83 C4 2C"       //ADD ESP,2C
    + " 61"             //POPAD
    + " 8B 45 08"       //MOV EAX, DWORD PTR SS:[EBP + 8]
    + " 5D"             //POP EBP
    + " C3"             //RETN
    ;
  
  //Step 4b - ReqShieldName code
  var ReqBegin = code.length;  
  code +=
      " 55"                   //PUSH EBP
    + " 8B EC"                //MOV EBP, ESP
    + " 60"                   //PUSHAD - lazy boy
    + " 31 FF"                //XOR EDI, EDI
    + " 8B 5D 08"             //MOV EBX, DWORD PTR SS:[EBP + 8] - Storage Base location        
    + " C7 45 08 00 00 00 00" //MOV DWORD PTR SS:[EBP + 8],0 - reuse
    + " 8D 55 08"             //LEA EDX,[EBP + 8]
    + " 52"                   //PUSH EDX
    + " 57"                   //PUSH EDI
    + " 68" + OFDS            //PUSH OFFSET d>s
    + " 83 EC 1C"             //SUB ESP,1C
    + " 89 E1"                //MOV ECX,ESP
    ;
  if (exe.getClientDate() > 20130605) {
    code +=
        " 31 C0"                //XOR EAX,EAX
      + " 6A 0D"                //PUSH 0D - Length of ReqShieldName
      + " C7 41 14 0F 00 00 00" //MOV DWORD PTR DS:[ECX+14],0F
      + " 89 41 10"             //MOV DWORD PTR DS:[ECX+10],EAX
      ;
  }
  
  code += " 68 00 00 00 00";  //PUSH OFFSET ReqShieldName
  var rqLoc = code.length - 4*3;
  
  if (exe.getClientDate() > 20130605) {
    code +=
        " 88 01"          //MOV BYTE PTR DS:[ECX],AL
      + " E8 00 00 00 00" //CALL FN01 - String allocator
      ;
    var fn1Loc2 = code.length - 4*3;
  }
  else {
    code += " FF 15" + stringAlloc.packToHex(4); //CALL DWORD PTR DS:[FN01] - String allocator
    var fn1Loc2 = false;
  }
  
  var fn2Loc2 = code.length + 8*3;
  code +=
      " 8B 0D" + dsOff.packToHex(4) //MOV ECX,DWORD PTR DS:[RG01]
    + " 51"             //PUSH ECX
    + " E8 00 00 00 00" //CALL FN02 - Lua Function Caller
    + " 83 C4 2C"       //ADD ESP,2C
    + " 84 C0"          //TEST AL,AL
    + " 75 07"          //JNE SHORT skip EBP+8 overwrite
    + " C7 45 08" + zeroS.packToHex(4) //MOV DWORD PTR SS:[EBP+8], OFFSET Default Null Byte location
    + " 8D 0C BB"       //LEA ECX,[EDI*4+EBX]
    + " 8B 45 08"       //MOV EAX,DWORD PTR SS:[EBP+8]
    + " 89 01"          //MOV DWORD PTR DS:[ECX],EAX
    + " 47"             //INC EDI
    + " 81 FF" + max.packToHex(4) //CMP EDI,max value
    + " 7E 00"          //JLE SHORT back to MOV [EBP+8],0
    + " 61"             //POPAD
    + " 5D"             //POP EBP
    + " C3"             //RETN
    ;    
  var loopLoc = code.length - 4*3;
  
  //Step 4c - Store the strings
  code += " 00"
      + "GetShieldID\x00".toHex()
      + "ReqShieldName\x00".toHex()
      + "Lua Files\\DataInfo\\ShieldTable\x00".toHex()
      + "Lua Files\\DataInfo\\ShieldTable_F\x00".toHex()
      ;
      
  var csize = code.hexlength();
  var special = 0;
  
  //Step 4d - Special for 2013 clients - remove item id limitation.
  if (exe.getClientDate() >= 20130320) {
    special = 17;
    code +=
        " 50"             //PUSH EAX - backup
      + " 56"             //PUSH ESI - Argument (item id)
      + " E8 00 00 00 00" //CALL Mapcode          
      + " 5E"             //POP ESI
      + " 85 C0"          //TEST EAX, EAX
      + " 58"             //POP EAX - restore
      + " 74 03"          //JE skip negation
      + " 83 C8 FF"       //OR EAX, FFFFFFFF
      + " C3"             //RETN
      ;
  }
  
  //--- Create Lua Reader code ---//
  //Step 5a - Find offset of Lua Files\Effect\NewEffect_F
  var newEff = exe.findString("Lua Files\\DataInfo\\NPCIdentity", RVA);
  if (newEff === false)
    return "Failed in Step 5 - NPCIdentity not found";
  
  //Step 5b - Find pushed location
  offset = exe.findCode("68" + newEff.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 5 - NPCIdentity reference missing";
  
  //Step 5c - Function to call for reading file
  var lualoader = offset + 5 + 5 + exe.fetchDWord(offset + 6);
  
  //Step 5d - Return jmp location
  var jmpback = offset + 10;
  
  //Step 5e - Read out prefix to use before pushing file basename
  var jmper = exe.find(" 8B 8E AB AB 00 00", PTYPE_HEX, true, "\xAB", offset - 10, offset);//Need to overwrite to a jump at this location
  var prefsize = offset - jmper;
  var prefix = exe.fetchHex(jmper, prefsize);//prefix to use for file
  
  //Step 5f - Create Code
  var filecode = 
      prefix 
    + " 68 00 00 00 00"       //PUSH ShieldTable
    + " E8 00 00 00 00"        //CALL lualoader
    + prefix 
    + " 68 00 00 00 00"       //PUSH ShieldTable_F
    + " E8 00 00 00 00"        //CALL lualoader
    + prefix 
    + " 68" + newEff.packToHex(4)  //PUSH newEff
    + " E8 00 00 00 00"    //CALL lualoader
    + " E9 00 00 00 00"    //JMP back
    + " 90 90 90"
    ;
  var fsize = filecode.hexlength();
  
  //Step 6 - Find a place to put these codes in xDiff section (without affecting any future diffs)
  var totalsize = fsize + csize + special + 4;//alignment extra space probably not needed.
  var insertLocation = exe.findZeros(totalsize);
  if (insertLocation === -1)
    return "Failed in Step 6 - Not enough free space";
  
  //--- Fill in the blanks ---//
  //Step 7a - jmper has to jump to insertLocation
  exe.replace(jmper, "E9" + GetRvaDiff(insertLocation, jmper+5), PTYPE_HEX);
  
  //Step 7b - return jmp 
  filecode = filecode.replaceAt(-7*3, GetRvaDiff(jmpback, insertLocation + fsize-3));
  
  //Step 7c - Lua loaders
  filecode = filecode.replaceAt( 3*(1*(prefsize+10)-4), GetRvaDiff(lualoader, insertLocation + (prefsize + 10)*1) );
  filecode = filecode.replaceAt( 3*(2*(prefsize+10)-4), GetRvaDiff(lualoader, insertLocation + (prefsize + 10)*2) );
  filecode = filecode.replaceAt( 3*(3*(prefsize+10)-4), GetRvaDiff(lualoader, insertLocation + (prefsize + 10)*3) );
  
  var cbase = insertLocation + fsize;  //Lua Loader is done and code begins from this offset
  
  //Step 7d - ShieldTable & ShieldTable_F
  filecode = filecode.replaceAt( 3*(1*(prefsize+10)-9), StrPack(cbase + csize - 64) );
  filecode = filecode.replaceAt( 3*(2*(prefsize+10)-9), StrPack(cbase + csize - 33) );

  //Step 7e - GetShieldID & ReqShieldName
  code = code.replaceAt( rqLoc, StrPack(cbase + csize - 78) );
  code = code.replaceAt( gsLoc, StrPack(cbase + csize - 90) );
  
  //Step 7f - String Builders
  if (exe.getClientDate() > 20130605) {
    code = code.replaceAt(fn1Loc1, GetRvaDiff(stringAlloc, cbase + fn1Loc1/3 + 4) );
    code = code.replaceAt(fn1Loc2, GetRvaDiff(stringAlloc, cbase + fn1Loc2/3 + 4) );
  }  
  
  //Step 7g - Lua Function Callers    
  code = code.replaceAt(fn2Loc1, GetRvaDiff(luaFnCaller, cbase + fn2Loc1/3 + 4) );
  code = code.replaceAt(fn2Loc2, GetRvaDiff(luaFnCaller, cbase + fn2Loc2/3 + 4) );
  
  
  //Step 7h - Loop completion for Req  
  code = code.replaceAt(loopLoc, ((ReqBegin/3 + 9) - (loopLoc/3 + 1)).packToHex(1) );  
  
  //Step 7i - 2013 Special (specify call location)
  if (special > 0)
    code = code.replaceAt(3*(csize + 3), (0-(7 + csize)).packToHex(4));

  //Step 8 - Insert the generated string of codes    
  exe.insert(insertLocation, totalsize, filecode + code, PTYPE_HEX);
  
  //--- By this point Lua File reading is proper now we need to replace the other two functions ---//
  //Step 9a - At insReq we have MOV E*X, [ESI+####] ,we make it a known register first - EAX then PUSH it and call the function and skip the allocations below
  exe.replace(insReq + 1, " 86", PTYPE_HEX); //86 - mov to EAX
  exe.replace(insReq + 6, " 50 E8" + GetRvaDiff(cbase + ReqBegin/3, insReq + 12) + " 58 EB 31 8D 6D 00", PTYPE_HEX); //50 - PUSH EAX, E8 - function call, EB 31 - jmp short 31
  
  //Step 9b - Modify the hardcoded limits used for storage allocation
  offset = exe.find(" 8B AB 2B AB C1 F8 02 83 F8 05", PTYPE_HEX, true, "\xAB", insReq-90, insReq);
  var o2 = 9;
  if (offset === -1) {
    offset = exe.find(" 8B AB 2B AB C1 F8 02 C7 45 AB AB AB AB AB 83 F8 05", PTYPE_HEX, true, "\xAB", insReq-90, insReq);
    o2 = 16;
  }
  if (offset === -1)
    return "Failed in step 9 - 1st pattern missing";

  exe.replace(offset+o2, (max+1).packToHex(1), PTYPE_HEX);
  
  offset = exe.find(" 05 00 00 00 2B", PTYPE_HEX, false, " ", offset + 12, insReq); //Extra 2 to skip the jnb instruction that follows
  if (offset === -1)
    return "Failed in step 9 - 2nd pattern missing";

  exe.replace(offset, (max+1).packToHex(1), PTYPE_HEX);
  
  //Step 9c - For insMap we are going to add a wrapper function - i dunno why it makes sense
  code =
      " 55"       //PUSH EBP
    + " 8B EC"    //MOV EBP,ESP
    + " 8B 45 08" //MOV EAX,DWORD PTR SS:[EBP+8]
    + " 50"       //PUSH EAX
    + " E8" + GetRvaDiff(cbase, insMap + 12) //CALL Mapper
    + " 83 C4 04" //ADD ESP,4
    + " 5D"       //POP EBP
    + " C2 04 00" //RETN 4
    + " 90 90"    //NOP 2 times
    ;
  exe.replace(insMap, code, PTYPE_HEX);
  
  //Step 9d - Remove Job specific limiter
  offset = exe.findCode(" 3D D0 07 00 00 7E 06 50", PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in step 9 - 3rd pattern missing";
  
  code = 
      " 85 C0"          //TEST EAX, EAX
    + " 7E 0A"          //JLE skip to MOV EAX
    + " 83 F8" + max.packToHex(1) //CMP EAX, max
    + " 7F 05"          //JG skip to MOV EAX
    + " BE 01 00 00 00" //MOV ESI, 1 - dunno why inc is not used 
    + " 8B C6"          //MOV EAX,ESI
    + " 5E"             //POP ESI
    + " 8B FF"          //MOV EDI,EDI - replaced by POP EBP for VS10
    + " C2 08 00"       //RETN 8      
    ;
      
  if (exe.getClientDate() > 20130605)
    code = code.replaceAt(-5*3, " 5D 90"); //POP EBP; NOP

  exe.replace(offset+13, code, PTYPE_HEX);
  
  //Step 10 - 2013 Special. We need to make the hardcoded limit checking for item ids call our function instead.
  if(special > 0) {
    offset = exe.findCode(" 81 C6 CB F7 FF FF 83 C4 04", PTYPE_HEX, false);
    if (offset === -1)
      return "Failed in Step 10";
    
    exe.replace(offset   , " E8" + GetRvaDiff(cbase + csize, offset + 5) + " 90", PTYPE_HEX);
    exe.replace(offset+ 9, " 8D 6D 00", PTYPE_HEX);
    exe.replace(offset+13, " EB", PTYPE_HEX);
  }

  return true;
}

function GetRvaDiff(target, source) {
  return (exe.Raw2Rva(target) - exe.Raw2Rva(source)).packToHex(4);
}

function StrPack(offset) {
  return exe.Raw2Rva(offset).packToHex(4);
}