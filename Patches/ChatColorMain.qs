function ChatColorMain() {
	var code =	  ' 6A 01'			// PUSH 1
				+ ' 68 FF FF FF 00'	// PUSH 0FFFFh
				;
	var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }
	
    exe.getUserInput('$mainChatColor', XTYPE_COLOR, 'Color input', 'Select the new Main Chat Color', 0x0000FFFF);
    exe.replace(offset+3, '$mainChatColor', PTYPE_STRING);
    return true;
}