function EnableShowName() {
	var code =    " 85 C0"		//TEST EAX, EAX
				+ " 74 AB"		//JNE short
				+ " 83 F8 06"	//CMP EAX, 06
				+ " 74 AB"		//JNE short
				+ " 83 F8 0A"	//CMP EAX, 0A
				;
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Step 1";
	}
	exe.replace(offset+2, "EB", PTYPE_HEX);
}