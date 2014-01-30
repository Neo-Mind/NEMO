function RemoveSerialDisplay() {

	//Step 1 - Check if the client date is valid for this diff
	if (exe.getClientDate() <= 20101116) {
		return "Client Date <= 16-11-2010 , Diff not valid";
	}
		
	//Step 2 - Find offset of pattern 
	var offset = exe.findCode(' 83 C0 AB 3B 41 AB 0F 8C AB 00 00 00 56 57 6A 00', PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return "Failed in Part 2";
	}
		
	//Step 3 - Replace pattern at the offset
	exe.replace(offset, ' 31 C0 83 F8 01 90', PTYPE_HEX);
	
	return true;
}