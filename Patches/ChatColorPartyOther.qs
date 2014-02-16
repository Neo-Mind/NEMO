function ChatColorPartyOther() {
	var code =	  ' 6A 03'			// push    03
				+ ' 68 FF C8 C8 00'	// push    0C8C8FFh (a pinkish color)
				;
	var offset = exe.findCode(code, PTYPE_HEX, false);
    if (offset == -1) {
        return 'Failed in part 1';
    }

    exe.getUserInput('$otherpartyChatColor', XTYPE_COLOR, 'Color input', 'Select the new Others Party Chat Color', 0x0000C8FF);
    exe.replace(offset+3, '$otherpartyChatColor', PTYPE_STRING);

	return true;
}