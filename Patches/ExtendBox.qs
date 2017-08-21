//==================================================//
// Patch Functions wrapping over ExtendBox function //
//==================================================//

function ExtendChatBox() {
  return ExtendBox(3);
}

function ExtendChatRoomBox() {
  return ExtendBox(0);
}

function ExtendPMBox() {
  return ExtendBox(2);
}

//##############################################################
//# Purpose: Change the Box Limit from 70 (0x46) to 234 (0xEA) #
//##############################################################

function ExtendBox(index) {
  
  //Step 1 - Find the Box Limiter Code - Atleast 4 matches should be there
  //         MOV DWORD PTR DS:[EAX+byte], 0x46
  var offsets = exe.findCodes(" C7 40 AB 46 00 00 00", PTYPE_HEX, true, "\xAB");
  
  // new client detected, so!
  if (offsets.length < 4)
	offsets = exe.findCodes(" C7 80 AB AB AB AB 46 00 00 00", PTYPE_HEX, true, "\xAB");
  
  
  if (offsets.length < 4)
    return "Failed in Step 1";
  
  //Step 2 - Change the limit
  // 0 = Chat Room
  // 1 = Unknown
  // 2 = Private Message
  // 3 = Chat Box
  exe.replace(offsets[index] + 3, "EA", PTYPE_HEX);
  
  return true;
}