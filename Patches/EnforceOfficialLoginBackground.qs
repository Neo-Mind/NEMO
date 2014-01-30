function EnforceOfficialLoginBackground() {

	var code =	' 74 AB 83 F8 04 74 AB 83 F8 08 74 AB 83 F8 09 74 AB 83 F8 AB 74 AB 83 F8 03';
	var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
		
	if (offsets.length !== 2) {
		return "Failed in part 1";
	}
	
	// The first one is the correct one.
	exe.replace(offsets[0], 'EB', PTYPE_HEX);  // XOR AL,AL
	return true;
}