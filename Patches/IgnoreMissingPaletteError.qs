function IgnoreMissingPaletteError() {

    if (exe.getClientDate() <= 20130605)
		var code =  ' E8 AB AB AB 00 84 C0 0F 85 AC 00 00 00 56';
	else 
		var code =  ' E8 AB AB AB 00 84 C0 0F 85 30 01 00 00 BF';
			
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}

    exe.replace(offset+7, ' 90 E9', PTYPE_HEX);
	return true;
}