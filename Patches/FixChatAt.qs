function FixChatAt() {

	if (exe.getClientDate() <= 20130605)
		var code = ' 46 29 00 5F 5E 5D B0 01';
	else
		var code = ' 46 2D 00 5F 5E B0 01 5B';
		
	var offset = exe.findCode(code, PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in part 1";
	}
    exe.replace(offset+2, '01', PTYPE_HEX);	
    return true;
}