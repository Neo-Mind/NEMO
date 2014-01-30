function Disable1rag1Params() {

	var rag1 = 	exe.findString("1rag1", RVA).packToHex(4);
	var code =
			  ' 68' + rag1	// push    offset a1rag1   ; "1rag1"
            + ' AB'			// push    ebp             ; Str
            + ' FF AB'		// call    esi ; strstr
            + ' 83 AB AB'	// add     esp, 8
            + ' 85 AB'		// test    eax, eax
            + ' 75 AB'		// jnz     short loc_723E28
			;
	
    var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if( offset == -1) {
		return 'Failed in part 1';
	}
	
	exe.replace(offset+13, 'EB', PTYPE_HEX);
	return true;
}