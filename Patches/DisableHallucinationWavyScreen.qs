function DisableHallucinationWavyScreen() {
  /////////////////////////////////////////////////////////////////
  // GOAL: Find the special offset from CGameMode::Initialize    //
  //       function and check for its reference in Hallucination //
  //       Effect function and change the conditional jump to    //
  //       regular JMP to skip the Effect                        //
  /////////////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - Old Client doesnt have the address reference
  //         Need to find which client onwards the pattern
  //         is missing.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1a - Prep the pattern to find the address
  if (exe.getClientDate() <= 20130605) {
    var code = 
      " 83 C6 AB" // ADD ESI, addrOff
    + " 89 3D"    // MOV g_Special, EDI
    ;
  }
  else {
    var code =
      " 8D 4E AB" // LEA ECX, [ESI + addrOff]
    + " 89 3D"    // MOV g_Special, EDI
    ;
  }
  
  //Step 1b - Find the pattern
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 1c - Extract the Address
  var spAddr = exe.fetchHex(offset+5, 4);
  
  //Step 2 - Find the Special Offset reference
  code =
      " 8B AB"                   // MOV ECX, reg32
    + " E8 AB AB AB AB"          // CALL addr1
    + " 83 3D" + spAddr + " 00"  // CMP DWORD PTR DS:[g_Special], 0
    + " 0F 84"                   // JE LONG addr2
    ;

  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 2";
  
  //Step 3 - Replace the JE with NOP + JMP
  exe.replace(offset+14, " 90 E9", PTYPE_HEX);
  return true;
}