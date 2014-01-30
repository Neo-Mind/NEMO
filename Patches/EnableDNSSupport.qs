function EnableDNSSupport() {

	var code =  ' E8 AB AB AB FF 8B C8 E8 AB AB AB FF 50 B9 AB AB AB 00 E8 AB AB AB FF A1';
	
	var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');	
	if (offset == -1) {
		return 'Failed in part 1';
	}
		
	var offsetRVA = exe.Raw2Rva(offset) + exe.fetchDWord(offset+1) + 5;
     
	var filler = ' 00 00 00 00';
    var codef =  
		// Call Unknown Function - Pos = 1
		  ' E8' + filler							// CALL UnknownCall
		+ ' 60'										// PUSHAD
		// Pointer of old address - Pos = 8
		+ ' 8B 35' + filler							// MOV ESI,DWORD PTR DS:[7F8320]            ; ASCII '127.0.0.1'
		+ ' 56'										// PUSH ESI
		// Call to gethostbyname - Pos = 15
		+ ' FF 15' + filler							// CALL DWORD PTR DS:[<&WS2_32+ #52>]
		+ ' 8B 48 0C'								// MOV ECX,DWORD PTR DS:[EAX+0C]
		+ ' 8B 11'									// MOV EDX,DWORD PTR DS:[ECX]
		+ ' 89 D0'									// MOV EAX,EDX
		+ ' 0F B6 48 03'							// MOVZX ECX,BYTE PTR DS:[EAX+3]
		+ ' 51'										// PUSH ECX
		+ ' 0F B6 48 02'							// MOVZX ECX,BYTE PTR DS:[EAX+2]
		+ ' 51'										// PUSH ECX
		+ ' 0F B6 48 01'							// MOVZX ECX,BYTE PTR DS:[EAX+1]
		+ ' 51'										// PUSH ECX
		+ ' 0F B6 08'								// MOVZX ECX,BYTE PTR DS:[EAX]
		+ ' 51'										// PUSH ECX
		// IP scheme offset - Pos = 46
		+ ' 68' + filler							// PUSH OFFSET 007B001C                     ; ASCII '%d.%d.%d.%d'
		// Pointer to new address Pos = 51
		+ ' 68' + filler							// PUSH OFFSET 008A077C                     ; ASCII '127.0.0.1'
		// Call to sprintf - Pos = 57
		+ ' FF 15' + filler							// CALL DWORD PTR DS:[<&MSVCR90+ sprintf>]
		+ ' 83 C4 18'								// ADD ESP,18
		// Replace old ptr with new ptr
		// Old Ptr - Pos = 66
		// New Ptr - Pos = 70
		+ ' C7 05' + filler + filler				// MOV DWORD PTR DS:[7F8320],OFFSET 008A07C ; ASCII '127.0.0.1'
		+ ' 61'										// POPAD
		+ ' C3'										// RETN
		+ ' 00' +  "127.0.0.1\x00".toHex()			// 127.0.0.1
		;
	
    // Calculate free space that the code will need.
    var size = codef.hexlength();
    
    // Find free space to inject our data.ini load function.
    // Note that for the time beeing those will be probably
    // return some space in .rsrc, but that's still okay
    // until our new diff patcher is finished for our own section.
    var free = exe.findZeros(size + 4 + 16); // Free space of enable multiple grf + space for dns support
	
    if (free == -1) {
		return 'Failed in part 2: Not enough free space';
    }
	//$free += 247 + 4 + 4;
     
    // Create a call to the free space that was found before.
	
	var uRvaFreeOffset = exe.Raw2Rva(free) - exe.Raw2Rva(offset) - 5;//more to be added 
	
    exe.replace(offset, 'E8' +  uRvaFreeOffset.packToHex(4), PTYPE_HEX);
	
	uRvaFreeOffset = uRvaFreeOffset + 2 + 16 ;

    //************************************************************************/
	//* Find old ptr.
	//the way is to just find location where the string "address" is pushed
	//and search for A3 AB AB AB 00 
	//you need to extract the last 4 bytes from A3 AB AB AB 00 
	//************************************************************************/
     
	if (exe.getClientDate() <= 20130605) {
		var code =  ' A3 AB AB AB 00 EB 0F 83 C0 04 A3 AB AB AB 00 EB 05';
	}
	else {
		var code =  ' 8B 00 A3 AB AB AB 00 68 AB AB AB 00 8B CB E8 AB AB AB 00 85 C0 74 1B';
	}
	
    offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return 'Failed in part 3';
	}
	if (exe.getClientDate() <= 20130605) {
		uOldptr = exe.fetchDWord(offset + 1);
	}
	else {
		uOldptr = exe.fetchDWord(offset + 3);
	}
     
    /************************************************************************/
	/* Find gethostbyname().
	/************************************************************************/

	if (exe.getClientDate() <= 20130605) {
		code = ' FF 15 AB AB AB 00 85 C0 75 29 8B AB AB AB AB 00';
	}
	else {
		code = ' FF 15 AB AB AB 00 85 C0 75 2B 8B AB AB AB AB 00';
	}

    offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		code = ' E8 AB AB AB 00 85 C0 75 35 8B AB AB AB AB 00';
		offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
		if (offset == -1) {
			return 'Failed in part 4';
		}
		else {
			offset = exe.Raw2Rva(offset) + exe.fetchDWord(offset + 1) + 5;
			var uGethostbyname = exe.fetchDWord(offset) + 2;
		}
	}
	else {
		var uGethostbyname = exe.fetchDWord(offset+2);
	}
     
	var uSprintf = exe.findFunction('sprintf', PTYPE_STRING, true);
    if (uSprintf == -1) {
		return 'Failed in part 5';
	}
	
	var uIPScheme = exe.findString('%d.%d.%d.%d', RVA);
    if (uIPScheme == -1) {
		return 'Failed in part 6';
	}
	
	offsetRVA = offsetRVA - exe.Raw2Rva(free) - 5;
	uRVAfreeoffset = exe.Raw2Rva(free + 77);
	
	codef = codef.replaceAt( 1*3, offsetRVA.packToHex(4) );
	codef = codef.replaceAt( 8*3, uOldptr.packToHex(4) );
	codef = codef.replaceAt(15*3, uGethostbyname.packToHex(4) );
	codef = codef.replaceAt(46*3, uIPScheme.packToHex(4) );
	codef = codef.replaceAt(51*3, uRVAfreeoffset.packToHex(4) );
	codef = codef.replaceAt(57*3, uSprintf.packToHex(4) );
	codef = codef.replaceAt(66*3, uOldptr.packToHex(4) );
	codef = codef.replaceAt(70*3, uRVAfreeoffset.packToHex(4) );
	
     // Finally, insert everything.
    exe.insert(free, size + 4 + 16, codef, PTYPE_HEX);        
    return true;
}