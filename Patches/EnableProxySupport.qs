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
	
	var bIndirectCALL = false;	
	var code = 	  " FF 15 AB AB AB AB"	// CALL    NEAR DWORD PTR DS:[<&WS2_32.connect>]
				+ " 83 F8 FF"			// CMP     EAX,-1
				+ " 75 AB"				// JNZ     SHORT OFFSET v
				+ " 8B 3D AB AB AB AB"	// MOV     EDI,DWORD PTR DS:[<&WS2_32.WSAGetLastError>]
				+ " FF D7"				// CALL    NEAR EDI
				+ " 3D 33 27 00 00"		// CMP     EAX,2733h
				;
				
	var bOffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x50, offset);
	if (bOffset != -1) {
		bIndirectCALL = true;
		exe.replace(bOffset," 90 E8", PTYPE_HEX);
		bOffset++;
	}
	else {
		code =	  " E8 AB AB AB AB"		// CALL    <&WS2_32.connect>
				+ " 83 F8 FF"			// CMP     EAX,-1
				+ " 75 AB"				// JNZ     SHORT OFFSET v
				+ " E8 AB AB AB AB"		// CALL    <&WS2_32.WSAGetLastError> 
				+ " 3D 33 27 00 00"		// CMP     EAX,2733h
				;
		
		bOffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x90, offset);
		if (bOffset == -1) {
			return "Failed in Part 3";
		}
	}
	
	var jmpCode =	  " A1 00 00 00 00"		// MOV     EAX,DWORD PTR DS:[<g_SaveIP>]
					+ " 85 C0"				// TEST    EAX,EAX
					+ " 75 08"				// JNZ     SHORT OFFSET v
					+ " 8B 46 0C"			// MOV     EAX,DWORD PTR DS:[ESI+C]
					+ " A3 00 00 00 00"		// MOV     DWORD PTR DS:[<g_SaveIP>],EAX
					+ " 89 46 0C"			// MOV     DWORD PTR DS:[ESI+C],EAX
					;

	if (bIndirectCALL) {
		jmpCode +=	  " FF 25 00 00 00 00"	// JMP     [OFFSET] ^
	}
	else {
		jmpCode +=	  " E9 00 00 00 00"		// JMP		OFFSET
	}
	
	var jCSize = jmpCode.hexlength();
	offset = exe.findZeros(0x4+jcSize);//First 4 bytes are g_SaveIP
	if (offset == -1) {
		return "Failed in Part 5";
	}
	
	// g_SaveIP
	jmpCode = jmpCode.replaceAt(3*0x01, offset.packToHex(4));
	jmpCode = jmpCode.replaceAt(3*0x0D, offset.packToHex(4));
	
	// WS2_32.connect address
	if (bIndirectCALL) {
		var jmpOff = exe.fetchHex(bOffset+1,4);
	}
	else {
		var jmpOff = (exe.Raw2Rva(offset+5) + exe.fetchDWord(bOffset+1)) - exe.Raw2Rva(offset+jcSize);
		jmpOff = jmpOff.packToHex(4);
	}
	
	jmpCode = jmpCode.replaceAt(3*(jcSize-4), jmpOff);
		
	// JMP in
	var jmpdiff = exe.Raw2Rva(offset+4) - exe.Raw2Rva(bOffset+5);	
	exe.replace(bOffset, " E8" + jmpdiff.packToHex(4), PTYPE_HEX);
	
    // Insert the JumpCode
	jmpCode = " 00 00 00 00" + jmpCode;
	exe.insert(offset, 0x4+jcSize, PTYPE_HEX);
	
    return true;
}