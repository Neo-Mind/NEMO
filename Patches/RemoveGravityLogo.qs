function RemoveGravityLogo() {
  ///////////////////////////////////////
  // GOAL: Zero out Gravity Logo Image //
  ///////////////////////////////////////
  
  //Step 1a - Find the image
  var offset = exe.findString("\\T_R%d.tga", RAW, false);
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 1b - Replace with NULL
  exe.replace(offset+1, "00", PTYPE_HEX);
  
  return true;
}