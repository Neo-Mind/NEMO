function KoreaServiceTypeXMLFix() {
  ///////////////////////////////////////////////////////////
  // GOAL: Remove the jmp after SelectKoreaClientInfo call //
  //       so that SelectClientInfo also gets called.      //
  ///////////////////////////////////////////////////////////

  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - Pattern differs for old clients & there is more than 1 called location.
  //        Find out when it changed.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1 - Find the called location
  var code = 
      " E8 AB AB FF FF"  // CALL SelectKoreaClientInfo
    + " E9 AB AB FF FF"  // JMP addr
    + " 6A 00"           // PUSH 0
    + " E8 AB AB FF FF"  // CALL SelectClientInfo
    + " 83 C4 04"        // ADD ESP, 4
    ;
    
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset == -1)
    return "Failed in part 1";
  
  //Step 2 - NOP out the JMP instruction
  exe.replace(offset+5, " 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}

// Note:
// Gravity has their clientinfo hardcoded and seperated the initialization, screw "em.. :(
// SelectKoreaClientInfo() has for example global variables like g_extended_slot set
// which aren"t set by SelectClientInfo(). Just call both functions will fix this as the
// changes from SelectKoreaClientInfo() will persist and overwritten by SelectClientInfo().