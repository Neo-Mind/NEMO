function UseAsciiOnAllLangtypes() {
  /////////////////////////////////////////////////////////
  // GOAL: Fix up the JNZ inside CSession::IsOnlyEnglish // 
  //       function to ignore Langtype comparison        //
  /////////////////////////////////////////////////////////
  
  // Step 1 - Find the comparison. JNZ is the very next instruction
  //          TEST BYTE PTR DS:[reg32_A + reg32_B], 80 
  //          JNZ SHORT addr
  var offset = exe.findCode("F6 04 AB 80 75", PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1";
  
  // Step 2 - NOP out the JNZ
  exe.replace(offset+4, " 90 90", PTYPE_HEX);
  
  return true;
}