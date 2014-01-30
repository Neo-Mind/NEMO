function ExtendChatBox() {
	return ExtendBox(3);
}

function ExtendChatRoomBox() {
	return ExtendBox(0);
}

function ExtendPMBox() {
	return ExtendBox(2);
}

function ExtendBox(index) {

	var offsets = exe.findCodes(' C7 40 78 46', PTYPE_HEX, false);	
	
	if (offsets.length !== 4) {
		offsets = exe.findCodes(' C7 40 64 46', PTYPE_HEX, false);
	}
	
	if (offsets.length !== 4) {
		offsets = exe.findCodes(' C7 40 68 46', PTYPE_HEX, false);
	}
	
	if (offsets.length !== 4) {
		return "Failed in part 1";
	}
	
	exe.replace(offsets[index]+3, 'EA', PTYPE_HEX);
	return true;
}