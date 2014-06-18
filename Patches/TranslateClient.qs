// 08.12.2010 - Started to rework some translations (this will be a hell of work) [Shinryo]
// 10.12.2010 - Okay, won't be so much work as I thought.. All of the translations from the
//              big array in DiffGen1 is already set in msgstringtable.txt and don't have to be
//              translated in client again. [Shinryo]

function TranslateClient() {

	var f = new TextFile();
	if (!f.open(APP_PATH + "/patches/TranslateClient.txt") ) {
		return "Failed in Part 1 - Unable to open file";
	}
	
	var find = -1;
	var msg = "";
	var i=0;
	var j=0;
	var failmsgs = new Array();
	while (!f.eof()) {
		var str = f.readline().trim();
		if (str.charAt(0) === "M") {
			msg = str.substring(2).trim();
		}
		else if (str.charAt(0) === "F") {		
			str = str.substring(2).trim();			
			if (str.charAt(0) === "'") {
				str = str.substring(1,str.length-1);
			}
			else {
				str = str.toAscii();
			}
			find = exe.findString(str, RAW);
			if (find == -1) {
				failmsgs.push(msg);
			}
		}
		else if (str.charAt(0) === "R" && find != -1) {
			str = str.substring(2).trim();
			if (str.charAt(0) === "'") {
				exe.replace(find, str.substring(1, str.length-1) + '\x00', PTYPE_STRING);
			}
			else {
				exe.replace(find, str + ' 00', PTYPE_HEX);
			}
			find = -1;
		}
	}
	f.close();
	
	//put up failmsgs in a txt file here - not an error. just warnings
	if (failmsgs.length != 0) {
		var outfile = new TextFile();
		if (outfile.open(APP_PATH + "/FailedTranslations.txt", "w")) {
			for(i=0; i< failmsgs.length; i++) {
				outfile.writeline(failmsgs[i]);
			}
		}
		outfile.close();
	}
	
	var msg = "Translate Taekwon Job";
	var langtype = getLangType();
	switch(langtype) {
		case -4: return "Failed in Part 2.1 :" + msg;
		case -3: return "Failed in Part 2.2 :" + msg;
		case -2: return "Failed in Part 2.3 :" + msg;
		case -1: return "Failed in Part 2.4 :" + msg;
	}
	langtype = langtype.packToHex(4);
	
	code =    ' 83 3D' + langtype + ' 00'	//CMP langtype 0
			+ ' B9 AB AB AB AB'				//MOV ECX, <some offset>
			+ ' 75 59'
			;
	
	offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Part 2.4 :" + msg;
	}
	
	exe.replace(offset+12, "EB", PTYPE_HEX);
	return true;
}