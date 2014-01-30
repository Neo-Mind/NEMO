function Disable4LetterUserCharacterLimit() {

	var code = 
			  ' E8 AB AB AB FF'	// call    <address>
			+ ' 83 AB 04'		// cmp     eax, 4
			+ ' 0F AB AB AB 00'	// jl      <location>
			;
			
	var offset = exe.findCodes(code, PTYPE_HEX, true, '\xAB');
	if (!offset[0]) { 
		//Check if any value returned
		return "Failed in part 1";
    }
        
    // 1st = CharacterLimit
    // 2nd = Password
    // 3rd = Unknown
	
    if (!offset[1]) { 
		//Check for count < 2 which also means offset[1] should be valid
		return "Failed in part 2";
	}
        
    exe.replace(offset[0]+7, '00', PTYPE_HEX);
	return true;
}