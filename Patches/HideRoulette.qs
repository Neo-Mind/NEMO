//###################################################################################
//# Purpose: Make client skip over the Roulette Icon UIWindow creation (ID = 0x11D) #
//###################################################################################

function HideRoulette() {
  
  //Step 1a - Get Window Manager Info
  var mgrInfo = GetWinMgrInfo();
  if (typeof(mgrInfo) === "string")
    return "Failed in Step 1 - " + mgrInfo;  
  
  //Step 1b - Find the UIWindow creation before Roulette (which is always present - 0xB5)
  var code =
    " 74 0F"           //JE SHORT addr
  + " 68 B5 00 00 00"  //PUSH 0B5
  + mgrInfo['gWinMgr'] //MOV ECX, OFFSET g_windowMgr
  + " E8"              //CALL UIWindowMgr::MakeWindow
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - Reference Code missing";
  
  offset += code.hexlength() + 4;
  
  //Step 2a - Check if the Succeding operation is Roulette UIWindow creation or not
  if (exe.fetchDWord(offset+1) !== 0x11D)
    return "Patch Cancelled - Roulette is already hidden";

  //Step 2b - If yes JMP over it
  exe.replace(offset, "EB 0D", PTYPE_HEX);//Skip over rest of the PUSH followed by ECX assignment and Function call
}

//======================================================//
// Disable for Unsupported Clients - Check for Icon bmp //
//======================================================//
function HideRoulette_() {
  return (exe.findString("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\basic_interface\\roullette\\RoulletteIcon.bmp", RAW) !== -1);
}