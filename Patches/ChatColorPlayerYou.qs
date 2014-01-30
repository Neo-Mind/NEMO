function ChatColorPlayerYou() {
	
	if (exe.getClientDate() <= 20130605) {
		var code = 
				  ' 1B C0'			// jz      short loc_5E179C
				+ ' 23 C1'			// push    1
				+ ' 68 00 FF 00 00'	// push    0FF00h
				;
	}
	else {
		var code = 
				  ' 6A 01'			// jz      short loc_5E179C
				+ ' 1B C0'			// push    1
				+ ' 68 00 FF 00 00'	// push    0FF00h
				;
	}
    
	var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }
	
	exe.getUserInput('$yourChatColor', XTYPE_COLOR, 'Color input', 'Select the new Self Chat Color', 0x0000FF00);
    exe.replace(offset+5, '$yourChatColor', PTYPE_STRING);
    return true;
}