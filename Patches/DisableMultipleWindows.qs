//#############################################################################
//# Purpose: Check for Existing Multiple Window Checker and enforce Disabling #
//#          If not present, insert custom code to do the check + disable     #
//#############################################################################

function DisableMultipleWindows() {
  
  //Step 1a - Find Address of ole32.CoInitialize function
  var offset = GetFunction("CoInitialize", "ole32.dll");
  if (offset === -1)
    return "Failed in Step 1 - CoInitialize not found";
  
  //Step 1b - Find where it is called from.
  var code = 
    " E8 AB AB AB FF" //CALL ResetTimer
  + " AB"             //PUSH reg32
  + " FF 15" + offset.packToHex(4) //CALL DWORD PTR DS:[<&ole32.CoInitialize>]
  ;    
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" FF AB", " FF 6A 00");//Change PUSH reg32 with PUSH 0
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1 - CoInitialize call missing";
  
  //Step 1c - If the MOV EAX statement follows the CoInitialize call then it is the old client where Multiple client check is there,
  //          Replace the statement with MOV EAX, 00FFFFFF
  if (exe.fetchUByte(offset + code.hexlength()) === 0xA1) {
    exe.replace(offset + code.hexlength(), " B8 FF FF FF 00");
    return true;
  }

  //=====================================================================================//
  // Now since the MOV was not found we can assume the Multiple Client check is removed. //
  // Hence we will put our own Checker code                                              // 
  //=====================================================================================//
    
  //Step 2a - Extract the ResetTimer function address (called before CoInitialize)
  offset += 5;
  var resetTimer = exe.fetchDWord(offset-4) + exe.Raw2Rva(offset);
    
  //Step 2b - Prepare code for mutex windows
  code =
    " E8" + GenVarHex(0)    // CALL ResetTimer
  + " 56"                   // PUSH ESI
  + " 33 F6"                // XOR ESI,ESI
  + " E8 0F 00 00 00"       // PUSH &JMP
  + " 47 6C 6F 62 61 6C 5C 53 75 72 66 61 63 65 00" // DB "Global\Surface",0
  + " 56"                   // PUSH ESI
  + " 56"                   // PUSH ESI
  + " FF 15" + GenVarHex(1) // CALL DWORD PTR DS:[<&KERNEL32.CreateMutexA>]
  + " 85 C0"                // TEST EAX,EAX
  + " 74 0F"                // JE addr1 -> ExitProcess call below
  + " 56"                   // PUSH ESI
  + " 50"                   // PUSH EAX
  + " FF 15" + GenVarHex(2) // CALL DWORD PTR DS:[<&KERNEL32.WaitForSingleObject>]
  + " 3D 02 01 00 00"       // CMP EAX, 258  ; WAIT_TIMEOUT
  + " 75 07"                // JNZ addr2 -> POP ESI below
  + " 56"                   // PUSH ESI
  + " FF 15" + GenVarHex(3) // CALL DWORD PTR DS:[<&KERNEL32.ExitProcess>]
  + " 5E"                   // POP ESI ; addr2
  + " E9" + GenVarHex(4)    // JMP AfterStolenCall
  ;
    
  var csize = code.hexlength();
  
  //Step 2c - Allocate space to store the code
  var free = exe.findZeros(csize);
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";

  //Step 2d - Replace the resetTimer call with our code
  exe.replace(offset - 5, "E9" + (exe.Raw2Rva(free) - exe.Raw2Rva(offset)).packToHex(4), PTYPE_HEX);
  
  //Step 2e - Fill in the blanks
  code = ReplaceVarHex(code, 0, (resetTimer - exe.Raw2Rva(free + 5)));
  code = ReplaceVarHex(code, 1, GetFunction("CreateMutexA", "KERNEL32.dll"));
  code = ReplaceVarHex(code, 2, GetFunction("WaitForSingleObject", "KERNEL32.dll"));
  code = ReplaceVarHex(code, 3, GetFunction("ExitProcess", "KERNEL32.dll"));
  code = ReplaceVarHex(code, 4, (exe.Raw2Rva(offset) - exe.Raw2Rva(free + csize)));
  
  //Step 2f - Insert the code to allocated space
  exe.insert(free, csize, code, PTYPE_HEX);
  
  return true;
}