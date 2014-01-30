function ChatColorGM() {
	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 68 FF FF 00 00' // push    0FFFFh
				+ ' EB 43 8B 56 04'; 
	}
	else {
		var code =	  
				  ' 68 FF FF 00 00' // push    0FFFFh
				+ ' EB 40 8B 47 04'; 
	}
	
	var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }

    exe.getUserInput('$gmChatColor', XTYPE_COLOR, 'Color input', 'Select the new GM Chat Color', 0x0000FFFF);
    exe.replace(offset+1, '$gmChatColor', PTYPE_STRING);

    return true;
}