function Disable1rag1Params() {
  /////////////////////////////////////////////////////
  // GOAL: Find the 1rag1 comparison and change the  //
  //       conditional jump to a regular JMP         //
  /////////////////////////////////////////////////////
  
  //Step 1a - Find offset of '1rag1'
  var rag1 = exe.findString("1rag1", RVA).packToHex(4);
  
  //Step 1b - Find its reference
  var code =
      " 68" + rag1  // PUSH OFFSET a1RAG1   ; "1rag1"
    + " AB"         // PUSH EBP             ; Str
    + " FF AB"      // CALL ESI             ; strstr function compares Str with "1rag1"
    + " 83 AB AB"   // ADD  ESP, 8
    + " 85 AB"      // TEST EAX, EAX
    + " 75 AB"      // JNZ  SHORT addr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if( offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Replace JNZ/JNE with JMP
  exe.replace(offset+13, "EB", PTYPE_HEX);
  
  return true;
}