function ChatColorGuild() {
  ///////////////////////////////////////////
  // GOAL: Replace guild chat color inside //
  //       CGameMode::Zc_guild_chat        //
  ///////////////////////////////////////////

  //To Do: There are some extra instructions between the two PUSH in old clients. Find when it changed

  //Step 1 - Find the area where color is pushed
  var code =
      " 6A 04"          // PUSH 4
    + " 68 B4 FF B4 00" // PUSH B4,FF,B4 (Light Green)
    ;
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 1";

  //Step 2 - Get new color from user
  exe.getUserInput("$guildChatColor", XTYPE_COLOR, "Color input", "Select the new Guild Chat Color", 0x00B4FFB4);
  
  //Step 3 - Replace with new color
  exe.replace(offset+3, "$guildChatColor", PTYPE_STRING);

  return true;
}

function ChatColorGM() {
  //////////////////////////////////////////////////
  // GOAL: Replace all the colors assigned for GM //
  //       inside CGameMode::Zc_Notify_Chat       //
  //////////////////////////////////////////////////
  
  // Step 1a - Find the unique color FF, 8D, 1D (Orange) PUSH for langtype 11
  var offset1 = exe.findCode("68 FF 8D 1D 00", PTYPE_HEX, false);
  if (offset1 === -1)
    return "Failed in Part 1 - Orange color not found";
  
  // Step 1b - Find FF, FF, 00 (Cyan) PUSH in the vicinity of Orange
  var offset2 = exe.find("68 FF FF 00 00", PTYPE_HEX, false, " ", offset1 - 0x30, offset1 + 0x30);
  if (offset2 === -1)
    return "Failed in Part 1 - Cyan not found";
  
  // Step 1c - Find 00, FF, FF (Yellow) PUSH in the vicinity of Orange
  var offset3 = exe.find("68 00 FF FF 00", PTYPE_HEX, false, " ", offset1 - 0x30, offset1 + 0x30);
  if (offset3 === -1)
    return "Failed in Part 1 - Yellow not found";
  
  // Step 2 - Get the new color from user
  exe.getUserInput("$gmChatColor", XTYPE_COLOR, "Color input", "Select the new GM Chat Color", 0x0000FFFF);
  
  // Step 3 - Replace all the colors with new color
  exe.replace(offset1+1, "$gmChatColor", PTYPE_STRING);
  exe.replace(offset2+1, "$gmChatColor", PTYPE_STRING);
  exe.replace(offset3+1, "$gmChatColor", PTYPE_STRING);

  return true;
}

function ChatColorPlayerSelf() {
  //////////////////////////////////////////////////
  // GOAL: Replace Chat color assigned for Player //
  //       inside CGameMode::Zc_Notify_Chat       //
  //////////////////////////////////////////////////
  
  //To Do: Old clients have different instruction between code1 and code4. Find when it changed.
  
  //Step 1a - Find PUSH 00,78,00 (Dark Green) offsets (the required Green color PUSH is within the vicinity of one of these)
  var code = " 68 00 78 00 00";
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Part 1 - Dark Green missing";
  
  //Step 1b - Find the Green color push.
  for (var i = 0; i < offsets.length; i++) {
    var offset = exe.find(" 68 00 FF 00 00", PTYPE_HEX, false, "", offsets[i] + 5, offsets[i] + 40);
    if (offset !== -1) break;
  }
  if (offset === -1)
    return "Failed in Part 1 - Green not found";
  
  // Step 2 - Get the new color from user
  exe.getUserInput("$yourChatColor", XTYPE_COLOR, "Color input", "Select the new Self Chat Color", 0x0000FF00);
  
  //Step 3 - Replace with new color
  exe.replace(offset+1, "$yourChatColor", PTYPE_STRING);
  
  return true;
}

function ChatColorPlayerOther() {
  ////////////////////////////////////////////////////////
  // GOAL: Replace Chat color assigned for Player while //
  //       receiving other's messages inside            //
  //       CGameMode::Zc_Notify_Chat                    //
  ////////////////////////////////////////////////////////
  
  //Step 1 - Find the area where color is pushed.
  var code =
      " 6A 01"           // PUSH 1
    + " 68 FF FF FF 00"  // PUSH FF,FF,FF (White)
    ;
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 1";
  
  // Step 2 - Get the new color from user
  exe.getUserInput("$otherChatColor", XTYPE_COLOR, "Color input", "Select the new Other Player Chat Color", 0x00FFFFFF);  
  
  //Step 3 - Replace with new color
  exe.replace(offset+3, "$otherChatColor", PTYPE_STRING);

  return true;
}

function ChatColorPartySelf() {
  /////////////////////////////////////////////////////
  // GOAL: Replace Chat Assigned for Player in Party //
  //       inside CGameMode::Zc_Notify_Chat_Party    //
  /////////////////////////////////////////////////////

  //Step 1 - Find the area where color is pushed
  var code =
      " 68 FF C8 00 00" // PUSH FF, C8, 00 (Yellowish Brown)
    + " AB"             // PUSH reg32
    + " 6A 01"          // PUSH 1
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
    
  // Step 2 - Get the new color from user
  exe.getUserInput("$yourpartyChatColor", XTYPE_COLOR, "Color input", "Select the new Self Party Chat Color", 0x0000C8FF);
  
  // Step 3 - Replace with new color
  exe.replace(offset+1, "$yourpartyChatColor", PTYPE_STRING);

  return true;
}

function ChatColorPartyOther() {
  ///////////////////////////////////////////////////////////////
  // GOAL: Replace Chat Assigned for Player from Party Members //
  //       inside CGameMode::Zc_Notify_Chat_Party              //
  ///////////////////////////////////////////////////////////////

  //Step 1 - Find the area where color is pushed
  var code =
      " 6A 03"          // PUSH 3 ; old clients have an extra instruction after this one
    + " 68 FF C8 C8 00" // PUSH FF, C8, C8 (Light Pink)
    + " AB"             // PUSH reg32
    + " 6A 01"          // PUSH 1
    ;
    
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";

  // Step 2 - Get the new color from user
  exe.getUserInput("$otherpartyChatColor", XTYPE_COLOR, "Color input", "Select the new Others Party Chat Color", 0x0000C8FF);
  
  // Step 3 - Replace with new color
  exe.replace(offset+3, "$otherpartyChatColor", PTYPE_STRING);

  return true;
}

/* - Same as Player Other which is wrong
function ChatColorMain() {
  var code =    " 6A 01"      // PUSH 1
        + " 68 FF FF FF 00"  // PUSH 0FFFFh
        ;
  var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset === -1) {
        return "Failed in part 1";
    }
  
    exe.getUserInput("$mainChatColor", XTYPE_COLOR, "Color input", "Select the new Main Chat Color", 0x0000FFFF);
    exe.replace(offset+3, "$mainChatColor", PTYPE_STRING);
    return true;
}
*/
