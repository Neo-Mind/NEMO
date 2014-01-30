function RemoveHourlyAnnounce() {

	// RemoveHourlyGameGrade
	//
	// "75 34"			// JNZ     SHORT ADDR v
	// "66 8B 44 24 AB"	// MOV     AX,WORD PTR SS:[ESP+?]
	// "66 85 C0"		// TEST    AX,AX
	// "75 15"			// JNZ     SHORT ADDR v
	// "84 C9"          // TEST    CL,CL
	// "75 26"          // JNZ     SHORT ADDR v
	// "B1 01"          // MOV     CL,1
	// "33 C0"          // XOR     EAX,EAX
	
	if (exe.getClientDate() <= 20130605) {
		var code =  ' 75 34 66 8B 44 24 AB';
	}
	else {
		var code =  ' 75 33 66 8B 45 E8 AB';
	}
		
    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset == -1) {
		return "Failed in part 1";
    }

    exe.replace(offset, 'EB', PTYPE_HEX); // JNZ -> JMP
		
	// RemoveHourlyPlaytimeMinder
	//
	//0   "B8 B17C2195"  // MOV     EAX,95217CB1h
	//5   "F7E1"         // MUL     ECX
	//7   "8BFA"         // MOV     EDI,EDX
	//9   "C1EF 15"      // SHR     EDI,15h
	//12  "3BFD"         // CMP     EDI,R32  ; R32 is initialized to 0
	//14  "0F8E"         // JLE     ADDR v
	
    code =  ' B8 B1 7C 21 95 F7 E1';
	offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 2";
	}

	if (exe.getClientDate() <= 20130605)
		exe.replace(offset+14, ' 90 E9', PTYPE_HEX); // JLE -> NOP and JLE -> JMP
	else
		exe.replace(offset+29, ' 90 E9', PTYPE_HEX); // JLE -> NOP and JLE -> JMP
	
	return true;
}