function RestoreLoginWindow() {

	//Step 1 - Find the code where we need to make client call the login window		
	var code =
			  ' 50'						// push    eax
            + ' E8 AB AB AB FF'			// call    sub_54AF30
            + ' 8B C8'					// mov     ecx, eax
            + ' E8 AB AB AB FF'			// call    sub_54B3D0
            + ' 50'						// push    eax
            + ' B9 AB AB AB 00'			// mov     ecx, offset unk_7D9DF0
            + ' E8 AB AB AB FF'			// call    sub_508EB0 
            // replace following with CreateWindow call .
            + ' 80 3D AB AB AB 00 00'	// cmp     T_param, 0
            + ' 74 AB'					// jz      short loc_61FCF5
            + ' C6 AB AB AB AB 00 00'	// mov     T_param, 0
            + ' C7 AB AB 04 00 00 00'	// mov     dword ptr [ebx+0Ch], 4
            // end of patch
            + ' E9 AB AB 00 00'			// jmp     loc_6212E3
			;
			
    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset == -1) {
        return "Failed in part 1";
    }
    
	//Step 2 - Extract the mov ecx, offset instruction from the above.
    var mov = exe.fetchHex(offset+14, 5);
	
	//Step 3 - Find code where the CreateWindow function is called  (that we know of)
	//3.1 - get offset of NUMACCOUNT
	var numaccoff = exe.findString("NUMACCOUNT", RVA);
	if (numaccoff == -1) {
		return "Failed in Part 3.1";
	}
    var numaccount = numaccoff.packToHex(4);
	
	//3.2 - use it to find the code location.
    code =	  ' B9 AB AB AB 00'		// mov     ecx, offset unk_816600
            + ' E8 AB AB AB FF'		// call    CreateWindow
            + ' 6A 00'				// push    0
            + ' 6A 00'				// push    0
            + ' 68' + numaccount	// push    offset aNumaccount ; 'NUMACCOUNT'
            + ' 8B F8'				// mov     edi, eax
            + ' 8B 17'				// mov     edx, [edi]
            + ' 8B 82 AB 00 00 00'	// mov     eax, [edx+90h]
            + ' 68 23 27 00 00'		// push    2723h
			;
			
    var o2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (o2 == -1) {
        return "Failed in part 3.2";
    }
	
	//3.3 - Get the function address & diff from where we are going to call the function
    var calladdr = o2 + 10 + exe.fetchDWord(o2 + 6);
	var call = (calladdr - (offset + 24 + 2 + 5 + 5)).packToHex(4);
	
	//Step 4 - Prepare the replace code to call the login window.
    code =    ' 6A 03'			// push    3
            +   mov				// mov     ecx, offset unk_7D9DF0
            + ' E8' + call	// call    CreateWindow
            + ' 90 90 90 90 90'	// set
            + ' 90 90 90 90 90'	// of
            + ' 90'				// NOPs
			;
			
    exe.replace(offset+24, code, PTYPE_HEX);
	
    //Step 5 - Force the client to send old login packet.
    code =	  ' 80 3D AB AB AB 00 00'	// cmp     g_passwordencrypt, 0
            + ' 0F AB AB AB 00 00'		// jnz     loc_62072D
            + ' A1 AB AB AB 00'			// mov     eax, Langtype
            // Some clients (this far only 2010-10-05a and 2010-10-07a)
            // use cmp eax,ebp instead of test eax,eax
            + ' AB AB'					// test    eax, eax
            + ' 0F AB AB AB 00 00'		// jz      loc_620587 <- remove
            + ' 83 F8 12'				// cmp     eax, 12h
            + ' 0F 84 AB AB 00 00'		// jz      loc_620587 <- remove
			;
            
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
        return "Failed in part 5";
    }
	
	var repl = " 90 90 90 90 90 90";
    exe.replace(offset+20, repl, PTYPE_HEX);
	exe.replace(offset+29, repl, PTYPE_HEX);    
	
    // Step 6 - Care of Shinryo:
    // The client doesn't return to the old login interface when an error
    // occurs. E.g. wrong password, failed to connect, etc.
    // This shall fix this behaviour by aborting the quit operation,
    // set the return mode to 3 (login) and pass 10013 as idle value.
    // It was handy that "this" pointer was passed before. :)
    code =	  ' 8B F1'					// MOV ESI,ECX
            + ' 8B 46 04'				// MOV EAX,DWORD PTR DS:[ESI+4]
            + ' C7 40 14 00 00 00 00'	// MOV DWORD PTR DS:[EAX+14],0
            + ' 83 3D AB AB AB 00 0B'	// CMP DWORD PTR DS:[<address>],0B
            + ' 75 AB'					// JNE SHORT 0054A7D3
            + ' 8B 0D AB AB AB 00'		// MOV ECX,DWORD PTR DS:[<address>]
            + ' 6A 01'					// PUSH 1
            + ' 6A 00'					// PUSH 0
            + ' 6A 00'					// PUSH 0
            + ' 68 AB AB AB 00'			// PUSH <offset>  ; ASCII 'http://www.ragnarok.co.in/index.php'
            + ' 68 AB AB AB 00'			// PUSH <offset>  ; ASCII 'open'
            + ' 51'						// PUSH ECX
            + ' FF 15 AB AB AB 00'		// CALL DWORD PTR DS:[<address>]  ; ShellExecuteA
            
            // Shinryo:
            // The easierst way would be propably to set this value to a random value instead of 0,
            // but the client would dimmer down/flicker and appear again at login interface.
            // I prefer the old way that the client used.
            + ' C7 06 00 00 00 00'		// MOV DWORD PTR DS:[ESI],0 <----- Return to which mode
			;
			
    offset = exe.findCode(" 8B 0D AB AB AB 00 8B 01 8B 50 18", PTYPE_HEX, true, "\xAB");//there are plenty of matches but they are all same
	if (offset == -1) {
		return "Failed in Part 6.1";
	}
	var infix = exe.fetchHex(offset, 11);
	
    var replace =	
            // Save the used registers this time..
			  ' 52'						// PUSH EDX
            + ' 50'						// PUSH EAX
			+ infix						// MOV ECX,DWORD PTR DS:[memaddr] 
										// MOV EAX,DWORD PTR DS:[ECX]
										// MOV EDX,DWORD PTR DS:[EAX+18]
            + ' 6A 00'					// PUSH 0
            + ' 6A 00'					// PUSH 0
            + ' 6A 00'					// PUSH 0
            + ' 6A 00'					// PUSH 0
            + ' 68 1D 27 00 00'			// PUSH 271D
            + ' C7 41 0C 03 00 00 00'	// MOV DWORD PTR DS:[ECX+0C],3
            + ' FF D2'					// CALL EDX
            // ..and restore them again.
            + ' 58'						// POP EAX
            + ' 5A'						// POP EDX
			+ " 90".repeat(19)			// NOPS
			;

	offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset == -1) {
        return "Failed in part 6.2";
    }
    exe.replace(offset, replace, PTYPE_HEX);
	
	// Part 7: New Addon for 2013 clients
	if(exe.getClientDate() >= 20130320) {
		//7.1 - Find offset of "ID"
		offset = exe.findString("ID", RVA);
		if (offset == -1) {
			return "Failed in part 7.1";
		}
		
		//7.2 - Find its reference location
		offset = exe.findCode('6A 01 6A 00 68' + offset.packToHex(4), PTYPE_HEX, false);
		if (offset == -1) {
			return "Failed in part 7.2";
		}
		
		//7.3 - Find the new function call in 2013 clients
		offset = exe.find('50 E8 AB AB AB 00 EB', PTYPE_HEX, true, "\xAB", offset-80, offset);
		if (offset == -1) {
			return "Failed in part 7.3";
		}
		
		//7.4 - Get the called address.
		call = exe.fetchDWord(offset+2) + offset + 6;
		
		//7.5 - Sly devils have made a jump here so search for that.
		offset = exe.find('E9', PTYPE_HEX, false, "", call);
		if (offset == -1) {
			return "Failed in part 7.5";
		}
		//return "REACHED HERE";
		//7.6 - Now get the jump offset
		call = offset + 5 + exe.fetchDWord(offset+1);//rva conversions are not needed since we are referring to same code section.
		
		//7.7 - Search for PUSH 13 followed by a call with DS:[addr]
		offset = exe.find(" 6A 13 FF 15 AB AB AB 00 25 FF 00 00 00", PTYPE_HEX, true, "\xAB", call);
		if (offset == -1) {
			return "Failed in part 7.7";
		}
		
		//7.8 - this part is tricky we are going to replace the call with xor eax,eax & add esp, c for now since i dunno what its purpose was anyways. 13 is a hint
		exe.replace(offset+2, " 31 C0 83 C4 0C 90", PTYPE_HEX);
		
	}
    return true;
}