function AllowSpaceInGuildName() {
  /////////////////////////////////////////////////////////////
  // GOAL: Change the Character being checked in Guild names //
  //       inside CGameMode::SendMsg from space to !         //
  /////////////////////////////////////////////////////////////
  
  // Step 1a - Find the comparison code
  var code = 
      " 6A 20"             //PUSH 20
    + " AB"                //PUSH reg32_B
    + " FF AB"             //CALL reg32_A; MSVCR#.strchr
    + " 83 C4 08"          //ADD ESP, 8
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1";

  // Step 2 - Replace 20 (blank space) with 21 (!)
  exe.replace(offset+1, "21", PTYPE_HEX);
  
  return true;
}