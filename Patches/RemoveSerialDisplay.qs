function RemoveSerialDisplay() {
  /////////////////////////////////////////////////////////////
  // GOAL: Modify the function which displays Serial Number  //
  //       to reset EAX and making JL always skip displaying //
  /////////////////////////////////////////////////////////////
  
  //Step 1 - Check if the client date is valid for this diff
  if (exe.getClientDate() <= 20101116)
    return "Patch Cancelled. Client Date <= 16-11-2010";
  
  //Step 2a - Prep comparison code
  var code1 = 
      " 83 C0 AB"          // ADD EAX, const1
    + " 3B 41 AB"          // CMP EAX, DWORD PTR DS:[EAX+const2]
    + " 0F 8C AB 00 00 00" // JL addr
    + " 56"                // PUSH ESI
    ;
  
  var code2 = " 6A 00"; // PUSH 0
  
  //Step 2b - Find the code
  var offset = exe.findCode(code1 + " 57" + code2, PTYPE_HEX, true, "\xAB"); 
  if (offset === -1)
    offset = exe.findCode(code1 + code2, PTYPE_HEX, true, "\xAB");//Older client

  if (offset === -1)
    return "Failed in Part 2";
    
  //Step 3 - Replace it with zeroing of EAX and comparing with 1 (therefore JL will be true)
  // NOP
  // XOR EAX, EAX
  // CMP EAX, 1
  exe.replace(offset, " 90 31 C0 83 F8 01", PTYPE_HEX);
  
  return true;
}