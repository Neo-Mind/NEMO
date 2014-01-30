function SkipResurrectionButtons() {

	// Simply change the 'Token of Siegfried' ID to 0xFFFF - way easier.
	var offset = exe.findCode(' 68 C5 1D 00 00', PTYPE_HEX, false);
	if (offset == -1) {
		return 'Failed in part 1';
	}
    
	exe.replace(offset+1, ' FF FF', PTYPE_HEX);
	return true;
}
