function ChatColorPartyYou() {

	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 24 18'			// jnz     
				+ ' 6A 03'			// push    3
				+ ' 68 FF C8 00 00'	// push    0C8FFh
				;
	}
	else {
		var code = 
				  ' 75 1C'			// jnz     
				+ ' 6A 03'			// push    3
				+ ' 68 FF C8 00 00'	// push    0C8FFh
				;
	}

	var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }

    exe.getUserInput('$yourpartyChatColor', XTYPE_COLOR, 'Color input', 'Select the new Self Party Chat Color', 0x0000C8FF);
    exe.replace(offset+5, '$yourpartyChatColor', PTYPE_STRING);
    return true;
}