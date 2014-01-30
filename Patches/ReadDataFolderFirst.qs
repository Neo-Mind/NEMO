function ReadDataFolderFirst() {
	// Strings for pattern search
	var readfolder = exe.findString("readfolder", RVA).packToHex(4);
	var loading	= exe.findString("loading", RVA).packToHex(4);
	
    var code =	  ' 68' + readfolder		// push    offset aReadfolder ; 'readfolder'
			+ ' 8B AB'					// mov     ecx, ebp
			+ ' E8 AB AB AB AB'			// call    XMLElement::FindChild
			+ ' 85 C0'					// test    eax, eax
			+ ' 74 07'					// jz      short loc_543B67  <- remove conditional jump
			+ ' C6 05 AB AB AB AB 01'	// mov     Readfolder, 1
			+ ' 68' + loading			// push    offset aLoading ; 'loading'
			;
	
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	exe.replace(offset+14, ' 90 90', PTYPE_HEX);        
    var readFolder = exe.fetchHex(offset+18, 4);  // store variable address of ReadFolder
	
	if(exe.getClientDate() < 20120101) { // not sure of actual date,
		var patch_offset = 14;
		code =    ' 80 3D' + readFolder + ' 00'	// cmp     Readfolder, 0
				+ ' 57'							// push    edi
				+ ' B9 AB AB AB 00'				// mov     ecx, offset unk_84FCAC
				+ ' 56'							// push    esi
				+ ' 74 23'						// jz      short loc_55FDFB
				;
		offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
		if (offset == -1) {
			return "Failed in part 2.1";
		}
	} 
	else if (exe.getClientDate() <= 20130605) {
		var patch_offset = 19;
		code =	  ' 80 3D' + readFolder + ' 00'	// cmp     Readfolder, 0
				+ ' 53'							// push    ebx
				+ ' 8B AB AB AB'				// mov     ebx, offset unk_84FCAC
				+ ' 57'							// push    edi
				+ ' 8B AB AB AB'
				+ ' 57'
				+ ' 53'
				+ ' 74 AB'
				;
				
		offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
		if (offset == -1) {
			return "Failed in part 2.2";
		}
	}
	else {
		var patch_offset = 17;
		code =    ' 80 3D' + readFolder + ' 00'	// cmp     Readfolder, 0
				+ ' 53'							// push    ebx
				+ ' 8B AB AB'					// mov     ebx, offset unk_84FCAC
				+ ' 57'							// push    edi
				+ ' 8B AB AB'
				+ ' 57'
				+ ' 53'
				+ ' 74 AB'
				;
				
		offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
		if (offset == -1) {
			return "Failed in part 2.3";
		}
	}
	
    exe.replace(offset+patch_offset, " 90 90", PTYPE_HEX);	
	return true;
}