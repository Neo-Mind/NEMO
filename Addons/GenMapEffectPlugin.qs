//######################################################################
//# Purpose: Generate Curiosity's Map Effect Plugin for loaded client  #
//#          using the template DLL (rdll2.asi) along with header file #
//######################################################################

function GenMapEffectPlugin() {
  
	//Step 1 - Open the Template file (making sure it exists before anything else)
  var fp = new BinFile();
	if (!fp.open(APP_PATH + "/Input/rdll2.asi"))
		throw "Error: Base File - rdll2.asi is missing from Input folder";
	
  //Step 2a - Find offset of xmas_fild01.rsw
	var offset = exe.findString("xmas_fild01.rsw", RVA);
	if (offset === -1)
		throw "Error: xmas_fild01 missing";
	
  //Step 2b - Find the CGameMode_Initialize_EntryPtr using the offset
	offset = exe.findCode(offset.packToHex(4) + " 8A", PTYPE_HEX, false);
	if (offset === -1)
		throw "Error: xmas_fild01 reference missing";
	
  //Step 2c - Save the EntryPtr address.
	var CI_Entry = offset - 1;
	
  //Step 3a - Look for g_Weather assignment before EntryPtr
  var code = 
      " B9 AB AB AB 00" //MOV ECX, g_Weather
    + " E8"             //CALL CWeather::ScriptProcess
    ;
    
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", CI_Entry-0x10, CI_Entry);
  if (offset === -1)
    throw "Error: g_Weather assignment missing";
  
  //Step 3b - Save the g_Weather address
  var gWeather = exe.fetchHex(offset+1, 4);
  
  //Step 4a - Look for the ending pattern after CI_Entry to get CGameMode_Initialize_RetPtr
  code = 
      " 74 0A"         //JE SHORT addr -> after the call. this address is RetPtr
    + " B9" + gWeather //MOV ECX, g_Weather
    + " E8"            //CALL CWeather::LaunchPokJuk
    ;
  offset = exe.find(code, PTYPE_HEX, false, "", CI_Entry+1);
  if (offset === -1)
    throw "Error: CI_Return missing";
  
  //Step 4b - Save RetPtr.
  var CI_Return = offset + code.hexlength() + 4;
  
  //Step 4c - Save CWeather::LaunchPokJuk address (not RAW)
  var CW_LPokJuk = (exe.Raw2Rva(CI_Return) + exe.fetchDWord(CI_Return-4)).packToHex(4);
  
  //Step 5a - Find offset of yuno.rsw
  var offset2 = exe.findString("yuno.rsw", RVA);
  if (offset2 === -1)
    throw "Error: yuno.rsw missing";
  
  //Step 5b - Find its reference between CI_Entry & CI_Return
  offset = exe.find(offset2.packToHex(4) + " 8A", PTYPE_HEX, false, "", CI_Entry+1, CI_Return);
  if (offset === -1)
    throw "Error: yuno.rsw reference missing";
  
  //Step 5c - Find the JZ below it which leads to calling LaunchCloud
  offset = exe.find(" 0F 84 AB AB 00 00", PTYPE_HEX, true, "\xAB", offset+5);
  if (offset === -1)
    throw "Error: LaunchCloud JZ missing";
  
  offset += exe.fetchDWord(offset+2) + 6;
  
  //Step 5d - Go Inside and extract g_useEffect
  var opcode = exe.fetchByte(offset) & 0xFF;//and mask to fix up Sign issues
  if (opcode === 0xA1)
    var gUseEffect = exe.fetchHex(offset+1, 4);
  else
    var gUseEffect = exe.fetchHex(offset+2, 4);
  
  //Step 5e - Now look for LaunchCloud call after it
  code = 
      " B9" + gWeather //MOV ECX, g_Weather
    + " E8"            //CALL CWeather::LaunchCloud
    ;
  
  offset = exe.find(code, PTYPE_HEX, false, "", offset);
  if (offset === -1)
    throw "Error: LaunchCloud call missing";
  
  offset += code.hexlength();
  
  //Step 5f - Save CWeather::LaunchCloud address (not RAW)
  var CW_LCloud = (exe.Raw2Rva(offset+4) + exe.fetchDWord(offset)).packToHex(4);
  
  //Step 6a - Find the 2nd reference to yuno.rsw - which will be at CGameMode_OnInit_EntryPtr
  offset = exe.find(" B8" + offset2.packToHex(4), PTYPE_HEX, false, "", 0, CI_Entry-1);

  if (offset === -1)
    offset = exe.find(" B8" + offset2.packToHex(4), PTYPE_HEX, false, "", CI_Return+1);
  
  if (offset === -1)
    throw "Error: 2nd yuno.rsw reference missing";
  
  //Step 6b - Save the EntryPtr
  var CO_Entry = offset;
  
  //Step 7a - Find the closest JZ after CO_Entry. It jumps to a g_renderer assignment
  offset = exe.find(" 0F 84 AB AB 00 00", PTYPE_HEX, true, "\xAB", CO_Entry+1);
  if (offset === -1)
    throw "Error: JZ after CO_Entry missing";
  
  offset += exe.fetchDWord(offset+2) + 6 + 1;//1 to skip the first opcode byte
  
  opcode = exe.fetchByte(offset-1) & 0xFF;//and mask to fix up Sign issues
  if (opcode !== 0xA1)
    offset++;//extra 1 to skip the second opcode byte
  
  //Step 7b - Save g_renderer & the g_renderer->ClearColor offset
  var gRenderer = exe.fetchHex(offset, 4);
  var gR_clrColor = exe.fetchHex(offset+6, 1);
  
  //Step 7c - Find pattern after offset that JMPs to CGameMode_OnInit_RetPtr
  code =
      gRenderer                               //MOV reg32_A, DWORD PTR DS:[g_renderer]
    + " C7 AB" + gR_clrColor + " 33 00 33 FF" //MOV DWORD PTR DS:[reg32_A+const], FF330033
    + " EB"                                   //JMP SHORT addr -> jumps to RetPtr
    ;
    
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+11);
  if (offset === -1)
    throw "Error: CO_Return missing";
  
  offset += code.hexlength();
  offset += exe.fetchByte(offset) + 1;
  
  //Step 7d - Check if its really after the last map - new clients have more 
  opcode = exe.fetchByte(offset) & 0xFF;
  if (opcode != 0xA1 && (opcode !== 0x8B || (exe.fetchByte(offset+1) & 0xC7) !== 5)) {//not MOV EAX, [addr] or MOV reg32_A, [addr]
    code = 
        gRenderer               //MOV reg32_A, g_renderer
      + " C7 AB" + gR_clrColor  //MOV DWORD PTR DS:[reg32_A+const], colorvalue
      ;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+1, offset+0x100);
    if (offset === -1)
      throw "Error: CO_Return missing 2";
    
    offset += code.hexlength() + 4;    
  }
  
  //Step 7e - Save the RetPtr
  var CO_Return = offset;
  
  //Step 8a - Find CWeather::LaunchNight function. It always has the same code
  offset = exe.findCode(" C6 01 01 C3", PTYPE_HEX, false); //MOV BYTE PTR DS:[ECX],1 and RETN
  if (offset === -1)
    throw "Error: LaunchNight missing";
  
  //Step 8b - Save CWeather::LaunchNight address (not RAW)
  var CW_LNight = exe.Raw2Rva(offset).packToHex(4);
  
  //Step 9a - Find CWeather::LaunchSnow function call. should be after xmas.rsw is PUSHed
  code = 
    " 74 07"          //JZ SHORT addr1 -> Skip LaunchSnow and call StopSnow instead
  + " E8 AB AB AB AB" //CALL CWeather::LaunchSnow
  + " EB 05"          //JMP SHORT addr2 -> Skip StopSnow call
  + " E8"             //CALL CWeather::StopSnow
  ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", CI_Entry);
  if (offset === -1)
    throw "Error: LaunchSnow call missing";
  
  //Step 9b - Save CWeather::LaunchSnow address (not RAW)
  var CW_LSnow = (exe.Raw2Rva(offset+7) + exe.fetchDWord(offset+3)).packToHex(4);
  
  //Step 10a - Find the PUSH 14D (followed by MOV) inside CWeather::LaunchMaple
  offset = exe.findCode(" 68 4D 01 00 00 89", PTYPE_HEX, false);
  if (offset === -1)
    throw "Error: LaunchMaple missing";
  
  //Step 10b - Find the start of the function
  code = 
      " 83 EC 0C" //SUB ESP, 0C
    + " 56"       //PUSH ESI
    + " 8B F1"    //MOV ESI, ECX
    ;
  offset2 = exe.find(" 55 8B EC" + code, PTYPE_HEX, false, "", offset-0x60, offset);
  
  if (offset2 === -1)
    offset2 = exe.find(code, PTYPE_HEX, false, "", offset-0x60, offset);
  
  if (offset2 === -1)
    throw "Error: LaunchMaple start missing";
  
  //Step 10c - Save CWeather::LaunchMaple address (not RAW)
  var CW_LMaple = exe.Raw2Rva(offset2).packToHex(4);
  
  //Step 11a - Find the PUSH A3 (followed by MOV) inside CWeather::LaunchSakura
  offset = exe.findCode(" 68 A3 00 00 00 89", PTYPE_HEX, false);
  if (offset === -1)
    throw "Error: LaunchSakura missing";
  
  //Step 11b - Find the start of the function
  offset2 = exe.find(" 55 8B EC" + code, PTYPE_HEX, false, "", offset-0x60, offset);
  
  if (offset2 === -1)
    offset2 = exe.find(code, PTYPE_HEX, false, "", offset-0x60, offset);
  
  if (offset2 === -1)
    throw "Error: LaunchSakura start missing";
  
  //Step 11c - Save CWeather::LaunchSakura address (not RAW)
  var CW_LSakura = exe.Raw2Rva(offset2).packToHex(4);
  
  //Step 12a - Read the input dll file
	var dll = fp.readHex(0,0x2000);
	fp.close();
  
  //Step 12b - Fill in the values
  dll = dll.replace(/ C1 C1 C1 C1/i, gWeather);
  dll = dll.replace(/ C2 C2 C2 C2/i, gRenderer);
  dll = dll.replace(/ C3 C3 C3 C3/i, gUseEffect);
  
  code = 
      CW_LCloud
    + CW_LSnow
    + CW_LMaple
    + CW_LSakura
    + CW_LPokJuk
    + CW_LNight
    ;
  dll = dll.replace(/ C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4 C4/i, code);
  
  dll = dll.replace(/ C5 C5 C5 C5/i, exe.Raw2Rva(CI_Entry).packToHex(4));
  dll = dll.replace(/ C6 C6 C6 C6/i, exe.Raw2Rva(CO_Entry).packToHex(4));
  dll = dll.replace(/ C7 C7 C7 C7/i, exe.Raw2Rva(CI_Return).packToHex(4));
  dll = dll.replace(/ C8 C8 C8 C8/i, exe.Raw2Rva(CO_Return).packToHex(4));
  
  dll = dll.replace(/ 6C 5D C3/i, gR_clrColor + " 5D C3");
 
  //Step 12c - Write to output dll file.
	fp.open(APP_PATH + "/Output/rdll2_" + exe.getClientDate() + ".asi", "w");
	fp.writeHex(0,dll);
	fp.close();
  
	//Step 12d - Also write out the values to header file (client.h)
	fp2 = new TextFile();
	fp2.open(APP_PATH + "/Output/client_" + exe.getClientDate() + ".h", "w");
	fp2.writeline("#include <WTypes.h>");
	fp2.writeline("\n// Client Date : " + exe.getClientDate());
	fp2.writeline("\n// Client offsets - some are #define because they were appearing in multiple locations unnecessarily");
	fp2.writeline("#define G_WEATHER 0x" + gWeather.toBE() + ";");
	fp2.writeline("#define G_RENDERER 0x" + gRenderer.toBE() + ";");
	fp2.writeline("#define G_USEEFFECT 0x" + gUseEffect.toBE() + ";");
	fp2.writeline("\nDWORD CWeather_EffectId2LaunchFuncAddr[] = {\n\tNULL, //CEFFECT_NONE");
	fp2.writeline("\t0x" + CW_LCloud.toBE() + ", // CEFFECT_SKY -> void CWeather::LaunchCloud(CWeather this<ecx>, char param)");
	fp2.writeline("\t0x" + CW_LSnow.toBE() + ", // CEFFECT_SNOW -> void CWeather::LaunchSnow(CWeather this<ecx>)");
	fp2.writeline("\t0x" + CW_LMaple.toBE() + ", // CEFFECT_MAPLE -> void CWeather::LaunchMaple(CWeather this<ecx>)");
	fp2.writeline("\t0x" + CW_LSakura.toBE() + ", // CEFFECT_SAKURA -> void CWeather::LaunchSakura(CWeather this<ecx>)");
	fp2.writeline("\t0x" + CW_LPokJuk.toBE() + ", // CEFFECT_POKJUK -> void CWeather::LaunchPokJuk(CWeather this<ecx>)");
	fp2.writeline("\t0x" + CW_LNight.toBE() + ", // CEFFECT_NIGHT -> void CWeather::LaunchNight(CWeather this<ecx>)");
	fp2.writeline("};\n");
	
	fp2.writeline("#define CGameMode_Initialize_EntryPtr (void*)0x" + exe.Raw2Rva(CI_Entry ).toBE(4) + ";");
	fp2.writeline("#define CGameMode_OnInit_EntryPtr (void*)0x"     + exe.Raw2Rva(CO_Entry ).toBE(4) + ";");
	fp2.writeline("void* CGameMode_Initialize_RetPtr = (void*)0x"   + exe.Raw2Rva(CI_Return).toBE(4) + ";");
	fp2.writeline("void* CGameMode_OnInit_RetPtr = (void*)0x"       + exe.Raw2Rva(CO_Return).toBE(4) + ";");

  fp2.writeline("\r\n#define GR_CLEAR " + (parseInt(gR_clrColor, 16)/4) + ";");
	fp2.close();
	
	return "MapEffect plugin for the loaded client has been generated in Output folder";
}