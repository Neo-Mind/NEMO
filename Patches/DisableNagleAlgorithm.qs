function SetTCPNODELAY() {
	
	var filler =  ' 00 00 00 00';	
	var code = 	 
			  ' 55'						// PUSH EBP       
			+ ' 8B EC'					// MOV EBP,ESP
			+ ' 83 EC 0C'				// SUB ESP,0C
			+ ' C7 45 F8 01 00 00 00'	// MOV DWORD PTR SS:[EBP-8],1
			+ ' 8B 45 10'				// MOV EAX,DWORD PTR SS:[EBP+10]
			+ ' 50'						// PUSH EAX
			+ ' 8B 4D 0C'				// MOV ECX,DWORD PTR SS:[EBP+0C]
			+ ' 51'						// PUSH ECX
			+ ' 8B 55 08'				// MOV EDX,DWORD PTR SS:[EBP+8]
			+ ' 52'						// PUSH EDX
			+ ' A1' + filler			// MOV EAX,DWORD PTR DS:[<&WS2_32.#23>]                  ; CA00 = socket() | offset = 26
			+ ' FF D0'					// CALL EAX
			+ ' 89 45 FC'				// MOV DWORD PTR SS:[EBP-4],EAX
			+ ' 83 7D FC FF'			// CMP DWORD PTR SS:[EBP-4],-1
			+ ' 74 35'					// JE SHORT 00734F4C
			+ ' 68' + filler			// PUSH 00734ED7                                         ; ST01 = ASCII 'setsockopt' | offset = 26+4+12 = 42
			+ ' 68' + filler			// PUSH 00734EE3                                         ; ST02 = ASCII 'WS2_32.DLL' | offset = 26+4+12+4+1 = 47
			+ ' 8B 0D' + filler			// MOV ECX,DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>]   ; CA01 = GetModuleHandleA() | offset = 26+4+12+4+1+4+2 = 53
			+ ' FF D1'					// CALL ECX
			+ ' 50'						// PUSH EAX
			+ ' 8B 15' + filler			// MOV EDX,DWORD PTR DS:[<&KERNEL32.GetProcAddress>]	 ; CA02 = GetProcAddress()	 | offset = 26+4+12+4+1+4+2+4+5 = 62
			+ ' FF D2'					// CALL EDX
			+ ' 89 45 F4'				// MOV DWORD PTR SS:[EBP-0C],EAX
			+ ' 83 7D F4 00'			// CMP DWORD PTR SS:[EBP-0C],0
			+ ' 74 11'					// JE SHORT 00734F4C
			+ ' 6A 04'					// PUSH 4
			+ ' 8D 45 F8'				// LEA EAX,[EBP-8]
			+ ' 50'						// PUSH EAX
			+ ' 6A 01'					// PUSH 1
			+ ' 6A 06'					// PUSH 6
			+ ' 8B 4D FC'				// MOV ECX,DWORD PTR SS:[EBP-4]
			+ ' 51'						// PUSH ECX
			+ ' FF 55 F4'				// CALL DWORD PTR SS:[EBP-0C]
			+ ' 8B 45 FC'				// MOV EAX,DWORD PTR SS:[EBP-4]
			+ ' 8B E5'					// MOV ESP,EBP
			+ ' 5D'						// POP EBP
			+ ' C2 0C 00'				// RETN 0C
			;
	
	var sopt = "setsockopt\x00";
	var ws32 = "WS2_32.DLL\x00";
	
	// Calculate free space that the code will need.
	var size = code.hexlength() + sopt.length + ws32.length;	
	var free = exe.findZeros(size+4);
	if (free == -1) {
		return "Failed in part 1: Not enough free space";
	}
	var freeRva = exe.Raw2Rva(free);
	//$free += 247 + 4 + 4 + 90 + 4;
	
	// ***********************************************************
	// Create default offsets that will be replaced into the code.
	// ***********************************************************
	
	// socket
	// Shinryo:
	// This one is a bit tricky..
	// First try to search for a call ds:socket, if not found
	// then search for call socket. If it was a call by distance
	// then calculate the offset at which socket() resides.
	var CA00_partA = " E8 AB AB 00 00 6A 00 6A 01 6A 02";
	
	// Call offset or distance.
	var CA00_partB1 = " FF 15 AB AB AB 00";
	var CA00_partB2 = " E8 AB AB AB 00";
	
	var CA00_offsetPos = 2;
	var socketDistanceCall = false;
	
	// Try to match both cases.
	var CA00_offset = exe.findCode(CA00_partA + CA00_partB1, PTYPE_HEX, true, "\xAB");
	if(CA00_offset == -1) {
		CA00_offset = exe.findCode(CA00_partA + CA00_partB2, PTYPE_HEX, true, "\xAB");
		CA00_offsetPos = 1;
		socketDistanceCall = true;
	}
	
	if(CA00_offset == -1) {
		return "Failed in part 2";
	}         
	
	// If called by offset..
	var CA00 = exe.fetchDWord(CA00_offset + CA00_partA.hexlength() + CA00_offsetPos);
	
	// If called by distance..
	if(socketDistanceCall === true) {
		CA00 = exe.Raw2Rva(CA00_offset + CA00_partA.hexlength()) + CA00 + 5;
	}
	if (CA00 < 0) {
		return "Failed in part 3";
	}
	
	var CA01 = exe.findFunction("GetModuleHandleA");
	if (CA01 == -1) {
		return "Failed in part 4";
	}
	
	// GetProcAddress
	var CA02 = exe.findFunction("GetProcAddress");
	if (CA02 == -1) {
		return "Failed in part 5";
	}
	
	//Now to get the location of the strings.
	var ST01 = freeRva + code.hexlength();
	var ST02 = ST01 + sopt.length; //1 for NULL
	
	// Time to place the addresses
	// CA00 at 26
	code = code.replaceAt(26*3, CA00.packToHex(4));
	// ST01 at 42                                
	code = code.replaceAt(42*3, ST01.packToHex(4));
	// ST02 at 47                                
	code = code.replaceAt(47*3, ST02.packToHex(4));
	// CA01 at 53                                
	code = code.replaceAt(53*3, CA01.packToHex(4));
	// CA02 at 62                                
	code = code.replaceAt(62*3, CA02.packToHex(4)); 
	
	// A JMP to socket() is found in each client.
	offset = exe.findCode('FF 25' + CA00.packToHex(4), PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in part 6";
	}
	
	// Replace all occurances where a call to socket() is made.
	exe.replace(offset+2, freeRva.packToHex(4), PTYPE_HEX);
	
	if (socketDistanceCall == false) {
		// Offset call to socket() is only available in VC9 clients.
		var offsets = exe.findCodes('FF 15' + CA00.packToHex(4), PTYPE_HEX, false);
		if (!offsets[0]) {
			return "Failed in part 7";
		}
		
		for (var i = 0; offsets[i]; i++) {
			// Replace all calls by offset with a call by distance.
			offset = offsets[i];
			exe.replace(offset, ' E8' + (freeRva - exe.Raw2Rva(offset) - 5).packToHex(4) + ' 90', PTYPE_HEX);
		}
	}
	
	// Finally, insert everything.
	exe.insert(free, size + 4, code + sopt.toHex() + ws32.toHex(), PTYPE_HEX);
	return true;
}