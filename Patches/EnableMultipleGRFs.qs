// Enable Multiple GRF files
// adds support to load GRF files from a list inside DATA.INI
//
// 26.11.2010 - Organized DiffPatch into a working state for vc9 compiled clients [Yom]
// 12.10.2010 - The complete diff would take 247+9+14 = 264 bytes.
//              Note that if you are using k3dt's diff patcher, you have to use 2.30
//              since 2.31 and all before have a limit of 255 byte changes. [Shinryo]

//If you enable this feature, you will have to put a data.ini in your client folder.
//You can only load up to 10 total grf files with this option (0-9).
//The read priority is 0 first to 9 last.

//--------[ Example of data.ini ]---------
//[data]
//0=bdata.grf
//1=adata.grf
//2=sdata.grf
//3=data.grf
//----------------------------------------

//If you only have 3 GRF files, you would only need to use: 0=first.grf, 1=second.grf, 2=last.grf");

function EnableMultipleGRFs() {
    // Locate call to grf loading function.
	var grf = exe.findString("data.grf", RVA).packToHex(4);
	
	if (exe.getClientDate() <= 20130605) {
		var code =
				  ' 68' + grf			// push    offset aData_grf ; 'data.grf'
				+ ' B9 AB AB AB 00'		// mov     ecx, offset unk_86ABBC
				+ ' 88 AB AB AB AB 00'	// mov     byte_C08AC2, dl
				+ ' E8 AB AB AB AB'		// call    CFileMgr::AddPak()
				;
	}
	else {
		var code =
				  ' 68' + grf			// push    offset aData_grf ; 'data.grf'
				+ ' B9 AB AB AB 00'		// mov     ecx, offset unk_86ABBC
				+ ' E8 AB AB AB AB'		// call    CFileMgr::AddPak()
				;
	}
	
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
        
	// Save "this" pointer and address of AddPak.
	var setECX = exe.fetchHex(offset+5, 5);
	if (exe.getClientDate() <= 20130605) {
		var AddPak = exe.Raw2Rva(offset+16) + exe.fetchDWord(offset + 17) + 5;
	}
	else {
		var AddPak = exe.Raw2Rva(offset+10) + exe.fetchDWord(offset + 11) + 5;
	}
	
	var filler = ' 00 00 00 00';	
	var code =	
			  ' C8 80 00 00'		// enter   80h, 0
			+ ' 60'					// pushad
			+ ' 68' +  filler		// push    offset ModuleName   		; ST00 = 'KERNEL32' | offset = 6
			+ ' FF 15' + filler		// call    ds:GetModuleHandleA 		; CA00 = GetModuleHandleA | offset = 6+4+2 = 12 
			+ ' 85 C0'				// test    eax, eax
			+ ' 74 23'				// jz      short loc_735E01
			+ ' 8B 3D' + filler		// mov     edi, ds:GetProcAddress 	; CA01 = GetProcAddress | offset = 12+4+6 = 22
			+ ' 68' + filler		// push    offset aGetprivateprof 	; ST01 = 'GetPrivateProfileStringA' | offset = 22+4+1 = 27
			+ ' 89 C3'				// mov     ebx, eax
			+ ' 50'					// push    eax  ; hModule
			+ ' FF D7'				// call    edi  ; GetProcAddress()
			+ ' 85 C0'				// test    eax, eax
			+ ' 74 0F'				// jz      short loc_735E01
			+ ' 89 45 F6'			// mov     [ebp+var_A], eax
			+ ' 68' + filler		// push    offset aWriteprivatepr 	; ST02 = 'WritePrivateProfileStringA' | offset = 27+4+13 = 44
			+ ' 89 D8'				// mov     eax, ebx
			+ ' 50'					// push    eax  ; hModule
			+ ' FF D7'				// call    edi  ; GetProcAddress() 
			+ ' 85 C0'				// test    eax, eax
			+ ' 74 6E'				// jz      short loc_735E71
			+ ' 89 45 FA'			// mov     [ebp+var_6], eax
			+ ' 31 D2'				// xor     edx, edx
			+ ' 66 C7 45 FE 39 00'	// mov     [ebp+var_2], 39h ; char 9
			+ ' 52'					// push    edx
			+ ' 68' + filler		// push    offset a_Data_ini 		; ST04 = '.\\DATA.INI' | offset = 44+4+22 = 70
			+ ' 6A 74'				// push    74h
			+ ' 8D 5D 81'			// lea     ebx, [ebp+var_7F]
			+ ' 53'					// push    ebx
			+ ' 8D 45 FE'			// lea     eax, [ebp+var_2]
			+ ' 50'					// push    eax
			+ ' 50'					// push    eax
			+ ' 68' + filler		// push    offset aData_2  			; ST03 = 'Data' | offset = 70+4+12 = 86
			+ ' FF 55 F6'			// call    [ebp+var_A]
			+ ' 8D 4D FE'			// lea     ecx, [ebp+var_2]
			+ ' 66 8B 09'			// mov     cx, [ecx]
			+ ' 8D 5D 81'			// lea     ebx, [ebp+var_7F]
			+ ' 66 3B 0B'			// cmp     cx, [ebx]
			+ ' 5A'					// pop     edx
			+ ' 74 0E'				// jz      short loc_735E44
			+ ' 52'					// push    edx
			+ ' 53'					// push    ebx
			+   setECX				// mov     ecx, offset unk_810248
			+ ' E8' + filler		// call    CFileMgr::AddPak()		; CA02 = AddPak() | offset = 86+4+26 = 116
			+ ' 5A'					// pop     edx
			+ ' 42'					// inc     edx
			+ ' FE 4D FE'			// dec     byte ptr [ebp+var_2]
			+ ' 80 7D FE 30'		// cmp     byte ptr [ebp+var_2], 30h
			+ ' 73 C1'				// jnb     short loc_735E0E
			+ ' 85 D2'				// test    edx, edx
			+ ' 75 20'				// jnz     short loc_735E71
			+ ' 68' + filler		// push    offset a_Data_ini 		; ST04 = '.\\DATA.INI' | offset = 116+4+16 = 136
			+ ' 68' + grf			// push    offset aData_grf
			+ ' 66 C7 45 FE 32 00'	// mov     [ebp+var_2], 32h
			+ ' 8D 45 FE'			// lea     eax, [ebp+var_2]
			+ ' 50'					// push    eax
			+ ' 68' + filler		// push    offset aData_2  			; ST03 = 'Data' | offset = 136+4+16 = 156
			+ ' FF 55 FA'			// call    [ebp+var_6]
			+ ' 85 C0'				// test    eax, eax
			+ ' 75 97'				// jnz     short loc_735E08
			+ ' 61'					// popad
			+ ' C9'					// leave
			+ ' C3 00'				// retn
			;
	
	var iniFile = exe.getUserInput('$dataINI', XTYPE_STRING, "String Input", "Enter the name of the INI file", "DATA.INI", 1, 20);
	if (iniFile === "") {
		iniFile = ".\\DATA.INI";
	}
	else {
		iniFile = ".\\" + iniFile;
	}
	
	var strings = new Array();
	strings.push("KERNEL32", "GetPrivateProfileStringA", "WritePrivateProfileStringA", "Data", iniFile);
	
	// Calculate free space that the code will need.
	var size = code.hexlength();
	for (var i=0; strings[i]; i++) {
		size = size + strings[i].length + 1;//1 for NULL
	}	
	
	// Find free space to inject our data.ini load function.
	var free = exe.findZeros(size+4);
	if (free == -1) {
		return "Failed in part 3: Not enough free space";
	}
	var freeRva = exe.Raw2Rva(free);

	// Create a call to the free space that was found before.
	exe.replace(offset, ' 90 90 90 90 90 90 90 90 90 90', PTYPE_HEX);
	if (exe.getClientDate() <= 20130605) {		
		exe.replace(offset+16, 'E8' + (freeRva - exe.Raw2Rva(offset+16) - 5).packToHex(4), PTYPE_HEX);
	}
	else {
		exe.replace(offset+10, 'E8' + (freeRva - exe.Raw2Rva(offset+10) - 5).packToHex(4), PTYPE_HEX);
	}
	
	// ***********************************************************
	// Create default offsets that will be replaced into the code.
	// ***********************************************************
	// GetModuleHandleA
	var CA00 = exe.findFunction("GetModuleHandleA");
	if (CA00 == -1) {
		return "Failed in part 4";
	}
	
	// GetProcAddress
	var CA01 = exe.findFunction("GetProcAddress");
	if (CA01 == -1) {
		return "Failed in part 5";
	}
	
	// AddPak - offset is 116 but op starts at 115
    var CA02 = AddPak - (freeRva + 115) - 5;
	
	// Get string Location starting.
	var memPosition = freeRva + code.hexlength();
	
    // Now put the respective addresses into the code.
	//ST00 at 6
	code = code.replaceAt(  6*3, memPosition.packToHex(4));
	memPosition = memPosition + strings[0].length + 1;//1 for null
	
	//ST01 at 27
	code = code.replaceAt( 27*3, memPosition.packToHex(4));
	memPosition = memPosition + strings[1].length + 1;//1 for null
	
	//ST02 at 44
	code = code.replaceAt( 44*3, memPosition.packToHex(4));
	memPosition = memPosition + strings[2].length + 1;//1 for null
		
	//ST03 at 86, 155
	code = code.replaceAt( 86*3, memPosition.packToHex(4));
	code = code.replaceAt(156*3, memPosition.packToHex(4));
	memPosition = memPosition + strings[3].length + 1;//1 for null
	
	//ST04 at 70, 135
	code = code.replaceAt( 70*3, memPosition.packToHex(4));
	code = code.replaceAt(136*3, memPosition.packToHex(4));
	
	//CA00 at 12
	code = code.replaceAt( 12*3, CA00.packToHex(4));
	
	//CA01 at 22
	code = code.replaceAt( 22*3, CA01.packToHex(4));
	
	//CA02 at 115
	code = code.replaceAt(116*3, CA02.packToHex(4));
	
	// Add the strings into our code as well
	for (var i=0; strings[i]; i++) {
		code = code + strings[i].toHex() + ' 00';
	}
	code = code + ' 00'.repeat(8);
	
	// Finally, insert everything.
    exe.insert(free, size+4, code, PTYPE_HEX);
	return true;
}
