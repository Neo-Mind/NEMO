function SsoLogin() {
	var code =
			  ' A1 AB AB AB AB' // push    0FFFFh
			+ ' 85 C0'
			+ ' 0F 84 AB AB AB AB'
			+ ' 83 F8 12'
			+ ' 0F 84 AB AB AB AB'
			+ ' 83 F8 0C'
			+ ' 0F 84 AB AB AB AB';
	
	var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return 'Failed in part 1';
	}
    
    exe.replace(offset+7, ' 90 E9', PTYPE_HEX);
    return true;
}