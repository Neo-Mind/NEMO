//####################################################################
//# Purpose: Extract Packet Keys from loaded client and dump to file #
//####################################################################

function GetPacketKeys() {
  //Step 1a - Get the Packet Key Info using fetchPacketKeyInfo function
  var info = FetchPacketKeyInfo();
  
  if (typeof(info) === "string")
    throw info;
  
  if (info.type === -1)
    throw "Failed to find any Patterns";
  
  //Step 1b - Convert them to BE format.
  var keys = [];
  keys[0] = "0x" + info.keys[0].toBE(); 
  keys[1] = "0x" + info.keys[1].toBE(); 
  keys[2] = "0x" + info.keys[2].toBE();
  
  //Step 2 - Write them to file.
	var fp = new TextFile();
	fp.open(APP_PATH + "/Output/PacketKeys_" + exe.getClientDate() + ".txt", "w");
	fp.writeline("Packet Keys : (" + keys.join(",") + ")");
	fp.close();

	return "Packet Keys have been written to Output folder";
}