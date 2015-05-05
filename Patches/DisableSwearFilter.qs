function DisableSwearFilter() {
  //////////////////////////////////////////////////////////////
  // GOAL: Zero out manner.txt so there wont be any bad words //
  //       loaded to compare text against.                    //
  //////////////////////////////////////////////////////////////

  //Step 1 - Find offset of manner.txt
  var offset = exe.findString("manner.txt", RAW);
  if (offset === -1)
    return "Failed in Part 1";
  
  //Step 2 - Replace with Zero
  exe.replace(offset, "00", PTYPE_HEX);
  
  return true;
}