function EnableMonsterInfo() {
	//Step 1 - Find the starting of the function
	var code = 
		  " 89 BE AB AB 00 00"	//MOV DWORD PTR DS:[ESI+2668],EDI ; Case 2723 of switch 
		+ " 57"					//PUSH EDI 
		+ " 89 3D AB AB AB 00"	//MOV DWORD PTR DS:[0CA2008],EDI
		;
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in Part 1";
	}
	
	//Step replace JNE with NOP + JMP at offset + 29 (which is following a comparison with 0x13.)
	exe.replace(offset+29, " 90 E9", PTYPE_HEX);
}