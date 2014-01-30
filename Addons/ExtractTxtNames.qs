function ExtractTxtNames() {
	
	var rOffset = exe.getROffset(DATA);
	var rEnd = rOffset + exe.getRSize(DATA);
	
	var offsets = exe.findAll(" 2E 74 78 74 00", PTYPE_HEX, false, " ", rOffset, rEnd);
	if (offsets.length == 0) {
		return "No .txt files found";
	}
	
	var fp = new TextFile();
	fp.open(APP_PATH + "/Output/loaded_txt_files_" + exe.getClientDate() + ".txt", "w");
	fp.writeline("Extracted with NEMO");
	fp.writeline("-------------------");
	for(var i = 0; i < offsets.length; i++) {
		var offset = offsets[i];
		var end = offset + 3;
		var dt;
		do {
			offset--;
			dt = exe.fetchByte(offset);
		} while (dt != 0 && dt != 0x40);
		
		var str = exe.fetch(offset+1,end - offset);
		if (str !== ".txt") {//Skip ".txt"
			fp.writeline(str);
		}
	}
	fp.close();
	return "Txt File list has been extracted to Output folder";
}