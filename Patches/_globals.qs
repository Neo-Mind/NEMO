function getLangType() {
  ////////////////////////////////////////////////////
  // GOAL: Find and Extract "g_serviceType" address //
  ////////////////////////////////////////////////////
  
  var offset = exe.findString("america", RVA);
  if (offset === -1)
    return -1;
  
  offset = exe.findCode('68' + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return -1;
  
  offset = exe.find('C7 05 AB AB AB AB 01 00 00 00', PTYPE_HEX, true, "\xAB", offset + 5);
  if (offset === -1)
    return -1;

  return exe.fetchHex(offset+2, 4);
}

LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType

function varHex(num) {
  //////////////////////////////////////////////
  // GOAL: Generate 'CC CC CC C0+num' hexcode //
  //       to use as variable in insert codes //
  //////////////////////////////////////////////
  return (0xCCCCCCC0 + num).packToHex(4);
}