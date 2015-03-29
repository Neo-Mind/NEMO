function DisableFilenameCheck() {
  //////////////////////////////////////////////////////////////////////
  // GOAL: Find the LangType comparison before Exe name check //
  //       and change the conditional jump to Regular JMP to skip it. //
  //////////////////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do: Old client doesnt have a seperate function for checking.
  //        its directly there in WinMain. Need to find which client
  //        date it changed.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1a - Construct the comparison code parts
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not Found";
    
  var codeA = " E8 AB AB AB FF"; // CALL CSession::Create
  
  var codeB = 
      " 39 AB" + LANGTYPE // CMP DWORD PTR DS:[g_ServiceType], reg32
    + " 75 AB"            // JNZ SHORT addr1
    + " E8 AB AB FF FF"   // CALL addr2 -> exe Name Check
    + " 84 C0"            // TEST AL, AL
    ;

  var jmpPos = 11;
  
  //Step 1b - Find the comparison - old pattern
  var offset = exe.findCode(codeA + codeB, PTYPE_HEX, true, "\xAB");
  
  //Step 1c - If it fails, Find the comparison - new pattern (1 XOR instruction in between)
  if (offset === -1) {  
    offset = exe.findCode(codeA + " AB AB" + codeB, PTYPE_HEX, true, "\xAB");
    jmpPos += 2;
  }
  
  if (offset === -1)
    return "Failed in Part 1";
  
  //Step 2 - Replace JNZ/JNE to JMP
  exe.replace(offset + jmpPos, "EB", PTYPE_HEX);
  
  return true;
}