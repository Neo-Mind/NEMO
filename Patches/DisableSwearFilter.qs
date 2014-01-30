function DisableSwearFilter() {
  
    // Shinryo: It's better to use a generic approach
    // as some calls to IsBadSentence can not be found.
    // Else it would be a huge mess to ensure that every location
    // is correctly found.
	if (exe.getClientDate() <= 20130605) {
		var code =    ' 8B 44 24 04'	// MOV EAX,DWORD PTR SS:[ESP+4]
				+ ' 50'				// PUSH EAX
				+ ' E8 AB AB FF FF'	// CALL <address>
				+ ' 33 C9'			// XOR ECX,ECX
				+ ' 84 C0'			// TEST AL,AL
				+ ' 0F 94 C1'		// SETE CL
				+ ' 8A C1'			// MOV AL,CL
				+ ' C2 04 00'		// RETN 4
				;

		var offsets = exe.findCodes(code, PTYPE_HEX, true, '\xAB');
		if (!offsets[0]) {
			return 'Failed in part 1';
		}
			
		if(offsets[1] && !offsets[2]) {
			return 'Failed in part 2';
		}

		// The first one is the correct one.
		exe.replace(offsets[0]+17, ' 30 C0', PTYPE_HEX);  // XOR AL,AL
	}
	else {
		var code = 	  ' 8B 45 08'		// MOV EAX,DWORD PTR SS:[EBP+arg_0]
				+ ' 50'				// PUSH EAX
				+ ' E8 AB AB FF FF'	// CALL <address>
				+ ' 33 C9'			// XOR ECX,ECX
				+ ' 84 C0'			// TEST AL,AL
				+ ' 0F 94 C0'		// SETZ AL Set byte if zero (ZF=1)
				+ ' 5D'				// POP EBP
				+ ' C2 04 00'		// RETN 4
				;

		var offsets = exe.findCodes(code, PTYPE_HEX, true, '\xAB');
		if (!offsets[0]) {
			return 'Failed in part 1';
		}
	
		exe.replace(offsets[0]+17, ' 30 C0 C2 04 00', PTYPE_HEX);
	}
    return true;
}