function EnableCustomShields() {
  ///////////////////////////////////////////////////////
  // GOAL: Modify the hardcoded Shield prefix table    //
  //       assignments to load them using Lua function //
  //       instead.                                    //
  ///////////////////////////////////////////////////////
  var maxShield = 10;
  
  //--- Find first function insert location (function for storing the shield suffixes in memory) and accompanying values needed ---//
  //Step 1a - Locate _가드 (Guard's suffix)
  var offset = exe.findString("_가드", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Guard not found";
  
  //Step 1b - Find location where it is referenced (moved to memory location)
  var code = " C7 AB 04" + offset.packToHex(4); //MOV DWORD PTR DS:[E*X+4],OFFSET <guard suffix>
  var insReq = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (insReq === -1)
    return "Failed in Step 1 - Guard reference missing";
  
  //Step 1c - Extract the ESI+const
  if (exe.fetchByte(insReq-2) === 0)
    var esiAddon = exe.fetchDWord(insReq-4);
  else
    var esiAddon = 0;
  
  //Step 1d - Find the return jmp address to skip hard loading
  offset = exe.findString("_버클러", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Buckler not found";
  
  code = " C7 AB 08" + offset.packToHex(4); //MOV DWORD PTR DS:[E*X+4],OFFSET <guard suffix>
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", insReq, insReq + 0x31)
  if (offset === -1)
    return "Failed in Step 1 - Buckler reference missing";
  
  var jmpReq = offset + 7;
  
  //--- Find second function insert location (function for mapping storage id from item id) ---//
  //Step 2a - Find location where the original mapping function is called
  code = 
      " 3D D0 07 00 00" //CMP EAX, 7D0
    + " 7E AB"          //JLE SHORT addr1
    + " 50"             //PUSH EAX
    + " B9 AB AB AB 00" //MOV ECX, TableRef <= its the value assigned to ESI when table is loaded.
    + " E8 AB AB AB AB" //CALL addr2 <= The called address is what we are looking for
    + " 89 86"          //MOV DWORD PTR DS:[ESI+const], EAX
    ;
    
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 2";
  
  //Step 2b - Extract function address
  var insMap = offset + 18 + exe.fetchDWord(offset + 14);
  
  //Step 3 - Get Lua Constants and Function addresses ---//
  GetLuaRefs();  
  
  //--- Get details for Lua File reader ---//
  //Step 4a - Find offset of jobName
  var jobName = exe.findString("Lua Files\\DataInfo\\jobName", RVA);
  if (jobName === -1)
    return "Failed in Part 4 - jobName not found";
  
  //Step 4b - Find its reference
  offset = exe.findCode(" 68" + jobName.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 4 - jobName reference missing";
  
  //Step 4c - Extract the common assignments for Lua file loading 
  //          MOV ECX, DS:[ESI+const] ; lua_state 
  //          followed by argument PUSHes before jobName PUSH
  var hookPoint = exe.find(" 8B 8E AB AB 00 00", PTYPE_HEX, true, "\xAB", offset - 10, offset);
  if (hookPoint === -1)
    return "Failed in Part 4 - Loading code has changed";
  
  var hookReturn = offset + 10;
  var preSize = offset - hookPoint;
  var preCode = exe.fetchHex(hookPoint, preSize);
  var luaLoader = offset + 10 + exe.fetchDWord(offset+6);
  
  //--- Insert Lua file reader codes ---//
  //Step 5a - Prepare code template and names
  var names = [
    "Lua Files\\DataInfo\\ShieldTable\x00",
    "Lua Files\\DataInfo\\ShieldTable_F\x00"
  ];
  
  var template =
        preCode
      + " 68" + genVarHex(1)
      + " E8" + genVarHex(2)
      ;
  var tmplSize = preSize + 10;
  
  //Step 5b - Allocate space for the names & code
  var nameSize = 0;
  for (var i = 0; i < names.length; i++) {
    nameSize += names[i].length;
  }
  
  var codeSize = (names.length + 1) * tmplSize + 5;
  
  var free = exe.findZeros(nameSize + codeSize);
  if (free === -1)
    return "Failed in Part 5 - Not enough space";
  
  //Step 5c - Build the code using the template for all the files.
  code = names.join("").toHex();
  
  var fnLoad = free + nameSize;
  var fileRVA = exe.Raw2Rva(free);
  var diff = exe.Raw2Rva(luaLoader) - exe.Raw2Rva(fnLoad + tmplSize);
  
  for (var i = 0; i < names.length; i++) {
    code += remVarHex(template, [1, 2], [fileRVA, diff]);
    diff -= tmplSize;
    fileRVA += names[i].length;
  }
  
  code += remVarHex(template, [1, 2], [jobName, diff]);
  code += " E9" + (exe.Raw2Rva(hookReturn) - exe.Raw2Rva(fnLoad + codeSize)).packToHex(4);

  //Step 5f - Insert it too
  exe.insert(free, nameSize + codeSize, code, PTYPE_HEX);
  
  //--- Build Lua caller code ---//
  //Step 6a - Allocate space for the code using max possible size
  free = exe.findZeros(0x100);
  
  //Step 6b - Build the first code for GetShieldID. 
  //          Since it is going to be run from 2 locations we implement it as a function.
  names = [
    "GetShieldID\x00",
    "ReqShieldName\x00"
  ];
  
  code = names.join("").toHex();
  
  var fnGet = free + code.hexlength();//Offset of first code (function)
  
  code += 
      " 55"          //PUSH EBP
    + " 8B EC"       //MOV EBP, ESP
    + " 51"          //PUSH ECX
    + " 52"          //PUSH EDX
    + " 57"          //PUSH EDI
    + " 83 EC 0C"    //SUB ESP,0C
    + " 8B 7D 08"    //MOV EDI, DWORD PTR SS:[ARG.1]
    ;
  
  code += GenLuaFnCall(free + code.hexlength(), false, false, names[0].length-1, exe.Raw2Rva(free));
  
  code +=
      " 8B 44 24 08" //MOV EAX,DWORD PTR SS:[ESP+8]
    + " 83 C4 0C"    //ADD ESP,0C    
    + " 5F"          //POP EDI
    + " 5A"          //POP EDX
    + " 59"          //POP ECX
    + " 5D"          //POP EBP
    + " C2 04 00"    //RETN 4
    ;
   
  //6c - Build second code for ReqShieldName
  var fnReq = free + code.hexlength();//Offset of second code
  
  code += 
      " 83 EC 08" //SUB ESP, 8
    + GenLuaFnCall(fnReq+3, true, false, names[1].length-1, exe.Raw2Rva(free+names[0].length), 0, maxShield, esiAddon)
    + " 83 C4 08" //ADD ESP, 8
    ;
  
  code += " E9" + (exe.Raw2Rva(jmpReq) - exe.Raw2Rva(free + code.hexlength() + 5)).packToHex(4);
  
  //6d - Insert both codes
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);
  
  //6e - Add call/jmp to our codes in their respective locations
  code = " E9" + (exe.Raw2Rva(fnReq) - exe.Raw2Rva(insReq+5)).packToHex(4);
  exe.replace(insReq, code, PTYPE_HEX);
  
  code = " E9" + (exe.Raw2Rva(fnGet) - exe.Raw2Rva(insMap+5)).packToHex(4);
  exe.replace(insMap, code, PTYPE_HEX);
  
  code = " E9" + (exe.Raw2Rva(fnLoad) - exe.Raw2Rva(hookPoint+5)).packToHex(4);
  exe.replace(hookPoint, code, PTYPE_HEX);
  
  //--- 2013+ Special : Item Id Limitation removal ---//
  if (exe.getClientDate() >= 20130320) {
    //Step 7a - Prep code to call our function and return value in EAX accordingly
    code = 
        " 50"        //PUSH EAX ; backup
      + " 56"        //PUSH ESI ; Argument 1 (item id)
      + " E8" + genVarHex(1) //CALL Mapcode
      + " 85 C0"     //TEST EAX, EAX
      + " 58"        //POP EAX ; restore
      + " 74 03"     //JE SHORT addr -> RETN ; skip negation
      + " 83 C8 FF"  //OR EAX, FFFFFFFF
      + " C3"        //RETN
      ;
    
    //Step 7b - Allocate space for it.
    free = exe.findZeros(code.hexlength());
    if (free === -1)
      return "Failed in Part 7 - Not enough space";
    
    code = remVarHex(code, 1, exe.Raw2Rva(fnGet) - exe.Raw2Rva(free+7));
    
    //Step 7c - Insert the code
    exe.insert(free, code.hexlength(), code, PTYPE_HEX);
    
    //Step 7d - Find the hardcoded limit checking
    code = 
        " 81 C6 CB F7 FF FF" //ADD ESI,-835
      + " 83 C4 04"          //ADD ESP,4
      + " 83 FE 62"          //CMP ESI,62
      + " 5E"                //POP ESI
      + " 77 03"             //JA SHORT addr -> RETN
      ;
    
    offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset === -1)
      return "Failed in Part 7 - Limit Checker not found";
    
    //Step 7e - Fixup the code to call our function and return directly.
    code = 
        " 90 E8" + (exe.Raw2Rva(free) - exe.Raw2Rva(offset+6)).packToHex(4) //CALL func
      + " 83 C4 04" //ADD ESP,4
      + " 5E"       //POP ESI
      + " 5D"       //POP EBP
      + " C2 04 00" //RETN 4
      ;
      
    exe.replace(offset, code, PTYPE_HEX);
  }
  
  return true;
}