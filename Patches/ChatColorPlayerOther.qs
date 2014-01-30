function ChatColorPlayerOther() {

	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 74 1A'			// jz      short loc_5E179C
				+ ' 6A 00'			// push    0
				+ ' 6A 01'			// push    1
				+ ' 68 FF FF FF 00'	// push    0FFFFFFh
				;
				
		var type = 0;	
	}
	else {
		var code =	
				  ' 74 15'			// jz      short loc_5E179C
				+ ' 53'				// push    ebx
				+ ' 6A 01'			// push    1
				+ ' 68 FF FF FF 00'	// push    0FFFFFFh
				;
				
		var type = 1;	
	}
	
	var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }
	
	exe.getUserInput('$otherChatColor', XTYPE_COLOR, 'Color input', 'Select the new Other Player Chat Color', 0x00FFFFFF);	
	if(type == 0)
		exe.replace(offset+7, '$otherChatColor', PTYPE_STRING);
	else
		exe.replace(offset+6, '$otherChatColor', PTYPE_STRING);

    return true;
}