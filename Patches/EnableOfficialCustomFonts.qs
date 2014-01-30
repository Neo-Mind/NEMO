function EnableOfficialCustomFonts() {

	var code =   
			  ' 0F 85 AE 00 00 00'
			+ ' E8 AB AB AB FF';
	
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	exe.replace(offset, ' 90 90 90 90 90 90', PTYPE_HEX);
	return true;
}