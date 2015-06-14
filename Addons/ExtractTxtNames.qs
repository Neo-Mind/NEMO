//#################################################################
//# Purpose: Extract all .txt filenames used in the loaded client #
//#################################################################

function ExtractTxtNames() {
  
  //Step 1 - Find all strings ending in .txt
  var offset = exe.getROffset(DATA);	
	var offsets = exe.findAll(" 2E 74 78 74 00", PTYPE_HEX, false, " ", offset, offset + exe.getRSize(DATA));
	if (offsets.length === 0)
		throw "Error: No .txt files found";
	
  //Step 2a - Open output file and write the header.
	var fp = new TextFile();
	fp.open(APP_PATH + "/Output/loaded_txt_files_" + exe.getClientDate() + ".txt", "w");
	fp.writeline("Extracted with NEMO");
	fp.writeline("-------------------");
  
	for (var i = 0; i < offsets.length; i++) {
    //Step 2b - Iterate backwards till the start of the string is found for each offset
		offset = offsets[i];
		var end = offset + 3;
		do {
			offset--;
			var code = exe.fetchByte(offset);
		} while (code !== 0 && code !== 0x40);//loop till NULL or @ is reached.
		
    //Step 2c - Extract the string and write to file
		var str = exe.fetch(offset+1,end - offset);
		if (str !== ".txt") //Skip ".txt"
			fp.writeline(str);
	}
  //Step 2d - Close the File
	fp.close();
  
	return "Txt File list has been extracted to Output folder";
}