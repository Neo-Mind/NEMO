function DisableHallucinationWavyScreen() {
    if (exe.getClientDate() <= 20130605) {
		var code = 
				  ' 83 C6 AB'			// add     esi, 6Ch
				+ ' 89 3D AB AB AB AB';	// mov     dword_C08A84, edi
	}
	else {
		var code =
				  ' 8D 4E AB'			// lea     ecx, [esi+6Ch]
				+ ' 89 3D AB AB AB AB';	// mov     dword_C08A84, edi
	}
	
	var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return 'Failed in part 1';
	}
    
	var dword = exe.fetchHex(offset+5, 4);
	code =    ' 8B AB'
			+ ' E8 AB AB AB AB'
			+ ' 83 3D' + dword + ' 00'
            + ' 0F 84 AB AB AB AB';
      
	offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
    if (offset == -1) {
		return 'Failed in part 2';
	}
	
    exe.replace(offset+14, ' 90 E9', PTYPE_HEX);
    return true;
}
