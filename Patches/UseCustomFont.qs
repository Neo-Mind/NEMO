function UseCustomFont() {
	// MISSION: Find the g_ServiceType->FontAddr array and
    // update it's values with the offset of the new font.
	
	// Step 1 - Find First Font of the array
	var goffset = exe.findString("Gulim", RVA); //Korean language font which is the first entry
	if (goffset == -1) {
		return "Failed in Step 1.1";
	}
	
	var offset = exe.find(goffset.packToHex(4), PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in Step 1.2";
	}
	
	// Step 2 - Allocate the font in a new area - considering 20 size (right now i am not checking if its already available)
	var free = exe.findZeros(20);
	if (free == -1) {
		return "Failed in Step 2: Not enough free space";
	}
	exe.getUserInput('$newFont', XTYPE_FONT, 'Font input', 'Select the new Font Family', "Arial");
	exe.insert(free, 20, '$newFont', PTYPE_STRING);
	
	// Step 3 - Paste the address until we runt out of entries
	freeRva = exe.Raw2Rva(free).packToHex(4);
	goffset &= 0xFFF00000;
	
	do
	{
		exe.replace(offset, freeRva, PTYPE_HEX);
		offset += 4;
	} while((exe.fetchDWord(offset) & goffset) === goffset);
	// NOTE: this might not be entirely fool-proof, but I do not
    // feel like betting on the fact, that the array always ends
    // with 0x00000081 (CHARSET_HANGUL).
	
	return true;	
}