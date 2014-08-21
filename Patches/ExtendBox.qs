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
	var offsets = exe.findCodes(' C7 40 AB 46 00 00 00', PTYPE_HEX, true, "\xAB");
	if (offsets.length < 4) {
		return "Failed in part 1";
	}
	
	exe.replace(offsets[index]+3, 'EA', PTYPE_HEX);
	return true;
}