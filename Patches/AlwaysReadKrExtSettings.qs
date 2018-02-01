function AlwaysReadKrExtSettings() {
	// Step 1a - Find ExternalSettings_kr path string
	var offset = exe.findString("Lua Files\\service_korea\\ExternalSettings_kr", RVA);
	if(offset === -1) {
		return "Failed in step 1a - Cannot find ExternalSettings_kr path string.";
	}
	
	// Step 1b - Find its reference
	var korea_ref_offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
	if(korea_ref_offset === -1) {
		return "Failed in step 1b - String reference is missing.";
	}
	
	// Step 2a - Find server_korea reading code
	var LANGTYPE = GetLangType();
	var SERVERTYPE = GetServerType();
	
	var code =
		" 8B F9"         // MOV EDI, ECX
	+	" A1" + LANGTYPE // MOV EAX, g_serviceType
	+	" 83 F8 12"      // CMP EAX, 12
	;
		
	offset = exe.find(code, PTYPE_HEX, true, "\xAB", korea_ref_offset - 0x50, korea_ref_offset);
	
	if (offset === -1)
		return "Failed in Step 2a - g_serviceType comparison not found";
	
	// offset now points to the JA instruction after CMP EAX, 12
	offset += code.hexlength();
	
	// Step 3a - Force the client to read Lua Files\service_korea\ExternalSettings_kr.lub
	var diff = korea_ref_offset - offset - 2; // -2 for EB xx
	exe.replace(offset, " EB" + diff.packToHex(1), PTYPE_HEX);
	
	return true;
}

//=================================//
// Disable for Unsupported clients //
//=================================//
function AlwaysReadKrExtSettings_() {
	return (exe.findString("Lua Files\\service_korea\\ExternalSettings_kr",RAW) !== -1);
}
