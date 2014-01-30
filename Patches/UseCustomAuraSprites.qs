function UseCustomAuraSprites(){

	var erb = exe.findString('effect\\ring_blue.tga', RVA).packToHex(4);
	var epp = exe.findString('effect\\pikapika2.bmp', RVA).packToHex(4);
	
	if (exe.getClientDate() <= 20130605) {
		var code00 =  ' 68' + erb					// PUSH    'effect\ring_blue.tga'
				+ ' FF 15 AB AB AB AB'			// CALL    NEAR DWORD PTR DS:[&MSVCP90.std::basic_string<char>::basic_string<char>]
				+ ' 89 AB AB AB'				// MOV     [esp+44h], ebp
				+ ' C7 44 AB AB AB AB AB AB'	// MOV     dword ptr [esp+44h], 0FFFFFFFFh
				+ ' 8B CE'						// MOV     ECX,ESI
				+ ' E8 AB AB AB AB'				// CALL    ADDR
				+ ' 8B 57 AB'					// MOV     EAX,DWORD PTR DS:[EDI+CONST]
				+ ' 56'							// PUSH    esi
				+ ' 8B CF'						// MOV     ecx, edi
				+ ' 89 AB AB'					// mov     [esi+4], edx
				+ ' 89 AB AB'					// mov     [esi+0Ch], ebx
				+ ' 89 AB AB'					// mov     [esi+10h], ebp
				+ ' C7 46 AB AB AB AB AB'		// mov     dword ptr [esi+8], 1
				+ ' E8 AB AB AB AB'				// call    sub_62A440
				;
					
		var code01 =  ' 68' + epp	// PUSH    'effect\pikapika2.bmp'
				+ ' FF 15'		// CALL    NEAR DWORD PTR DS:[&MSVCP90.std::basic_string<char>::basic_string<char>]
				;				
	}
	else {
		var code00 =  ' 68' + erb				// PUSH    'effect\ring_blue.tga'
				+ ' C6 01 00'				// CALL    NEAR DWORD PTR DS:[&MSVCP90.std::basic_string<char>::basic_string<char>]
				+ ' E8 AB AB AB AB'			// MOV     [esp+44h], ebp
				+ ' C7 45 AB AB AB AB AB'	// mov     [ebp+var_4], 0
				+ ' C7 45 AB AB AB AB AB'	// mov     [ebp+var_4], 0FFFFFFFFh
				+ ' 8B CE'					// mov     ecx, esi
				+ ' E8 AB AB AB AB'			// call    sub_64CB00
				+ ' 8B 57 04'				// mov     edx, [edi+4]
				+ ' 56'						// PUSH    esi
				+ ' 8B CF'					// MOV     ecx, edi
				+ ' 89 AB AB'				// mov     [esi+4], edx
				+ ' 89 AB AB'				// mov     [esi+0Ch], ebx
				+ ' C7 46 AB AB AB AB AB'	// mov     dword ptr [esi+10h], 0
				+ ' C7 46 AB AB AB AB AB'	// mov     dword ptr [esi+8], 1
				+ ' E8 AB AB AB AB'			// call    sub_42AAE0	
				;

		var code01 =  ' 68' + epp 		// PUSH    'effect\pikapika2.bmp'
				+ ' C6 AB AB'		// mov     byte ptr [ecx], 0
				+ ' E8 AB AB AB AB'	// CALL    ADR
				;
	}

    var offset00 = exe.findCode(code00, PTYPE_HEX, true, "\xAB");
	if (offset00 == -1) {
		return "Failed in part 1";
	}
	
	var offset01 = exe.findCode(code01, PTYPE_HEX, true, "\xAB");
	if (offset01 == -1) {
		return "Failed in part 2";
	}
     
	var code =  "effect\\aurafloat.tga\x00effect\\auraring.bmp\x00\x90";
	var size =  code.length;
	
	var free = exe.findZeros(size);
	if (free == -1) {
		return "Failed to find enough free space";
	}
	
	exe.replace(offset00+1,  exe.Raw2Rva(free+0 ).packToHex(4), PTYPE_HEX);
	exe.replace(offset01+1,  exe.Raw2Rva(free+21).packToHex(4), PTYPE_HEX);
	exe.insert(free, size, code.toHex(), PTYPE_HEX);
	
	return true;
}