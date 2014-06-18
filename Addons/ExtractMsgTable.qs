function ExtractMsgTable() {
	var offset = exe.findString("msgStringTable.txt", RVA);
	if (offset == -1) {
		return "Failed in Part 1";
	}
	
	offset = exe.findCode(" 68" + offset.packToHex(4) + " 68", PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Part 2";
	}
	
	offset = exe.findCode(" 8B 14 F5 AB AB AB 00 52 56", PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Part 3";
	}
	
	offset = exe.Rva2Raw(exe.fetchDWord(offset+3));
	var done = false;
	var id = 0;
	var fp = new TextFile();
	fp.open(APP_PATH + "/Output/msgstringtable_" + exe.getClientDate() + ".txt", "w");
	while (!done) {
		if (exe.fetchDWord(offset-4) == id) {
			var start_offset = exe.Rva2Raw(exe.fetchDWord(offset));
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
	return "Msgstringtable has been Extracted to Output folder";
}