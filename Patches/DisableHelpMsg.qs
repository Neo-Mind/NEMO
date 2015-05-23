function DisableHelpMsg() {
  ///////////////////////////////////////////////////////////
  // GOAL: Change the Langtype comparison JNE to JMP which //
  //       skips calling the HelpMsgStr loader function    //
  ///////////////////////////////////////////////////////////
  
  //Step 1a - Find the Unique PUSHes after the comparison . This is same for all clients
  var code = 
    " 6A 0E" //PUSH 0E
  + " 6A 2A" //PUSH 2A
  ;

  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 1 - Signature PUSHes missing";
  
  //Step 1b - Now find the comparison before it
  var LANGTYPE = getLangType();
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";
  
  code = 
    LANGTYPE //CMP DWORD PTR DS:[g_serviceType], reg32_A
  + " 75"    //JNE addr
  ;
  offset2 = exe.find(code, PTYPE_HEX, false, "", offset - 0x20, offset);
  
  if (offset2 === -1) {
    code = code.replace(" 75", " 00 75");//directly compared to 0
    offset2 = exe.find(code, PTYPE_HEX, false, "", offset - 0x20, offset);  
  }
  
  if (offset2 === -1)
    return "Failed in Part 1 - Comparison not found";
  
  //Step 2 - Replace JNE with JMP
  exe.replace(offset2 + code.hexlength() - 1, "EB", PTYPE_HEX);
  
  return true;
}