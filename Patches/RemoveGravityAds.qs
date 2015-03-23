function RemoveGravityAds() {
  //////////////////////////////////////////
  // GOAL: Zero out all Gravity Ad Images //
  //////////////////////////////////////////
  
  //Step 1a - Find 1st Pic
  var offset = exe.findString("\\T_중력성인.tga", RAW, false);
  if (offset === -1)
    return "Failed in part 1";

  //Step 1b - Replace with NULL
  exe.replace(offset+1, "00", PTYPE_HEX);
  
  //Step 2a - Find 2nd Pic
  offset = exe.findString("\\T_GameGrade.tga", RAW, false);
  if (offset === -1)
    return "Failed in part 2";
  
  //Step 2b - Replace with NULL
  exe.replace(offset+1, "00", PTYPE_HEX);

  //Step 3a - Find Last Pic
  offset = exe.findString("\\T_테입%d.tga", RAW, false);
  if (offset === -1)
    return "Failed in part 3";
    
  //Step 3b - Replace with NULL
  exe.replace(offset+1, "00", PTYPE_HEX);
  
  return true;
}