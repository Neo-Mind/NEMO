function FixCameraAnglesRecomm() {
	return FixCameraAngles(" 00 00 28 42"); //little endian hex of 42.00
}
  
function FixCameraAnglesLess() {
	return FixCameraAngles(" 00 00 EC 41"); //little endian hex of 29.50
}

function FixCameraAnglesFull() {
	return FixCameraAngles(" 00 00 82 42"); //little endian hex of 65.00
}
	
function FixCameraAngles(newvalue) {
  
	// Shinryo:
	// VC9 compiler finally recognized to store
	// float values which are used more than once
	// at an offset and use FLD/FSTP to place
	// those in registers.
	if (exe.getClientDate() <= 20130605)
		var code = ' 74 AB D9 05 AB AB AB 00 D9 5C 24 08';
	else
		var code = ' 74 AB D9 05 AB AB AB 00 D9 5D FC 8B';

	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset == -1) {
        return "Failed in part 1";
    }

	var free = exe.findZeros(4);
	if (free == -1) {
		return "Failed in Part 2: Not enough free space";
	}
	exe.insert(free, 4, newvalue, PTYPE_HEX);	
	exe.replace(offset+4, exe.Raw2Rva(free).packToHex(4), PTYPE_HEX);
	
	return true;
}
