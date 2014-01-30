function RemoveChatLimit() {
	return ChatLimit(0);
}

function AllowChatFlood() {
	return ChatLimit(1);
}

function ChatLimit(option) {
	//Search for the pattern
	if (exe.getClientDate() <= 20130605) {
	    var code = 
				  ' 83 3D AB AB AB AB 0A'
				+ ' 74 AB'
				+ ' 83 7C 24 04 02'
				+ ' 7C 47'
				+ ' 6A 00';
				
		var type = 0;				
	}
	else {
		var code = 
				  ' 83 3D AB AB AB AB 0A'
	            + ' 74 AB'
	            + ' 83 7D 08 02'
	            + ' 7C 49'
	            + ' 6A 00';
		var type = 1;
	}
	
	var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return "Failed in Step 1";
	}
	
	if (option == 1) {
		//Get new value from user
		exe.getUserInput('$allowChatFlood', XTYPE_BYTE, 'Number Input', 'Enter new chat limit (0-127, default is 3):', 3, 0, 127);	
		
		//Do the replacement of 2 with new value
		if (type == 0)	{
			exe.replace(offset+13, '$allowChatFlood', PTYPE_STRING);
		}
		else {
			exe.replace(offset+12, '$allowChatFlood', PTYPE_STRING);
		}
	}
	else {
		//Do the replacement of JL with JMP
		if (type == 0)	{
			exe.replace(offset+14, 'EB', PTYPE_HEX);
		}
		else {
			exe.replace(offset+13, 'EB', PTYPE_HEX);
		}
	}
	return true;
}