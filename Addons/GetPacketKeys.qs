//####################################################################
//# Purpose: Extract Packet Keys from loaded client and dump to file #
//####################################################################

function GetPacketKeys() {
  //Step 1a - Get the Packet Key Info using fetchPacketKeyInfo function
  var keyInfo = fetchPacketKeyInfo();
  
  if (typeof(keyInfo) === "string")
    throw keyInfo;
  
  if (keyInfo[1] === 0 && keyInfo[2] === 0 && keyInfo[3] === 0)
    throw "Failed to find any Patterns";
  
  //Step 1b - Convert them to BE format.
  var keys = [];
  keys[0] = "0x" + keyInfo[1].toBE(); 
  keys[1] = "0x" + keyInfo[2].toBE(); 
  keys[2] = "0x" + keyInfo[3].toBE(); 
  
  //Step 2 - Write them to file.
	var fp = new TextFile();
	fp.open(APP_PATH + "/Output/PacketKeys_" + exe.getClientDate() + ".txt", "w");
	fp.writeline("Packet Keys : (" + keys.join(",") + ")");
	fp.close();
    
	return "Packet Keys have been written to Output folder";
}