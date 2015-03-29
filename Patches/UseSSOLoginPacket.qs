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
      " A1" + LANGTYPE     // MOV EAX, DWORD PTR DS:[g_serviceType]
    + " 85 C0"             // TEST EAX, EAX
    + " 0F 84 AB AB AB AB" // JE addr
    + " 83 F8 12"          // CMP EAX, 12
    + " 0F 84 AB AB AB AB" // JE addr
    + " 83 F8 0C"          // CMP EAX, 0C
    + " 0F 84"             // JE addr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Change first JE to JMP
  exe.replace(offset+7, " 90 E9", PTYPE_HEX);
  
  return true;
}