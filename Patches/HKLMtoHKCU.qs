function HKLMtoHKCU() {

	var code = ' 68 02 00 00 80';
	var offsets = exe.findCodes(code, PTYPE_HEX, false);
	
	if (!offsets[0]) {
		return "Failed in part 1";
	}
	
	for (var i = 0; offsets[i]; i++) {
		if (exe.fetchByte(offsets[i]+5) != 0x3B) {
			exe.replace(offsets[i]+1, '01', PTYPE_HEX);
		}
	}
	
	return true;
}