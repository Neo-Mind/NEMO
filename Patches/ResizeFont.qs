function ResizeFont() {
	var cfonta = exe.findFunction("CreateFontA", PTYPE_STRING, true);
	if (cfonta == -1) {
		return "Failed in Step 1";
	}
	
	var code =    " 52"		//PUSH EDX
				+ " FF 15" + cfonta.packToHex(4) //CALL DWORD PTR DS:[<&GDI32.CreateFontA>]
				
	var offset = exe.findCode(code, PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Step 2";
	}
	
	var preoffset = exe.find("8B 56 04", PTYPE_HEX, false, " ", offset-0x30, offset);
	if (preoffset == -1) {
		return "Failed in Step 3";
	}
	
	code = exe.fetchHex(preoffset+3, offset - (preoffset+3));
	
	var inp = exe.getUserInput('$newFontHgt', XTYPE_BYTE, "Number Input", "Enter the new Font Height(1-127) - snaps to closest valid value", 10, 1, 127);
	code = code + ' 90 90 6A' + (0-inp).packToHex(1);
	
	exe.replace(preoffset, code, PTYPE_HEX);
}