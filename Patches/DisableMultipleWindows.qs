function DisableMultipleWindows() {
	
	var code = " E8 AB AB AB FF AB FF 15 AB AB AB 00 A1 AB AB AB 00";
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	var addon = 12;
	if (offset == -1) {
		code = " E8 AB AB AB FF 6A 00 FF 15 AB AB AB 00 A1 AB AB AB 00";
		offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
		addon = 13;
	}
	
	if (offset != -1) {	
		exe.replace(offset + addon, ' B8 FF FF FF', PTYPE_HEX);
	}
	else {
		// assume this is a client, where gravity already
		// removed the code that prevented multiple client
		// instances from spawning. the great thing about
		// it is, that we do not have the space to do
		// anything in the area where the code used to be...
		
		// "Please use the correct client."
		
		// Step 1 - Find the message string.
		code =	  "\xC1\xA4\xBB\xF3\xC0\xFB\xC0\xCE\x20\xB6\xF3"
				+ "\xB1\xD7\xB3\xAA\xB7\xCE\xC5\xA9\x20\xC5\xAC"
				+ "\xB6\xF3\xC0\xCC\xBE\xF0\xC6\xAE\xB8\xA6\x20"
				+ "\xBD\xC7\xC7\xE0\xBD\xC3\xC4\xD1\x20\xC1\xD6"
				+ "\xBD\xC3\xB1\xE2\x20\xB9\xD9\xB6\xF8\xB4\xCF"
				+ "\xB4\xD9\x2E"
				;
		offset = exe.findString(code, RVA);
		if (offset == -1) {
			return 'Failed in Step 1';
		}
			
		//Step 2 - Find reference to where it is pushed.
		offset = exe.findCode('68' + offset.packToHex(4), PTYPE_HEX, false);
		if (offset == -1) {
			return 'Failed in Step 2';
		}
			
		//Step 3 - Get the address of CoInitialize function.
		code = ' E8 AB AB AB AB AB FF 15 AB AB AB 00';//CALL func, PUSH reg32, CALL ole32.CoInitialize
		var o2 = exe.find(code, PTYPE_HEX, true, '\xAB', offset - 0x200, offset);
		if (o2 == -1) {
			return 'Failed in Step 3';
		}
		
		//Step 4 - Steal the called address before CoInitialize.
		o2 = o2 + 5;
		var stolen = exe.fetchDWord(o2-4) + exe.Raw2Rva(o2);
		
		//Step 5 - Setup ASM code for mutex
		code =    ' E8 00 00 00 00'									// CALL StolenCall
				+ ' 56'												// PUSH ESI
				+ ' 33 F6'											// XOR ESI,ESI
				+ ' E8 09 00 00 00'									// PUSH &JMP
				+ ' 4B 45 52 4E 45 4C 33 32 00'						// DB 'KERNEL32',0
				+ ' FF 15 00 00 00 00'								// CALL <&GetModuleHandleA>
				+ ' E8 0D 00 00 00'									// PUSH &JMP
				+ ' 43 72 65 61 74 65 4D 75 74 65 78 41 00'			// DB 'CreateMutexA',0
				+ ' 50'												// PUSH EAX
				+ ' FF 15 00 00 00 00'								// CALL <&GetProcAddress>
				+ ' E8 0F 00 00 00'									// PUSH &JMP
				+ ' 47 6C 6F 62 61 6C 5C 53 75 72 66 61 63 65 00'	// DB 'Global\Surface',0
				+ ' 56'												// PUSH ESI
				+ ' 56'												// PUSH ESI
				+ ' FF D0'											// CALL EAX
				+ ' 85 C0'											// TEST EAX,EAX
				+ ' 74 0F'											// JE lFailed
				+ ' 56'												// PUSH ESI
				+ ' 50'												// PUSH EAX
				+ ' FF 15 00 00 00 00'								// CALL <&WaitForSingleObject>
				+ ' 3D 02 01 00 00'									// CMP EAX,258  ; WAIT_TIMEOUT
				+ ' 75 2F'											// JNZ lSuccess
				+ ' E8 09 00 00 00'									// lFailed: PUSH &JMP
				+ ' 4B 45 52 4E 45 4C 33 32 00'						// DB 'KERNEL32',0
				+ ' FF 15 00 00 00 00'								// CALL <&GetModuleHandleA>
				+ ' E8 0C 00 00 00'									// PUSH &JMP
				+ ' 45 78 69 74 50 72 6F 63 65 73 73 00'			// DB 'ExitProcess',0
				+ ' 50'												// PUSH EAX
				+ ' FF 15 00 00 00 00'								// CALL <&GetProcAddress>
				+ ' 56'												// PUSH ESI
				+ ' FF D0'											// CALL EAX
				+ ' 5E'												// lSuccess: POP ESI
				+ ' E9 00 00 00 00'									// JMP AfterStolenCall
				;
			
		//Step 6 - Get Free Offset
		var free = exe.findZeros(0x95);
		if (free == -1) {
			return "Failed in Step 6 - Not enough free space";
		}

		//Step 7 - Replace the stolen call with our code
		exe.replace(o2-5, "E9" + (exe.Raw2Rva(free)-exe.Raw2Rva(o2)).packToHex(4), PTYPE_HEX);
	
		//Step 8 - Fill the call instruction.
		code = code.replaceAt( 0x01*3, (stolen - exe.Raw2Rva(free + 5)).packToHex(4));
		code = code.replaceAt( 0x18*3, exe.findFunction('GetModuleHandleA'   ).packToHex(4));
		code = code.replaceAt( 0x31*3, exe.findFunction('GetProcAddress'     ).packToHex(4));
		code = code.replaceAt( 0x55*3, exe.findFunction('WaitForSingleObject').packToHex(4));
		code = code.replaceAt( 0x70*3, exe.findFunction('GetModuleHandleA'   ).packToHex(4));
		code = code.replaceAt( 0x88*3, exe.findFunction('GetProcAddress'     ).packToHex(4));
		code = code.replaceAt( 0x91*3, (exe.Raw2Rva(o2) - exe.Raw2Rva(free + 0x95)).packToHex(4));
		
		//Step 9 - Insert the ASM code
		exe.insert(free, 0x95, code, PTYPE_HEX);
	}
	return true;
}