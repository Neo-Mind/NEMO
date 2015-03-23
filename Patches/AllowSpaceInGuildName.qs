function AllowSpaceInGuildName() {
  /////////////////////////////////////////////////////////////
  // GOAL: Change the Character being checked in Guild names //
  //       inside CGameMode::SendMsg from space to !         //
  /////////////////////////////////////////////////////////////
  
  // Step 1a - Prep the comparison code
  if (exe.getClientDate() <= 20130605) {
    var code = 
        " 6A 20"    // PUSH 20
      + " 53"       // PUSH EBX
      + " FF D6"    // CALL ESI
      + " 83 C4 08" // ADD ESP, 8
      ;
  }
  else {
    var code = 
        " 6A 20"    // PUSH 20
      + " 56"       // PUSH ESI
      + " FF D7"    // CALL EDI
      + " 83 C4 08" // ADD ESP, 8
      ;
  }
  
  // Step 1b - Find the code
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1";

  // Step 2 - Replace 20 (blank space) with 21 (!)
  exe.replace(offset+1, "21", PTYPE_HEX);
  
  return true;
}