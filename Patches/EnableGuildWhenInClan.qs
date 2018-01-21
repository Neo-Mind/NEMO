//#########################################################################
//# Purpose: Skips the check that requires the player to not be in a clan #
//# Author : Functor                                                      #
//#########################################################################
function EnableGuildWhenInClan() {

    // Step 1 - Find Message ID #2605 reference
	var code =
		" 68 2D 0A 00 00" // PUSH 0x0A2D
		+ " E8 AB AB AB FF" // CALL MsgStr     
		+ " 50"             // PUSH EAX
	;

	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset === -1)
		return "Failed in Step 1 - reference to MsgStr with ID 2605 missing.";
	
	// Replace the jump before message ID push
	exe.replace(offset - 2, " EB", PTYPE_HEX);
	
	// Step 2 - Find the jump followed by push 0x168
	var code = 
		" 0F 85 AB FF FF FF" // JNZ addr
	+   " B8 68 01 00 00"    // MOV EAX, 168
	;
	
	offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x200);
	
	if (offset === -1)
		return "Failed in Step 2 - magic jump not found";
	
	// Replace the jump with NOPs
	exe.replace(offset, " 90".repeat(6), PTYPE_HEX);
	
	return true;
}

// Disable for unsupported clients
function EnableGuildWhenInClan_() {
	return exe.findString("/clanchat", RAW) !== -1;
}
