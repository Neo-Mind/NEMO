function EnableTitleBarMenu() {
	if (exe.getClientDate() <= 20130605) {
		var code =
			  ' 68 00 00 C2 02'	// push    2C20000h        ; dwStyle
			+ ' 51'				// push    ecx             ; lpWindowName
			;
	}
	else {
		var code = 
			  ' 68 00 00 C2 02'	// push    2C20000h        ; dwStyle
			+ ' 52'				// push    ecx             ; lpWindowName
			;
	}
	
	var offset = exe.findCode(code, PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	exe.replace(offset+3, 'CA', PTYPE_HEX);
	return true;
}