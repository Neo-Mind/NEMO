// Purpose: To make the client load client plug-in libraries regardless of its sound settings.
// Author: Secret <secret@rathena.org>
// To-do: See if it has any undesirable side effect

function AlwaysLoadClientPlugins() {
	// Step 1a - Find SOUNDMODE
	var offset = exe.findString("SOUNDMODE", RVA);
	if (offset === -1)
		return "Failed in Step 1 - SOUNDMODE not found";
	
	// Step 1b - Find its reference
	offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
	if (offset === -1)
		return "Failed in Step 1 - SOUNDMODE reference not found";
	
	// Step 2a - Fetch soundMode variable location
	var code =
		" 68 AB AB AB AB"	// PUSH soundMode
	+	" 8D 45 AB"			// LEA EAX, [EBP+Type]
	+	" 50"				// PUSH EAX
	+	" 6A 00"			// PUSH 0
	;
	offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x10, offset);
	
	if (offset === -1)
		return "Failed in Step 2 - Argument pushes for call to RegQueryValueEx not found";
	
	var soundMode = exe.fetchHex(offset + 1, 4);
	
	// Step 3a - Find soundMode comparison
	code =
		" 8D 40 04"				// LEA EAX, [EAX+4]
	+	" 49"					// DEC ECX
	+	" 75 AB"				// JNZ _loop
	+	" 39 0D" + soundMode	// CMP soundMode, ECX
	;
	offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	
	if (offset === -1)
		return "Failed in Step 3 - soundMode comparison not found";
	
	offset += code.hexlength();
	
	exe.replace(offset, " 90".repeat(6), PTYPE_HEX);
	
	return true;
}
