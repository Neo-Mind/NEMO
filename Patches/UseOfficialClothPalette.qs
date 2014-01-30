function UseOfficialClothPalette() {

	var offset = exe.findString("america", RVA);
	if (offset == -1) {
		return "Failed in Part 1";
	}
	
	offset = exe.findCode('68' + offset.packToHex(4), PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Part 2";
	}
	
	offset = exe.find('C7 05 AB AB AB AB 01 00 00 00', PTYPE_HEX, true, "\xAB", offset + 5);
	if (offset == -1) {
		return "Failed in Part 3";
	}
	
	var langtype = exe.fetchHex(offset+2, 4);
	
	var code =	  " 83 3D" + langtype + " 00"	//CMP DWORD PTR DS:[g_servicetype], 0
				+ " 0F 85 AB AB 00 00"			//JNE nonkorean
				+ " 8B"							//MOV reg32, DWORD PTR DS:[reg32b+offset]
				;
	offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Part 4";
	}
	
	exe.replace(offset+7, " 90 90 90 90 90 90", PTYPE_HEX);
}