function SkipLicenseScreen() {

	// Find offset of btn_disagree
	var btnoff = exe.findString("btn_disagree", RVA);
		
	// Find the location where it is pushed
	var finish = exe.findCode(' 68 '+ btnoff.packToHex(4), PTYPE_HEX, false);
		
	var start = finish - 0x1A0;//will increase this number if necessary
		
	// Now find the jump table jumper inside that address set.
	var offset = exe.find(' FF 24 85 AB AB AB 00', PTYPE_HEX, true, '\xAB', start, finish);
		
	// Now retrieve the jumptable address from the instruction
	var jmpoffset = exe.Rva2Raw(exe.fetchDWord(offset + 3));//We need the raw address
	
	// Pick up the third entry in jumptable
	var third = exe.fetchHex(jmpoffset+8, 4);
	
	// Now replace first and second with third.
	exe.replace(jmpoffset, third, PTYPE_HEX);
	exe.replace(jmpoffset+4, third, PTYPE_HEX);
	return true;
}