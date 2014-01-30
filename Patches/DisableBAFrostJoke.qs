function DisableBAFrostJoke() {
	var offset = exe.findString('english\\BA_frostjoke.txt', RAW);
	if (offset == -1) {
		return 'Failed in Part 1';
	}
	
	exe.replace(offset, '00', PTYPE_HEX);
		
	offset = exe.findString('BA_frostjoke.txt', RAW);
	if (offset == -1) {
		return 'Failed in Part 2';
	}
	
	exe.replace(offset, '00', PTYPE_HEX);
	return true;
}