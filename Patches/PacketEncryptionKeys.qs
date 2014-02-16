function PacketFirstKeyEncryption() {
	return PacketEncryptionKeys('$firstkey', 0);
}

function PacketSecondKeyEncryption() {
	return PacketEncryptionKeys('$secondkey', 1);
}

function PacketThirdKeyEncryption() {
	return PacketEncryptionKeys('$thirdkey', 2);
}	

function PacketEncryptionKeys(varname, keyindex) {
	var keyaddrs = fetchPacketKeyAddrs();
	if (typeof(keyaddrs) === "string") {
		return keyaddrs;//Error message
	}
	
	//Duplicate Check
	switch(keyindex) {
		case 0:
			if (keyaddrs[2] == keyaddrs[0]) {
				return "First Packet Key is copy of Third for this date - change Third one instead";
			}
			if (keyaddrs[1] == keyaddrs[0]) {
				return "First Packet Key is copy of Second for this date - change Second one instead";
			}
			break;
		case 1:
			if (keyaddrs[2] == keyaddrs[1]) {
				return "Second Packet Key is copy of Third for this date - change Third one instead";
			}
			break;
	}
	
	var curValue = convertToBE(exe.fetchHex(keyaddrs[keyindex], 4));
	exe.getUserInput(varname, XTYPE_HEXSTRING, 'Hex input', 'Enter the new key', curValue);
	exe.replace(keyaddrs[keyindex], varname, PTYPE_STRING);
	if (keyaddrs.length === 6) {
		exe.replace(keyaddrs[keyindex+3], varname, PTYPE_STRING);
	}
	return true;
}