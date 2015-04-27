function EnableMonsterInfo() {
  ///////////////////////////////////////////////////////////////////
  // GOAL: Change the Langtype comparison jump in the Monster talk //
  //       loader function
  ///////////////////////////////////////////////////////////////////
  
  //To Do - Old clients dont have this pattern.
  
  //Step 1 - Find the Comparison - Hint: Case 2723 of switch and it appears before PUSH "uae\"
  
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";
 
  var code = 
      LANGTYPE             //MOV reg32_A, DWORD PTR DS:[g_serviceType]
    + " 83 C4 04"          //ADD ESP, 4
    + " 83 AB 13"          //CMP reg32_A, 13
    + " 0F 85 AB 00 00 00" //JNE addr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1 -  Comparison not found";
    
  //Step 2 - Swap JNE with NOP + JMP
  exe.replace(offset + code.hexlength() - 6, " 90 E9", PTYPE_HEX);
  
  return true;
}