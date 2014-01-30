function UsePlainTextDescriptions() {

	if (exe.getClientDate() <= 20130605) {
		var code = 
				  ' 75 54'			// jnz     short loc_58CADD
				+ ' 56'				// push    esi
				+ ' 57'				// push    edi
				+ ' 8B 7C 24 0C'	// mov     edi, [esp+8+arg_0]
				;
	}
	else {
		var code =
				  ' 75 51'		// jnz     short loc_58CADD
				+ ' 56'			// push    esi
				+ ' 57'			// push    edi
				+ ' 8B 7D 08'	// mov     edi, [ebp+arg_0]
				;
	}
	
	var offset = exe.findCode(code, PTYPE_HEX, false);	
	if (offset == -1) {
		return 'Failed in part 1';
	}
	
    exe.replace(offset, 'EB', PTYPE_HEX);
    return true;
}