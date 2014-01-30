function IncreaseViewID() {
	
	//Step 1 - Find ReqAccName
	var reqacc = exe.findString("ReqAccName", RVA).packToHex(4);
	
	//Step 2 - Find where it is pushed - there is only 1 place
	var reqpush = exe.findCode('68' + reqacc, PTYPE_HEX, true, "\xAB");
		
	//Step 3 - Get Little Endian byte sequence of old value and get new value from user.	
	if (exe.isThemida) {
		var oldValue = " D0 07"; //2000 packed up
	}
	else {
		var oldValue = " E8 03"; //1000 packed up.
	}
		
	exe.getUserInput('$newValue', XTYPE_DWORD, 'Number input', 'Enter the new Max Headgear View ID', 3000, 2000, 32000);//32000 could prove fatal.
	
	//Step 4 - Replace old value in the cmp/push/mov instructions before and after the push - lets start with a relative limit of -100 from the push.
	if (exe.getClientDate() > 20130605) {
		var count = 3; //there are two cmp and 1 mov instruction
	}
	else {
		var count = 2; //there is 1 push and 1 cmp instruction
	}
		
	var offset = reqpush - 400;	
	for (i = 1; i <= count; i++) {
		offset = exe.find(oldValue, PTYPE_HEX, false, "\xAB", offset);
		if (offset == -1)
		{
			return "Failed at Part 4: iteration " + i;
		}
		exe.replace(offset, '$newValue', PTYPE_STRING);
		offset += 4;
	}
	return true;
}