//===================================================//
// Patch Functions wrapping over HideButton function //
//===================================================//

function HideNavButton() {
	if(UseNewIcons())
		return HideButton2("navigation");
	return HideButtonOld(
		["navigation_interface\\btn_Navigation", "RO_menu_icon\\navigation"],
		["\x00", "\x00"]
	);
}

function HideBgButton() {
	if(UseNewIcons())
		return HideButton2("battle");
	return HideButtonOld(
		["basic_interface\\btn_battle_field", "RO_menu_icon\\battle"],
		["\x00", "\x00"]
	);
}

function HideBankButton() {
	if(UseNewIcons())
		return HideButton2("bank");
	return HideButtonOld(
		["basic_interface\\btn_bank", "RO_menu_icon\\bank"],
		["\x00", "\x00"]
	);
}

function HideBooking() {
	if(UseNewIcons())
		return HideButton2("booking");
	return HideButtonOld(
		["basic_interface\\booking", "RO_menu_icon\\booking"],
		["\x00", "\x00"]
	);
}

function HideRodex() {
	if(UseNewIcons())
		return HideButton2("mail");
	return HideButtonOld("RO_menu_icon\\mail", "\x00");
}

function HideAchieve() {
	if(UseNewIcons())
		return HideButton2("achievement");
	return HideButtonOld("RO_menu_icon\\achievement", "\x00");
}

function HideRecButton() {
	if(UseNewIcons())
		return HideButton2("rec");
	return HideButtonOld(
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

function HideSNSButton() {
	return HideButton2("sns");
}

//##########################################################
//# Purpose: Find the first match amongst the src prefixes #
//#          and replace it with corresponding tgt prefix  #
//##########################################################

function HideButtonOld(src, tgt) {

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

function HideButton2(prefix) {
	if(UseNewIcons())
		HideButtonNew("equip", prefix);
	else
		HideButtonNew("info", prefix);
}

//#######################################################################
//# Purpose: Find the prefix assignment inside UIBasicWnd::OnCreate and #
//#          assign address of NULL after the prefix instead            #
//#######################################################################
function HideButtonNew(reference, prefix) {
	
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

//#######################################################################
//# Purpose: Determine whether this client uses new menu icons          #
//#######################################################################
function UseNewIcons() {
	return (exe.findString("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\menu_icon\\bt_%s.bmp") !== -1);
}

//========================================================//
// Disable for Unsupported Clients - Check for Button bmp //
//========================================================//

function HideRodex_() {
	return (exe.findString("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\RO_menu_icon\\mail", RAW) !== -1 || (UseNewIcons() && exe.findString("navigation") !== -1));
}

function HideAchieve_() {
	return (exe.findString("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\RO_menu_icon\\achievement", RAW) !== -1 || (UseNewIcons() && exe.findString("achievement") !== -1));
}

function HideSNSButton_() {
	return (exe.findString("sns") !== -1);
}
