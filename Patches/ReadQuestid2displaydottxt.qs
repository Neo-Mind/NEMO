function ReadQuestid2displaydottxt() {
	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 83 3D AB AB AB 00 00'	// cmp     <langtype>, 0
				+ ' 0F 85 CB 00 00 00'		// jnz     short <address> <---- Skip 'ReadQuestid2display()'
				+ ' 6A 00'					// push    0
				+ ' 68 AB AB AB 00'			// push    offset <offset> ; 'questID2display.txt'
				+ ' 8D 44 24 30'			// lea     eax, [esp+7Ch+var_4C]
				;
	}
	else {
		var code =
				  ' 83 3D AB AB AB 00 00'	// cmp     <langtype>, 0
				+ ' 75 5E'					// jnz     short <address> <---- Skip 'ReadQuestid2display()'
				+ ' 6A 00'					// push    0
				+ ' 68 AB AB AB 00'			// push    offset <offset> ; 'questID2display.txt'
				+ ' 8D 55 C8'				// lea     edx, [ebp+var_4C]
				;
	}
                
    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	// Skip JNZ and force reading of questid2display.txt
	if (exe.getClientDate() <= 20130605)
		exe.replace(offset+7, ' 90 90 90 90 90 90', PTYPE_HEX);
	else
		exe.replace(offset+7, ' 90 90', PTYPE_HEX);
		
	return true;
}