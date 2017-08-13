//#########################################################################################
//# Purpose: Fix the switch and JMP in InitClientInfo and InitDefaultClientInfo functions #
//#          to make sure both SelectKoreaClientInfo and SelectClientInfo are called.     #
//#########################################################################################

function KoreaServiceTypeXMLFix() {

  //Step 1a - Find offset of error string.
  var offset = exe.findString("Unknown ServiceType !!!", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Error String missing";
  
  //Step 1b - Find all its references
  var offsets = exe.findCodes(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Step 1 - No references found";
  
  for (var i = 0; i < offsets.length; i++) {
    //Step 2a - Find the Select calls before each PUSH
    var code = 
      " FF 24 AB AB AB AB 00" //JMP DWORD PTR DS:[reg32_A*4 + refAddr]
    + " E8 AB AB AB AB"       //CALL SelectKoreaClientInfo
    + " E9 AB AB AB AB"       //JMP addr2 -> Skip calling SelectClientInfo
    + " 6A 00"                //PUSH 0
    + " E8"                   //CALL SelectClientInfo
    ;
    var repl = " 90 90 90 90 90";
    var offset2 = 12; //12 = 7 from JMP DWORD PTR and 5 from CALL SelectKoreaClientInfo
	
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offsets[i] - 0x30, offsets[i]);
    
    if (offset === -1) {
      code = code.replace(" E9 AB AB AB AB", " EB AB");//Change JMP addr2 to JMP SHORT addr2
      repl = " 90 90";//Since JMP is short, Only 2 NOPs are needed
      
      offset = exe.find(code, PTYPE_HEX, true, "\xAB", offsets[i] - 0x30, offsets[i]);
    }
   
    if (offset === -1) { // 2017 clients [Secret]
	  code = 
  	    " 75 AB"                //JNZ SHORT addr
  	  + " E8 AB AB AB AB"       //CALL SelectKoreaClientInfo
  	  + " E9 AB AB AB AB"       //JMP addr2 -> Skip calling SelectClientInfo
  	  + " 6A 00"                //PUSH 0
  	  + " E8"                   //CALL SelectClientInfo
	  ;
	  repl = " 90 90 90 90 90";
	  offset2 = 7; //7 = 2 from JNZ SHORT and 5 from CALL SelectKoreaClientInfo
	  
	  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offsets[i] - 0x30, offsets[i]);
	}
	
    if (offset === -1)
      return "Failed in Step 2 - Calls missing for iteration no." + i;
    
    //Step 2b - Replace the JMP skipping SelectClientInfo
    exe.replace(offset + offset2, repl, PTYPE_HEX);
    
    //Step 2c - Extract the refAddr
    offset = exe.Rva2Raw(exe.fetchDWord(offset + 3));
    
    //Step 2d - Replace refAddr + 4 with the contents from refAddr, so that all valid langtypes will use same case as 0 i.e. Korea
    code = exe.fetchHex(offset, 4);
    exe.replace(offset + 4, code, PTYPE_HEX);
  }
  
  return true;
}

/*
 Note:
-------
 Gravity has their clientinfo hardcoded and seperated the initialization, screw "em.. :(
 SelectKoreaClientInfo() has for example global variables like g_extended_slot set
 which aren"t set by SelectClientInfo(). Just call both functions will fix this as the
 changes from SelectKoreaClientInfo() will persist and overwritten by SelectClientInfo().
*/