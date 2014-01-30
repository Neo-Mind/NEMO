function EnableMailBox() {
	if (exe.getClientDate() < 20130320) {
		return "Only meant for 2013 Clients";
	}

	//Step 1 - First fix the Short Jumps
	var common  =   " 74 AB"	//JMP Short for LT=0 (prev statement is either TEST EAX, EAX or CMP EAX, r32 => both instructions use 2 bytes)
				  +	" 83 F8 08" //CMP EAX,08
				  + " 74 AB"	//JMP Short for LT=8
				  + " 83 F8 09" //CMP EAX,09
				  + " 74 AB"	//JMP Short for LT=9
				  ;
				  
	var pat1 = " 8B 8E AB 00 00 00"	//MOV ECX, DWORD PTR DS:[ESI+const]
	
	var offsets = exe.findCodes(common+pat1, PTYPE_HEX, true, "\xAB");
	if (offsets.length != 3) {
		return "Failed in Part 1";
	}
	
	for (i=0; i<offsets.length; i++) {
		exe.replace(offsets[i]-2, " EB 0C", PTYPE_HEX);
	}

	var pat2 = " BB 01 00 00 00"	//MOV EBX,1
		
	var offset = exe.findCode(common+pat2, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Part 2";
	}
	
	exe.replace(offset-2, " EB 0C", PTYPE_HEX);
	
	//Step 2 - Fix the long jumps
	
	common =  " 0F 84 AB AB 00 00"	//JMP Long for LT=0 (prev statement is either TEST EAX, EAX or CMP EAX, r32 => both instructions use 2 bytes)
			+ " 83 F8 08"			//CMP EAX,08
			+ " 0F 84 AB AB 00 00"  //JMP Long for LT=8
			+ " 83 F8 09"           //CMP EAX,09
			+ " 0F 84 AB AB 00 00"  //JMP Long for LT=9
			;
	
	pat1 = " A1 AB AB AB 00 AB AB" //MOV EAX, DS:[g_Servicetype]; EAX test (g_servicetype is overriden by langtype meh )
	
	offsets = exe.findCodes(pat1+common, PTYPE_HEX, true, "\xAB");
	if (offsets.length < 3 || offsets.length > 4) {
		return "Failed in Part 3";
	}
	
	for (i=0; i<offsets.length; i++) {
		exe.replace(offsets[i]+5, " EB 18", PTYPE_HEX);
	}
	
	if (offsets.length == 3) {
		var pat2 = " 6A 23"	//PUSH 23
		
		var offset = exe.findCode(common+pat2, PTYPE_HEX, true, "\xAB");		
		if (offset == -1) {
			return "Failed in Part 4";
		}
		
		exe.replace(offset-2, " EB 18", PTYPE_HEX);
	}
	return true
}