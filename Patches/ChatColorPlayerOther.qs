function ChatColorPlayerOther() {
	var code =	  ' 6A 01'			// push    1
				+ ' 68 FF FF FF 00'	// push    0FFFFFFh
				;
	var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }
	
	exe.getUserInput('$otherChatColor', XTYPE_COLOR, 'Color input', 'Select the new Other Player Chat Color', 0x00FFFFFF);	
	exe.replace(offset+3, '$otherChatColor', PTYPE_STRING);

    return true;
}