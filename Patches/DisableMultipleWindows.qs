function DisableMultipleWindows() {
  //////////////////////////////////////////////////////
  // GOAL: Check for Existing Multiple Window Checker //
  //       and enforce Disabling. In case it is not   //
  //       present. Insert our own Code and make the  //
  //       client call it for checking                //
  //////////////////////////////////////////////////////
  
  //Step 1a - Find Address of ole32.CoInitialize function
  var offset = exe.findFunction("CoInitialize");
  if (offset === -1)
    return "Failed in Part 1 - CoInitialize not found";
  
  var coInit = offset.packToHex(4);
  
  //Step 1b - Find where it is called from.
  var code = 
      " E8 AB AB AB FF" //CALL ResetTimer
    + " AB"             //PUSH reg32
    + " FF 15" + coInit //CALL DWORD PTR DS:[<&ole32.CoInitialize>]
    ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" FF AB", " FF 6A 00");
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Part 1 - CoInitialize call missing";
  
  //Step 1c - If the MOV EAX statement follows the above its the old client where Multiple client check is there,
  //          So Replace it with MOV EAX, 00FFFFFF
  var opcode = exe.fetchByte(offset + code.hexlength());
  if (opcode === 0xA1) {//MOV EAX, DWORD PTR DS:[addr]
    exe.replace(offset + code.hexlength(), " B8 FF FF FF 00");
    return true;
  }
   
  // Assuming this is a client where Gravity already removed the Multiple Client check
  // We will have to put our own code like stated before.
  
  // To Do - Make sure it is the correct client and not just really old for the previous match
    
  //Step 2a - Extract the ResetTimer function address (called before CoInitialize)
  offset += 5;
  var resetTimer = exe.fetchDWord(offset-4) + exe.Raw2Rva(offset);
    
  //Step 2b - Prepare code for mutex windows
  code =
      " E8" + genVarHex(0)    // CALL ResetTimer
    + " 56"                   // PUSH ESI
    + " 33 F6"                // XOR ESI,ESI
    + " E8 09 00 00 00"       // PUSH &JMP ; a little trick to use the string from
    + " 4B 45 52 4E 45 4C 33 32 00" // DB "KERNEL32",0
    + " FF 15" + genVarHex(1) // CALL DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>]
    + " E8 0D 00 00 00"       // PUSH &JMP
    + " 43 72 65 61 74 65 4D 75 74 65 78 41 00" // DB "CreateMutexA",0
    + " 50"                   // PUSH EAX
    + " FF 15" + genVarHex(2) // CALL DWORD PTR DS:[<&KERNEL32.GetProcAddress>]
    + " E8 0F 00 00 00"       // PUSH &JMP
    + " 47 6C 6F 62 61 6C 5C 53 75 72 66 61 63 65 00" // DB "Global\Surface",0
    + " 56"                   // PUSH ESI
    + " 56"                   // PUSH ESI
    + " FF D0"                // CALL EAX
    + " 85 C0"                // TEST EAX,EAX
    + " 74 0F"                // JE addr1 -> ExitProcess call below
    + " 56"                   // PUSH ESI
    + " 50"                   // PUSH EAX
    + " FF 15" + genVarHex(3) // CALL DWORD PTR DS:[<&KERNEL32.WaitForSingleObject>]
    + " 3D 02 01 00 00"       // CMP EAX, 258  ; WAIT_TIMEOUT
    + " 75 2F"                // JNZ addr2 -> POP ESI below
    + " E8 09 00 00 00"       // PUSH &JMP ; addr1
    + " 4B 45 52 4E 45 4C 33 32 00" // DB "KERNEL32",0
    + " FF 15" + genVarHex(4) // CALL DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>]
    + " E8 0C 00 00 00"       // PUSH &JMP
    + " 45 78 69 74 50 72 6F 63 65 73 73 00" // DB "ExitProcess",0
    + " 50"                   // PUSH EAX
    + " FF 15" + genVarHex(5) // CALL DWORD PTR DS:[<&KERNEL32.GetProcAddress>]
    + " 56"                   // PUSH ESI
    + " FF D0"                // CALL EAX
    + " 5E"                   // POP ESI ; addr2
    + " E9" + genVarHex(6)    // JMP AfterStolenCall
    ;
    
  var csize = code.hexlength();
  
  //Step 2c - Get Free Offset
  var free = exe.findZeros(csize);
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";

  //Step 2d - Replace the resetTimer call with our code
  exe.replace(offset-5, "E9" + (exe.Raw2Rva(free)-exe.Raw2Rva(offset)).packToHex(4), PTYPE_HEX);
  
  //Step 2e - Fill the call instruction.
  code = remVarHex(code, 0, (resetTimer - exe.Raw2Rva(free + 5)));
  code = remVarHex(code, 1, exe.findFunction("GetModuleHandleA"   ));
  code = remVarHex(code, 2, exe.findFunction("GetProcAddress"     ));
  code = remVarHex(code, 3, exe.findFunction("WaitForSingleObject"));
  code = remVarHex(code, 4, exe.findFunction("GetModuleHandleA"   ));
  code = remVarHex(code, 5, exe.findFunction("GetProcAddress"     ));
  code = remVarHex(code, 6, (exe.Raw2Rva(offset) - exe.Raw2Rva(free + csize)));
  
  //Step 2f - Insert the ASM code
  exe.insert(free, csize, code, PTYPE_HEX);
  
  return true;
}