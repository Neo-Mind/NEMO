function SharedHeadPalettesV1() {
	var code = "head%.s_%s_%d.pal\x00"; //effectively same as head_%s_%d.pal
	return SharedHeadPalettes(code);
}

function SharedHeadPalettesV2() {
	var code = "head%.s%.s_%d.pal\x00"; //effectively same as head_%d.pal
	return SharedHeadPalettes(code);	
}

function SharedHeadPalettes(code) {
	//Step 1 - Find Offset of ¸Ó¸®\¸Ó¸®%s%s_%d.pal - Old Format
	var offset = exe.findString("\xB8\xD3\xB8\xAE\x5C\xB8\xD3\xB8\xAE\x25\x73\x25\x73\x5F\x25\x64\x2E\x70\x61\x6C", RAW);
	
	if (offset == -1) {
		offset = exe.findString("\xB8\xD3\xB8\xAE\x5C\xB8\xD3\xB8\xAE\x25\x73\x5F\x25\x73\x5F\x25\x64\x2E\x70\x61\x6C", RAW);
	}
	
	if (offset == -1) {
		return "Failed to Find Matching Pattern";
	}
	
	//Step 2 - Replace String with our code	
	exe.replace(offset, code, PTYPE_STRING);
	return true;
}