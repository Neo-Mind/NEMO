function UseAsciiOnAllLangtypes() {
	var offset = exe.findCode("F6 04 AB 80", PTYPE_HEX, true, "\xAB"); //TEST BYTE PTR DS:[reg32+reg32], 80
	if (offset == -1) {
		return "Failed in Part 1";
	}
	
	exe.replace(offset+4, " 90 90", PTYPE_HEX);
}