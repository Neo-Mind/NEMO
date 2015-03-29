function ReadQuestid2displaydottxt() {
  ///////////////////////////////////////////////////////////////
  // GOAL: NOP out the JNE to skip reading questID2display.txt //
  //       inside ITEM_INFO::InitItemInfoTables                //  
  ///////////////////////////////////////////////////////////////

  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - The pattern is different for old clients. 
  //         Find out which client changed it.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  // Step 1 - Find the LangType comparison
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";

  if (exe.getClientDate() <= 20130605) {
    var code =
        " 83 3D" + LANGTYPE + " 00" // CMP DWORD PTR DS:[g_serviceType], 0
      + " 0F 85 CB 00 00 00"        // JNE addr1 -> Skip loading
      + " 6A 00"                    // PUSH 0
      + " 68 AB AB AB 00"           // PUSH addr2 ; "questID2display.txt"
      + " 8D 44 24 30"              // LEA EAX, [ESP+30]
      ;
  }
  else {
    var code =
        " 83 3D" + LANGTYPE + " 00" // CMP DWORD PTR DS:[g_serviceType], 0
      + " 75 5E"                    // JNE SHORT addr1 -> Skip loading
      + " 6A 00"                    // PUSH 0
      + " 68 AB AB AB 00"           // PUSH addr2 ; "questID2display.txt"
      + " 8D 55 C8"                 // LEA EDX, [EBP-38]
      ;
  }

  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";

  // Step 2 - NOP out the JNZ
  if (exe.getClientDate() <= 20130605)
    exe.replace(offset+7, " 90 90 90 90 90 90", PTYPE_HEX);
  else
    exe.replace(offset+7, " 90 90", PTYPE_HEX);
    
  return true;
}