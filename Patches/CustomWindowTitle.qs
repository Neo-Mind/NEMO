function CustomWindowTitle() {
	var newstr = 'http://ro.hangame.com/login/loginstep.asp?prevURL=/NHNCommon/NHN/Memberjoin.asp';
	
	var strOff = exe.findString(newstr, RAW);
    if (strOff == -1) {
		return 'Failed in part 1';
	}
	
	var title = exe.getUserInput('$customWindowTitle', XTYPE_STRING, 'String Input - maximum 60 characters', 'Enter the new window Title', 'Ragnarok', 1, 60);
	if (title.trim() === "Ragnarok") {//Skip if no change
		return true;
	}
	exe.replace(strOff, '$customWindowTitle', PTYPE_STRING);
	
	strOff = exe.Raw2Rva(strOff);	
	
	var code = exe.findString("Ragnarok", RVA).packToHex(4);	
    var offset = exe.findCode(code, PTYPE_HEX, false);
	if( offset == -1) {
		return 'Failed in part 2';
	}
	
    exe.replaceDWord(offset, strOff);
	return true;
}