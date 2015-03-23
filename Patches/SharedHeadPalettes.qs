//Both patches have same procedure - only diff is format string
function SharedHeadPalettesV1() {
  return SharedHeadPalettes("head%.s_%s_%d.pal\x00");// %.s is required. Skips jobname
}

function SharedHeadPalettesV2() {
  return SharedHeadPalettes("head%.s%.s_%d.pal\x00");// %.s is required. Skips jobname & gender
}

function SharedHeadPalettes(fmt) {
  ////////////////////////////////////////////////////////////////////
  // GOAL: Modify the format string in CSession::GetHeadPaletteName //
  //       used for constructing Head palette filename to skip parts//
  ////////////////////////////////////////////////////////////////////

  //Step 1 - Find Offset of 赣府\赣府%s%s_%d.pal - Old Format
  var offset = exe.findString("赣府\\赣府%s%s_%d.pal", RAW);
  
  if (offset === -1) //otherwise look for 赣府\赣府%s_%s_%d.pal - New Format
    offset = exe.findString("赣府\\赣府%s_%s_%d.pal", RAW);
  
  if (offset === -1)
    return "Failed in Part 1";
  
  //Step 2 - Replace string with ours   
  exe.replace(offset, fmt, PTYPE_STRING);
  
  return true;
}