function EnableCustomHomunculus() {
  ////////////////////////////////////////////////////////////
  // GOAL: Modify the Hardcoded reading of Homunculus names //
  //       with ReqJobName lua function call in a loop for  //
  //       the homunculus id range                          //
  ////////////////////////////////////////////////////////////
  var max = 7000;
    
  //Step 1a - Find the homunculus reader code.
  var code =
      " 47"                // INC EDI
    + " 83 C4 2C"          // ADD ESP,2C
    + " 81 FF AB AB 00 00" // CMP EDI, const ; Max Value
    + " 7C AB"             // JL SHORT addr; loop
    + " 8B"                // MOV E*X, <expression>
    ;
 
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1 - homun code not found";
  
  var insLoc = offset + 12;
    
  //Step 1b - Find location to jmp to after reading from lua (to skip hardcoded reading)
  code =
      " 8B 8E AB AB 00 00" // MOV ECX, DWORD PTR DS:[ESI+const1]
    + " 8B 96 AB AB 00 00" // MOV EDX, DWORD PTR DS:[ESI+const2]
    ;
    
  var jmpLoc = exe.find(code, PTYPE_HEX, true, "\xAB", insLoc);
  if (jmpLoc === -1)
    return "Failed in Step 1 - endpoint not found";
  
  //Step 1c - Replace with NOP before jmp location
  exe.replace(jmpLoc-6, " 90 90 90 90 90 90", PTYPE_HEX);
  
  //Step 2a - Find offset of ReqJobName
  //Get the current lua caller code for Job Name i.e. ReqJobName calls
  offset = exe.findString("ReqJobName", RVA);
  if (offset === -1)
    return "Failed in Step 2 - ReqJobName not found";
  
  //Step 2b - Find the last reference - Since offset is moved to ECX here
  var offsets = exe.findCodes(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  if (!offsets[0])
    return "Failed in Step 2 - ReqJobName reference missing";
  
  offset = offsets[offsets.length-1];
  
  //Step 3a - Get the current JobName code and make modifications to call locations.
  if(exe.getClientDate() > 20130605) {
    code = exe.fetchHex(offset - 36, 83);
    
    var fn = exe.fetchDWord(offset - 36 + (83 - 38) ) - 88;
    code =  code.replaceAt(3*(83 - 38), fn.packToHex(4));
    
    fn = exe.fetchDWord(offset - 36 + (83 - 16) ) - 88;
    code =  code.replaceAt(3*(83 - 16), fn.packToHex(4));
    
    jmpLoc -= 9;
  }
  else {
    code = exe.fetchHex(offset - 25, 68);
    
    var fn = exe.fetchDWord(offset - 25 + (68 - 16) ) - 73;
    code =  code.replaceAt(3*(68 - 16), fn.packToHex(4));
  }
  
  code = code.replaceAt(-6*3, (max+1).packToHex(4));
  
  //Step 3b - Complete lua caller code    
  code =  " BF 71 17 00 00" + code; //MOV EDI, 1771
  code += " E9" + (jmpLoc - (insLoc + code.hexlength() + 5)).packToHex(4);
  
  //Step 4 - Replace with lua caller
  exe.replace(insLoc, code, PTYPE_HEX);
  
  //Step 5a - Find the homun limiter code for right click menu.
  code =
      " 05 8F E8 FF FF" //SUB EAX, 1771
    + " B9 33 00 00 00" //MOV ECX, 33
    ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 5";
  
  //Step 5b - Replace the 33 with our maximum difference
  exe.replace(offset+6, (max - 6001).packToHex(4), PTYPE_HEX);
  
  return true;
}