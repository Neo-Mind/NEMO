function Disable4LetterUserIDLimit() {

	var code =
			  ' E8 AB AB AB FF'	// call    <address>
			+ ' 83 AB 04'		// cmp     eax, 4
			+ ' 0F AB AB AB 00'	// jl      <location>
			;
			
	var offset = exe.findCodes(code, PTYPE_HEX, true, '\xAB');
	if (!offset[0]) { 
		//Check if any value returned
		return 'Failed in part 1';
    }
        
    // 1st = CharacterLimit
    // 2nd = Password
    // 3rd = Unknown
	

	if (!offset[1]) { 
		//Check for count < 2 which also means offset[1] should be valid
		return 'Failed in part 2';
	}
            
    //Password check is done at the second offset in the list.
	//The UserID check comes right after password check, so start searching from this position..
    var tgtoffset = exe.find(' 83 AB 04', PTYPE_HEX, true, '\xAB', offset[1] + 13);  //13 = strlen(code)
	if (tgtoffset == -1) {
		return 'Failed in part 3';
	}

    exe.replace(tgtoffset+2, '00', PTYPE_HEX);
	return true;
}