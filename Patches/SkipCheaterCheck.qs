//===========================================================//
// Patch Functions wrapping over SkipCheaterCheck function //
//===========================================================//

function SkipCheaterFriendCheck() {
  return SkipCheaterCheck(0x395);
}

function SkipCheaterGuildCheck() {
  return SkipCheaterCheck(0x397);
}

//###################################################################################
//# Purpose: Change the JZ to JMP after CSession::IsCheatName/IsGuildCheatName call #
//#          inside UIWindowMgr::AddWhisperChatToWhisperWnd to ignore its result    #
//###################################################################################

function SkipCheaterCheck(msgNum) {
  
  //Step 1 - Find the TEST after CSession::IsCheatName/IsGuildCheatName Call (testing its result)
  var code = 
    " 85 C0"          //TEST EAX, EAX
  + " 74 AB"          //JZ SHORT addr
  + " 6A 00"          //PUSH 0
  + " 6A 00"          //PUSH 0
  + " 68 FF FF 00 00" //PUSH 0FFFF
  + " 68" + msgNum.packToHex(4) //PUSH msgNum
  ;
  var offset = exe.findCode(code, PTYPE_HEX, false);
  
  if (offset === -1) {
    code = code.replace(/6A 00/g, "AB");//Change PUSH 0 with PUSH reg32
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Change the JZ to JMP
  exe.replace(offset + 2, "EB", PTYPE_HEX);
  
  return true;
}
