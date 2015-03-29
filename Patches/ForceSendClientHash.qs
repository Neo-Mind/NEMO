function ForceSendClientHash() {
  /////////////////////////////////////////////////////////////////////////
  // GOAL: Find the comparisons in CLoginMode::CheckExeHashFromAccServer //
  //       and change all the conditional jumps to regular jmp so that   //
  //       the MD5 hash is always sent irrespective of LangType          //
  /////////////////////////////////////////////////////////////////////////
  
  //Step 1a - Find the 1st LangType comparison
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";
    
  var code =  
      " 8B AB" + LANGTYPE // MOV reg32,DWORD PTR DS:[g_serviceType]
    + " 33 C0"            // XOR EAX, EAX
    + " 83 AB 06"         // CMP reg32, 6
    + " 74"               // JE SHORT addr -> (to MOV EAX, 1)
    ;
    
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1";
  
  //Step 1b - Replace JE with JMP
  exe.replace(offset+11, " EB", PTYPE_HEX);
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - 2nd and 3rd comparison codes are different for old clients
  //         need to check which date onwards it changed
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 2a - Find the 2nd comparison
  code =
      " 85 C0"  // TEST EAX, EAX
    + " 75 AB"  // JNE SHORT addr1
    + " A1"     // MOV EAX, DWORD PTR DS:[addr2]
    ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+12);
  if (offset === -1)
    return "Failed in Part 2";
  
  //Step 2b - Replace JNE with JMP
  exe.replace(offset+2, "EB", PTYPE_HEX);
  
  //Step 3a - Find the last comparison
  code =
      " 83 F8 06"  //CMP EAX, 6
    + " 75"        //JNE SHORT addr3
    ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+9);
  if (offset === -1)
    return "Failed in Part 3";
  
  //Step 3b - Replace JNE with JMP
  exe.replace(offset+3, "EB", PTYPE_HEX);
  return true;
}