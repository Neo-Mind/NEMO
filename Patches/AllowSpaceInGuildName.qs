function AllowSpaceInGuildName() {

	//Find the code
	if (exe.getClientDate() <= 20130605) {
		var offset = exe.findCode(' 6A 20 53 FF D6 83 C4 08', PTYPE_HEX, true, '\xAB');		
	}
	else {
		var offset = exe.findCode(' 6A 20 56 FF D7 83 C4 08', PTYPE_HEX, true, '\xAB');		
	}
	
	if (offset == -1) {
		return "Failed in Part 1";
	}

	//Replace 20 (blank space) with different character
	exe.replace(offset+1, '21', PTYPE_HEX);
	return true;
}