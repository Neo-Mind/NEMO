function GetPacketKeys() {
	var key = fetchPacketKeys();
	if (typeof(key) === "string") {
		throw key;
	}
	else {
		key[0] = "0x" + convertToBE(key[0].packToHex(4));
		key[1] = "0x" + convertToBE(key[1].packToHex(4));
		key[2] = "0x" + convertToBE(key[2].packToHex(4));
		
		var fp = new TextFile();
		fp.open(APP_PATH + "/Output/PacketKeys_" + exe.getClientDate() + ".txt", "w");
		fp.writeline("Packet Keys : (" + key[0] + " , " + key[1] + " , " + key[2] + ")");
		fp.close();
		return "Packet Keys have been written to Output folder";
	}
}