function ChatColorGM() {
	var offset = exe.findCode('68 FF 8D 1D 00', PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Part 1";
	}
	
	offset = exe.find('68 FF FF 00 00', PTYPE_HEX, false, ' ', offset);
	if (offset == -1) {
		return "Failed in Part 2";
	}
	
	exe.getUserInput('$gmChatColor', XTYPE_COLOR, 'Color input', 'Select the new GM Chat Color', 0x0000FFFF);
    exe.replace(offset+1, '$gmChatColor', PTYPE_STRING);

    return true;
}