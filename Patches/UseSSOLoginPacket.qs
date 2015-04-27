function UseSSOLogin() {
  ///////////////////////////////////////////////
  // GOAL: Modify the Conditional Jump to send //
  //       SSO Login Packet                    //
  ///////////////////////////////////////////////
  
  //To Do - did not find it in old client
  
  //Step 1 - Find the LangType comparison
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";
    
  var code =
      LANGTYPE             // MOV reg32_A, DWORD PTR DS:[g_serviceType]
    + " 85 AB"             // TEST reg32_A, reg32_A
    + " 0F 84 AB AB 00 00" // JE addr
    + " 83 AB 12"          // CMP reg32_A, 12
    + " 0F 84 AB AB 00 00" // JE addr
    + " 83 AB 0C"          // CMP reg32_A, 0C
    + " 0F 84"             // JE addr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Change first JE to JMP
  exe.replace(offset+6, " 90 E9", PTYPE_HEX);
  
  return true;
}