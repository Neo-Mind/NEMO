function getInputFile(f, varname, title, prompt, fpath) {
	var inp = "";
	while (inp === "") {
		inp = exe.getUserInput(varname, XTYPE_FILE, title, prompt, fpath);		
		if (inp === "") {
			return false;
		}
		
		f.open(inp);
		if (f.eof()) {
			f.close();
			inp = "";
		}
	}
	return true;
}

function fetchPacketKeys() {
	return _fetchPacketKeyInfo(1);
}

function fetchPacketKeyAddrs() {
	return _fetchPacketKeyInfo(2);
}

function _fetchPacketKeyInfo(retType) {
	//Step 1 - Look for PACKET_CZ_ENTER push
	var offset = exe.findString("PACKET_CZ_ENTER", RVA);
	if (offset == -1) {
		return "Failed in Step 1";
	}
	
	offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Step 2";
	}
	
	var returnValue = new Array();
	//Previous Form - Keys are pushed along with call to encryptor.
	var code =	  ' 8B 0D AB AB AB 00'	//MOV ecx, DS:[ADDR1] dont care what
				+ ' 68 AB AB AB AB'		//PUSH key3 <- modify these
				+ ' 68 AB AB AB AB'		//PUSH key2 <-
				+ ' 68 AB AB AB AB'		//PUSH key1 <-
				+ ' E8'					//CALL encryptor
				;
	var coffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x100, offset);
	if (coffset !== -1) {
		
		switch(retType) {
			case 1:				
				returnValue[0] = exe.fetchDWord(coffset+17);
				returnValue[1] = exe.fetchDWord(coffset+12);
				returnValue[2] = exe.fetchDWord(coffset+07);
				break;
			case 2:
				//We need two locations for retType = 2
				code = exe.fetchHex(coffset, code.hexlength());//replacing all the wildcards
				coffset = exe.findAll(code, PTYPE_HEX, false);
				
				if (coffset.length != 2) {
					return "Failed in Step 3 - Triple push not present in 2 locations";
				}
				
				returnValue[0] = coffset[0]+17;
				returnValue[1] = coffset[0]+12;
				returnValue[2] = coffset[0]+07;
				
				returnValue[3] = coffset[1]+17;
				returnValue[4] = coffset[1]+12;
				returnValue[5] = coffset[1]+07;
				break;
		}		
		return returnValue;
	}
	
	//New Function is used which means we will have to go inside it.
	code =	  ' 8B 0D AB AB AB 00'	//MOV ecx, DS:[ADDR1] dont care what
			+ ' 6A 01'				//PUSH 1
			+ ' E8'					//CALL combofunction - encryptor and other related functions combined.
			;
	coffset = exe.find(code, PTYPE_HEX, true, '\xAB', offset-0x100, offset);
	if (coffset == -1) {
		return "Failed in Step 3 - Unable to find encryptor";
	}
		
	offset = coffset + 13 + exe.fetchDWord(coffset+9);
	//Now again there are 2 varieties (shared key for december clients and unshared key for jan ones =_=)
	var part1 =	  ' 83 F8 01'	//CMP EAX,1
				+ ' 75 AB'		//JNE short
	
	code = 	part1
			+ ' C7 41 AB AB AB AB AB'	//MOV DWORD PTR DS:[ECX+4], <First Key>
			+ ' C7 41 AB AB AB AB AB'	//MOV DWORD PTR DS:[ECX+8],	<Second Key>
			+ ' C7 41 AB AB AB AB AB'	//MOV DWORD PTR DS:[ECX+0C],<Third Key> 
			;//now ofcourse the order could change so we take preparations :D
	
	coffset = exe.find(code, PTYPE_HEX, true, '\xAB', offset, offset+0x50);
	if (coffset != -1) {
		switch(retType) {
			case 1:				
				returnValue[(exe.fetchByte(coffset+07)/4)-1] = exe.fetchDWord(coffset+08);
				returnValue[(exe.fetchByte(coffset+14)/4)-1] = exe.fetchDWord(coffset+15);
				returnValue[(exe.fetchByte(coffset+21)/4)-1] = exe.fetchDWord(coffset+22);
				break;
			case 2:
				returnValue[(exe.fetchByte(coffset+07)/4)-1] = coffset+08;
				returnValue[(exe.fetchByte(coffset+14)/4)-1] = coffset+15;
				returnValue[(exe.fetchByte(coffset+21)/4)-1] = coffset+22;
				break;
		}
		return returnValue;
	}
	
	//Decemeber clients ugh
	code = 	part1
			+ ' B8 AB AB AB AB'	// MOV EAX, Third Key
			+ ' 89 41 AB'		// MOV DWORD PTR DS:[ECX+8], EAX -- Second key
			+ ' 89 41 AB'		// MOV DWORD PTR DS:[ECX+0C], EAX -- Third key
			+ ' C7 41 AB'		// MOV DWORD PTR DS:[ECX+4], First Key/
			;//like before they could try switching the orders with a shared key again.
			
	coffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x50);
	if (coffset != -1) {
		switch(retType) {
			case 1:				
				returnValue[(exe.fetchByte(coffset+12)/4)-1] = exe.fetchDWord(coffset+06);
				returnValue[(exe.fetchByte(coffset+15)/4)-1] = exe.fetchDWord(coffset+06);
				returnValue[(exe.fetchByte(coffset+18)/4)-1] = exe.fetchDWord(coffset+19);
				break;
			case 2:
				returnValue[(exe.fetchByte(coffset+12)/4)-1] = coffset+06;
				returnValue[(exe.fetchByte(coffset+15)/4)-1] = coffset+06;
				returnValue[(exe.fetchByte(coffset+18)/4)-1] = coffset+19;
				break;
		}
		return returnValue;
	}
	
	//All known options exhausted
	return "Failed in Step 4 - packet key assignment has been changed";
}

function convertToBE(le) {//le is in PTYPE_HEX format but output wont have spaces
	var be = "";
	for (var i = le.length-3; i >= 0; i-=3) {
		be += le.substr(i,3);
	}
	return be.replace(/ /g,"");	
}