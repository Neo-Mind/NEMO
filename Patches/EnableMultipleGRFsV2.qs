// Enable Multiple GRF files
// adds support to load GRF files from a list inside DATA.INI
//
function EnableMultipleGRFsV2() {
    // Locate call to grf loading function.
	var grf = exe.findString("data.grf", RVA).packToHex(4);
	
	var code = 	  ' 68' + grf			// push    offset aData_grf ; 'data.grf'
				+ ' B9 AB AB AB 00'		// mov     ecx, offset unk_86ABBC
				;
	
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	// Save "this" pointer and address of AddPak.
	var setECX = exe.fetchHex(offset+5, 5);
	    
	code =	  ' E8 AB AB AB AB'		//call CFileMgr::AddPak()
			+ ' 8B AB AB AB AB 00'	//mov reg32, DWORD PTR DS:[addr1]
			+ ' A1 AB AB AB 00'		//MOV EAX, DWORD PTR DS:[addr2]
			;
			
	var fnoffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10);
	if (fnoffset == -1) {
		return "Failed in part 2";
	}
	
	var AddPak = exe.Raw2Rva(fnoffset + 5) + exe.fetchDWord(fnoffset + 1);

	var f = new TextFile();
	if (!getInputFile(f, '$inpMultGRF', 'File Input - Enable Multiple GRF', 'Enter your INI file', APP_PATH) ) {
		return "Patch Cancelled";
	}
	
	var temp = new Array();
	
	while (!f.eof()) {
		var str = f.readline().trim();
		if (str.charAt(1) === "=") {
			var key = parseInt(str.charAt(0));
			if (!isNaN(key)) {
				temp[key] = str.substr(2);//full length is retrieved.
			}
		}
	}
	
	f.close();
	
	var grfs = new Array();
	
	for (var i = 0; i < 10; i++) {
		if (temp[i])
			grfs.push(temp[i]);
	}
	if (!grfs[0]) {
		grfs.push("data.grf");
	}
	
	var strcode = grfs.join("\x00") + "\x00";	
	var size = strcode.length + grfs.length * 15 + 2;	

	var free = exe.findZeros(size);	
	if (free === -1) {
		return "Unable to find enough free space";
	}
	
	var freeRva = exe.Raw2Rva(free);
	var o2 = freeRva + grfs.length * 15 + 2;
	var fn = AddPak - (freeRva + 15*grfs.length);
	
	var code = "";
	
	for (var j = 0; grfs[j]; j++) {
		code =	  " 68" + o2.packToHex(4)	//PUSH grf
				+ setECX					//MOV ECX, g_fileMgr
				+ " E8" + fn.packToHex(4) 	//CALL CFileMgr::AddPak
				+ code
				;
				
		o2 += grfs[j].length + 1; //Extra 1 for NULL byte
		fn += 15;
	}
	code += " C3 00";//RETN and 1 extra NULL
	code += strcode.toHex();
	
	// Create a call to the free space that was found before.
	exe.replace(offset, ' B9', PTYPE_HEX);//Little trick to avoid changing 10 bytes - apparently the push gets nullified in the original
	exe.replaceDWord(fnoffset + 1, freeRVA - exe.Raw2Rva(fnoffset + 5));
	
	// Finally, insert everything.
    exe.insert(free, size, code, PTYPE_HEX);	
	return true;
}