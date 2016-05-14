//##############################################################################
//# Purpose: Change the Hardcoded loading of Job tables (name, path prefix,    #
//#          hand prefix, palette prefix and imf prefix) to use Lua functions. #
//#                                                                            #
//#          Also modify the sprite size checker and Cash Mount retrieval      #
//#          codes to use Lua Functions.                                       #   
//##############################################################################

MaxJob = 4400;
function EnableCustomJobs() {//Pre-VC9 Client support not completed
  
  //===============================//
  // Find all the inject locations //
  //===============================//
  
  //Step 1a - Get address of reference strings . (Pattern for Archer seems to be stable across clients hence we will use it)
  var refPath = exe.findString("\xB1\xC3\xBC\xF6", RVA); // ±Ã¼ö for Archer. Same value is used for palette as well as imf
  if (refPath === -1)
    return "Failed in Step 1 - Path prefix missing";
  
  var refHand = exe.findString("\xB1\xC3\xBC\xF6\\\xB1\xC3\xBC\xF6", RVA); // ±Ã¼ö\±Ã¼ö for Archer
  if (refHand === -1)
    return "Failed in Step 1 - Hand prefix missing";
  
  var refName = exe.findString("Acolyte", RVA);//We use Acolyte here because Archer has a MOV ECX, OFFSET statement before it in Older clients
  if (refName === -1)
    return "Failed in Step 1 - Name prefix missing";
  
  
  //Step 1b - Find all references of refPath
  var hooks = exe.findCodes("C7 AB 0C" + refPath.packToHex(4), PTYPE_HEX, true, "\xAB");
  var assigner;//std::vector[] function used in Older clients

  if (hooks.length === 2) {
    //Step 1c - Look for old style assignment following a call to std::vector[] - For Older clients
    var offset = exe.findCode(" C7 00" + refPath.packToHex(4) + " E8", PTYPE_HEX, false);
    if (offset === -1)
      return "Failed in Step 1 - Palette reference is missing";
    
    //Step 1d - Extract the function address (RAW)
    assigner = (offset + 11) + exe.fetchDWord(offset + 7);
    
    //Step 1e - Hook Location will be 4 bytes before at PUSH 4
    hooks[2] = offset - 4;

    //Step 1f - Little trick to change the PUSH 3 to PUSH 0 so that EAX will point to the first location like we need   
    offset = exe.find(" 6A 03", PTYPE_HEX, false, "", hooks[2] - 0x12, hooks[2]);
    exe.replace(offset + 1, "00", PTYPE_HEX);
  }
  if (hooks.length !== 3)
    return "Failed in Step 1 - Prefix reference missing or extra";
  
  //Step 1g - Find reference of refHand
  var offset = exe.findCode("C7 AB 0C" + refHand.packToHex(4), PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1 - Hand reference missing";
  
  hooks[3] = offset;
  
  //Step 1h - Find reference of refName
  offset = exe.findCode("C7 AB 10" + refName.packToHex(4), PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1 - Name reference missing";
  
  hooks[4] = offset;
  
  //===============================================================//
  // Extract/Calculate all the required info for all the locations //
  //===============================================================//
  
  //Step 2a - Get the LangType address
  var LANGTYPE = GetLangType();
  if (LANGTYPE.length === 1)
    return "Failed in Step 2 - " + LANGTYPE[0];
  
  var details = [];
  var curRegs = [];
  
  for (var i = 0; i < hooks.length; i++) {
    
    //Step 2b - Extract the reference Register (usually ESI), reference Offset and current Register for all hooks from the instruction before each
    //          MOV curReg, DWORD PTR DS:[refReg + refOff]
    //          curReg can also be extracted from code at hook location
    
    if (exe.fetchByte(hooks[i] - 2) === 0) {//refOff != 0
      var modrm  = exe.fetchByte(hooks[i] - 5);
      var refOff = exe.fetchDWord(hooks[i] - 4);
    }
    else if (exe.fetchByte(hooks[i]) === 0x6A) {//Older client
      var modrm  = 0x6;//so that refReg will be ESI and curReg will be EAX
      var refOff = 0;
    }
    else {//refOff = 0
      var modrm  = exe.fetchByte(hooks[i] - 1);
      var refOff = 0;
    }
    var refReg = modrm & 0x7;
    curRegs[i] = (modrm & 0x38) >> 3;
    
    //Step 2c - Find Location after the Table assignments which is the location to jump to after lua based loading
    //          Also extract all non-table related instuctions in between
    details[i] = FetchTillEnd(hooks[i], refReg, refOff, curRegs[i], LANGTYPE, CheckEoT, assigner);
  }

  //====================================//
  // Add Function Names & Table Loaders //
  //====================================//
  
  //Step 3 - Insert Lua Function Names into client (Since we wont be using the hardcoded JobNames we will overwrite suitable ones)
  var Funcs = [];
  
  Funcs[0]  = OverwriteString("Professor",     "ReqPCPath");
  Funcs[1]  = OverwriteString("Blacksmith",    "MapPCPath\x00");
  Funcs[2]  = OverwriteString("Swordman",      "ReqPCImf");
  Funcs[3]  = OverwriteString("Assassin",      "MapPCImf");
  Funcs[4]  = OverwriteString("Magician",      "ReqPCPal");
  Funcs[5]  = OverwriteString("Crusader",      "MapPCPal");  
  Funcs[6]  = OverwriteString("Swordman High", "ReqPCHandPath");
  Funcs[7]  = OverwriteString("Magician High", "MapPCHandPath");
  Funcs[8]  = OverwriteString("White Smith_W", "ReqPCJobName_M");
  Funcs[9]  = OverwriteString("High Wizard_W", "MapPCJobName_M");
  Funcs[10] = OverwriteString("High Priest_W", "ReqPCJobName_F");
  Funcs[11] = OverwriteString("Lord Knight_W", "MapPCJobName_F");
  Funcs[12] = OverwriteString("Alchemist",     "GetHalter");
  Funcs[13] = OverwriteString("Acolyte",       "IsDwarf");
  
  //Step 4a - Write the Loader into client for Path, Imf, Weapon and Palette
  WriteLoader(hooks[0], curRegs[0], "PCPath"    , Funcs[0], Funcs[1], details[0].endOff, details[0].code);
  WriteLoader(hooks[1], curRegs[1], "PCImf"     , Funcs[2], Funcs[3], details[1].endOff, details[1].code);
  WriteLoader(hooks[2], curRegs[2], "PCPal"     , Funcs[4], Funcs[5], details[2].endOff, details[2].code);
  WriteLoader(hooks[3], curRegs[3], "PCHandPath", Funcs[6], Funcs[7], details[3].endOff, details[3].code);
  
  //Step 4b - For Jobname we will simply add the extracted code and jmp to endOff instead of loading now
  //          to avoid repetitive loading (happens again when gender is checked)
  var code =
    details[4].code
  + " E9";
  
  code += (details[4].endOff - (hooks[4] + code.hexlength() + 4)).packToHex(4);
  
  exe.replace(hooks[4], code, PTYPE_HEX);
  
  //Step 4c - Update hook location to address after the JMP
  hooks[4] += code.hexlength();
  
  //================================================================//
  // Find Gender based Name assignment & Extract/Calculate all info //
  //================================================================//
  
  //Step 5a - Find address of 'TaeKwon Girl'
  offset = exe.findString("TaeKwon Girl", RVA);
  if (offset === -1)
    return "Failed in Step 5 - 'TaeKwon Girl' missing";
  
  //Step 5b - Find its reference - this is where we will jump out and start loading the table
  code =
    " 85 C0"                                   //TEST EAX, EAX
  + " 75 AB"                                   //JNZ SHORT addr -> TaeKwon Boy assignment
  + " A1 AB AB AB 00"                          //MOV EAX, DWORD PTR DS:[g_jobName]
  + " C7 AB 38 3F 00 00" + offset.packToHex(4) //MOV DWORD PTR DS:[EAX+3F38], OFFSET addr; ASCII "TaeKwon Girl"
  ;
  var gJobName = 5;
  var offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");//VC9 Clients

  if (offset2 === -1) {//Older clients
    code = code.replace(" A1", " 8B AB");//Change EAX to reg32_A and update the JNZ
    gJobName = 6;
    offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset2 === -1) {//Latest Clients
    code =
      " 85 C0"                    //TEST EAX, EAX
    + " A1 AB AB AB 00"           //MOV EAX, DWORD PTR DS:[g_jobName]
    + " AB" + offset.packToHex(4) //MOV reg32_A, OFFSET addr; ASCII "TaeKwon Girl"
    ;
    gJobName = 3;
    offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset2 === -1)
    return "Failed in Step 5 - 'TaeKwon Girl' reference missing";
  
  //Step 5c - Extract the g_jobName address
  gJobName = exe.fetchDWord(offset2 + gJobName);
  
  //Step 5d - Look for the LangType comparison before offset2 (in fact the JNZ should jump to a call after which we do the above TEST)
  //          Steps 5d and 5e are also done in TranslateClient but we will keep it anyways as a failsafe
  code =
    " 83 3D" + LANGTYPE + " 00" //CMP DWORD PTR DS:[g_serviceType], 00
  + " B9 AB AB AB 00"           //MOV ECX, g_session
  + " 75"                       //JNE SHORT addr -> CALL CSession::GetSex
  ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x80, offset2);
  
  if (offset === -1) {
    code = code.replace(" 83 3D", " A1").replace(" 00 B9 AB AB AB 00 75", " B9 AB AB AB 00 85 C0 75");//Change the CMP to MOV EAX, DWORD PTR DS:[g_serviceType] and insert TEST EAX, EAX before JNZ
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x80, offset2);
  }

  if (offset === -1)
    return "Failed in Step 5 - LangType comparison missing";
  
  //Step 5e - Change the JNE to JMP
  exe.replace(offset + code.hexlength() - 1, "EB", PTYPE_HEX)
  
  offset = offset2;
  
  //Step 5f - Find the LangType comparison with 0C, 5 & 6 after offset 
  code =
    " 83 F8 0C" //CMP EAX, 0C
  + " 74 0E"    //JE SHORT addr
  + " 83 F8 05" //CMP EAX, 5
  + " 74 09"    //JE SHORT addr
  + " 83 F8 06" //CMP EAX, 6
  + " 0F 85"    //JNE addr2
  ;
  
  offset2 = exe.find(code, PTYPE_HEX, false, " ", offset + 0x10, offset + 0x100);
  if (offset2 === -1)
    return "Failed in Step 5 - 2nd LangType comparison missing";
  
  //Step 5g - Extract any Register Pushes before the Comparison - This is needed since they are restored at the end of the function
  var push1 = exe.fetchUByte(offset2 - 1);
  if (push1 < 0x50 || push1 > 0x57)
    push1 = 0x90;
  
  var push2 = exe.fetchUByte(offset2 - 2);
  if (push2 < 0x50 || push2 > 0x57)
    push2 = 0x90;
  
  if (push2 === 0x90 && push1 === 0x90) //Recent client does PUSH ESI somewhat earlier hence we dont detect any
    push1 = 0x56;
    
  offset2 += code.hexlength();
  offset2 += 4 + exe.fetchDWord(offset2);
  
  //Step 5h - Change the CMP to NOP and JNE to JMP as shown below at The JNE address
  //A1 <LANGTYPE> ; MOV EAX, DWORD PTR DS:[g_serviceType]
  //83 F8 0A    => push2 push1 90
  //0F 85 addr  => 90 E9 addr
  exe.replace(offset2, push2.packToHex(1) + push1.packToHex(1) + " 90 90 E9", PTYPE_HEX);

  //Step 5h - Point offset2 to the MOV EAX before the CMP
  offset2 -= 5;
  
  //======================//
  // Add Job Name Loaders //
  //======================//
  
  //Step 6a - Build the gender test
  code =
    " 85 C0"                //TEST EAX, EAX
  + " 0F 85" + GenVarHex(1) //JNE addr1 -> Male Job Name Loading 
  ;
  
  var csize = code.hexlength();
  
  //Step 6b - Write the Female Job Name Loader below
  csize += WriteLoader(offset + csize, gJobName, "PCJobName_F", Funcs[10], Funcs[11], offset2, "").hexlength();
  
  //Step 6c - Write the Male Job Name Loader below 
  WriteLoader(offset + csize, gJobName, "PCJobName_M", Funcs[8], Funcs[9], offset2, "");
  
  //Step 6d - Replace the variable in code (since we know where addr1 is now)
  code = ReplaceVarHex(code, 1, csize - code.hexlength());
  
  //Step 6e - Add it to client
  exe.replace(offset, code, PTYPE_HEX);
  
  //=========================//
  // Inject Lua file loading //
  //=========================//
  
  var retVal = InjectLuaFiles(
    "Lua Files\\DataInfo\\NPCIdentity", 
    [
      "Lua Files\\Admin\\PCIds",
      "Lua Files\\Admin\\PCPaths",
      "Lua Files\\Admin\\PCImfs",
      "Lua Files\\Admin\\PCHands",
      "Lua Files\\Admin\\PCPals",
      "Lua Files\\Admin\\PCNames",
      "Lua Files\\Admin\\PCFuncs"
    ],
    hooks[4]
  );
  if (typeof(retVal) === "string")
    return retVal;
  
  var fpEnb = HasFramePointer();
  
  //============================//
  // Special Mod 1 : Cash Mount //
  //============================//
 
  //Step 7a - Find the function where the Cash Mount Job ID is assigned
  code =
    " 83 F8 19"        //CMP EAX, 19
  + " 75 AB"           //JNE SHORT addr -> next CMP
  + " B8 12 10 00 00"  //MOV EAX, 1012
  ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset !== -1) {
    //Step 7b - Build the replacement code using GetHalter Lua function
    code = 
      " 52" //PUSH EDX
    + GenLuaCaller(offset + 1, "GetHalter", Funcs[12], "d>d", " 50")
    + " 5A" //POP EDX
    ;
    
    if (fpEnb)
      code += " 5D";     //POP EBP
    
    code += " C2 04 00"; //RETN 4
    
    //Step 7c - Replace at offset
    exe.replace(offset, code, PTYPE_HEX);
  }
  
  //================================================//
  // Special Mod 2 : Baby Jobs (Shrinking/Dwarfing) //
  //================================================//
  
  //Step 8a - Find Function where Baby Jobs are checked (missing in old client)
  if (fpEnb) {
    code = " 8B AB 08";    //MOV reg32_A, DWORD PTR SS:[EBP+8]
    csize = 3;
  }
  else {
    code = " 8B AB 24 04"; //MOV reg32_A, DWORD PTR SS:[ESP+4]
    csize = 4;
  }
  
  code +=
    " 3D B7 0F 00 00" //CMP EAX, 0FB7
  + " 7C AB"          //JL SHORT addr -> next CMP chain
  + " 3D BD 0F 00 00" //CMP EAX, 0FBD
  ;
  offset2 = " 50"; //Don't mind the var name
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(/ 3D/g, " 81 AB");//Change EAX with reg32_A
    offset2 = "";
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset !== -1) {
    offset += csize;
    //Step 8b - Get the PUSH register in case it is not EAX
    if (offset2 === "")
      offset2 = (0x50 + (exe.fetchByte(offset + 1) & 0x7)).packToHex(1);
    
    //Step 8c - Build the replacement code using IsDwarf Lua function
    code = 
      " 52" //PUSH EDX
    + GenLuaCaller(offset + 1, "IsDwarf", Funcs[13], "d>d", offset2)
    + " 5A" //POP EDX
    ;
    
    if (fpEnb)
      code += " 5D";     //POP EBP
    
    code += " C2 04 00"; //RETN 4
    
    //Step 8d - Replace at offset
    exe.replace(offset, code, PTYPE_HEX);
  }
  
  return true;
}

//###############################################################
//# Purpose: Check whether End of Table has been reached at the #
//#          supplied offset. Used as argument to FetchTillEnd  #
//###############################################################

function CheckEoT(opcode, modrm, offset, details, assigner) {
  if (typeof(assigner) === "undefined")
    assigner = -1;
  
  //SUB reg32_A, reg32_B
  //SAR reg32_A, 2
  if (opcode === 0x2B && exe.fetchUByte(offset + 2) === 0xC1 && exe.fetchUByte(offset + 4) === 0x02 )
    return true;
  
  //PUSH 524C
  if (opcode === 0x68 && exe.fetchDWord(offset + 1) === 0x524C)
    return true;
  
  //PUSH EAX
  //PUSH 2 or PUSH 5
  if (opcode === 0x50 && modrm === 0x6A && (exe.fetchByte(offset + 2) === 0x02 || exe.fetchByte(offset + 2) === 0x05))
    return true;

  
  //CALL func; where func !== assigner
  if (opcode === 0xE8 && (assigner === -1 || details.tgtImm !== (assigner - (offset + 5))) )
    return true;
  
  //MOV EAX, DWORD PTR DS:[EDI+4]
  if (opcode === 0x8B && modrm === 0x47 && details.tgtImm === 0x4)//Hope this doesnt conflict any point later
    return true;

  //CALL DWORD PTR DS:[addr]
  if (opcode === 0xFF && modrm === 0x15)//Hope this doesnt conflict with any other client
    return true;
    
  //OR reg32_A, FFFFFFFF
  if (opcode === 0x83 && (modrm & 0xF8) === 0xC8 && exe.fetchUByte(offset + 2) === 0xFF)
    return true;
  
  //MOV EDI, EDI
  if (opcode === 0x8B && modrm === 0xFF)
    return true;
  
  //MOV EDI, 2D - deprecated since MOV EDI, EDI doesn't leave out any stray assignments
  //if (opcode === 0xBF && exe.fetchDWord(offset + 1) === 0x2D)
  //  return true;
  
  return false;
}

//###################################################################
//# Purpose: Find address of srcString, overwrite it with tgtString #
//#          and return it (RVA)                                    #
//###################################################################

function OverwriteString(srcString, tgtString) {
  //Step 1 - Find address
  var offset = exe.findString(srcString, RAW);
  
  //Step 2a - Overwrite it
  exe.replace(offset, tgtString, PTYPE_STRING);
  
  //Step 2b - Return the RVA of offset
  return exe.Raw2Rva(offset);
}

//########################################################################
//# Purpose: Overwrite code at hook with Lua function based table loader #
//########################################################################
function WriteLoader(hookLoc, curReg, suffix, reqAddr, mapAddr, jmpLoc, extraData) {

  //Step 1 - Setup all arrays we will be using   
  var prefixes = [];//Two prefixes for two range of Jobs
  var templates = [];//Two templates one for Req functions and other for Map functions
  var fnNames = ["Req" + suffix, "Map" + suffix]; // - do -
  var fnAddrs = [reqAddr, mapAddr]; // - do -
  var argFormats = ["d>s", "d>d"]; // - do -
  
  prefixes[0] =
    " 33 FF"          //XOR EDI, EDI
  + " BB 2C 00 00 00" //MOV EBX, 2C
  ;
  
  if (suffix.indexOf("Name") !== -1) {
    prefixes[1] = 
      " 90"
    + " BF A1 0F 00 00"           //MOV EDI, 0xFA1;//4001
    + " BB" + MaxJob.packToHex(4) //MOV EBX, MaxJob
    ;
  }
  else {
    prefixes[1] =
      " 90"
    + " BF 33 00 00 00"                    //MOV EDI, 0x33;//4001 - 3950
    + " BB" + (MaxJob - 3950).packToHex(4) //MOV EBX, MaxJob-3950
    ;
  }
  
  templates[0] = 
    " PrepVars"
  + " GenCaller"
  + " 85 C0"          //TEST EAX, EAX
  + " 74 12"          //JE SHORT addr2
  + " 8A 08"          //MOV CL, BYTE PTR DS:[EAX]
  + " 84 C9"          //TEST CL, CL
  + " 74 07"          //JE SHORT addr
  + " 8B 4C 24 20"    //MOV ECX, DWORD PTR SS:[ESP+20]
  + " 89 04 B9"       //MOV DWORD PTR DS:[EDI*4+ECX], EAX
  + " 47"             //INC EDI; addr
  + " 39 DF"          //CMP EDI,EBX
  + " 7E ToGenCaller" //JLE SHORT addr2; to start of generate
  ;
  
  templates[1] = 
    " PrepVars"
  + " GenCaller"
  + " 85 C0"          //TEST EAX,EAX
  + " 78 0A"          //JS SHORT addr
  + " 8B 4C 24 20"    //MOV ECX, DWORD PTR SS:[ESP+20]
  + " 8B 04 81"       //MOV EAX, DWORD PTR DS:[EAX*4+ECX]
  + " 89 04 B9"       //MOV DWORD PTR DS:[EDI*4+ECX], EAX
  + " 47"             //INC EDI; addr
  + " 39 DF"          //CMP EDI, EBX
  + " 7E ToGenCaller" //JLE SHORT addr2; to start of generate
  ;

  //Step 2a - Push the register containing first element and save all registers
  if (curReg > 7)
    var code = " FF 35" + curReg.packToHex(4); //PUSH OFFSET curReg
  else
    var code = (0x50 + curReg).packToHex(1);//PUSH reg32_A; reg32_A points to the location of first element of the tablell 
  
  code += " 60";                            //PUSHAD
  
  //Step 2b - Now for each template fill in the blanks with corresponding prefix and GenLuaCaller code
  for (var i = 0; i < templates.length; i++) {
    for (var j = 0; j < prefixes.length; j++) {
      var coff = code.hexlength() + prefixes[j].hexlength(); //relative offset from hookLoc
      
      code += templates[i].replace(" PrepVars", prefixes[j]); //Change PrepVars to the actual prefix
      code = code.replace(" GenCaller", GenLuaCaller(hookLoc + coff, fnNames[i], fnAddrs[i], argFormats[i], " 57")); //Change GenCaller with generated code
      
      code = code.replace(" ToGenCaller", "");//Remove ToGenCaller and 
      code += (coff - (code.hexlength() + 1)).packToHex(1);//put the actual JLE distance
    }
  }
  
  //Step 2c - Add the finishing touches. 
  //          Restore registers, Add the extracted code, Jump to jmpLoc or RETN
  code += 
    " 61"       //POPAD
  + " 83 C4 04" //ADD ESP, 4
  + extraData
  ;
  
  if (jmpLoc !== -1)
    code += " E9" + (jmpLoc - (hookLoc + code.hexlength() + 5)).packToHex(4); //JMP jmpLoc
  else
    code += " C3"; //RETN
  
  exe.replace(hookLoc, code, PTYPE_HEX);
  
  return code;
}
