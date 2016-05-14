//##################################################################################
//# Purpose: Overwrite all entries in the Font Name Array with user specified name #
//##################################################################################

function UseCustomFont() {
  
  //Step 1a - Find offset of "Gulim" - Korean language font which serves as the first entry of the array
  var goffset = exe.findString("Gulim", RVA, false);
  if (goffset === -1)
    return "Failed in Step 1 - Gulim not found";
  
  //Step 1b - Find its reference - We should limit the search to .data section but that would pose a problem with themida clients.
  var offset = exe.find(goffset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - Gulim reference not found";
  
  //Step 2a - Get the Font name from user
  var newFont = exe.getUserInput("$newFont", XTYPE_FONT, 'Font input', 'Select the new Font Family', "Arial");

  //Step 2b - Get its address if its already existing
  var free = exe.findString(newFont, RAW);
  
  //Step 2c - Otherwise Insert the font in the xdiff section
  if (free === -1) {
    free = exe.findZeros(newFont.length + 1);
    
    if (free === -1)
      return "Failed in Step 2 - Not enough free space";

    exe.insert(free, newFont.length + 1, '$newFont', PTYPE_STRING);
  }
  
  var freeRva = exe.Raw2Rva(free);
  
  //Step 3 - Overwrite all entries with the custom font address
  goffset &= 0xFFF00000;
  do
  {
    exe.replaceDWord(offset, freeRva);
    offset += 4;
  } while((exe.fetchDWord(offset) & goffset) === goffset);
  
  /*==================================================================
  NOTE: this might not be entirely fool-proof, but we cannot depend 
        on the fact the array ends with 0x00000081 (CHARSET_HANGUL).
        It can change in any client.
  ==================================================================*/
  
  return true;
}