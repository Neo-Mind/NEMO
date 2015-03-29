function DisableMultipleWindows() {
  //////////////////////////////////////////////////////
  // GOAL: Check for Existing Multiple Window Checker //
  //       and enforce Disabling. In case it is not   //
  //       present. Insert our own Code and make the  //
  //       client call it for checking                //
  //////////////////////////////////////////////////////
  
  //Step 1a - Find Existing checker
  var code = 
      " E8 AB AB AB FF"    // CALL addr1
    + " AB"                // PUSH reg32
    + " FF 15 AB AB AB 00" // CALL DWORD PTR DS:[<&func>] ; dunno what it should be but i doubt it is CoInitialize
    + " A1 AB AB AB 00"    // MOV EAX, DWORD PTR DS:[addr2]
    ;
    
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  var addon = 12;
  
  if (offset === -1) {
    code = 
        " E8 AB AB AB FF"    // CALL addr1
      + " 6A 00"             // PUSH 0
      + " FF 15 AB AB AB 00" // CALL DWORD PTR DS:[<&func>] ; dunno what it should be but i doubt it is CoInitialize
      + " A1 AB AB AB 00"    // MOV EAX, DWORD PTR DS:[addr2]
      ;
      
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    addon = 13;
  }
  
  if (offset !== -1) {
    //Step 2 - Replace the last EAX assignment with EAX = 0xFFFFFF
    exe.replace(offset + addon, " B8 FF FF FF", PTYPE_HEX);
  }
  else { 
    // Assuming this is a client where gravity already removed the Multiple Client check
    // We will have to put our own code like stated before.
    // To Do - Make sure it is the correct client and not just really old for the previous matches
    
    // Step 3a - Find the Error message string.
    code = "정상적인 라그나로크 클라이언트를 실행시켜 주시기 바랍니다.";

    offset = exe.findString(code, RVA);
    if (offset === -1)
      return "Failed in Step 3 - String not found";

    //Step 3b - Find its reference
    offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
    if (offset === -1)
      return "Failed in Step 3 - String reference not found";
      
    //Step 3c - Find "ResetTimer" call before the above reference (a call to CoInitialize should be there after ResetTimer)
    //          This is inside WinMain
    code = 
        " E8 AB AB AB AB"    // CALL ResetTimer
      + " AB"                // PUSH reg32
      + " FF 15 AB AB AB 00" // CALL DWORD PTR DS:[<&ole32.CoInitialize>]
      ;
      
    var offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x200, offset);
    if (offset === -1)
      return "Failed in Step 3 - ResetTimer not found";
    
    //Step 3d - Extract its address
    offset += 5;
    var resetTimer = exe.fetchDWord(offset-4) + exe.Raw2Rva(offset);
    
    //Step 4 - Prepare code for mutex windows
    code =
        " E8" + genVarHex(0)    // CALL ResetTimer
      + " 56"                // PUSH ESI
      + " 33 F6"             // XOR ESI,ESI
      + " E8 09 00 00 00"    // PUSH &JMP ; a little trick to use the string from
      + " 4B 45 52 4E 45 4C 33 32 00" // DB "KERNEL32",0
      + " FF 15" + genVarHex(1) // CALL DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>]
      + " E8 0D 00 00 00"    // PUSH &JMP
      + " 43 72 65 61 74 65 4D 75 74 65 78 41 00" // DB "CreateMutexA",0
      + " 50"                // PUSH EAX
      + " FF 15" + genVarHex(2) // CALL DWORD PTR DS:[<&KERNEL32.GetProcAddress>]
      + " E8 0F 00 00 00"    // PUSH &JMP
      + " 47 6C 6F 62 61 6C 5C 53 75 72 66 61 63 65 00" // DB "Global\Surface",0
      + " 56"                // PUSH ESI
      + " 56"                // PUSH ESI
      + " FF D0"             // CALL EAX
      + " 85 C0"             // TEST EAX,EAX
      + " 74 0F"             // JE addr1 -> ExitProcess call below
      + " 56"                // PUSH ESI
      + " 50"                // PUSH EAX
      + " FF 15" + genVarHex(3) // CALL DWORD PTR DS:[<&KERNEL32.WaitForSingleObject>]
      + " 3D 02 01 00 00"    // CMP EAX, 258  ; WAIT_TIMEOUT
      + " 75 2F"             // JNZ addr2 -> POP ESI below
      + " E8 09 00 00 00"    // PUSH &JMP ; addr1
      + " 4B 45 52 4E 45 4C 33 32 00" // DB "KERNEL32",0
      + " FF 15" + genVarHex(4) // CALL DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>]
      + " E8 0C 00 00 00"    // PUSH &JMP
      + " 45 78 69 74 50 72 6F 63 65 73 73 00" // DB "ExitProcess",0
      + " 50"                // PUSH EAX
      + " FF 15" + genVarHex(5) // CALL DWORD PTR DS:[<&KERNEL32.GetProcAddress>]
      + " 56"                // PUSH ESI
      + " FF D0"             // CALL EAX
      + " 5E"                // POP ESI ; addr2
      + " E9" + genVarHex(6)    // JMP AfterStolenCall
      ;
      
    //Step 6 - Get Free Offset
    var free = exe.findZeros(0x95);
    if (free === -1)
      return "Failed in Step 6 - Not enough free space";

    //Step 7 - Replace the resetTimer call with our code
    exe.replace(offset-5, "E9" + (exe.Raw2Rva(free)-exe.Raw2Rva(offset)).packToHex(4), PTYPE_HEX);
  
    //Step 8 - Fill the call instruction.
    code = remVarHex(code, 0, (resetTimer - exe.Raw2Rva(free + 5)));
    code = remVarHex(code, 1, exe.findFunction("GetModuleHandleA"   ));
    code = remVarHex(code, 2, exe.findFunction("GetProcAddress"     ));
    code = remVarHex(code, 3, exe.findFunction("WaitForSingleObject"));
    code = remVarHex(code, 4, exe.findFunction("GetModuleHandleA"   ));
    code = remVarHex(code, 5, exe.findFunction("GetProcAddress"     ));
    code = remVarHex(code, 6, (exe.Raw2Rva(offset) - exe.Raw2Rva(free + 0x95)));
    
    //Step 9 - Insert the ASM code
    exe.insert(free, 0x95, code, PTYPE_HEX);
  }
  
  return true;
}