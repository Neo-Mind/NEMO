function RemoveGMSprite() {
  ///////////////////////////////////////////////////////////////////
  // GOAL: NOP out the GM ID comparison inside CPc::SetSprNameList //
  //       and CPc::SetActNameList functions                       //
  ///////////////////////////////////////////////////////////////////
  
  //Step 1a - Find the location where both functions are called
  var code = 
      " 68 AB AB AB 00" //PUSH OFFSET addr; actName
    + " 6A 05"          //PUSH 5; layer
    + " 8B AB"          //MOV ECX, reg32_A
    + " E8 AB AB FF FF" //CALL CPc::SetActNameList
    ;
  var len = code.hexlength();
  
  code += code; //PUSH OFFSET addr; sprName
                //PUSH 5; layer
                //MOV ECX, reg32_A 
                //CALL CPc::SetSprNameList
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1) {
    code = code.replace(" 8B AB"); //Remove the first MOV ECX, reg32_A . It might have been assigned earlier
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Part 1";
  
  offset += code.hexlength() - len;
  
  //Step 1b - Extract the Function addresses (RAW)
  var funcs = [];
  funcs[0] = offset + exe.fetchDWord(offset - 4);
  funcs[1] = offset + len + exe.fetchDWord(offset + len - 4);
  
  //Step 2a - Prep code to look for IsNameYellow function call
  code = 
      " E8 AB AB AB AB" //CALL IsNameYellow
    + " 83 C4 04"       //ADD ESP, 4
    + " 84 C0"          //TEST AL, AL
    + " 0F 84"          //JNE addr2
    ;
    
  for (var i = 0; i < funcs.length; i++) {
    //Step 2b - Find the call
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", funcs[i]);
    if (offset === -1)
      return "Failed in Part 2 - Function call missing for iteration " + i;
    
    //Step 2c - Replace JNE with NOP + JMP
    exe.replace(offset + code.hexlength() - 2, " 90 E9", PTYPE_HEX);
  }
  
  return true;
}