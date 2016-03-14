//######################################################################################
//# Purpose : Modify the Aura setting code inside CPlayer::ReLaunchBlurEffects to CALL #
//#           custom function which sets up aura based on user specified limits        #
//######################################################################################

function CustomAuraLimits() {
  
  //Step 1a - Find the 2 value PUSHes before ReLaunchBlurEffects is called.
  var code =
    " 68 4E 01 00 00" //PUSH 14E
  + " 6A 6D"          //PUSH 6D
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - Value PUSHes missing";
  
  offset += code.hexlength();
  
  //Step 1b - Find the call below it
  code =
    " 8B AB AB 00 00 00" //MOV reg32_A, DWORD PTR DS:[reg32_B+const]
  + " 8B AB AB"          //MOV ECX, DWORD PTR DS:[reg32_A+const2]
  + " E8 AB AB AB 00"    //CALL CPlayer::ReLaunchBlurEffects
  ;
  
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x100);
  if (offset2 === -1)
    return "Failed in Step 1 - ReLaunchBlurEffects call missing";
  
  offset2 += code.hexlength();
  
  //Step 1c - Extract the RAW address of ReLaunchBlurEffects
  offset = offset2 + exe.fetchDWord(offset2 - 4);
  
  //Step 2a - Find the first JE inside the function
  offset = exe.find(" 0F 84 AB AB 00 00", PTYPE_HEX, true, "\xAB", offset, offset + 0x80);
  if (offset === -1)
    return "Failed in Step 2 - First JE missing";
  
  //Step 2b - Save the Raw location 
  var cmpEnd = (offset + 6) + exe.fetchDWord(offset + 2);
  
  //Step 2c - Find PUSH 2E2 after it (only there in 2010+)
  offset = exe.find(" 68 E2 02 00 00", PTYPE_HEX, false, "", offset + 6, offset + 0x100);
  if (offset === -1)
    return "Failed in Step 2 - 2E2 push missing";
  
  //Step 2d - Now find the JE after it
  offset = exe.find(" 0F 84 AB AB 00 00", PTYPE_HEX, true, "\xAB", offset + 5, offset + 0x80);
  if (offset === -1)
    return "Failed in Step 2 - JE missing";
  
  //Step 2e - Save the Raw location
  var cmpBegin = (offset + 6) + exe.fetchDWord(offset + 2);
  
  //---------------------------------------------------------------------
  // Now we Check for the comparison style. 
  //   Old Clients directly compare there itself.
  //   New Clients do it in a seperate function (by New i mean 2013+)
  //---------------------------------------------------------------------
  
  if (exe.fetchUByte(cmpBegin) === 0xB9) {//MOV ECX, g_session ; Old Style
  
    var directComparison = true;
  
    //Step 3a - Extract g_session and job Id getter addresses
    var gSession = exe.fetchDWord(cmpBegin + 1);
    var jobIdFunc = exe.Raw2Rva(cmpBegin + 10) + exe.fetchDWord(cmpBegin + 6);
    
    //Step 3b - Find the Level address comparison
    code = " A1 AB AB AB 00"; //MOV EAX, DWORD PTR DS:[g_level] ; EAX is later compared with 96
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", cmpBegin, cmpBegin + 0x20);
  
    if (offset === -1) {
      code = " 81 3D AB AB AB 00"; //CMP DWORD PTR DS:[g_level], 96
      offset = exe.find(code, PTYPE_HEX, true, "\xAB", cmpBegin, cmpBegin + 0x80);
    }
  
    if (offset === -1)
      return "Failed in Step 3 - Level Comparison missing";
    
    offset += code.hexlength();
    
    //Step 3c - Extract g_level address
    var gLevel = exe.fetchDWord(offset - 4);
    
    //Step 3d - Find the Aura Displayer Call (its a reg call so dunno the name of the function)
    code = 
      " 6A AB" //PUSH auraconst
    + " 6A 00" //PUSH 0
    + " 8B CE" //MOV ECX, ESI
    + " FF"    //CALL reg32 or CALL DWORD PTR DS:[reg32+8]
    ;
    var argPush = "\x6A\x00";
    var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x20);
    
    if (offset2 === -1) {
      code = code.replace("6A 00", "AB");//swap PUSH 0 with PUSH reg32_B
      argPush = "";
      offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x20);
    }
    
    if (offset2 === -1)
      return "Failed in Step 3 - Aura Call missing";
    
    if (argPush === "")
      argPush = exe.fetch(offset2 + 2, 1);
    
    //Step 3e - Extract the auraconst
    var gAura = [exe.fetchHex(offset2 + 1, 1)];
    gAura[1] = gAura[2] = gAura[0];//Same value is used for All Auras - and therefore shows only 1 type of aura per job
    
    //Step 3f - Extract the Zero PUSH count
    var argCount = argPush.length;
    argPush = exe.fetchHex(offset2 - 4 * argCount, 4 * argCount);

    if (argPush.substr(0, 3 * argCount) === argPush.substr(9 * argCount))//First and Last is same means there are actually 4 PUSHes
      argCount = 4;
    else
      argCount = 3;
    
    //Step 3g - Setup ZeroAssign
    var zeroAssign = " EB 08 8D 24 24 8D 6D 00 89 C0"; //JMP and some Dummy operations
  }
  else {//MOV reg16, WORD PTR DS:[g_level] ; New Style - comparisons are done inside a seperate function
  
    var directComparison = false;
  
    //Step 4a - Extract g_level address
    var gLevel = exe.fetchDWord(cmpBegin + 3);
    
    //Step 4b - Find the comparison function call
    offset = exe.find(" E8 AB AB AB FF", PTYPE_HEX, true, "\xAB", cmpBegin, cmpBegin + 0x30);
    if (offset === -1)
      return "Failed in Step 4 - Function call missing";
    
    //Step 4c - Go inside the function
    offset = (offset + 5) + exe.fetchDWord(offset + 1);
    
    //Step 4d - Find g_session assignment
    code =
      " E8 AB AB AB AB" //CALL jobIdFunc
    + " 50"             //PUSH EAX
    + " B9 AB AB AB 00" //MOV ECX, g_session
    + " E8"             //CALL addr
    ;

    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x20);
    if (offset === -1)
      return "Failed in Step 4 - g_session reference missing";
    
    //Step 4e - Extract job Id getter address (we dont need the gSession for this one)
    var jobIdFunc = exe.Raw2Rva(offset + 5) + exe.fetchDWord(offset + 1);
    
    //Step 4f - Find the Zero assignment at the end of the function
    code = " C7 86 AB AB 00 00 00 00 00 00"; //MOV DWORD PTR DS:[ESI + const], 0
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x180);
    if (offset === -1)
      return "Failed in Step 4 - Zero assignment missing";
    
    //Step 4g - Save it (only needed for new types)
    var zeroAssign = exe.fetchHex(offset, code.hexlength());
    
    //Step 4h - Setup the Aura constants and Arg count
    var argCount = 4;
    var gAura = [" 7D", " 93", " 92"];
  }
  
  //Step 5a - Get the input file
  var fp = new TextFile();
  var inpFile = GetInputFile(fp, "$auraSpec", "File Input - Custom Aura Limits", "Enter the Aura Spec file", APP_PATH + "/Input/auraSpec.txt");
  if (!inpFile)
    return "Patch Cancelled";
  
  //Step 5b - Load the ID and Level Limits to a table
  var idLvlTable = [];
  var tblSize = 0;
  var index = -1;
  
  while (!fp.eof()) {
    var line = fp.readline().trim();
    if (line === "") continue;
    
    if (matches = line.match(/^([\d\-,\s]+):$/)) {
      index++;
      var idSet = matches[1].split(",");
      idLvlTable[index] = {
        "idTable":"", 
        "lvlTable":""
      };
      
      if (index > 0) {
        idLvlTable[index-1].lvlTable += " FF FF";
        tblSize += 2;
      }
      
      for (var i = 0; i < idSet.length; i++) {
        var limits = idSet[i].split("-");
        if (limits.length === 1)
          limits[1] = limits[0];
        
        idLvlTable[index].idTable += parseInt(limits[0]).packToHex(2) 
        idLvlTable[index].idTable += parseInt(limits[1]).packToHex(2);
        tblSize += 4;
      }
      
      idLvlTable[index].idTable += " FF FF";
      tblSize += 2; 
    }
    else if (matches = line.match(/^([\d\-\s]+)\s*=>\s*(\d)\s*,/)) {
      var limits = matches[1].split("-");
      
      idLvlTable[index].lvlTable += parseInt(limits[0]).packToHex(2);
      idLvlTable[index].lvlTable += parseInt(limits[1]).packToHex(2);
      idLvlTable[index].lvlTable += gAura[parseInt(matches[2])-1];
      tblSize += 5;
    }
  }
  fp.close();
  
  if (index >= 0) {
    idLvlTable[index].lvlTable += " FF FF";
    tblSize += 2;
  }
  
  //Step 6a - Prep code for comparison
  code =
    " 56"                     //PUSH ESI
  + " 89 CE"                  //MOV ESI, ECX
  + " 52"                     //PUSH EDX
  + " 53"                     //PUSH EBX
  + " B9" + GenVarHex(1)      //MOV ECX, g_session
  + " E8" + GenVarHex(2)      //CALL jobIdFunc
  + " BB" + GenVarHex(3)      //MOV EBX, tblAddr
  + " 8B 0B"                  //MOV ECX, DWORD PTR DS:[EBX];	addr6
  + " 85 C9"                  //TEST ECX, ECX
  + " 74 49"                  //JE SHORT addr1
  + " 0F BF 11"               //MOVSX EDX, WORD PTR DS:[ECX];	addr5
  + " 85 D2"                  //TEST EDX, EDX
  + " 78 15"                  //JS SHORT addr2
  + " 39 D0"                  //CMP EAX, EDX
  + " 7C 0C"                  //JL SHORT addr3
  + " 0F BF 51 02"            //MOVSX EDX, WORD PTR DS:[ECX+2]
  + " 85 D2"                  //TEST EDX,EDX
  + " 78 09"                  //JS SHORT addr2
  + " 39 D0"                  //CMP EAX,EDX
  + " 7E 0A"                  //JLE SHORT addr4
  + " 83 C1 04"               //ADD ECX, 4;	addr3
  + " EB E4"                  //JMP SHORT addr5
  + " 83 C3 08"               //ADD EBX, 8;	addr2
  + " EB D9"                  //JMP SHORT addr6
  + " A1" + GenVarHex(4)      //MOV EAX, DWORD PTR DS:[g_level];	addr4
  + " 8B 4B 04"               //MOV ECX, DWORD PTR DS:[EBX+4]
  + " 85 C9"                  //TEST ECX, ECX
  + " 74 1C"                  //JE SHORT addr1
  + " 0F BF 11"               //MOVSX EDX, WORD PTR DS:[ECX];	addr9
  + " 85 D2"                  //TEST EDX, EDX
  + " 78 15"                  //JS SHORT addr1
  + " 39 D0"                  //CMP EAX, EDX
  + " 7C 0C"                  //JL SHORT addr7
  + " 0F BF 51 02"            //MOVSX EDX, WORD PTR DS:[ECX+2]
  + " 85 D2"                  //TEST EDX, EDX
  + " 78 09"                  //JS SHORT addr1
  + " 39 D0"                  //CMP EAX, EDX
  + " 7E 14"                  //JLE SHORT addr8
  + " 83 C1 05"               //ADD ECX, 5;	addr7
  + " EB E4"                  //JMP SHORT addr9
  + " 5B"                     //POP EBX; addr1
  + " 5A"                     //POP EDX
  + zeroAssign                //MOV DWORD PTR DS:[ESI+const], 0 (or Dummy)
  + " 5E"                     //POP ESI
  + " C3"                     //RETN
  + " 90"                     //NOP
  + " 5B"                     //POP EBX; addr8
  + " 5A"                     //POP EDX
  + " 6A 00".repeat(argCount) //PUSH 0
                              //PUSH 0
                              //PUSH 0
                              //PUSH 0 - May or may not be there
  + " 0F B6 49 04"            //MOVZX ECX,BYTE PTR DS:[ECX+4]; addr8
  + " 51"                     //PUSH ECX
  + " 6A 00"                  //PUSH 0
  + " 8B 06"                  //MOV EAX,DWORD PTR DS:[ESI]
  + " 8B CE"                  //MOV ECX,ESI
  + " FF 50 08"               //CALL DWORD PTR DS:[EAX+8]
  + " 5E"                     //POP ESI
  + " C3"                     //RETN
  ;
  
  if (!directComparison)
    code = code.replace(" B9" + GenVarHex(1), " 90 90 90 90 90");

  //Step 6b - Allocate space for it
  var size = code.hexlength() + 8 * idLvlTable.length + 4 + tblSize;
  var free = exe.findZeros(size);
  if (free === -1)
    return "Failed in Step 6 - Not enough free space";
  
  var freeRva = exe.Raw2Rva(free);
  
  //Step 6c - Fill in the blanks
  code = ReplaceVarHex(code, 1, gSession);
  code = ReplaceVarHex(code, 2, jobIdFunc - (freeRva + 15));
  code = ReplaceVarHex(code, 3, freeRva + code.hexlength());
  code = ReplaceVarHex(code, 4, gLevel);
  
  //Step 6d - Construct the table pointers & limits to insert
  var tblAddrData = "";
  var tblData = "";
  for (var i = 0, addr = size - tblSize; i < idLvlTable.length; i++) {
    tblAddrData += (freeRva + addr).packToHex(4);
    tblData += idLvlTable[i].idTable;
    addr += idLvlTable[i].idTable.hexlength();
    
    tblAddrData += (freeRva + addr).packToHex(4);
    tblData += idLvlTable[i].lvlTable;
    addr += idLvlTable[i].lvlTable.hexlength();
  }

  //Step 7a - Insert the function and table data
  exe.insert(free, size, code + tblAddrData + " 00 00 00 00" + tblData, PTYPE_HEX);
  
  if (directComparison) {

  //Step 7b - Since there was no existing Function CALL, We add a CALL to our function after ECX assignment
    code =
      " 8B CE" //MOV ECX, ESI
    + " E8" + (freeRva - exe.Raw2Rva(cmpBegin + 7)).packToHex(4) //CALL func
    + " EB" + (cmpEnd - (cmpBegin + 9)).packToHex(1) //JMP SHORT cmpEnd
    ;
    
    exe.replace(cmpBegin, code, PTYPE_HEX);
  }
  else {
    //Step 7c - Find the function call... again and replace it with a CALL to our Function
    offset = exe.find(" E8 AB AB AB FF", PTYPE_HEX, true, "\xAB", cmpBegin, cmpBegin + 0x30);
    exe.replaceDWord(offset + 1, freeRva - exe.Raw2Rva(offset + 5));
    
    offset += 5;
    
    //Step 7d - Fill with NOPs till cmpEnd
    if (offset < cmpEnd)
      exe.replace(offset, " 90".repeat(cmpEnd - offset), PTYPE_HEX);
  }
  
  return true;
}