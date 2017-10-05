function AlwaysReadKrExtSettings() {
	// Step 1a - Find ExternalSettings_kr path string
	var offset = exe.findString("Lua Files\\service_korea\\ExternalSettings_kr", RVA);
	if(offset === -1) {
		return "Failed in step 1a - Cannot find ExternalSettings_kr path string.";
	}
	
	// Step 1b - Find its reference
	offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
	if(offset === -1) {
		return "Failed in step 1b - String reference is missing.";
	}
	
	// Step 1c - Find switch jump above
	var code = " FF 24 AB AB AB AB 00"; // JMP T[EAX * 4]
	offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x30, offset);
	if(offset === -1) {
		return "Failed in step 1c - Switch jump is missing.";
	}
	
	// Step 2 - Replace JMP with NOPs
	var repl = " 90".repeat(code.hexlength()); // replace with NOPs
	exe.replace(offset, repl, PTYPE_HEX);
	
	return true;
}

//=================================//
// Disable for Unsupported clients //
//=================================//
function AlwaysReadKrExtSettings_() {
	return (exe.findString("Lua Files\\service_korea\\ExternalSettings_kr",RAW) !== -1);
}
