function ExtractMsgTable() {
	var offset = exe.find(" 3F 41 56 56 4E 49 49 6E 70 75 74 4D 6F 64 65 40", PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Part 1";		
	}
	if (exe.getClientDate() <= 20130605) {
		offset += 0x23;
	}
	else {
		offset += 0x1D3;
	}
	
	var done = false;
	var id = 0;
	var fp = new TextFile();
	fp.open(APP_PATH + "/Output/msgstringtable_" + exe.getClientDate() + ".txt", "w");
	while (!done) {
		if (exe.fetchDWord(offset) == id) {
			var start_offset = exe.Rva2Raw(exe.fetchDWord(offset+4));
			var end_offset   = exe.find(" 00", PTYPE_HEX, false, " ", start_offset);
			var msgstr = exe.fetch(start_offset, end_offset - start_offset);
			msgstr = msgstr.replace(/\r\n/g, "\n");
			fp.writeline(msgstr + "#");
			offset += 0x08;
			id++;
		}
		else {
			done = true;
		}
	}
	fp.close();
	return "Msgstringtable has been Extracted to NEMO's path";
}