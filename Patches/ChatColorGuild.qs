function ChatColorGuild() {
	var code =	  ' 6A 04'			// push    4
				+ ' 68 B4 FF B4 00' // push    0B4FFB4h
				;				
    var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }

	exe.getUserInput('$guildChatColor', XTYPE_COLOR, 'Color input', 'Select the new Guild Chat Color', 0x00B4FFB4);
	exe.replace(offset+3, '$guildChatColor', PTYPE_STRING);
	
    return true;
}