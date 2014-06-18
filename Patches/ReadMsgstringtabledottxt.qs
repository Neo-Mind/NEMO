function ReadMsgstringtabledottxt() {
	var langtype = getLangType();
	switch(langtype) {
		case -4: return "Failed in Part 1.1 ";
		case -3: return "Failed in Part 1.2 ";
		case -2: return "Failed in Part 1.3 ";
		case -1: return "Failed in Part 1.4 ";
	}
	
	var code =    ' 83 3D' + langtype.packToHex(4) + ' 00'	// cmp     langtype, 0
							+ ' 56'							// push    esi
							+ ' 75 24'					// jnz     short loc_582B4B <---- Jmp to ReadMsgStringTable()
							+ ' 33 C9'					// xor     ecx, ecx
							+ ' 33 C0'					// xor     eax, eax
							+ ' 8B FF'					// mov     edi, edi
							+ ' 8B 90 AB AB AB 00'	// mov     edx, off_7EF7FC[eax]
							;
                
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	        
	// Force a jump to ReadMsgStringTable(): JNZ -> JMP
	exe.replace(offset+8, 'EB', PTYPE_HEX);
	return true;
}