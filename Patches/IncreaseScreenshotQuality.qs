function IncreaseScreenshotQuality() {
	//There are two patterns to look for 
	//"C785 -x 03000000"    // MOV DWORD PTR SS:[EBP-x],3    ; DIBChannels - default value is also 3
	//"C785 -y 02000000"    // MOV DWORD PTR SS:[EBP-y],2    ; DIBColor    - default value is also 2
	//here x and y are dwords
	or
	//"C74424 x 03000000"   // MOV DWORD PTR SS:[ESP+x],3    ; DIBChannels - default value is also 3
	//"C74424 y 02000000"   // MOV DWORD PTR SS:[ESP+y],2    ; DIBColor    - default value is also 2
	//here x and y are signed bytes. 
	//y = x+4 always not that its relevant


	var code =  ' C7 85 AB AB FF FF 03 00 00 00 C7 85 AB AB FF FF 02 00 00 00';
	var type = 1;
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		type = 2;
		code =  ' C7 44 24 AB 03 00 00 00 C7 44 24 AB 02 00 00 00';
		offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	}
	if (offset == -1) {
		return "Failed in part 1";
	}
		
	exe.getUserInput('$uQuality', XTYPE_BYTE, "Number Input", "Enter the new quality factor (0-100)", 50, 0, 100);
	
	if (type == 1) {
		var ebpOffset = exe.fetchDWord(offset+2) + 60;//Point to Quality part of the structure
		exe.replaceDWord(offset+2, ebpOffset);//Change DIBChannels to Quality offset
		exe.replace(offset+6, '$uQuality', PTYPE_STRING); //Set the value
	}
	else {
		var espOffset = exe.fetchByte(offset+3) + 60;//Point to Quality part of the structure
		exe.replace(offset, ' C7 84 24' + espOffset.packToHex(4), PTYPE_HEX);//Change DIBChannels to Quality offset
		exe.replace(offset+7, '$uQuality', PTYPE_STRING); //Set the value
		exe.replace(offset+8, ' 00 00 00 8D 00 8D 6D 00', PTYPE_HEX);//Filling remaining
	}
	return true;
}
