function IncreaseScreenshotQuality() {
	//"C74424 70 03000000"   // MOV     DWORD PTR SS:[ESP+70h],3    ; DIBChannels
    //"C74424 74 02000000"   // MOV     DWORD PTR SS:[ESP+74h],2    ; DIBColor
	
	if (exe.getClientDate() <= 20130605)
		var code =  ' C7 44 24 70 03 00 00 00 C7 44 24 74 02 00 00 00';
	else
		var code =  ' C7 85 A8 B1 FF FF 03 00 00 00 C7 85 AC B1 FF FF 02 00 00 00';
		
    var offset = exe.findCode(code, PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in part 1";
	}
		
	exe.getUserInput('$uQuality', XTYPE_BYTE, "Number Input", "Enter the new quality factor (0-100)", 50, 0, 100);
		
	if (exe.getClientDate() <= 20130605) {
		exe.replace(offset+1, '84', PTYPE_HEX);				// MOV DST operand 8 bit -> 32 bit
		exe.replace(offset+3, 'AC 00', PTYPE_HEX);			// [ESP+70h] -> [ESP+0ACh]
		exe.replace(offset+7, '$uQuality', PTYPE_STRING);	// uQuality
		exe.replace(offset+8, ' 00 00 00 90 90 90 90 90');	// Filling
	}
	else {
		exe.replace(offset+2, '28 B1', PTYPE_HEX);			// [LOCAL.5061] -> [LOCAL.5046]
		exe.replace(offset+6, '$uQuality', PTYPE_STRING);	// uQuality
	}	
	return true;
}