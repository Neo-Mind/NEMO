//############################################
//# Purpose: Replace guild chat color inside #
//#          CGameMode::Zc_guild_chat        #
//############################################

function ChatColorGuild() {
  
  //Step 1 - Find the area where color is pushed
  var code =
    " 6A 04"          //PUSH 4
  + " 68 B4 FF B4 00" //PUSH B4,FF,B4 (Light Green)
  ;
  var offset = exe.findCode(code, PTYPE_HEX, false);
  
  if (offset === -1) {
    code = code.replace(" 6A 04", " 6A 04 8D AB AB AB FF FF");//insert LEA reg32_A, [EBP-x] after PUSH 4
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1";

  //Step 2a - Get new color from user
  var color = exe.getUserInput("$guildChatColor", XTYPE_COLOR, "Color input", "Select the new Guild Chat Color", 0x00B4FFB4);
  if (color === 0x00B4FFB4)
    return "Patch Cancelled - New Color is same as old";
  
  //Step 2b - Replace with new color
  exe.replace(offset + code.hexlength() - 4, "$guildChatColor", PTYPE_STRING);

  return true;
}

//###################################################
//# Purpose: Replace all the colors assigned for GM #
//#          inside CGameMode::Zc_Notify_Chat       #
//###################################################

function ChatColorGM() {
  
  //Step 1a - Find the unique color FF, 8D, 1D (Orange) PUSH for langtype 11
  var offset1 = exe.findCode("68 FF 8D 1D 00", PTYPE_HEX, false);
  if (offset1 === -1)
    return "Failed in Step 1 - Orange color not found";
  
  //Step 1b - Find FF, FF, 00 (Cyan) PUSH in the vicinity of Orange
  var offset2 = exe.find("68 FF FF 00 00", PTYPE_HEX, false, " ", offset1 - 0x30, offset1 + 0x30);
  if (offset2 === -1)
    return "Failed in Step 1 - Cyan not found";
  
  //Step 1c - Find 00, FF, FF (Yellow) PUSH in the vicinity of Orange
  var offset3 = exe.find("68 00 FF FF 00", PTYPE_HEX, false, " ", offset1 - 0x30, offset1 + 0x30);
  if (offset3 === -1)
    return "Failed in Step 1 - Yellow not found";
  
  //Step 2a - Get the new color from user
  var color = exe.getUserInput("$gmChatColor", XTYPE_COLOR, "Color input", "Select the new GM Chat Color", 0x0000FFFF);
  if (color === 0x0000FFFF)
    return "Patch Cancelled - New Color is same as old";
  
  //Step 2b - Replace all the colors with new color
  exe.replace(offset1 + 1, "$gmChatColor", PTYPE_STRING);
  exe.replace(offset2 + 1, "$gmChatColor", PTYPE_STRING);
  exe.replace(offset3 + 1, "$gmChatColor", PTYPE_STRING);

  return true;
}

//###################################################
//# Purpose: Replace Chat color assigned for Player #
//#          inside CGameMode::Zc_Notify_PlayerChat #
//###################################################
  
function ChatColorPlayerSelf() {//N.B. - Check if it holds good for old client. Till 2010 no issue is there.
  
  //Step 1a - Find PUSH 00,78,00 (Dark Green) offsets (the required Green color PUSH is within the vicinity of one of these)
  var offsets = exe.findCodes(" 68 00 78 00 00", PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Step 1 - Dark Green missing";
  
  //Step 1b - Find the Green color push.
  for (var i = 0; i < offsets.length; i++) {
    var offset = exe.find(" 68 00 FF 00 00", PTYPE_HEX, false, "", offsets[i] + 5, offsets[i] + 40);
    if (offset !== -1) break;
  }
  
  if (offset === -1)
    return "Failed in Step 1 - Green not found";
  
  //Step 2a - Get the new color from user
  var color = exe.getUserInput("$yourChatColor", XTYPE_COLOR, "Color input", "Select the new Self Chat Color", 0x0000FF00);
  if (color === 0x0000FF00)
    return "Patch Cancelled - New Color is same as old";

  //Step 2b - Replace with new color
  exe.replace(offset + 1, "$yourChatColor", PTYPE_STRING);
  
  return true;
}

//############################################################
//# Purpose: Replace Chat color assigned for Player inside   #
//#          CGameMode::Zc_Notify_Chat for received messages #
//############################################################

function ChatColorPlayerOther() {
  
  //Step 1 - Find the area where color is pushed.
  var code =
    " 6A 01"           //PUSH 1
  + " 68 FF FF FF 00"  //PUSH FF,FF,FF (White)
  ;
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2a - Get the new color from user
  var color = exe.getUserInput("$otherChatColor", XTYPE_COLOR, "Color input", "Select the new Other Player Chat Color", 0x00FFFFFF);  
  if (color === 0x00FFFFFF)
    return "Patch Cancelled - New Color is same as old";

  //Step 2b - Replace with new color
  exe.replace(offset + code.hexlength() - 4, "$otherChatColor", PTYPE_STRING);

  return true;
}

//###################################################
//# Purpose: Replace Chat color assigned for Player #
//#          inside CGameMode::Zc_Notify_Chat_Party #
//###################################################

function ChatColorPartySelf() {

  //Step 1 - Find the area where color is pushed
  var code =
    " 6A 03"          //PUSH 3
  + " 68 FF C8 00 00" //PUSH FF,C8,00 (Yellowish Brown)
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" 6A 03", " 6A 03 8D AB AB AB FF FF");//insert LEA reg32_A, [EBP-x] after PUSH 3
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1";
    
  //Step 2a - Get the new color from user
  var color = exe.getUserInput("$yourpartyChatColor", XTYPE_COLOR, "Color input", "Select the new Self Party Chat Color", 0x0000C8FF);
  if (color === 0x0000C8FF)
    return "Patch Cancelled - New Color is same as old";

  //Step 2b - Replace with new color
  exe.replace(offset + code.hexlength() - 4, "$yourpartyChatColor", PTYPE_STRING);

  return true;
}

//################################################################
//# Purpose: Replace Chat color assigned for Player inside       # 
//#          CGameMode::Zc_Notify_Chat_Party for Member messages #
//################################################################

function ChatColorPartyOther() {

  //Step 1a - Find the area where color is pushed
  var code =
    " 6A 03"          //PUSH 3 ; old clients have an extra instruction after this one
  + " 68 FF C8 C8 00" //PUSH FF,C8,C8 (Light Pink)
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" 6A 03", " 6A 03 8D AB AB AB FF FF"); //insert LEA reg32_A, [EBP-x] after PUSH 3
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1";

  //Step 2a - Get the new color from user
  var color = exe.getUserInput("$otherpartyChatColor", XTYPE_COLOR, "Color input", "Select the new Others Party Chat Color", 0x00C8C8FF);
  if (color === 0x00C8C8FF)
    return "Patch Cancelled - New Color is same as old";

  //Step 2b - Replace with new color
  exe.replace(offset + code.hexlength() - 4, "$otherpartyChatColor", PTYPE_STRING);

  return true;
}

//ChatColorMain - is included in ChatColorGM so it makes it pointless