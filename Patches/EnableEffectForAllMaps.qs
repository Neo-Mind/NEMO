//###################################################################
//# Purpose: Make the function which loads the EffectTool lua files #
//#          skip the Jump for specific maps                        #
//###################################################################

function EnableEffectForAllMaps() {
  //Step 1a - Find the address of Lua file prefix string
  var offset = exe.findString("Lua Files\\EffectTool\\", RVA);
  if (offset === -1)
    return "Failed in Step 1 - String missing";
  
  //Step 1b - Find its reference
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);//PUSH addr
  if (offset === -1)
    return "Failed in Step 1 - String Reference missing";
  
  //Step 2a - Find the JE before the PUSH
  offset = exe.find("0F 84 AB AB 00 00", PTYPE_HEX, true, "\xAB", offset - 0x20, offset);
  if (offset === -1)
    return "Failed in Step 2 - Jump missing";

  //Step 2b - Replace with a JMP that skips over the 6 bytes (2 gone for the code itself hence 04)
  exe.replace(offset, "EB 04", PTYPE_HEX);
  
  return true;
}