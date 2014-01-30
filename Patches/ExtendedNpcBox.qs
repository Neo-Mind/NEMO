function ExtendNpcBox() {

	// 04 08 (2052) to 00 10 (4096)
	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 81 EC 08 08 00 00'		// SUB     ESP,808h
				+ ' A1 AB AB AB 00'			// MOV     EAX,DWORD PTR DS:[___security_cookie]
				+ ' 33 C4'					// XOR     EAX,ESP
				+ ' 89 84 24 04 08 00 00'	// MOV     DWORD PTR SS:[ESP+804h],EAX
				+ ' 56'						// push    esi
				+ ' 8B C1'					// mov     eax, ecx
				+ ' 57'						// push    edi
				+ ' 8B BC 24 14 08 00 00'	// mov     edi, [esp+810h+arg_0]
				;
	}
	else {
		var code =
				  ' 81 EC 08 08 00 00'				// SUB     ESP,808h
				+ ' A1 AB AB AB 00'					// MOV     EAX,DWORD PTR DS:[___security_cookie]
				+ ' 33 C5'							// XOR     EAX,ESP
				+ ' 89 45 FC'						// MOV     DWORD PTR SS:[EBP],EAX
				+ ' 56'								// push    esi
				+ ' 8B C1'							// mov     eax, ecx
				+ ' 57'								// push    edi
				+ ' 8B 7D 08'						// mov     edi, [ebp+arg_0]
				+ ' C7 80 E0 02 00 00 01 00 00 00'	// mov     dword ptr [eax+2E0h], 1
				;
	}

	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset == -1) {
        return "Failed in part 1";
    }
	
    exe.replace(offset+2, ' 04 10', PTYPE_HEX);
	
	if (exe.getClientDate() <= 20130605) {
		exe.replace(offset+16, " 00 10", PTYPE_HEX);
		exe.replace(offset+27, " 10 10", PTYPE_HEX);

		code =  ' FF D2 8B 8C 24 0C 08 00 00 5F 5E 33 CC E8 AB AB 0C 00 81 C4 08 08 00 00';
			  
		offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
		if (offset == -1) {
			return "Failed in part 2";
		}

		exe.replace(offset+5,  " 08 10", PTYPE_HEX);
		exe.replace(offset+20, " 04 10", PTYPE_HEX);
	}	
    return true;	
}