//######################################################################
//# Purpose: Extract the Hardcoded Msgstringtable in the loaded client #
//#          translated using the reference tables                     #
//######################################################################

function ExtractMsgTable() {
  
  //Step 1a - Find offset of msgStringTable.txt
	var offset = exe.findString("msgStringTable.txt", RVA);
	if (offset === -1)
		throw "Error: msgStringTable.txt missing";
	
  //Step 1b - Find its reference
	offset = exe.findCode(" 68" + offset.packToHex(4) + " 68", PTYPE_HEX, false);
	if (offset === -1)
		throw "Error: msgStringTable.txt reference missing";
	
	//Step 1c - Find the msgstring push after it
  code = 
      " 73 05"                //JAE SHORT addr1 -> after JMP below
    + " 8B AB AB"             //MOV reg32_A, DWORD PTR DS:[reg32_B*4 + reg32_C]
    + " EB AB"                //JMP SHORT addr2
    + " 8B AB AB AB AB AB 00" //MOV reg32_D, DWORD PTR DS:[reg32_B*8 + tblAddr]
    ;  
	var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10, offset+80);
  
	if (offset2 === -1) {//Newest Clients
    code = code.replace(" AB 8B AB", " AB FF AB");//Change MOV reg32_D with PUSH 
	  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10, offset+80);
  }

	if (offset2 === -1) {//Old clients
    code =
      " 33 F6"          //XOR ESI, ESI
    + " AB AB AB AB 00" //MOV reg32_A, tblAddr
    ;
    
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10, offset+30);
    if (offset2 != -1 && (exe.fetchByte(offset2 + 2) & 0xB8) != 0xB8) {//Checking the opcode is within 0xB8-0xBF
      offset2 = -1;
    }
  }

	if (offset2 === -1)
		throw "Error: msgString LUT missing";
	
  //Step 1d - Extract the tblAddr
	offset = exe.Rva2Raw(exe.fetchDWord(offset2 + code.hexlength() - 4)) - 4;
  
  //Step 2a - Read the reference strings from file (Korean original in hex format)
	var fp = new TextFile();
  var refList = [];
  var msgStr = "";
  
	fp.open(APP_PATH + "/Input/msgStringRef.txt", "r");
	while (!fp.eof()) {
    var parts = fp.readline().split('#');
    for (var i = 1; i <= parts.length; i++) {
      msgStr += parts[i - 1].replace(/\\r/g, " 0D").replace(/\\n/g, " 0A");
      if (i < parts.length) {
        refList.push(msgStr.toAscii());
        msgStr = "";
      }
    }
  }
  fp.close();
  
  //Step 2b - Read the translated strings from file (English regular text)
  msgStr = "";
  var index = 0;
  var engMap = {};
  
	fp.open(APP_PATH + "/Input/msgStringEng.txt", "r");
	while (!fp.eof()) {
    var parts = fp.readline().split('#');
    for (var i = 1; i <= parts.length; i++) {
      msgStr += parts[i-1];
      if (i < parts.length) {
        engMap[refList[index]] = msgStr;
        msgStr = "";
        index++;
      }
    }
  }
  fp.close();
  
  //Step 3 - Loop through the table inside the client - Each Entry
	var done = false;
	var id = 0;
  
	fp.open(APP_PATH + "/Output/msgstringtable_" + exe.getClientDate() + ".txt", "w");
	while (!done) {
		if (exe.fetchDWord(offset) === id) {
      
      //Step 3a - Get the string for the current id
			var start_offset = exe.Rva2Raw(exe.fetchDWord(offset+4));
			var end_offset   = exe.find("00", PTYPE_HEX, false, "", start_offset);
      
      msgStr = exe.fetch(start_offset, end_offset - start_offset);
      
      //Step 3b - Map the Korean string to English
      if (engMap[msgStr])
        fp.writeline(engMap[msgStr] + '#');
      else
      	fp.writeline(msgStr + "#");
      
			offset += 8;
			id++;
		}
		else {
			done = true;
		}
	}  
	fp.close();
  
	return "Msgstringtable has been Extracted to Output folder";
}