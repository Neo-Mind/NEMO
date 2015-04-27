function ReadQuestid2displaydottxt() {
  ///////////////////////////////////////////////////////////////
  // GOAL: NOP out the JNE to skip reading questID2display.txt //
  //       inside ITEM_INFO::InitItemInfoTables                //  
  ///////////////////////////////////////////////////////////////

  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - The pattern is different for old clients. 
  //         Find out which client changed it.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  // Step 1a - Find address of questID2display.txt
  var offset = exe.findString("questID2display.txt", RVA);
  if (offset === -1)
    return "Failed in Part 1 - questID2display not found";
  
  //Step 1b - Find the LangType comparison
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";

  if (exe.getClientDate() <= 20130605) {
    var code =
        " 83 3D" + LANGTYPE + " 00" // CMP DWORD PTR DS:[g_serviceType], 0
      + " 0F 85 AB 00 00 00"        // JNE addr1 -> Skip loading
      + " 6A 00"                    // PUSH 0
      + " 68" + offset.packToHex(4) // PUSH addr2 ; "questID2display.txt"
      ;
  }
  else {
    var code =
        " 83 3D" + LANGTYPE + " 00" // CMP DWORD PTR DS:[g_serviceType], 0
      + " 75 AB"                    // JNE SHORT addr1 -> Skip loading
      + " 6A 00"                    // PUSH 0
      + " 68" + offset.packToHex(4) // PUSH addr2 ; "questID2display.txt"
      ;
  }

  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";

  // Step 2 - NOP out the JNZ/JNE
  if (exe.getClientDate() <= 20130605)
    exe.replace(offset+7, " 90 90 90 90 90 90", PTYPE_HEX);
  else
    exe.replace(offset+7, " 90 90", PTYPE_HEX);
    
  return true;
}