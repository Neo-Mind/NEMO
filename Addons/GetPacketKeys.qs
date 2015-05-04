function GetPacketKeys() {
  ////////////////////////////////////////////////////////////////////
  // GOAL: Extract PacketKeys from loaded client and write to file. //
  ////////////////////////////////////////////////////////////////////
  
  //Step 1a - Get the Packet Keys using utility function. For clients with latest themida unpacking, this wont work
	var keys = fetchPacketKeys();
	if (typeof(keys) === "string") {
		throw keys;
	}
	else {
		keys[0] = "0x" + convertToBE(keys[0].packToHex(4));
		keys[1] = "0x" + convertToBE(keys[1].packToHex(4));
		keys[2] = "0x" + convertToBE(keys[2].packToHex(4));
		
    //Step 1b - Write them to file.
		var fp = new TextFile();
		fp.open(APP_PATH + "/Output/PacketKeys_" + exe.getClientDate() + ".txt", "w");
		fp.writeline("Packet Keys : (" + key[0] + " , " + key[1] + " , " + key[2] + ")");
		fp.close();
    
		return "Packet Keys have been written to Output folder";
	}
}