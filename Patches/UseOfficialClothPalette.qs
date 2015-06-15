//##########################################################################
//# Purpose: Change the JNE after LangType comparison when loading Palette #
//#          prefixes into Palette Table in CSession::InitJobTable         #
//##########################################################################
  
function UseOfficialClothPalette() {
  
  //Step 1a - Check if Custom Job patch is being used. Does not work with it
  if (exe.getActivePatches().indexOf(202) !== -1)
    return "Patch Cancelled - Turn off Custom Job patch first";
  
  //Step 1b - Find offset of palette prefix for Archer - ±Ã¼ö
  var offset = exe.findString("\xB1\xC3\xBC\xF6", RVA);// Same value is used for job path as well as imf
  if (offset === -1)
    return "Failed in Step 1 - Palette prefix missing";
  
  //Step 1c - Find its references
  var offsets = exe.findCodes(" C7 AB 0C" + offset.packToHex(4), PTYPE_HEX, true, "\xAB");
  
  if (offsets.length === 2) {//For Pre-VC9 client
    offset = exe.findCode(" C7 00" + offset.packToHex(4) + " E8", PTYPE_HEX, false);
    if (offset === -1)
      return "Failed in Step 1 - Prefix reference missing";
    offsets[2] = offset;
  }
  
  if (offsets.length !== 3)
    return "Failed in Step 1 - Prefix reference missing or extra";
  
  offset = offsets[2];
  
  //Step 2a - Find the JNE after offset
  offset = exe.find(" 0F 85 AB AB 00 00", PTYPE_HEX, true, "\xAB", offset + 0x7, offset + 0x200);// JNE addr
  if (offset === -1)
    return "Failed in Step 2";
  
  //Step 2b - NOP out the JNE
  exe.replace(offset, " 90 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}