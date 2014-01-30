function OnlyFirstLoginBackground() {

	var first  = 'T_' + "\xB9\xE8\xB0\xE6" + '%d-%d.bmp' + "\x00\x00";
	var second = 'T2_' + "\xB9\xE8\xB0\xE6" + '%d-%d.bmp' + "\x00";
	return OnlySelectedBackground(second, first);
}

function OnlySecondLoginBackground() {
	var first  = 'T_' + "\xB9\xE8\xB0\xE6" + '%d-%d.bmp' + "\x00\x00";
	var second = 'T2_' + "\xB9\xE8\xB0\xE6" + '%d-%d.bmp' + "\x00";
	return OnlySelectedBackground(first, second);
}

function OnlySelectedBackground(str1, str2) {

	var prefix = "\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\x5C";
	
	//Step 1 - Find the string
	var offset = exe.findString(prefix + str1, RAW);
	if (offset == -1) {
		return "Failed to find matching data : Part 1";
	}
	
	//Step 2 - Replace with the other 
	exe.replace(offset+15, str2, PTYPE_STRING);
	return true;
}