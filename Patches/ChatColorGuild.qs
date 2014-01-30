function ChatColorGuild() {

	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 14 53'			// push    ebx
				+ ' 6A 04'			// push    4
				+ ' 68 B4 FF B4 00' // push    0B4FFB4h
				;
				
		var type = 0;		
	}
	else {
		var code =	  
				  ' 53'				// push    ebx
				+ ' 6A 04'			// push    4
				+ ' 68 B4 FF B4 00'	// push    0B4FFB4h
				;
				
		var type = 1;
	}
          
    var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }

	exe.getUserInput('$guildChatColor', XTYPE_COLOR, 'Color input', 'Select the new Guild Chat Color', 0x00B4FFB4);
	if (type == 0)
		exe.replace(offset+5, '$guildChatColor', PTYPE_STRING);
	else
		exe.replace(offset+4, '$guildChatColor', PTYPE_STRING);
		
    return true;
}