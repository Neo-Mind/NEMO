function EnableFlagEmotes() {
	var code =	  " 05 2E FF FF FF" // ADD EAX,-D2
				+ " 83 F8 08"		// CMP EAX, 08
				;
	var offset = exe.findCode(code, PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Step 1";
	}
	
	var f = new TextFile();
	if (!getInputFile(f, '$inpFlag', 'File Input - Enable Flag Emoticons', 'Enter the Flags list file', APP_PATH + "/Input/flags.txt")) {
		return "Patch Cancelled";
	}
	
	var consts = new Array();
	while (!f.eof()) {
		var str = f.readline().trim();
		if (str.charAt(1) === "=") {
			var key = parseInt(str.charAt(0));
			if (!isNaN(key)) {
				var value = parseInt(str.substr(2));//full length is retrieved.
				if (!isNaN(value)) consts[key] = value;
			}
		}
	}
	f.close();	
	
	var code  =	  " A1 AB AB AB 00" // MOV EAX, DS:[g_servicetype]
				+ " 85 C0"			// TEST EAX, EAX
				;
				
	var code2 =   " 8B 01"   	//MOV EAX,DWORD PTR DS:[ECX]
				+ " 8B 50 18"	//MOV EDX,DWORD PTR DS:[EAX+18]
				+ " 6A 00"   	//PUSH 0
				+ " 6A 00"   	//PUSH 0
				+ " 6A 00"   	//PUSH 0
				+ " 6A AB"   	//PUSH emoteConstant
				+ " 6A 1F"   	//PUSH 1F
				+ " FF D2"   	//CALL EDX
				;

	for (var i = 1; i < 10; i++) {
		offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+1);
		if (offset == -1) {
			return "Failed in Step 2.1." + i;
		}
		
		var jmpoffset = exe.find(code2, PTYPE_HEX, true, "\xAB", offset+7);
		if (jmpoffset == -1) {
			return "Failed in Step 2.2." + i;
		}
		
		if (consts[i]) {
			exe.replace(offset+7, " EB" + ( (jmpoffset) - (offset+9) ).packToHex(1), PTYPE_HEX);
			exe.replace(jmpoffset+12, consts[i].toString(16), PTYPE_HEX);
			
		}
		else {
			exe.replace(offset+7, " EB" + ( (jmpoffset+17) - (offset+9) ).packToHex(1), PTYPE_HEX);
		}
		offset = jmpoffset+12;	
	}
}