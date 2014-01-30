function LoadCustomQuestLua() {
	var prefix = "lua files\\quest\\";
	var qfuncoff = exe.findString("lua files\\quest\\Quest_function", RVA);
	if (qfuncoff == -1) {
		return "Failed in Part 1";
	}
	
	var offset = exe.findCode( "68" + qfuncoff.packToHex(4), PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Part 2";
	}
	var jmpback = offset + 10;
	
	var jmpfrom = exe.find(" 8B 0D AB AB AB 00", PTYPE_HEX, true, "\xAB", offset - 10, offset);//Need to overwrite to a jump at this location
	if (jmpfrom == -1) {
		return "Failed in Part 3";
	}
	
	var luacode = exe.fetchHex(jmpfrom, jmpback - jmpfrom);//Instructions for loading lua.
	var insize  = jmpback-jmpfrom;//needed later.

	var lualoader = exe.Raw2Rva( jmpback + exe.fetchDWord(offset + 6) );//Function which loads Lua file
	
	var f = new TextFile();
	if (!getInputFile(f, '$inpQuest', 'File Input - Load Custom Quest Lua', 'Enter the Lua list file', APP_PATH)) {
		return "Patch Cancelled";
	}
	
	var files = new Array();
	var size = 0;
	while (!f.eof()) {
		var line = f.readline().trim();
		if (line.charAt(0) !== "/" && line.charAt(1) !== "/") {
			files.push(line);
			size += prefix.length + line.length + 1;
		}
	}
	f.close();
	
	if (files.length > 0) {
		var blocksize = size + (files.length + 1) * insize + 5; //string data + loading instructions + last 5 bytes for jumping back.
		var free = exe.findZeros(blocksize);		
		if (free == -1) {
			return "Failed to find enough free space";
		}
			
		var freeRva = exe.Raw2Rva(free);
		
		var code = prefix + files.join("\x00" + prefix) + "\x00"; //the strings.
		var stroffset = 0;
		var callpos = lualoader - (freeRva + code.length + insize);
		
		code = code.toHex();
		for (var i = 0; i < files.length; i++) {
			code += luacode.replaceAt(-4*3, callpos.packToHex(4)).replaceAt(-9*3, (freeRva + stroffset).packToHex(4));
			stroffset += prefix.length + files[i].length + 1;
			callpos -= insize;
		
		}
		
		code += luacode;
		code = code.replaceAt(-4*3, callpos.packToHex(4));
		code = code.replaceAt(-9*3, qfuncoff.packToHex(4));
		
		code += " E9" + (exe.Raw2Rva(jmpback) - (freeRva + blocksize)).packToHex(4);
		
		exe.insert(free, blocksize, code, PTYPE_HEX);
		exe.replace(jmpfrom, "E9" + (freeRva + size - exe.Raw2Rva(jmpfrom+5)).packToHex(4), PTYPE_HEX);
	}
	return true;
}