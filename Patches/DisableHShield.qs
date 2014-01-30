function DisableHShield() {
	if (exe.getClientDate() <= 20130605) {
		var code =	
				  ' 51'						// push    ecx
				+ ' 83 3D AB AB AB 00 00'	// cmp     dword_88A210, 0
				+ ' 74 04'					// jz      short loc_58AD2E
				+ ' 33 C0'					// xor     eax, eax
				+ ' 59'						// pop     ecx
				+ ' C3'						// retn
				;
	}
	else {
		var code =	  
				  ' 51'						// push    ecx
				+ ' 83 3D AB AB AB 00 00'	// cmp     dword_C40C94, 0
				+ ' 74 06'					// jz      short loc_626FD3
				+ ' 33 C0'					// xor     eax, eax
				+ ' 8B E5'					// mov     esp, ebp
				+ ' 5D'						// pop     ebp
				+ ' C3'						// retn		
				;
	}
        
	var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return 'Failed in part 1';
	}
        
    // Just return 1 without initializing AhnLab :)
	exe.replace(offset+1, ' 31 C0 40 90 90 90 90 90 90 90 90', PTYPE_HEX);
		
	offset = exe.findString('CHackShieldMgr::Monitoring() failed', RAW);
	if (offset != -1) {
		// Second part of patch, i think only for ragexe
		code =	  ' E8 AB AB AB AB'
				+ ' 84 C0'
				+ ' 74 16'
				+ ' 8B AB'
				+ ' E8 AB AB AB AB'
				;
				
		offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
		if (offset == -1) {
			return 'Failed in part 2';
		}
		
		exe.replace(offset, ' B0 01 5E C3 90', PTYPE_HEX);
    }
		
    // Import table fix for aossdk.dll
	// The dll name offset gives the hint where the image descriptor of this
    // dll resides.
    
	var aOffset = exe.find('aossdk.dll', PTYPE_STRING, false);
	if (aOffset == -1) {
		return 'Failed in part 3';
	}
        
    //Convert to RVA
    var bOffset = aOffset + exe.getVOffset(IMPORT) - exe.getROffset(IMPORT);//IMPORT section is auto detected internally
	
	
	// The name offset comes after the thunk offset.
    // Thunk offset is guessed through wildcard.
	
	code = ' 00 AB AB AB 00 00 00 00 00 00 00 00 00' + bOffset.packToHex(4);	
	offset = exe.find(code, PTYPE_HEX, true, '\xAB', exe.getROffset(IMPORT), exe.getROffset(IMPORT) + exe.getRSize(IMPORT)-1);
		
    if (offset == -1) {
		return 'Failed in part 4';
	}
	
    // Shinryo: As far as I see, all clients which were compiled with VC9
    // have always the same import table and therefore I assume that the last entry
    // is always 221 bytes after the aossdk.dll thunk offset.
    // So just read the last import entry, clear it with zeros and
    // place it where aossdk.dll was set before.
    // TO-DO: Create a seperate PE parser for easier access
    // and modification in case this diff should break in the near future.
		
	if (exe.isThemida()) {
		var entries = 6;
	}
	else {
		var entries = 11;
	}
	
	var data = exe.fetchHex(offset + 20 * entries, 20);
	
	exe.replace(offset + 20 * entries, " 00".repeat(20), PTYPE_HEX);
    exe.replace(offset, data, PTYPE_HEX);
	
	return true;
}