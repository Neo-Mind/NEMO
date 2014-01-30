function DisableFilenameCheck() {    
	var codeA =	  ' E8 AB AB AB FF';	// call    sub_707420
	
	var codeB =	  ' 39 AB AB AB AB 00'	// cmp     Langtype, ebp
				+ ' 75 AB'				// jnz     short loc_73FE94
				+ ' E8 AB AB FF FF'		// call    sub_73DFB0
				+ ' 84 C0'				// test    al, al
				;

	var jmpPos = 11;
    var offset = exe.findCode(codeA + codeB, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		//Try to search for register XORing
		offset = exe.findCode(codeA + ' AB AB' + codeB, PTYPE_HEX, true, '\xAB');
		jmpPos = 13;
	}
	
	if (offset == -1) {
		return 'Failed in Part 1';
	}
	
	exe.replace(offset + jmpPos, 'EB', PTYPE_HEX);
    return true;
}