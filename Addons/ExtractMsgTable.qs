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
  
	var fp = new TextFile();
  var refArr = {};
  var engArr = [];
  var str = "";
  
  //Step 2a - Read the reference file to an array - Korean ASCII
	var index = 0;
  var debug, i;
	fp.open(APP_PATH + "/Input/msgStringRef.txt", "r");
	while (!fp.eof()) {
		var line = fp.readline();
    str += line.toHex();
    
    if (line.indexOf('#', line.length - 1) !== -1) {
      refArr[str] = index;
      str = "";
      index++;
    }
    else {
      str += " 0d 0a";
      debug = str;
      i = index;
    }
  }
	fp.close();
  
  str = "";
	fp.open(APP_PATH + "/Input/msgStringEng.txt", "r");
	while (!fp.eof()) {
		var line = fp.readline();
    str += line;
    
    if (line.indexOf('#', line.length - 1) !== -1) {
      engArr.push(str);
      str = "";
    }
    else {
      str += "\n";
    }
  }
  fp.close();
  
  //return i + ":" + debug + " " + engArr[i];
  
  //Step 3 - Loop through the table inside the client - Each Entry
	var done = false;
	var id = 0;
	fp.open(APP_PATH + "/Output/msgstringtable_" + exe.getClientDate() + ".txt", "w");
	while (!done) {
		if (exe.fetchDWord(offset) === id) {
      
      //Step 3a - Get the string for the current id
			var start_offset = exe.Rva2Raw(exe.fetchDWord(offset+4));
			var end_offset   = exe.find("00", PTYPE_HEX, false, "", start_offset);
      
      var msgstr = exe.fetchHex(start_offset, end_offset - start_offset) + " 23";
      
      //Step 3b - Map the Korean string to English
			if (typeof(refArr[msgstr]) !== "undefined" && typeof(engArr[refArr[msgstr]]) !== "undefined")
				fp.writeline(engArr[refArr[msgstr]]);
			else  
      	fp.writeline(msgstr.toAscii() + "#");
      
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