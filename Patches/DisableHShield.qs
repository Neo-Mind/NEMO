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
	exe.replace(offset+8, ' 33 C0 40 90', PTYPE_HEX);
		
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
        
    //Convert to RVA (the actual Relative Virtual Address not the RVA we mistook)
    var bOffset = exe.Raw2Rva(aOffset) - exe.getImageBase();//ideally should be in IMPORT section
	
	// The name offset comes after the thunk offset.
    // Thunk offset is guessed through wildcard.
	
	code = ' 00 00 00 00 00 00 00 00 00' + bOffset.packToHex(4);	
	offset = exe.find(code, PTYPE_HEX, false, ' ', exe.getROffset(IMPORT), exe.getROffset(IMPORT) + exe.getRSize(IMPORT)-1);

    if (offset == -1) {
		return 'Failed in part 4';
	}
	offset -= 3 ; //(AB AB AB 00) got shrinked to 00 so we need to subtract 3 to get needed value;
	
    // Shinryo: As far as I see, all clients which were compiled with VC9
    // have always the same import table and therefore I assume that the last entry
    // is always 221 bytes after the aossdk.dll thunk offset.
    // So just read the last import entry, clear it with zeros and
    // place it where aossdk.dll was set before.
    // TO-DO: Create a seperate PE parser for easier access
    // and modification in case this diff should break in the near future.
	
	// Neo: Enough with the dependencies - find the 20 NULL byte sequence following the last entry and just subtract 20 
	
	var endoffset = exe.find(" 00".repeat(21), PTYPE_HEX, false, " ", offset + 20);//20 from the end + 1 zero is from the last dll entry bytes
	if (endoffset == -1) {
		return "Failed in Part 5 - Unable to determine end of Import Table"
	}
	endoffset -= 19;//<= points to the last dll imported
		
	var data = exe.fetchHex(endoffset, 20);
	
	exe.replace(endoffset, " 00".repeat(20), PTYPE_HEX);
    exe.replace(offset, data, PTYPE_HEX);
	
	return true;
}