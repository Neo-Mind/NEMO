function Enable64kHairstyle() {

	var code = ' C0 CE B0 A3 C1 B7 5C B8 D3 B8 AE C5 EB'; // After it must have \\%s\\%s_%s.%s
	var offset = exe.find(code, PTYPE_HEX, false);

    if (offset == -1) {
        return 'Failed in part 1';
    }
	
	exe.replace(offset+18, '75', PTYPE_HEX); // %s -> %u
	
	// \\%s\%s_%s.%s
	//$push_var = pack("I", $exe->str("\xC0\xCE\xB0\xA3\xC1\xB7\x5C\xB8\xD3\xB8\xAE\xC5\xEB\x5C\x25\x73\x5C\x25\x73\x5F\x25\x73\x2E\x25\x73","rva"));
	//echo bin2hex($push_var) . " ";

	// Update the parameter PUSHed to be the hair style ID
	// itself rather than the string obtained from hard-coded
	// table. Note, that this will mess up existing hair-style
	// IDs 0..12. Also the 2nd and 3rd patch block ensures, that
	// ID 0 (invalid) is mapped to 2, as the table would do.
	
	if (exe.getClientDate() <= 20130605) {
		code =    ' 8B 4C 24 AB'  	// mov     ecx, [esp-50h+arg_84]
				+ ' 73 04' 		  	// jnb     short loc_67168D
				+ ' 8D 4C 24 AB'	// lea     ecx, [esp-50h+arg_84]
				+ ' 83 FE 10';		// cmp     eax, 10h
		var type = 0;
	}
	else {
		code =	  ' 83 7D AB AB'	// cmp     [ebp+var_18], 10h 
				+ ' 8B 4D D4'  		// mov     ecx, [esp-50h+arg_84]
				+ ' 73 03' 		  	// jnb     short loc_67168D
				+ ' 8D 4D D4'		// lea     ecx, [esp-50h+arg_84]
				+ ' 83 F8 10';		// cmp     eax, 10h
		var type = 1;
	}
	
    offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
    if (offset == -1) {
        return 'Failed in part 2';
    }
	
	if (type == 0) {
		code = 	  ' 4D 00 90'		// -> MOV     ECX,DWORD PTR SS:[EBP]
				+ ' 85 C9'          // -> TEST    ECX,ECX
				+ ' 75 02 41 41'    // -> JNZ     SHORT ADDR v & -> INC     ECX x2
				;
		
		exe.replace(offset+1, code, PTYPE_HEX);
	}
	else {
		code =	' 8B 4D 18 8B 09 85 C9 75 02 41 41 90';
		exe.replace(offset, code, PTYPE_HEX);
	}

	// Void table lookup.
	if (type == 0) {
		code =	  ' 8B 45 00'  // MOV     EAX,DWORD PTR SS:[EBP]
				+ ' 8B 14 81'  // MOV     EDX,DWORD PTR DS:[ECX+EAX*4]
				;
	}
	else {
		code =	  ' 75 19'
				+ ' 8B 0E'
				+ ' 8B 15 AB AB AB 00'	// MOV     EDX,DWORD PTR SS:[EBP]
				+ ' 8B 14 8A'			// MOV     EDX,DWORD PTR DS:[EDX+ECX*4]
				;
		
		//$code =  "\x75\x23"
		//		."\x8B\x06"
		//		."\x8B\x0D\xAB\xAB\xAB\x00"    // MOV     EDX,DWORD PTR SS:[EBP]
		//		."\x8B\x14\x81";     // MOV     EDX,DWORD PTR DS:[EDX+ECX*4]
		
	}
	
	offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
    if (offset == -1) {
		return 'Failed in part 3';
    }
	
	if (type == 0) {
		exe.replace(offset+4, ' 11 90', PTYPE_HEX); // -> MOV     EDX,DWORD PTR DS:[ECX]
	}
	else {
		exe.replace(offset+11, ' 12 90', PTYPE_HEX); // -> MOV     EDX,DWORD PTR DS:[EDX]
	}
		
		
	if (type == 1) {
		code =    ' 75 23'
				+ ' 8B 06'
				+ ' 8B 0D AB AB AB 00'	// MOV     ECX,DWORD PTR SS:[EBP]
				+ ' 8B 14 81'			// MOV     EDX,DWORD PTR DS:[EDX+ECX*4]
				;
		offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');

		if (offset == -1) {
			return 'Failed in part 3';
		}
		
		exe.replace(offset+11, ' 11 90', PTYPE_HEX); // -> MOV     EDX,DWORD PTR DS:[ECX]
	}
		
	// Lift limit that protects table from invalid access. We
	// keep the < 0 check, since lifting it would not give any
	// benefits.

	if (type == 0) {
		code =	  ' 7C 05'  				// JL      SHORT ADDR v
				+ ' 83 F8 AB'				// CMP     EAX,X
				+ ' 7E 07'					// JLE     SHORT ADDR v
				+ ' C7 45 00 0D 00 00 00';	// MOV     DWORD PTR SS:[EBP],0Dh
	}
	else {
		code =    ' 7C 05' 					// JL      SHORT ADDR v
				+ ' 83 F8 AB'				// CMP     EAX,X
				+ ' 7E 06'					// JLE     SHORT ADDR v
				+ ' C7 06 0D 00 00 00';		// MOV     DWORD PTR SS:[ESI],0Dh
	}
	
    offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
    if (offset == -1) {
        return 'Failed in part 4';
    }
	
	exe.replace(offset+5, 'EB', PTYPE_HEX); // -> MOV     EDX,DWORD PTR DS:[ECX]	
    return true;
}