function ExtractMsgTable() {
  //////////////////////////////////////////////////////////////////
  // GOAL: Extract the Hardcoded Msgstringtable inside the client //
  //       translated using the reference tables                  //
  //////////////////////////////////////////////////////////////////
  
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
	if (offset2 === -1) {
    code = code.replace(" AB 8B AB", " AB FF AB");//Change MOV reg32_D with PUSH 
	  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10, offset+80);
  }
	if (offset2 === -1) 
		throw "Error: msgString LUT missing";
	
  //Step 1d - Extract the tblAddr
	offset = exe.Rva2Raw(exe.fetchDWord(offset + code.hexlength()-4)) - 4;
  
  //Step 2a - Read the reference file to an array - Korean in Hex
	var fp = new TextFile();
	var hArr = new Object();

	var index = 0;
	fp.open(APP_PATH + "/Input/msgStringHex.txt", "r");
	while(!fp.eof()) {
		var line = fp.readline().trim();
		hArr[line] = index;
		index++;
	}
	fp.close();
	
  //Step 2b - Read the reference file to an array - English translations
	var engArr = [];
	fp.open(APP_PATH + "/Input/msgStringEng.txt", "r");
	while(!fp.eof()) {
		engArr.push(fp.readline());
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
      
      var msgstr = exe.fetchHex(start_offset, end_offset - start_offset);
			msgstr = msgstr.replace(/ 0d 0a/g, " 5c 6e").trim();
			
      //Step 3b - Map the Korean string to English
      if (typeof(hArr[msgstr]) !== "undefined" && typeof(engArr[hArr[msgstr]]) !== "undefined")
				fp.writeline(engArr[hArr[msgstr]]);
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