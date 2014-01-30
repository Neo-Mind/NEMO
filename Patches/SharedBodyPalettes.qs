function SharedBodyPalettesV1() {

	code = "body%.s_%s_%d.pal\x00"; //%.s is required
	return SharedBodyPalettes(code);
}

function SharedBodyPalettesV2() {

	code = "body%.s%.s_%d.pal\x00"; //%.s is required
	return SharedBodyPalettes(code);
}

function SharedBodyPalettes(code) {

	//Step 1 - Find offset of String 个\%s%s_%d.pal - Old Format
	var offset = exe.findString("个\\%s%s_%d.pal", RVA);
	
	if (offset == -1) {
		// Otherwise look for new format 个\%s_%s_%d.pal - New Format
		offset = exe.findString("个\\%s_%s_%d.pal", RVA);
	}
	
	if (offset == -1) {
		return "Failed in Step 1";
	}
	
	//Step 2 - Originally we used to adjust stack and lot of hurdles were there. so I said screw it.
	//		   Since we cant place our own string in that area (not enough space) 
	//		   we will insert it in a new place DUH!	
	
	var offset2 = exe.findZeros( code.length );	
	if (offset2 == -1) {
		return "Failed in Step 2. Not enough free space";
	}
	
	exe.insert(offset2, code.length, code, PTYPE_STRING);
	
	//Step 3 - Replace the pushed string with ours.
	offset = exe.findCode('68' + offset.packToHex(4), PTYPE_HEX, false);
	
	if (offset == -1) {
		return "Failed in Step 3";
	}
	
	exe.replace(offset+1, exe.Raw2Rva(offset2).packToHex(4), PTYPE_HEX);
	return true;
}