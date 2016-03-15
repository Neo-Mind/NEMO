//===================================================//
// Patch Functions wrapping over HideButton function //
//===================================================//

function HideNavButton() {
  return HideButton(
    ["navigation_interface\\btn_Navigation", "RO_menu_icon\\navigation"],
    ["\x00", "\x00"]
  );
}

function HideBgButton() {
  return HideButton(
    ["basic_interface\\btn_battle_field", "RO_menu_icon\\battle"],
    ["\x00", "\x00"]
  );
}

function HideBankButton() {
  return HideButton(
    ["basic_interface\\btn_bank", "RO_menu_icon\\bank"],
    ["\x00", "\x00"]
  );
}

function HideBooking() {
  return HideButton(
    ["basic_interface\\booking", "RO_menu_icon\\booking"],
    ["\x00", "\x00"]
  );
}

function HideRodex() {
  return HideButton("RO_menu_icon\\mail", "\x00");
}

function HideAchieve() {
  return HideButton("RO_menu_icon\\achievement", "\x00");
}

function HideRecButton() {
  return HideButton(
    ["replay_interface\\rec", "RO_menu_icon\\rec"],
    ["\x00", "\x00"]
  );
}

//===================================================//
// Patch Functions wrapping over HideButton2 function //
//===================================================//

function HideMapButton() {
  return HideButton2("map");
}

function HideQuest() {
  return HideButton2("quest");
}

//##########################################################
//# Purpose: Find the first match amongst the src prefixes #
//#          and replace it with corresponding tgt prefix  #
//##########################################################

function HideButton(src, tgt) {
  
  //Step 1a - Ensure both are lists/arrays
  if (typeof(src) === "string")
    src = [src];
  
  if (typeof(tgt) === "string")
    tgt = [tgt];
  
  //Step 1b - Loop through and find first match
  var offset = -1;
  for (var i = 0; i < src.length; i++) {
    offset = exe.findString(src[i], RAW, false);
    if (offset !== -1)
      break;
  }
  
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace with corresponding value in tgt
  exe.replace(offset, tgt[i], PTYPE_STRING);
  
  return true;
}

//#######################################################################
//# Purpose: Find the prefix assignment inside UIBasicWnd::OnCreate and #
//#          assign address of NULL after the prefix instead            #
//#######################################################################

function HideButton2(prefix) {
  
  //Step 1a - Find the address of the reference prefix "info" (needed since some prefixes are matching multiple areas)
  var refAddr = exe.findString("info", RVA);
  if (refAddr === -1)
    return "Failed in Step 1 - info missing";
  
  //Step 1b - Find the address of the string
  var strAddr = exe.findString(prefix, RVA);
  if (strAddr === -1)
    return "Failed in Step 1 - Prefix missing";
  
  //Step 2a - Find assignment of "info" inside UIBasicWnd::OnCreate
  var suffix = " C7";
  var offset = exe.findCode(refAddr.packToHex(4) + suffix, PTYPE_HEX, false);
  
  if (offset === -1) {
    suffix = " 8D"; 
    offset = exe.findCode(refAddr.packToHex(4) + suffix, PTYPE_HEX, false);
  }
 
  if (offset === -1)
    return "Failed in Step 2 - info assignment missing";
  
  //Step 2b - Find the assignment of prefix after "info" assignment
  offset = exe.find(strAddr.packToHex(4) + suffix, PTYPE_HEX, false, "", offset + 5, offset + 0x500);
  if (offset === -1)
    return "Failed in Step 2 - Prefix assignment missing";
  
  //Step 2c - Update the address to point to NULL
  exe.replaceDWord(offset, strAddr + prefix.length);
  
  return true;
}

//========================================================//
// Disable for Unsupported Clients - Check for Button bmp //
//========================================================//

function HideRodex_() {
  return (exe.findString("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\RO_menu_icon\\mail", RAW) !== -1);
}

function HideAchieve_() {
  return (exe.findString("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\RO_menu_icon\\achievement", RAW) !== -1);
}
