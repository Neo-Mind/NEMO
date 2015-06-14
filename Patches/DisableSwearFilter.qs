//#####################################################################
//# Purpose: Zero out 'manner.txt' to prevent any reference bad words #
//#          from loading to compare against                          #
//#####################################################################

function DisableSwearFilter() {

  //Step 1 - Find offset of manner.txt
  var offset = exe.findString("manner.txt", RAW);
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace with Zero
  exe.replace(offset, "00", PTYPE_HEX);
  
  return true;
}