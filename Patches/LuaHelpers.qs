//Globals
var D2D;
var D2S;
var IsAbsCall;
var StrAlloc;
var LuaState;
var LuaFnCaller;

function GetLuaRefs() {
  //Step 1a - Get d>s offset
  var offset = exe.findString("d>s", RVA);
  if (offset === -1)
    return "Failed in Part 1 - d>s not found";
  
  D2S = offset.packToHex(4);
  
  //Step 1b - Get d>d offset
  offset = exe.findString("d>d", RVA);
  if (offset === -1)
    return "Failed in Part 1 - d>d not found";
  
  D2D = offset.packToHex(4);
  
  //Step 2a - Get ReqAccName offset
  offset = exe.findString("ReqAccName", RVA);
  if (offset === -1)
    return "Failed in Part 2 - ReqAccName missing";
    
  //Step 2b - Find its reference
  offset = exe.findCode(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 2 - ReqAccName reference missing";
  
  //Step 2c - Get ReqJobName offset
  var offset2 = exe.findString("ReqJobName", RVA);
  if (offset2 === -1)
    return "Failed in Part 2 - ReqJobName missing";

  //Step 2d - Find its reference
  offset2 = exe.findCode(" 68" + offset2.packToHex(4), PTYPE_HEX, false);
  if (offset2 === -1)
    return "Failed in Part 2 - ReqJobName missing";
  
  //Step 3 - Extract addresses needed
  //----------------------------------------
  // StrAlloc  = String Allocation & Store
  // LuaState  = Address containing global lua_state value
  // LuaFnCaller = Calls the Pushed Function Name with the specified arguments based on the pattern.
  //             int LuaFnCaller(lua_state, funcName, argSpec, ....)
  
  if (exe.getClientDate() > 20130605) {
    IsAbsCall = false;
    StrAlloc  = exe.Raw2Rva(offset2 + 13) + exe.fetchDWord(offset2 + 9);//E8 call
    LuaState  = exe.fetchHex(offset2 + 22, 4);
    LuaFnCaller = exe.Raw2Rva(offset2 + 35) + exe.fetchDWord(offset2 + 31);
  }
  else {
    IsAbsCall = true;
    StrAlloc  = exe.fetchDWord(offset + 15);//FF 15 call
    LuaState  = exe.fetchHex(offset2 + 21, 4);
    LuaFnCaller = exe.Raw2Rva(offset + 47) + exe.fetchDWord(offset + 43);
  }
}

function GenLuaFnCall(insAddr, isNameFn, isMapper, fnLen, fnAddr, first, last, esiAddon) {
  var CDate = exe.getClientDate();
  var code = "";
  
  if (typeof(first) !== "undefined") {
    if (first === 0)
      code += " 31 FF"; //XOR EDI, EDI
    else
      code += " BF" + first.packToHex(4); //MOV EDI, first
  }
  
  if (typeof(last) !== "undefined") {
    if (last === 0)
      code += " 31 DB"; //XOR EBX, EBX
    else
      code += " BB" + last.packToHex(4);  //MOV EBX, last
  }
  
  var loopDiff = code.hexlength();
  
  code +=
      " C7 44 E4 08 00 00 00 00" //MOV DWORD PTR SS:[ESP+8], 0
    + " 8D 54 E4 08"             //LEA EDX,[ESP+8]
    + " 52"                      //PUSH EDX
    + " 57"                      //PUSH EDI
    ;

  if (isNameFn)
    code += " 68" + D2S;         //PUSH OFFSET addr1; "d>s"
  else
    code += " 68" + D2D;         //PUSH OFFSET addr1; "d>d"
    
  code +=
      " 83 EC 1C"                //SUB ESP,1C
    + " 89 E1"                   //MOV ECX,ESP
    ;

  if (CDate > 20130605) {
    code +=
        " 6A" + fnLen.packToHex(1)  //PUSH fnLen ; length of the Function name
      + " C7 41 14 0F 00 00 00"     //MOV DWORD PTR DS:[ECX+14],0F
      + " C7 41 10 00 00 00 00"     //MOV DWORD PTR DS:[ECX+10],0
      + " 68" + fnAddr.packToHex(4) //PUSH fnAddr ; Function name
      + " C6 01 00"                 //MOV BYTE PTR DS:[ECX],0
      ;
  }
  else {
    code += " 68" + fnAddr.packToHex(4); //PUSH fnAddr ; Function name
  }
  
  if (IsAbsCall)
    code += " FF 15" + StrAlloc.packToHex(4) ; //CALL DWORD PTR DS:[StrAlloc]
  else
    code += " E8" + (StrAlloc - exe.Raw2Rva(insAddr + code.hexlength() + 5)).packToHex(4); //CALL StrAlloc
  
  code += 
      " 8B 0D" + LuaState // MOV ECX, DWORD PTR DS:[g_LuaState]
    + " 51"               // PUSH ECX
    + " E8" + (LuaFnCaller - exe.Raw2Rva(insAddr + code.hexlength() + 12)).packToHex(4) //CALL LuaFnCaller
    + " 83 C4 2C"         // ADD ESP, 2C
    ;
  
  if (typeof(last) !== "undefined") {
    var code2 =
        " 84 C0"       //TEST AL, AL
      + " 74 F1"       //JE SHORT to INC EDI
      + " 8B 44 E4 08" //MOV EAX, DWORD PTR SS:[ESP+8]
      ;
      
    if (isMapper) {
      code2 += 
          " 40"    //INC EAX
        + " 85 C0" //TEST EAX, EAX
        + " 74 F2" //JE SHORT to INC EDI
        ;
    }
    else {
      code2 +=
          " 8B 10" //MOV EDX, DWORD PTR DS:[EAX]
        + " 84 D2" //TEST DL, DL
        + " 74 F2" //JE SHORT to INC EDI
        ;
    }
    
    if (esiAddon === 0)
      code2 += " 8B 16"; //MOV EDX, DWORD PTR DS:[ESI]
    else
      code2 += " 8B 96" + esiAddon.packToHex(4); //MOV EDX, DWORD PTR DS:[ESI+esiAddon]
    
    code2 += " 8D 0C BA"; //LEA ECX, [EDI*4+EDX]
    
    if (isMapper) {
      code2 +=
          " 8B 44 E4 08" // MOV EAX, DWORD PTR SS:[ESP+8]
        + " 8B 04 82"    // MOV EAX, DWORD PTR DS:[EAX*4 + EDX]
        ;
    }
    
    var jOff = code2.indexOf(" F1")/3 + 1;
    code2 = code2.replace(" F1", (code2.hexlength() + 2 - jOff).packToHex(1));
    
    jOff = code2.indexOf(" F2")/3 + 1;
    code2 = code2.replace(" F2", (code2.hexlength() + 2 - jOff).packToHex(1));
    
    code2 +=
        " 89 01" //MOV DWORD PTR DS:[ECX],EAX
      + " 47"    //INC EDI
      + " 39 DF" //CMP EDI,EBX
      + " 7E" + (-(code.hexlength() - loopDiff + code2.hexlength() + 7)).packToHex(1) //JLE SHORT to MOV DWORD PTR SS:[ESP+8], 0
      + " 90 90" //NOPs as a gapper in between
      ;
    
    code += code2;
  }
  
  return code;
}