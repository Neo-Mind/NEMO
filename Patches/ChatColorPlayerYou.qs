function ChatColorPlayerYou() {
	var code1 = ' 6A 01'	//PUSH 1
	var code2 = ' 1B C0'	//SBB EAX,EAX
	var code3 = ' 23 C1'	//AND EAX,ECX
	var code4 = ' 68 00 FF 00 00'	//PUSH 0FF00h
	
	var addon = 5;
	var offset = exe.findCode(code1 + code2 + code4, PTYPE_HEX, false);
	if (offset == -1) {//older 2013 client
		addon = 7;
		offset = exe.findCode(code1 + code2 + code3 + code4, PTYPE_HEX, false);
	}
	if (offset == -1) {//2012 and older one.
		addon = 3;
		offset = exe.findCode(code1 + code4, PTYPE_HEX, false);
	}
	if (offset == -1) {	
	    return 'Failed in part 1';
    }
	
	exe.getUserInput('$yourChatColor', XTYPE_COLOR, 'Color input', 'Select the new Self Chat Color', 0x0000FF00);
    exe.replace(offset+addon, '$yourChatColor', PTYPE_STRING);
    return true;
}