function UseRagnarokIcon() {

	var code = ' 72 00 00 00 AB 01 00 80';
	
	if (exe.isThemida)
		var section = "sect_0";
	else
		var section = ".data";
	
	var offset = exe.find(code, PTYPE_HEX, true, "\xAB", exe.getROffset(section) );
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	var new_value = exe.fetchWord(offset + 4) + 24;
	exe.replace(offset+4, new_value.packToHex(2), PTYPE_HEX);
	return true;
}