function HKLMtoHKCU() {
  /////////////////////////////////////////////////////////////////////////
  // GOAL: Change all HKEY_LOCAL_MACHINE parameters to HKEY_CURRENT_USER //
  /////////////////////////////////////////////////////////////////////////
  
  //Step 1 - Find all occurrences of HKEY_LOCAL_MACHINE (0x80000002)
  var code = " 68 02 00 00 80";//PUSH 80000002
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  
  if (!offsets[0])
    return "Failed in part 1";
  
  //Step 2 - Change all to HKEY_CURRENT_USER (0x80000001)
  for (var i = 0; offsets[i]; i++) {
    if (exe.fetchByte(offsets[i]+5) !== 0x3B)//Skip False matches - old clients dont have this issue
      exe.replace(offsets[i]+1, "01", PTYPE_HEX);
  }
  
  return true;
}