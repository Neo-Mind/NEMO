function ForceSendClientHash() {

	var code =	
			  ' 8B AB AB AB AB 00 '	//MOV reg32,DWORD PTR DS:[g_serviceType]
			+ ' 33 C0'				//XOR EAX, EAX
			+ ' 83 AB 06'			//CMP reg32, 6	
			+ ' 74'					//JE SHORT TO MOV EAX, 1
			;
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Part 1";
	}
	
	exe.replace(offset+11, 'EB', PTYPE_HEX);
	
	code =	  ' 85 C0'	// TEST EAX, EAX
			+ ' 75 AB'	// JNE SHORT
			+ ' A1'		// MOV EAX. DWORD PTR DS:[addr]			
			;
	
	offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+12);
	if (offset == -1) {
		return "Failed in Part 2";
	}
	
	exe.replace(offset+2, 'EB', PTYPE_HEX);
	
	code =	  ' 83 F8 06'	//CMP EAX, 6
			+ ' 75'			//JNE SHORT
			;
			
	offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+9);
	if (offset == -1) {
		return "Failed in Part 3";
	}
	
	exe.replace(offset+3, 'EB', PTYPE_HEX);
	return true;
}