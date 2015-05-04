function KoreaServiceTypeXMLFix() {
  ///////////////////////////////////////////////////////////
  // GOAL: Remove the jmp after SelectKoreaClientInfo call //
  //       so that SelectClientInfo also gets called       //
  //       in all areas where it happens                   //
  ///////////////////////////////////////////////////////////

  //Step 1a - Find offset of error string.
  var offset = exe.findString("Unknown ServiceType !!!", RVA);
  if (offset === -1)
    return "Failed in Part 1 - Error String missing";
  
  //Step 1b - Find all its references
  var offsets = exe.findCodes(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Part 1 - No references found";
  
  for (var i = 0; i < offsets.length; i++) {
    //Step 2a - Find the Select calls before each PUSH
    var code = 
        " FF 24 AB AB AB AB 00" //JMP DWORD PTR DS:[reg32_A*4 + addr1]
      + " E8 AB AB AB AB"       //CALL SelectKoreaClientInfo
      + " E9 AB AB AB AB"       //JMP addr2 -> Skip calling SelectClientInfo
      + " 6A 00"                //PUSH 0
      + " E8"                   //CALL SelectClientInfo
      ;
    var repl = " 90".repeat(5);
    
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offsets[i]-0x30, offsets[i]);
    
    if (offset === -1) {
      code = code.replace(" E9 AB AB AB AB", " EB AB");
      repl = " 90 90";
      
      offset = exe.find(code, PTYPE_HEX, true, "\xAB", offsets[i]-0x30, offsets[i]);
    }
   
    if (offset === -1)
      return "Failed in Part 2 - call not found for iteration no." + i;
    
    //Step 2b - Replace the JMP skipping SelectClientInfo
    exe.replace(offset+12, repl, PTYPE_HEX);
  }
  
  return true;
}

// Note:
// Gravity has their clientinfo hardcoded and seperated the initialization, screw "em.. :(
// SelectKoreaClientInfo() has for example global variables like g_extended_slot set
// which aren"t set by SelectClientInfo(). Just call both functions will fix this as the
// changes from SelectKoreaClientInfo() will persist and overwritten by SelectClientInfo().