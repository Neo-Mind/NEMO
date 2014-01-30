function EnableProxySupport() {
	// MISSION: Hijack connect() call in CConnection::Connect,
	// save the first IP that comes into sight and use it for
    // any following connection attempts.
	// Now since ws2_32::connect is linked by ordinal without
	// name, we cannot search for it with FindFunction, but
	// there is a certain string in CConnection::Connect, that
	// we can use instead...

	var offset = exe.findString("Failed to setup select mode", RVA);
	if (offset == -1) {
		return "Failed in Part 1";
	}

	// ...and function referencing it is CConnection::Connect.
	offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Part 2";
	}
	
	//var bIndirectCALL = false;
	
	var code = 	  " FF 15 AB AB AB AB"	// CALL    NEAR DWORD PTR DS:[<&WS2_32.connect>]
				+ " 83 F8 FF"			// CMP     EAX,-1
				+ " 75 AB"				// JNZ     SHORT OFFSET v
				+ " 8B 3D AB AB AB AB"	// MOV     EDI,DWORD PTR DS:[<&WS2_32.WSAGetLastError>]
				+ " FF D7"				// CALL    NEAR EDI
				+ " 3D 33 27 00 00"		// CMP     EAX,2733h
				;
	var bOffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x50, offset);
	if (bOffset == -1) {
		return "Failed in Part 3";
	}
	
	exe.replace(bOffset," 90", PTYPE_HEX);
	bOffset++;

	var jmpCode =	  " A1 00 00 00 00"		// MOV     EAX,DWORD PTR DS:[<g_SaveIP>]
					+ " 85 C0"				// TEST    EAX,EAX
					+ " 75 08"				// JNZ     SHORT OFFSET v
					+ " 8B 46 0C"			// MOV     EAX,DWORD PTR DS:[ESI+C]
					+ " A3 00 00 00 00"		// MOV     DWORD PTR DS:[<g_SaveIP>],EAX
					+ " 89 46 0C"			// MOV     DWORD PTR DS:[ESI+C],EAX
					+ " FF 25 00 00 00 00"	// JMP     [OFFSET] ^
					;

	offset = exe.findZeros(0x4+0x1A);
	if (offset == -1) {
		return "Failed in Part 5";
	}
	
	// g_SaveIP
	jmpCode = jmpCode.replaceAt(3*0x01, offset.packToHex(4));
	jmpCode = jmpCode.replaceAt(3*0x0D, offset.packToHex(4));
	
	// WS2_32.connect address
	jmpCode = jmpCode.replaceAt(3*0x16, exe.fetchHex(bOffset+1,4));
		
	// JMP in
	var jmpdiff = exe.Raw2Rva(offset+4) - exe.Raw2Rva(bOffset) - 5;	
	exe.replace(bOffset, " E8" + jmpdiff.packToHex(4), PTYPE_HEX);
	
    // Insert the JumpCode
	jmpCode = " 00 00 00 00" + jmpCode;
	exe.insert(offset, 0x4+0x1A, PTYPE_HEX);
	
    return true;
}