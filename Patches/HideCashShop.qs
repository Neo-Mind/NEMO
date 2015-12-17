//###################################################################################
//# Purpose: Make client skip over the Cash Shop Icon UIWindow creation (ID = 0xBE) #
//###################################################################################

function HideCashShop() {

  //Step 1a - Get Window Manager Info  
  var mgrInfo = GetWinMgrInfo();
  if (typeof(mgrInfo) === "string")
    return "Failed in Step 1 - " + mgrInfo;
  
  //Step 1b - Find the UIWindow creation for Cash Shop - 0xBE
  var code = 
    " 68 BE 00 00 00"  //PUSH 0BE
  + mgrInfo['gWinMgr'] //MOV ECX, OFFSET g_windowMgr
  + " E8"              //CALL UIWindowMgr::MakeWindow
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Patch Cancelled - Cash Shop already hidden";
  
  //Step 2 - If found then JMP over it
  exe.replace(offset, "EB 0D", PTYPE_HEX);
}

//======================================================//
// Disable for Unsupported Clients - Check for Icon bmp //
//======================================================//
function HideCashShop_() {
  return (exe.findString("NC_CashShop", RAW) !== -1);
}