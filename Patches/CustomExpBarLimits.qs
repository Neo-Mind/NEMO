//###############################################################################
//# Purpose: Modify the Exp Bar Displayer code inside UIBasicInfoWnd::NewHeight #
//#          to display Job & Base Exp Bars based on user specified limits      #
//###############################################################################

function CustomExpBarLimits() {
  
  //Step 1a - Find the reference PUSHes (coord PUSHes ?)
  var code =
    " 6A 4E"          //PUSH 4E
  + " 68 38 FF FF FF" //PUSH -0C8
  ;
  
  var refOffsets = exe.findCodes(code, PTYPE_HEX, false);
  if (refOffsets.length === 0)
    return "Failed in Step 1 - Reference PUSHes missing";
  
  //Step 1b - Find the Job ID getter before the first reference
  code =
    " B9 AB AB AB 00" //MOV ECX, OFFSET g_session
  + " E8 AB AB AB 00" //CALL CSession::jobIdFunc
  + " 50"             //PUSH EAX
  + " B9 AB AB AB 00" //MOV ECX, OFFSET g_session
  + " E8 AB AB AB 00" //CALL CSession::isThirdJob
  
  var suffix = 
    " 85 C0"          //TEST EAX, EAX
  + " A1 AB AB AB 00" //MOV EAX, DWORD PTR DS:[g_level]
  + " BF 63 00 00 00" //MOV EDI, 63
  ;
  var type = 1;//VC6 style
  var offset = exe.find(code + suffix, PTYPE_HEX, true, "\xAB", refOffsets[0] - 0x120, refOffsets[0]);
  
  if (offset === -1) {
    suffix =
      " 8B 8E AB 00 00 00" //MOV ECX, DWORD PTR DS:[ESI+const]
    + " BF 63 00 00 00"    //MOV EDI, 63 
    + " 85 C0"             //TEST EAX, EAX
    ;
    type = 2;//VC9 style 1
    offset = exe.find(code + suffix, PTYPE_HEX, true, "\xAB", refOffsets[0] - 0x120, refOffsets[0]);
  }
  
  if (offset === -1) {
    suffix = suffix.replace(" 8B 8E AB 00 00 00", "");
    type = 3;//VC9 style 2
    offset = exe.find(code + suffix, PTYPE_HEX, true, "\xAB", refOffsets[0] - 0x120, refOffsets[0]);
  }

  if (offset === -1)
    return "Failed in Step 1 - Comparison setup missing";

  //Step 1c - Extract g_session, jobIdFunc and save the offset to baseBegin variable  
  var gSession = exe.fetchDWord(offset + 1);
  var jobIdFunc = exe.Raw2Rva(offset + 10) + exe.fetchDWord(offset + 6);
  var baseBegin = offset;
  
  offset += code.hexlength() + suffix.hexlength();
  
  //Step 1d - Extract the base level comparison (for VC9+ clients we need to find the comparison after offset)
  if (type === 1) {
    var gLevel = exe.fetchDWord(offset - 9);
  }
  else {
    var offset2 = exe.find(" 81 3D AB AB AB 00 AB 00 00 00", PTYPE_HEX, true, "\xAB", offset, refOffsets[0]); //CMP DWORD PTR DS:[g_level], value
    
    if (offset2 === -1)
      offset2 = exe.find(" 39 3D AB AB AB 00 75", PTYPE_HEX, true, "\xAB", offset, refOffsets[0]);//CMP DWORD PTR DS:[g_level], EDI
    
    if (offset2 === -1)
      return "Failed in Step 1 - First comparison missing";

    var gLevel = exe.fetchDWord(offset2 + 2);
  }
  
  //Step 2a - Find the ESI+const movement to ECX between baseBegin and first reference offset
  offset = exe.find(" 8B 8E AB 00 00 00", PTYPE_HEX, true, "\xAB", baseBegin, refOffsets[0]);//MOV ECX, DWORD PTR DS:[ESI+const]
  if (offset === -1)
    return "Failed in Step 2 - First ESI Offset missing";

  //Step 2b - Extract the gNoBase and calculate other two
  var gNoBase = exe.fetchDWord(offset + 2);
  var gNoJob = gNoBase + 4;
  var gBarOn = gNoBase + 8;
  
  //Step 2c - Extract ESI offset and baseEnd
  if (exe.fetchUByte(refOffsets[1] + 8) >= 0xD0) {
    var funcOff = exe.fetchByte(refOffsets[1] - 1);
    var baseEnd = (refOffsets[1] + 11) + exe.fetchByte(refOffsets[1] + 10);
  }
  else {
    var funcOff = exe.fetchByte(refOffsets[1] + 9);
    var baseEnd = (refOffsets[1] + 12) + exe.fetchByte(refOffsets[1] + 11);
  }
  
  //Step 2d - jobBegin is same as baseEnd
  var jobBegin = baseEnd;
  
  //Step 3a - Find the PUSHes for Job Exp bar
  code =
    " 6A 58"          //PUSH 58
  + " 68 38 FF FF FF" //PUSH -0C8
  ;
  
  var refOffsets2 = exe.findAll(code, PTYPE_HEX, true, "\xAB", jobBegin, jobBegin + 0x120);
  if (refOffsets2.length === 0)
    return "Failed in Step 3 - 2nd Reference PUSHes missing";
  
  //Step 3b - Find jobEnd (JMP after the last PUSH will lead to jobEnd)
  offset = refOffsets2[refOffsets2.length - 1] + code.hexlength();
  
  if (exe.fetchUByte(offset) === 0xEB) {
    offset = (offset + 2) + exe.fetchByte(offset + 1);
  }
  
  if (exe.fetchUByte(offset + 1) >= 0xD0) {//FF D0 (CALL reg) or FF 5# 1# CALL DWORD PTR DS:[reg + 1#]
    var jobEnd = offset + 2;
  }
  else {
    var jobEnd = offset + 3;
  }

  //Step 3c - Find g_jobLevel reference between the 2nd reference set  
  code = " 83 3D AB AB AB 00 0A"; //CMP DWORD PTR DS:[g_jobLevel], 0A
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffsets2[0], refOffsets2[refOffsets2.length - 1]);
  if (offset === -1)
    return "Failed in Step 3 - g_jobLevel reference missing";
  
  //Step 3d - Extract g_jobLevel
  var gJobLevel = exe.fetchDWord(offset + 2);
 
  //Step 4a - Get the input file
  var fp = new TextFile();
  var inpFile = GetInputFile(fp, "$expBarSpec", "File Input - Custom Exp Bar Limits", "Enter the Exp Bar Spec file", APP_PATH + "/Input/expBarSpec.txt");
  if (!inpFile)
    return "Patch Cancelled";

  //Step 4b - Extract table from the file  
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
        "lvlTable":[" FF 00", " FF 00"]
      };
      
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
    else if (matches = line.match(/^([bj])\s*=>\s*(\d+)\s*,/)) {
      var limit = parseInt(matches[2]).packToHex(2);
      
      if (matches[1] === "b") {
        idLvlTable[index].lvlTable[0] = limit;
      }
      else {
        idLvlTable[index].lvlTable[1] = limit;
      }
    }
  }
  fp.close();
  
  //Step 5a - Prep code to replace at baseBegin
  code =
    " 52"                     //PUSH EDX
  + " 53"                     //PUSH EBX
  + " B9" + GenVarHex(1)      //MOV ECX, g_session
  + " E8" + GenVarHex(2)      //CALL CSession::jobIdFunc
  + " BB" + GenVarHex(3)      //MOV EBX, tblAddr
  + " 8B 0B"                  //MOV ECX, DWORD PTR DS:[EBX];	addr6
  + " 85 C9"                  //TEST ECX, ECX
  + " 74 26"                  //JE SHORT addr1
  + " 0F BF 11"               //MOVSX EDX, WORD PTR DS:[ECX];	addr5
  + " 85 D2"                  //TEST EDX, EDX
  + " 78 15"                  //JS SHORT addr2
  + " 39 D0"                  //CMP EAX, EDX
  + " 7C 0C"                  //JL SHORT addr3
  + " 0F BF 51 02"            //MOVSX EDX, WORD PTR DS:[ECX+2]
  + " 85 D2"                  //TEST EDX, EDX
  + " 78 09"                  //JS SHORT addr2
  + " 39 D0"                  //CMP EAX, EDX
  + " 7E 0A"                  //JLE SHORT addr4
  + " 83 C1 04"               //ADD ECX, 4;	addr3
  + " EB E4"                  //JMP SHORT addr5
  + " 83 C3 08"               //ADD EBX, 8;	addr2
  + " EB D9"                  //JMP SHORT addr6
  + " 8D 7B 04"               //LEA EDI, [EBX+4]; addr4
  + " EB 05"                  //JMP SHORT addr7
  + " BF" + GenVarHex(4)      //MOV EDI, OFFSET defAddr; addr1
  + " 5B"                     //POP EBX; addr7
  + " 5A"                     //POP EDX
  + " 0F B7 07"               //MOVZX EAX, WORD PTR DS:[EDI]
  + " 39 05" + GenVarHex(5)   //CMP DWORD PTR DS:[g_level], EAX
  + " 8B 8E" + GenVarHex(6)   //MOV ECX, DWORD PTR DS:[ESI + gNoBase]
  + " 7C 09"                  //JL SHORT addr8
  + " 6A 4E"                  //PUSH 4E
  + " 68 38 FF FF FF"         //PUSH -0C8
  + " EB 0C"                  //JMP SHORT addr9
  + " 8B 86" + GenVarHex(7)   //MOV EAX, DWORD PTR DS:[ESI + gBarOn]; addr8
  + " 83 C0 4C"               //ADD EAX, 4C
  + " 50"                     //PUSH EAX
  + " 6A 55"                  //PUSH 55
  + " 8B 01"                  //MOV EAX, DWORD PTR DS:[ECX]; addr9
  + " FF 50 XX"               //CALL DWORD PTR DS:[EAX + funcOff]
  + " 0F B7 47 02"            //MOVZX EAX, WORD PTR DS:[EDI+2]
  + " 39 05" + GenVarHex(8)   //CMP DWORD PTR DS:[g_jobLevel], EAX
  + " 8B 8E" + GenVarHex(9)   //MOV ECX, DWORD PTR DS:[ESI + gNoJob]
  + " 7C 09"                  //JL SHORT addr10
  + " 6A 58"                  //PUSH 58
  + " 68 38 FF FF FF"         //PUSH -0C8
  + " EB 0C"                  //JMP SHORT addr11
  + " 8B 86" + GenVarHex(10)  //MOV EAX, DWORD PTR DS:[ESI + gBarOn]; addr10
  + " 83 C0 58"               //ADD EAX, 58
  + " 50"                     //PUSH EAX
  + " 6A 55"                  //PUSH 55
  + " 8B 01"                  //MOV EAX, DWORD PTR DS:[ECX]; addr11
  + " FF 50 XX"               //CALL DWORD PTR DS:[EAX + funcOff]
  + " E9" + GenVarHex(11)     //JMP jobEnd
  ;
  
  //Step 5b - Allocate space for the table to use in the above code
  var free = exe.findZeros(tblSize);
  if (free === -1)
    return "Failed in Step 5 - Not enough free space";
  
  //Step 5c - Setup tblAddr
  var freeRva = exe.Raw2Rva(free);
  var tblAddr = baseBegin + code.hexlength() + 4;
  
  //Step 5d - Fill in the blanks
  code = code.replace(/ XX/g, funcOff.packToHex(1));
  
  code = ReplaceVarHex(code, 1, gSession);
  code = ReplaceVarHex(code, 2, jobIdFunc - exe.Raw2Rva(baseBegin + 12));
  
  code = ReplaceVarHex(code, 3, exe.Raw2Rva(tblAddr));
  code = ReplaceVarHex(code, 4, exe.Raw2Rva(tblAddr - 4));//defAddr = tblAddr - 4
  
  code = ReplaceVarHex(code, 5, gLevel);
  code = ReplaceVarHex(code, [6,7] , [gNoBase, gBarOn]);
  
  code = ReplaceVarHex(code, 8, gJobLevel);
  code = ReplaceVarHex(code, [9,10], [gNoJob , gBarOn]);
 
  code = ReplaceVarHex(code, 11, jobEnd - (baseBegin + code.hexlength()));
  
  //Step 6a - Construct the table pointers & limits to insert
  var tblAddrData = "";
  var tblData = "";
  
  for (var i = 0, addr = 0; i < idLvlTable.length; i++) {
    tblAddrData += (freeRva + addr).packToHex(4);
    tblData += idLvlTable[i].idTable;
    addr += idLvlTable[i].idTable.hexlength();
    
    tblAddrData += idLvlTable[i].lvlTable.join("");    
  }
  
  //Step 6b - Replace the function at baseBegin
  exe.replace(baseBegin, code + " FF 00 FF 00" + tblAddrData, PTYPE_HEX);
  
  //Step 6c - Insert the table at allocated location.
  exe.insert(free, tblSize, tblData, PTYPE_HEX);
  
  return true;
}