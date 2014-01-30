function CancelToLoginWindow() {

	//Step 1 - Find the offset of Message (Since Client is not translated we will use the original korean B8 DE BD C3 C1 F6
	var msg = exe.findString('\xB8\xDE\xBD\xC3\xC1\xF6', RVA);
	if (msg == -1) 	{
		return 'Failed in Step 1';
	}
		
	//Step 2 - Find the location where the message box gets displayed and client quits
	var prefix =  
			  ' 6A 78'			//PUSH 78
			+ ' 68 18 01 00 00'	//PUSH 118
			;
				  
	var code =  
			  ' 68' + msg.packToHex(4)	//PUSH <title name (Message in translated version)>
			+ ' AB'					//PUSH reg32 (contains 0)
			+ ' AB'					//PUSH reg32 (contains 0)
			+ ' 6A 01'				//PUSH 1
			+ ' 6A 02'				//PUSH 2
			+ ' 6A 11'				//PUSH 11
			;
	
	var overwriter = exe.findCode(prefix + code, PTYPE_HEX, true, '\xAB');
	if (overwriter == -1) {
		prefix = "";
		overwriter = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	}		
	
	if (overwriter == -1) {
		return 'Failed in Step 2';
	}
	
	var winoffset = prefix.hexlength() + code.hexlength() + 5 + 3 + 1 + 5 + 5 + 5 + 6; //CALL + ADD ESP + PUSH reg + MOV reg, offset + CALL + CMP eax, value + JNE long
	
	//Step 3 - Find CConnection::Disconnect & CRagConnection::instanceR
	//3.1 - Find the signature 
	code =    ' 68 AB AB AB 00'		//PUSH OFFSET "5,01,2600,1832"
			+ ' 51'					//PUSH ECX
			+ ' FF D0'				//CALL EAX
			+ ' 83 C4 08'			//ADD ESP, 8
			+ ' E8'					//CALL CRag
			;
				
	var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return 'Failed in Step 3.1';
	}
		
	//3.2 - Read function addresses.
	var crag = offset + 16 + exe.fetchDWord(offset+12);
	var ccon = offset + 23 + exe.fetchDWord(offset+19);//NO RVA conversion needed since we are traversing same section.
		
	//Step 4 - Prep the replace code
	//4.1 - Disconnect from Char server
	code =    ' E8' + (crag - (overwriter + 5)).packToHex(4)	//CALL CRagConnection::instanceR
			+ ' 8B C8'										    				//MOV ECX, EAX
			+ ' E8' + (ccon - (overwriter + 12)).packToHex(4)	//CALL CConnection::disconnect
			;
				
	//4.2 - Append Window Caller - read from existing code (till window code)
	code = code + exe.fetchHex(overwriter + winoffset, 15);
		
	//4.3 - Provide Login Window's code and call the Window caller.
	code = code + ' 68 23 27 00 00'	//PUSH 2723
			    + ' FF D0'			//CALL EAX
			    + ' EB' +  ((winoffset + 15 + 4) - (12 + 15 + 9)).packToHex(1) //JMP to PUSH ESI below - skipping rest.
			;
		
	//Step 5 - Replace with the prepped code
	exe.replace(overwriter, code, PTYPE_HEX);
	return true;
}