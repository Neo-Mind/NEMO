function IgnoreMissingFileError() {
	if (exe.getClientDate() <= 20130605)
		var code = ' E8 AB AB AB FF 8B 44 24 04 8B 0D AB AB AB AB 6A 00';
	else
		var code = ' E8 AB AB AB FF 8B 45 08 8B 0D AB AB AB AB 6A 00';
		
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	if (exe.getClientDate() <= 20130605)
		exe.replace(offset+5, ' 31 C0 C3 90', PTYPE_HEX);
	else
		exe.replace(offset+5, ' 31 C0 5D C3', PTYPE_HEX);

	return true;
}