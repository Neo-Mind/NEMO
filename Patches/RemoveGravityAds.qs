//###########################################
//# Purpose: Zero out all Gravity Ad Images #
//###########################################

function RemoveGravityAds() {
  
  //Step 1a - Find address of 1st Pic -> \T_중력성인.tga
  var offset = exe.findString("\\T_\xC1\xDF\xB7\xC2\xBC\xBA\xC0\xCE.tga", RAW, false);
  if (offset === -1)
    return "Failed in Step 1";

  //Step 1b - Replace with NULL
  exe.replace(offset + 1, "00", PTYPE_HEX);
  
  //Step 2a - Find address of 2nd Pic
  offset = exe.findString("\\T_GameGrade.tga", RAW, false);
  if (offset === -1)
    return "Failed in Step 2";
  
  //Step 2b - Replace with NULL
  exe.replace(offset + 1, "00", PTYPE_HEX);

  //Step 3a - Find address of Last Pic -> \T_테입%d.tga 
  offset = exe.findString("\\T_\xC5\xD7\xC0\xD4%d.tga", RAW, false);
  if (offset === -1)
    return "Failed in Step 3";
    
  //Step 3b - Replace with NULL
  exe.replace(offset + 1, "00", PTYPE_HEX);
  
  return true;
}