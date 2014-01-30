function findStart(off, type) {//type=1 PUSH ESI, type=2 PUSH EBX
	var code = " 83 EC 0C 56 8B F1";
	var range = 0x20;
	
	if (type === 2) {
		code = " 83 EC 0C 53";
		range = 0x50;
	}
	
	var startoff = exe.find(" 55 8B EC" + code, PTYPE_HEX, false, " ", off - range, off);
	if (startoff === -1) {
		startoff = exe.find(code, PTYPE_HEX, false, " ", off - range, off);
	}
	return startoff;
}


function GenMapEffectPlugin() {
	var fp = new BinFile();
	if (!fp.open(APP_PATH + "/Input/rdll2.asi")) {
		return "Base File - rdll2.asi is missing from Input folder..Exiting";
	}
	
	var errorStr = "Script needs update";
	var xmasRVA = exe.findString("xmas_fild01.rsw", RVA);
	if (xmasRVA === -1) {
		return errorStr;
	}
	
	var CGIEntry = exe.findCode(xmasRVA.packToHex(4) + " 8A", PTYPE_HEX, false);
	if (CGIEntry === -1) {
		return errorStr;
	}
	CGIEntry--;
	
	var CGIExit = exe.find("E8 AB AB AB AB 8A", PTYPE_HEX, true, "\xAB", CGIEntry + 5);
	if (CGIExit === -1) {
		return errorStr;
	}
	var LCl = CGIExit + 5 + exe.fetchDWord(CGIExit+1);	
	CGIExit += 5;
	
	var yunoRVA = exe.findString("yuno.rsw", RVA);
	if (yunoRVA === -1) {
		return errorStr;
	}
	var CGOEntry = exe.find(" B8" + yunoRVA.packToHex(4), PTYPE_HEX, false, " ", 0, CGIEntry-1);
	if (CGOEntry === -1) {
		CGOEntry = exe.find(" B8" + yunoRVA.packToHex(4), PTYPE_HEX, false, " ", CGIExit+8);
	}
	if (CGOEntry === -1) {
		return errorStr;
	}
	
	var CGOExit = exe.find("C7 AB AB AB AB AB FF 8B AB AB AB AB 00 8B", PTYPE_HEX, true, "\xAB", CGOEntry);
	if (CGOExit === -1) {
		return errorStr;
	}
	CGOExit += 7;
	
	var LNt = exe.findCode(" C6 01 01 C3", PTYPE_HEX, false);
	if (LNt === -1) {
		return errorStr;
	}
	
	var offsets = exe.findCodes("81 F9 2C 01 00 00 7E AB B9", PTYPE_HEX, true, "\xAB");
	if (offsets.length !== 3) {
		return errorStr;
	}
	
	var LSk = 0;
	var LSn = 0;
	var LMp = 0;
	
	for (var i = 0; i < 3; i++) {
		var offset = findStart(offsets[i], 1);
		if (exe.find(" 68 A2 00 00 00", PTYPE_HEX, false, " ", offsets[i], offsets[i]+0x60) !== -1) {
			LSn = offset;
		}
		else if (exe.find(" 68 A3 00 00 00", PTYPE_HEX, false, " ", offsets[i], offsets[i]+0x60) !== -1) {
			LSk = offset;
		}		
		else if (exe.find(" 68 4D 01 00 00", PTYPE_HEX, false, " ", offsets[i], offsets[i]+0x60) !== -1) {
			LMp = offset;
		}
	}
	if (LSn === -1 || LSk === -1 || LMp === -1) {
		return errorStr;
	}
	
	offsets = exe.findCodes("68 2D 01 00 00", PTYPE_HEX, false);
	var LPk = findStart(offsets[1], 2);
	if (LPk === -1) {
		return errorStr;
	}
	
	var offset = exe.find("B9 AB AB AB 00 E8", PTYPE_HEX, true, "\xAB", CGIEntry-0x10, CGIEntry);
	if (offset === -1) {
		return errorStr;
	}
	var GW = exe.fetchHex(offset+1,4);
	var GU = 0;
	
	var df = 0;
	
	offset = exe.find("B9" + GW + " 39 1D", PTYPE_HEX, false);
	
	if (offset === -1) {
		offset = exe.find("A1 AB AB AB 00 B9" + GW, PTYPE_HEX, true, "\xAB");
		df = 1;
	}
	else {
		df = 7;
	}
	
	if (offset === -1) {
		return errorStr;
	}
	
	GU = exe.fetchHex(offset+df, 4);
	
	offset = exe.findCode("8B 0D AB AB AB 00 68 01 02 00 00 50", PTYPE_HEX, true, "\xAB");
	if (offset === -1) {
		return errorStr;
	}
	
	var GC = exe.fetchHex(offset+2,4);
	
	var PEOff = exe.find(" 50 45 00 00", PTYPE_HEX, false);
	if (PEOff === -1) {
		return errorStr;
	}
	
	var TS = exe.fetchHex(PEOff+0x08,4);

	var dll = fp.readHex(0,0x2000);
	fp.close();
	
	dll = dll.replace(/ 29 35 83 4F/i, TS);
	dll = dll.replace(/ A0 1B 97 00/i, GW);
	dll = dll.replace(/ D8 3D 8F 00/i, GC);
	dll = dll.replace(/ EC 0E 9A 00/i, GU);
	dll = dll.replace(/ 80 68 6C 00/i, exe.Raw2Rva(LCl).packToHex(4));
	dll = dll.replace(/ 60 66 6C 00/i, exe.Raw2Rva(LSn).packToHex(4));
	dll = dll.replace(/ C0 68 6C 00/i, exe.Raw2Rva(LMp).packToHex(4));
	dll = dll.replace(/ 40 68 6C 00/i, exe.Raw2Rva(LSk).packToHex(4));
	dll = dll.replace(/ 30 6B 6C 00/i, exe.Raw2Rva(LPk).packToHex(4));
	dll = dll.replace(/ E0 6B 6C 00/i, exe.Raw2Rva(LNt).packToHex(4));
	
	dll = dll.replace(/ 61 AB 72 00/i, exe.Raw2Rva(CGIEntry).packToHex(4));
	dll = dll.replace(/ 48 B4 72 00/i, exe.Raw2Rva(CGIExit ).packToHex(4));
	dll = dll.replace(/ ED 37 73 00/i, exe.Raw2Rva(CGOEntry).packToHex(4));
	dll = dll.replace(/ 08 49 73 00/i, exe.Raw2Rva(CGOExit ).packToHex(4));
	
	fp.open(APP_PATH + "/Output/rdll2_" + exe.getClientDate() + ".asi", "w");
	fp.writeHex(0,dll);
	fp.close();
	
	/* - Use incase you need the source file
	fp2 = new TextFile();
	fp2.open(APP_PATH + "/Output/client_" + exe.getClientDate() + ".h", "w");
	fp2.writeline("#include <WTypes.h>");
	fp2.writeline("\n//Client Date : " + exe.getClientDate());
	fp2.writeline("#define CLIENT_TIMESTAMP " + le2be(TS));
	fp2.writeline("\n//Client offsets");
	fp2.writeline("void* G_WEATHER = (void*)" + le2be(GW) + ";");
	fp2.writeline("void** G_CRENDERER = (void**)" + le2be(GC) + ";");
	fp2.writeline("void* G_USEEFFECT = (void*)" + le2be(GU) + ";");
	fp2.writeline("\nDWORD CWeather_EffectId2LaunchFuncAddr[] = {\n\tNULL, //CEFFECT_NONE");
	fp2.writeline("\t" + le2be(exe.Raw2Rva(LCl).packToHex(4)) + ", // CEFFECT_SKY -> void CWeather::LaunchCloud(CWeather this<ecx>, char param)");
	fp2.writeline("\t" + le2be(exe.Raw2Rva(LSn).packToHex(4)) + ", // CEFFECT_SNOW -> void CWeather::LaunchSnow(CWeather this<ecx>)");
	fp2.writeline("\t" + le2be(exe.Raw2Rva(LMp).packToHex(4)) + ", // CEFFECT_MAPLE -> void CWeather::LaunchMaple(CWeather this<ecx>)");
	fp2.writeline("\t" + le2be(exe.Raw2Rva(LSk).packToHex(4)) + ", // CEFFECT_SAKURA -> void CWeather::LaunchSakura(CWeather this<ecx>)");
	fp2.writeline("\t" + le2be(exe.Raw2Rva(LPk).packToHex(4)) + ", // CEFFECT_POKJUK -> void CWeather::LaunchPokJuk(CWeather this<ecx>)");
	fp2.writeline("\t" + le2be(exe.Raw2Rva(LNt).packToHex(4)) + ", // CEFFECT_NIGHT -> void CWeather::LaunchNight(CWeather this<ecx>)");
	fp2.writeline("};\n");
	
	fp2.writeline("void* CGameMode_Initialize_EntryPtr = (void*)" + le2be(exe.Raw2Rva(CGIEntry).packToHex(4)) + ";");
	fp2.writeline("void* CGameMode_Initialize_RetPtr = (void*)" + le2be(exe.Raw2Rva(CGIExit ).packToHex(4)) + ";");
	fp2.writeline("void* CGameMode_OnInit_EntryPtr = (void*)" + le2be(exe.Raw2Rva(CGOEntry).packToHex(4)) + ";");
	fp2.writeline("void* CGameMode_OnInit_RetPtr = (void*)" + le2be(exe.Raw2Rva(CGOExit ).packToHex(4)) + ";");

	fp2.close();
	*/
	
	return "MapEffect plugin for the loaded client has been generated in Output folder";
}

function le2be(le) {
	var be = "";
	for (var i = le.length-3; i >= 0; i-=3) {
		be += le.substring(i,i+3);
	}
	return "0x" + be.replace(/ /g,"");	
}