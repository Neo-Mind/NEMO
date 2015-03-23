function UseCustomFont() {
  //////////////////////////////////////////////////////////////
  // GOAL: Find the FontAddr array and update all its entries //
  //       to the offset of the custom font.                  //
  //////////////////////////////////////////////////////////////
  
  // Step 1a - Find offset of "Gulim" - Korean language font which serves as the first entry of the array
  var goffset = exe.findString("Gulim", RVA);
  if (goffset === -1)
    return "Failed in Part 1 - Gulim not found";
  
  // Step 1b - Find its reference - We should limit the search to .data section but that would pose a problem with themida clients.
  var offset = exe.find(goffset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 1 - Gulim reference not found";
  
  // Step 2a - Find space for inserting new font name - considering length of 20 chars
  var free = exe.findZeros(20);
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";
    
  var freeRva = exe.Raw2Rva(free).packToHex(4);
  
  // Step 2b - Get the Font name from user
  exe.getUserInput('$newFont', XTYPE_FONT, 'Font input', 'Select the new Font Family', "Arial");
  
  // Step 2c - Insert the received Font name
  exe.insert(free, 20, '$newFont', PTYPE_STRING);
  
  // Step 3 - Overwrite all entries with the custom font address
  goffset &= 0xFFF00000;
  do
  {
    exe.replace(offset, freeRva, PTYPE_HEX);
    offset += 4;
  } while((exe.fetchDWord(offset) & goffset) === goffset);
  
  // NOTE: this might not be entirely fool-proof, but we cannot depend 
  //       on the fact the array ends with 0x00000081 (CHARSET_HANGUL).
  //       It can change in any client.
  
  return true;
}