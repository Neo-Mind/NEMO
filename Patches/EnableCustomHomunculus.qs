function EnableCustomHomunculus() {
	var max = 7000;
	//Step 1 - Find location where Homunculus is currently read hardcoded
	var code =
			  ' 47'					//INC EDI
			+ ' 83 C4 2C'			//ADD ESP,2C
			+ ' 81 FF AB AB 00 00'	//CMP EDI, Max Value
			+ ' 7C AB'				//JL Short loop
			+ ' 8B'					//start of MOV E*X
			;
			
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Step 1";
	}
	
	var insLoc = offset + 12;
		
	//Step 2 - Find jump location to jmp to after reading from lua (to skip hardcoded reading)
	code = " 8B 8E AB AB 00 00 8B 96 AB AB 00 00";
	offset = exe.find(code, PTYPE_HEX, true, "\xAB", insLoc);
	if (offset == -1) {
		return "Failed in Step 2";
	}
	
	var jmpLoc = offset;
	
	//Step 3 - Replace with NOP before jmp location
	exe.replace(jmpLoc-6, " 90 90 90 90 90 90", PTYPE_HEX);
	
	//Step 4 - Get the current lua caller code for Job Name we can use same for homunculus
	//4.1 - Find offset of ReqJobName
	offset = exe.findString("ReqJobName", RVA);
	if (offset == -1) {
		return "Failed in Step 4.1";
	}
	
	//4.2 - Find the last place referenced
	var offsets = exe.findCodes("68" + offset.packToHex(4), PTYPE_HEX, false);
	if (!offsets[0]) {
		return "Failed in Step 4.2";
	}
	
	offset = offsets[offsets.length-1];
	
	//Step 5 - Get the current JobName code and make modifications to call locations.
	if(exe.getClientDate() > 20130605) {
		code = exe.fetchHex(offset - 36, 83);
		
		var fn = exe.fetchDWord(offset - 36 + (83 - 38) ) - 88;
		code =  code.replaceAt(3*(83 - 38), fn.packToHex(4));
		
		fn = exe.fetchDWord(offset - 36 + (83 - 16) ) - 88;
		code =  code.replaceAt(3*(83 - 16), fn.packToHex(4));
		
		jmpLoc -= 9;
	}
	else {
		code = exe.fetchHex(offset - 25, 68);
		
		var fn = exe.fetchDWord(offset - 25 + (68 - 16) ) - 73;
		code =  code.replaceAt(3*(68 - 16), fn.packToHex(4));
	}
	
	code = code.replaceAt(-6*3, (max+1).packToHex(4));
	
	//Step 6 - Complete lua caller code		
	code =    " BF 71 17 00 00"			//MOV EDI, 1771
			+ code
			;
	
	code =	  code
			+ " E9" + (jmpLoc - (insLoc + code.hexlength() + 5)).packToHex(4);
			;
	
	
	//Step 6 - Replace with lua caller
	exe.replace(insLoc, code, PTYPE_HEX);
	
	//Step 7 - Find the homun limiter code for right click menu.
	code =    " 05 8F E8 FF FF"	//SUB EAX, 1771
			+ " B9 33 00 00 00" //MOV ECX, 33
			;
	
	offset = exe.findCode(code, PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Step 7";
	}
	
	//Step 8 - Replace the 33 with our maximum difference
	exe.replace(offset+6, (max - 6001).packToHex(4), PTYPE_HEX);	
	return true;
}