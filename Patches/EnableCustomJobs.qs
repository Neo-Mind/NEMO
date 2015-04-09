//--Globals--//
var Enders;
var Starters;
var EsiAddon;
var MaxJob = 4400;

function EnableCustomJobs() {
  
  //--- Find Starting Points of each table assignment---//
  //Step 1a - Get Offset of Reference strings. Swordsman's values used for Path and hand since code for novice changes too much.
  var refPath = exe.findString("검사", RVA);
  var refHand = exe.findString("검사\\검사", RVA);
  var refName = exe.findString("Novice", RVA);
  
  //Step 1b - Sanity check
  if (refPath === -1 || refHand === -1 || refName === -1)
    return "Failed in Part 1 - Reference String missing";
  
  //Step 1c - Find references of refPath - 3 should be there (job prefix, imf prefix, palette prefix)
  var template = " C7 AB 04 " + genVarHex(1); //MOV DWORD PTR DS:[reg32_A+4], OFFSET addr
  
  Starters = exe.findCodes(remVarHex(template, 1, refPath), PTYPE_HEX, true, "\xAB");
  if (Starters.length !== 3)
    return "Failed in Part 1 - less/more than 3 path references found";
  
  //Step 1d - Find reference of refHand
  Starters[3] = exe.findCode(remVarHex(template, 1, refHand), PTYPE_HEX, true, "\xAB");
  if (Starters[3] === -1)
    return "Failed in Part 1 - hand reference not found";
  
  //Step 1e - Find reference of refName
  Starters[4] = exe.findCode(" C7 AB" + refName.packToHex(4), PTYPE_HEX, true, "\xAB");
  if (Starters[4] === -1)
    return "Failed in Part 1 - name reference not found";
  
  Starters = Starters.sort(function(a, b){return a-b});
  
  //Step 1f - Extract ESI offsets
  EsiAddon = [];
  for (var i = 0; i < Starters.length-1; i++) {
    if (exe.fetchByte(Starters[i]-2) === 0)//Check if previous statement is a MOV reg32, DWORD PTR DS:[ESI+const]
      EsiAddon[i] = exe.fetchDWord(Starters[i]-4);
    else
      EsiAddon[i] = 0;
  }
  EsiAddon[4] = 0;
  
  //--- Find Ending points of each table assignment---//
  Enders = [];
  //Step 2a - Job Path = Index 0
  var nopOut = 3;
  var code = 
      " 8B 75 AB"          //MOV ESI, DWORD PTR SS:[LOCAL.4]
    + " C7 AB AB 04 00 00" //MOV DWORD PTR DS:[reg32_A+42*], OFFSET addr ; "peco_rebellion" or "frog_oboro"
    ;
  var offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[0], Starters[1]);
  
  if (offset === -1) {
    code = 
        " 8D AB AB AB 00 00" //LEA reg32_A, [ESI+const]
      + " C7 AB F8 03 00 00" //MOV DWORD PTR DS:[reg32_B+3F8], OFFSET addr
      ;
    nopOut = 6;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[0], Starters[1]);
  }
  
  if (offset === -1) {
    code = 
        " 8B AB AB AB 00 00" //MOV reg32_A, DWORD PTR DS:[ESI+const1]
      + " 8B AB AB AB 00 00" //MOV reg32_B, DWORD PTR DS:[ESI+const2]
      ;
    nopOut = false;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[0], Starters[1]);
  }
  
  if (offset === -1)
    return "Failed in Part 2 - Job Path end missing";
  
  if (nopOut)
    exe.replace(offset+nopOut, " 8D 40 00 8D 49 00 8D 5B 00 90", PTYPE_HEX);
  
  Enders[0] = offset;
  
  //Step 2b - Imf Path = Index 1
  nopOut = 6;
  code = 
      " 8D AB AB AB 00 00" //LEA reg32_A, [ESI+const]
    + " 89 AB 20 04 00 00" //MOV DWORD PTR DS:[reg32_B+420], reg32_C
    ;  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[1], Starters[2]);
  
  if (offset === -1) {
    code = 
        " C7 44 24 AB AB AB AB AB" //MOV DWORD PTR SS:[LOCAL.x], OFFSET addr
      + " 8B"                       //MOV reg32_A, DWORD PTR DS:[reg32_B+const]
      ;
    nopOut = false;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[1], Starters[2]);
  }
  
  if (offset === -1) {
    code = 
        " 8B AB AB AB 00 00" //MOV reg32_A, DWORD PTR DS:[ESI+const]
      + " C7 45"             //MOV DWORD PTR SS:[LOCAL.x], OFFSET addr
      ;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[1], Starters[2]);
  }
  
  if (offset === -1) {
    code = 
        " 8B 8E AB AB 00 00" //MOV ECX,DWORD PTR DS:[ESI+const1]
      + " 8B 96 AB AB 00 00" //MOV EDX,DWORD PTR DS:[ESI+const2]
      ;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[1], Starters[2]);
  }
  
  if (offset === -1)
    return "Failed in Part 2 - Imf Path end missing";
  
  if (nopOut)
    exe.replace(offset+nopOut, " 8D 40 00 8D 49 00", PTYPE_HEX);
  
  Enders[1] = offset;
  
  //Step 2c - Hand Path
  nopOut = false;
  code = 
      " 8B AB AB AB 00 00" //MOV reg32_A, DWORD PTR DS:[ESI+const1]
    + " 8B"                //MOV reg32_B, DWORD PTR DS:[ESI+const2]
    ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[2], Starters[3]);
  
  if (offset === -1)
    return "Failed in Part 2 - Hand Path end missing";
  
  Enders[2] = offset;
  
  //Step 2d - Pal Path
  nopOut = 6;
  code =
      " 8D AB AB AB 00 00" //LEA reg32_A, [ESI+const1]
    + " 89 AB 20 04 00 00" //MOV DWORD PTR DS:[reg32_B+const2], reg32_C
    ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[3], Starters[4]);
  
  if (offset === -1) {
    code = 
        " C7 44 24 AB AB AB AB AB" //MOV DWORD PTR SS:[LOCAL.x], OFFSET addr
      + " 8D"                      //LEA reg32_A, [ESI+const]
      ;
    nopOut = false;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[3], Starters[4]);
  }
    
  if (offset === -1) {
    code =
        " C7 45 AB AB AB AB AB" //MOV DWORD PTR SS:[LOCAL.x], OFFSET addr
      + " 8B"                   //MOV reg32_A, DWORD PTR DS:[ESI+const]
      ;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[3], Starters[4]);
  }
   
  if (offset === -1) {
    code = 
        " 8B AB AB AB 00 00" //MOV reg32_A, DWORD PTR DS:[ESI+const1]
      + " 8B AB AB AB 00 00" //MOV reg32_B, DWORD PTR DS:[ESI+const2]
      ;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", Starters[3], Starters[4]);
  }
  
  if (offset === -1)
    return "Failed in Part 2 - Pal Path end missing";
  
  if (nopOut)
    exe.replace(offset+nopOut, " 8D 40 00 8D 49 00", PTYPE_HEX);
  
  Enders[3] = offset;
  
  //Step 2e - Job Name
  code = 
      " BF 2D 00 00 00" //MOV EDI, 2D
    + " 83 CB FF"       //OR EBX, FFFFFFFFF
    ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB", Starters[4]);
  
  if (offset === -1) {
    code = 
        " 68 AB AB AB 00" //PUSH OFFSET addr
      + " 8D"             //LEA ECX, [LOCAL.x]
      ;
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB", Starters[4]);
  }
  
  if (offset === -1)
    return "Failed in Part 2 - Job Name end missing";
  
  Enders[4] = offset;
    
  //Step 4 - Insert Function Names into Client (to save space we will overwrite existing class names) ---//
  var ReqPath   = WriteString("Professor", "ReqPCPath");
  var MapPath   = WriteString("Blacksmith", "MapPCPath\x00");
  var ReqHand   = WriteString("Swordman High", "ReqPCHandPath");
  var MapHand   = WriteString("Magician High", "MapPCHandPath");
  var ReqImf    = WriteString("Swordman", "ReqPCImf");
  var MapImf    = WriteString("Assassin", "MapPCImf");
  var ReqPal    = WriteString("Magician", "ReqPCPal");
  var MapPal    = WriteString("Crusader", "MapPCPal");  
  var ReqName_M = WriteString("White Smith_W", "ReqPCJobName_M");
  var MapName_M = WriteString("High Wizard_W", "MapPCJobName_M");
  var ReqName_F = WriteString("High Priest_W", "ReqPCJobName_F");
  var MapName_F = WriteString("Lord Knight_W", "MapPCJobName_F");
  var GetHalter = WriteString("Alchemist", "GetHalter");
  var IsDwarf   = WriteString("Acolyte", "IsDwarf");
  
  //Step 5 - Get Lua Constants and Function addresses ---//
  GetLuaRefs();  
  
  //Step 6a - Build code for loading tables from lua and overwrite current mechanism with it ---//
  WriteLoader(0, "PCPath", ReqPath, MapPath);
  WriteLoader(1, "PCImf", ReqImf, MapImf);
  WriteLoader(2, "PCHandPath", ReqHand, MapHand);
  WriteLoader(3, "PCPal", ReqPal, MapPal);
  
  //Step 6b - For Job Name skip the loading now. The table will be loaded later based on Gender
  exe.replace(Starters[4], " E9" + (Enders[4] - (Starters[4] + 5)).packToHex(4), PTYPE_HEX);
  
  //--- Build Code to load required lua files and write it in the area after Job Name Lua calls above---//
  var loadStart = Starters[4] + 10; //free offset to use for writing Lua file loader code

  //Step 7a - Find NPCIdentity offset
  var npcIdent = exe.findString("Lua Files\\DataInfo\\NPCIdentity", RVA);
  if (npcIdent === -1)
    return "Failed in Part 3 - NPCIdentity missing";
  
  //Step 7b - Find its reference
  offset = exe.findCode(" 68" + npcIdent.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 7 - NPCIdentity reference missing";
  
  //Step 7c - Extract the common assignments for Lua file loading 
  //          MOV ECX, DS:[ESI+const] ; lua_state 
  //          followed by argument PUSHes before NPCIdentity PUSH
  
  var hookPoint = exe.find(" 8B 8E AB AB 00 00", PTYPE_HEX, true, "\xAB", offset - 10, offset);
  if (hookPoint === -1)
    return "Failed in Part 7 - Loading code has changed";
  
  var hookReturn = offset + 10;
  var preSize = offset - hookPoint;
  var preCode = exe.fetchHex(hookPoint, preSize);
  var luaLoader = offset + 10 + exe.fetchDWord(offset+6);
  
  //Step 7d - Find "Dark Collector". There are a lot of job names after it which makes it perfect place for what comes next
  offset = exe.findString("Dark Collector", RVA);
  if (offset === -1)
    return "Failed in Part 7 - Dark Collector missing";
  
  //Step 7e - Overwrite above with File name strings to be read
  var fileNames = [
    "Lua Files\\Admin\\PCIds\x00",
    "Lua Files\\Admin\\PCPaths\x00",
    "Lua Files\\Admin\\PCImfs\x00",
    "Lua Files\\Admin\\PCHands\x00",
    "Lua Files\\Admin\\PCPals\x00",
    "Lua Files\\Admin\\PCNames\x00",
    "Lua Files\\Admin\\PCFuncs\x00"
  ];
  
  exe.replace(exe.Rva2Raw(offset), fileNames.join("").toHex(), PTYPE_HEX);
  
  //Step 7f - Build up the code for each file
  var template =
      preCode
    + " 68" + genVarHex(1)
    + " E8" + genVarHex(2)
    ;
  var tmplSize = preSize + 10;
  
  var code = "";
  var diff = luaLoader - (loadStart + tmplSize);
  for (var i = 0; i < fileNames.length; i++) {
    code += remVarHex(template, [1,2], [offset, diff]);
    diff -= tmplSize;
    offset += fileNames[i].length;  
  }
  
  //Step 7g - Now add same for NPCIdentity and finish off with a returning JMP
  code += remVarHex(template, [1,2], [npcIdent, diff]);
  code += " E9" + ( hookReturn - (loadStart + (fileNames.length + 1) * tmplSize + 5)).packToHex(4);
  
  //Step 7h - Write into client
  exe.replace(loadStart, code, PTYPE_HEX);
  
  //Step 7i - Add Jump to Lua File loaders at hookPoint
  exe.replace(hookPoint, " E9" + (loadStart - (hookPoint+5)).packToHex(4), PTYPE_HEX);
  
  //--- Build Code for Loading Job Name table based on Gender
  //Step 8a - Location for adding
  //var femStart = loadStart + code.hexlength() + 4;//Leaving 4 byte extra gap
  
  //Step 8b - Find "TaeKwon Girl"
  var tg = exe.findString("TaeKwon Girl", RVA);
  if (tg === -1)
    return "Failed in Part 8 - TaeKwon Girl missing";
  
  //Step 8c - Find the reference
  code = 
      " 85 C0"                               //TEST EAX, EAX
    + " 75 11"                               //JNZ SHORT addr -> TaeKwon Boy assignment
    + " AB AB AB AB 00"                      //MOV EAX, DWORD PTR DS:[jobNameRef]
    + " C7 AB 38 3F 00 00" + tg.packToHex(4) //MOV DWORD PTR DS:[EAX+3F38], OFFSET addr; "TaeKwon Girl"
    ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");

  if (offset === -1) {
    code = 
        " 85 C0"                               //TEST EAX, EAX
      + " 75 12"                               //JNZ SHORT addr -> TaeKwon Boy assignment
      + " 8B AB AB AB AB 00"                   //MOV reg32, DWORD PTR DS:[jobNameRef] 
      + " C7 AB 38 3F 00 00" + tg.packToHex(4) //MOV DWORD PTR DS:[reg32+3F38], OFFSET addr; "TaeKwon Girl"
      ;
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Part 8 - TaeKwon Girl reference missing";
  
  //Step 8d - Extract the jobNameRef address
  var jobNameRef = exe.fetchHex(offset + code.hexlength() - 14, 4);
  
  //Step 8e - Check for the Langtype comparison.  
  var LANGTYPE = getLangType();
  if (LANGTYPE === -1)
    return "Failed in Part 8 - LangType not found";
  
  code = 
      " 83 3D" + LANGTYPE + " 00" //CMP DWORD PTR DS:[g_serviceType], 0
    + " B9 AB AB AB 00"           //MOV ECX, genderRef
    + " 75 59"                    //JNZ addr
    ;
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x80,offset);
  
  if (offset2 === -1) {
    code =
        " A1" + LANGTYPE  //MOV EAX, DWORD PTR DS:[g_serviceType] 
      + " B9 AB AB AB 00" //MOV ECX, genderRef
      + " 85 C0"          //TEST EAX, EAX
      + " 75 59"          //JNZ addr
      ;
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x80,offset);
  }
  
  if (offset2 === -1)
    return "Failed in Part 8 - LangType check not found";
  
  //Step 8f - Convert JNZ to JMP
  exe.replace(offset2 + code.hexlength() - 2, "EB", PTYPE_HEX);
  
  //Step 8g - Find the endpoint to jmp to after loading table - only for old clients
  code = 
      " A1" + LANGTYPE //MOV EAX, DWORD PTR DS:[g_serviceType] 
    + " 83 C4 10"      //ADD ESP, 10
    + " 83 F8 06"      //CMP EAX, 6
    ;
  var endpoint = exe.find(code, PTYPE_HEX, false, " ", offset+0x10, offset+0x1000);
  
  //Step 8f - Build code for selecting job name table loader
  code = 
      " 60"                //PUSHAD
    + " BE" + jobNameRef   //MOV ESI, jobNameRef
    + " 85 C0"             //TEST EAX, EAX
    + " 74 00"             //JNE SHORT addr1 to Female Job Name loading
    + " E9" + genVarHex(1) //JMP SHORT addr2 to Male Job Name loading
    + " 61"                //POPAD
    ;
    
  var jmpBack = offset + code.hexlength() - 1;
  
  if (endpoint === -1)
    code += " C3"; //RETN
  else
    code += " E9" + (endpoint - (offset + code.hexlength() + 4)).packToHex(4); //JMP endpoint
  
  //Step 8g - Build & Write loader for Female and Male (essentially a repeat but for the time being there is no choice)
  var femStart = offset + code.hexlength() + 4;
  var maleStart = femStart +
  WriteLoader(4, "PCJobName_F", ReqName_F, MapName_F, femStart, jmpBack);
  
  WriteLoader(4, "PCJobName_M", ReqName_M, MapName_M, maleStart, jmpBack);
  
  //Step 8h - Replace unknowns and insert the table selector code
  code = code.replaceAt(3*9, (femStart - (offset+10)).packToHex(1));
  code = remVarHex(code, 1, maleStart - (offset+15));

  exe.replace(offset, code, PTYPE_HEX);
 
  //--- Special Modification 1 = Cash Mount ---//
  //Step 9a - Find the function where the mount is checked
  code = 
      " 83 F8 19"        //CMP EAX, 19
    + " 75 AB"           //JNE SHORT addr -> next CMP
    + " B8 12 10 00 00"  //MOV EAX, 1012
    ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset !== -1) {
    //Step 9b - Calculate starting offset of the function
    if (exe.getClientDate() > 20130605)
      var mountBegin = offset-6;
    else
      var mountBegin = offset-4;
    
    //Step 9c - Build the replacement code using Lua functions
    code =
        " 55"       //PUSH EBP
      + " 8B EC"    //MOV EBP, ESP
      + " 51"       //PUSH ECX
      + " 52"       //PUSH EDX
      + " 57"       //PUSH EDI
      + " 83 EC 0C" //SUB ESP,0C
      + " 8B 7D 08" //MOV EDI,DWORD PTR SS:[EBP+8]
      ;
    code += GenLuaFnCall(mountBegin + code.hexlength(), false, false, "GetHalter".length, GetHalter);
    code +=
        " 8B 44 24 08" //MOV EAX,DWORD PTR SS:[ESP+8]
      + " 83 C4 0C"    //ADD ESP,0C    
      + " 5F"          //POP EDI
      + " 5A"          //POP EDX
      + " 59"          //POP ECX
      + " 5D"          //POP EBP
      + " C2 04 00"    //RETN 4
      ;
    
    //Step 9d - Overwrite with the built code.
    exe.replace(mountBegin, code, PTYPE_HEX);
  }
  
  //--- Special Modification 2 = Baby Jobs (Shrinking/Dwarfing) ---//
  //Step 10a - Find the function where Baby Jobs are checked. Pattern not found in old client - To Do
  code =
      " 3D B7 0F 00 00" //CMP EAX, 0FB7
    + " 7C AB"          //JL SHORT addr -> next CMP chain
    + " 3D BD 0F 00 00" //CMP EAX, 0FBD
    ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset !== -1) {
    //Step 10b - Calculate starting offset of function
    if (exe.getClientDate() > 20130605)
      var dwarfBegin = offset - 6;
    else
      var dwarfBegin = offset - 4;
    
    //Step 10c - Build the replacement code using Lua function
    code =
        " 55"       //PUSH EBP
      + " 8B EC"    //MOV EBP, ESP
      + " 57"       //PUSH EDI
      + " 83 EC 0C" //SUB ESP,0C
      + " 8B 7D 08" //MOV EDI,DWORD PTR SS:[EBP+8]
      ;
    code += GenLuaFnCall(dwarfBegin + code.hexlength(), false, false, "IsDwarf".length, IsDwarf);
    code +=
        " 8B 44 24 08" //MOV EAX,DWORD PTR SS:[ESP+8]
      + " 83 C4 0C"    //ADD ESP,0C    
      + " 5F"          //POP EDI
      + " 5D"          //POP EBP
      + " C2 04 00"    //RETN 4
      ;
    
    //Step 10d - Overwrite with the built code.
    exe.replace(dwarfBegin, code, PTYPE_HEX);
  }
  
  return true;
}

function WriteString(srcStr, tgtStr) {
  var offset = exe.findString(srcStr, RAW);
  if (offset !== -1)
    exe.replace(offset, tgtStr, PTYPE_STRING);
  
  return exe.Raw2Rva(offset);  
}

function WriteLoader(index, fnSuffix, reqAddr, mapAddr, insAddr, endAddr) {
  if (typeof(insAddr) === "undefined")
    insAddr = Starters[index];
  
  if (typeof(endAddr) === "undefined")
    endAddr = Enders[index];
  
  var isJobNameFn = (fnSuffix.indexOf("Name") !== -1);
  
  if (isJobNameFn) {
    thirdStart = 4001;
    allEnd = MaxJob;
  }
  else {
    thirdStart = 4001 - 3950;
    allEnd = MaxJob - 3950;
  }
    
  var code = " 83 EC 0C"; // SUB ESP, 0C
  code += GenLuaFnCall(insAddr + code.hexlength(), true , false, 3+fnSuffix.length, reqAddr, 0, 0x2C, EsiAddon[index]);
  code += GenLuaFnCall(insAddr + code.hexlength(), true , false, 3+fnSuffix.length, reqAddr, thirdStart, allEnd, EsiAddon[index]);
  code += GenLuaFnCall(insAddr + code.hexlength(), false, true, 3+fnSuffix.length, mapAddr, 0, 0x2C, EsiAddon[index]);
  code += GenLuaFnCall(insAddr + code.hexlength(), false, true, 3+fnSuffix.length, mapAddr, thirdStart, allEnd, EsiAddon[index]);
  code +=
      " 83 C4 0C" // ADD ESP, 0C
    + " E9" + (endAddr - (insAddr + code.hexlength() + 8)).packToHex(4) // JMP addr2 -> outside table allocation
    ;
  exe.replace(insAddr, code, PTYPE_HEX);
  return code.hexlength();
}