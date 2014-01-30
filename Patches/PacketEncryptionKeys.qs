function PacketSecondKeyEncryption() {
	return PacketEncryptionKeys('$secondkey', 12);
}

function PacketFirstKeyEncryption() {
	return PacketEncryptionKeys('$firstkey', 17);
}

function PacketThirdKeyEncryption() {
	return PacketEncryptionKeys('$thirdkey', 7);
}	

function PacketEncryptionKeys(varname, addon) {
	// Search for PACKET_CZ_ENTER it's a little bit at the top position of that string <- not done since the pattern is working.

	if (exe.getClientDate() == 20131223) {
		if (varname === '$secondkey') {
			return "Second Packet Key is not supported for this date (since it is a copy of the third - Change Third one instead)";
		}
		var code = 
				  ' B8 AB AB AB AB'	// MOV EAX, Third Key
				+ ' 89 41 08'		// MOV DWORD PTR DS:[ECX+8], EAX -- Second key
				+ ' 89 41 0C'		// MOV DWORD PTR DS:[ECX+0C], EAX -- Third key
				+ ' C7 41 04'		// MOV DWORD PTR DS:[ECX+4], First Key
				;
		var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
		if (offset == -1) {
			return "Failed in part 1";
		}
		
		exe.getUserInput(varname, XTYPE_HEXSTRING, 'Hex input', 'Enter the new key', "00");
		
		if (varname === '$firstkey') {
			addon = 14;
		} 
		else {
			addon = 1;
		}
		
		exe.replace(offset+addon, varname, PTYPE_STRING);
	} 
	else {
	
		//Step 1: Find the location of the encryption keys.
		var code =	 
				  ' 8B 0D AB AB AB 00'	//MOV ecx, DS:[ADDR1] dont care what
				+ ' 68 AB AB AB AB'		//PUSH key1 <- modify these
				+ ' 68 AB AB AB AB'		//PUSH key2 <-
				+ ' 68 AB AB AB AB'		//PUSH key3 <-
				+ ' E8'					//CALL encryptor
				;
			
		var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
		if (offsets.length !== 2) {
			return "Failed in part 1";
		}
	
		//Step 2: Get the input and replace.
		exe.getUserInput(varname, XTYPE_HEXSTRING, 'Hex input', 'Enter the new key', "00");
		exe.replace(offsets[0]+addon, varname, PTYPE_STRING);
		exe.replace(offsets[1]+addon, varname, PTYPE_STRING);
	}
	return true;
}