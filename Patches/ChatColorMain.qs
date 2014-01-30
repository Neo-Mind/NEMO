function ChatColorMain() {
	// To find ZC_Notify_Chat : "68 FF 8D 1D 00";  // PUSH 1D8DFFh (orange)
	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 68 FF FF FF 00'	// push    0FFFFh
				+ ' 8B 4C AB AB'	// lea     edx, [esp+118h+Dst]
				+ ' 51'				// push    edx
				+ ' 6A 01'			// jmp     short loc_5E1790
				;
	}
	else {
		var code =
				  ' 68 FF FF FF 00'	// push    0FFFFh
				+ ' B9 AB AB AB 00'	// lea     edx, [ebp+var_104]
				+ ' 56'				// push    edx
				+ ' 6A 01'			// jmp     short loc_5E1790
				;
	}

	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset == -1) {
        return 'Failed in part 1';
    }

    exe.getUserInput('$mainChatColor', XTYPE_COLOR, 'Color input', 'Select the new Main Chat Color', 0x0000FFFF);
    exe.replace(offset+1, '$mainChatColor', PTYPE_STRING);
    return true;
}