function DisableHShield() {
	if (exe.getClientDate() <= 20130605) {//alternative to finding webclinic
		var code =	
				  ' 51'						// push    ecx
				+ ' 83 3D AB AB AB 00 00'	// cmp     dword_88A210, 0
				+ ' 74 04'					// jz      short loc_58AD2E
				+ ' 33 C0'					// xor     eax, eax
				+ ' 59'						// pop     ecx
				+ ' C3'						// retn
				;
	}
	else {
		var code =	  
				  ' 51'						// push    ecx
				+ ' 83 3D AB AB AB 00 00'	// cmp     dword_C40C94, 0
				+ ' 74 06'					// jz      short loc_626FD3
				+ ' 33 C0'					// xor     eax, eax
				+ ' 8B E5'					// mov     esp, ebp
				+ ' 5D'						// pop     ebp
				+ ' C3'						// retn		
				;
	}
        
	var offset = exe.findCode(code, PTYPE_HEX, true, '\xAB');
	if (offset == -1) {
		return 'Failed in part 1';
	}
        
    // Just return 1 without initializing AhnLab :)
	exe.replace(offset+8, ' 33 C0 40 90', PTYPE_HEX);
	
	// Next we take care of a new function call that is there in the newer clients (maybe all ragexe too?)
	offset = exe.findString('CHackShieldMgr::Monitoring() failed', RVA);
	if (offset != -1) {
		offset = exe.findCode(" 68" + offset.packToHex(4) + " FF 15", PTYPE_HEX, false);
	}
	
	if (offset != -1) {
		code =	  ' E8 AB AB AB AB'
				+ ' 84 C0'
				+ ' 74 16'
				+ ' 8B AB'
				+ ' E8 AB AB AB AB'
				;
				
		offset = exe.find(code, PTYPE_HEX, true, '\xAB', offset - 0x40, offset);
	}
	if (offset != -1) {
		exe.replace(offset, ' B0 01 5E C3 90', PTYPE_HEX);
    }
	
	// Adding FailSafe - avoiding the calls itself.
	offset = exe.findString("ERROR", RVA);//prefixZero is true by default.
	if (offset == -1) {
		return "Failed in part 2.1";
	}
	
	offset = exe.findCode(" 68" + offset.packToHex(4) + " 50", PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in part 2.2";
	}
	
	offset = exe.find(" 80 3D AB AB AB AB 00 75", PTYPE_HEX, true, "\xAB", offset, offset+0x80);
	if (offset == -1) {
		return "Failed in part 2.3";
	}
	
	exe.replace(offset+7, "EB", PTYPE_HEX);//change JNE to JMP

  // Import table fix for aossdk.dll  
	// The dll name offset gives the hint where the image descriptor of this dll resides.
	var aOffset = exe.find("aossdk.dll", PTYPE_STRING, false);
	if (aOffset == -1) {
		return 'Failed in part 3';
	}
		
	//Convert to RVA (the actual Relative Virtual Address not the RVA we mistook) prefixed by 8 zeros
	aOffset = " 00".repeat(8) + (exe.Raw2Rva(aOffset) - exe.getImageBase()).packToHex(4);
	
	//Check if Custom DLL has been enabled - does the import table fix inside.
	var hasCustomDLL = (exe.getActivePatches().indexOf(211) != -1);	
	if (hasCustomDLL) {
		var tblData = Imp_DATA.valueSuf;
		var newTblData = "";
		
		for (var i = 0; i < tblData.length; i+=20*3) {
			var curValue = tblData.substr(i, 20*3);
			if (curValue.indexOf(aOffset) === 3*4)
				continue;
			newTblData = newTblData + curValue;	
		}
		
		if(newTblData !== tblData) {
			exe.emptyPatch(211);//We will add the changes to this patch instead.
			var PEoffset = exe.find("50 45 00 00", PTYPE_HEX, false);
			exe.insert(Imp_DATA.offset, (Imp_DATA.valuePre + newTblData).hexlength(), Imp_DATA.valuePre + newTblData, PTYPE_HEX);
			exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0x8, Imp_DATA.tblAddr);
			exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0xC, Imp_DATA.tblSize);
		}		
	}
	else {
		var dir = GetDataDirectory(1);
		var finalValue = " 00".repeat(20);
		var offset = dir.offset;
		var dllOffset = false;
		
		var curValue = exe.fetchHex(offset,20);
		do {
			if (curValue.indexOf(aOffset) === 3*4) 
				dllOffset = offset;
				
			offset += 20;
			curValue = exe.fetchHex(offset,20);
		} while(curValue != finalValue);
		
		if (!dllOffset) {
			return "Failed in Part 4";
		}
		var endOffset = offset - 20;//Last DLL Entry
		exe.replace(dllOffset, exe.fetchHex(endOffset, 20), PTYPE_HEX);//Replace aossdk.dll import with the last import
		exe.replace(endOffset, finalValue, PTYPE_HEX);//Replace last import with 0s to indicate end of table.	
	}
	return true;
}