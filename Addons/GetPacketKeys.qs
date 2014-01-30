function le2be(le) {
	var be = "";
	for (var i = le.length-3; i >= 0; i-=3) {
		be += le.substring(i,i+3);
	}
	return "0x" + be.replace(/ /g,"");	
}

function GetPacketKeys() {
	var key = new Array();
	if (exe.getClientDate() == 20131223) {//Shared Key and code change
		var code =
				  ' B8 AB AB AB AB'	// MOV EAX, Third Key
				+ ' 89 41 08'		// MOV DWORD PTR DS:[ECX+8], EAX -- Second key
				+ ' 89 41 0C'		// MOV DWORD PTR DS:[ECX+0C], EAX -- Third key
				+ ' C7 41 04'		// MOV DWORD PTR DS:[ECX+4], First Key
				;
		var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
		if (offset == -1) {
			return "Unsupported Client - looks like it is corrupted";
		}
		
		key[0] = le2be(exe.fetchHex(offset+14,4));//First  Key
		key[1] = le2be(exe.fetchHex(offset+01,4));//Second Key
		key[2] = key[1];//Third  Key		
	}
	else {
		var code =	 
				  ' 8B 0D AB AB AB 00'	//MOV ecx, DS:[ADDR1] dont care what
				+ ' 68 AB AB AB AB'		//PUSH key1 <- modify these
				+ ' 68 AB AB AB AB'		//PUSH key2 <-
				+ ' 68 AB AB AB AB'		//PUSH key3 <-
				+ ' E8'					//CALL encryptor
				;
			
		var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
		if (offsets.length !== 2) {
			return "Unable to find the keys - Addon needs to be updated to support the client";
		}
		
		key[0] = le2be(exe.fetchHex(offsets[0]+17,4));//First  Key
		key[1] = le2be(exe.fetchHex(offsets[0]+12,4));//Second Key
		key[2] = le2be(exe.fetchHex(offsets[0]+07,4));//Third  Key	
	}
	var fp = new TextFile();
	fp.open(APP_PATH + "/Output/PacketKeys_" + exe.getClientDate() + ".txt", "w");
	
	fp.writeline("Packet Keys : (" + key[0] + " , " + key[1] + " , " + key[2] + " )");
	fp.close();
	return "Packet Keys have been written to Output folder";
}