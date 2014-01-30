function ReadMsgstringtabledottxt() {

	var code =
			  ' 83 3D AB AB AB 00 00'	// cmp     dword_869FF0, 0
			+ ' 56'						// push    esi
			+ ' 75 24'					// jnz     short loc_582B4B <---- Jmp to ReadMsgStringTable()
			+ ' 33 C9'					// xor     ecx, ecx
			+ ' 33 C0'					// xor     eax, eax
			+ ' 8B FF'					// mov     edi, edi
			+ ' 8B 90 AB AB AB 00'		// mov     edx, off_7EF7FC[eax]
			;
                
    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	        
	// Force a jump to ReadMsgStringTable(): JNZ -> JMP
    exe.replace(offset+8, 'EB', PTYPE_HEX);
	return true;
}