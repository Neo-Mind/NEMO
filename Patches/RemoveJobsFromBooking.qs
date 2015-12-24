//########################################################################
//# Purpose: Hijack the MsgStr function call inside the Booking OnCreate #
//#          function which loads comboboxes for testing the ID against  #
//#          our list and skip iteration if present.                     #
//########################################################################

function RemoveJobsFromBooking() {
  
  //Step 1a - Find the MsgStr call used for Job Name loading.
  var code =
    " 8D AB 5D 06 00 00" //LEA reg32_A, [reg32_B + 65D]
  + " 03 AB"             //ADD reg32_B, reg32_C
  + " 89 AB AB"          //MOV DWORD PTR SS:[EBP-const1], reg32_A
  + " 89 AB AB"          //MOV DWORD PTR SS:[EBP-const2], reg32_B
  + " 8B AB AB"          //MOV EAX, DWORD PTR SS:[EBP-const1]
  + " 50"                //PUSH EAX
  + " E8"                //CALL MsgStr
  ;
  var type = 1; //VC6
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code =
      " 8D 49 00"          //LEA ECX, [ECX]
    + " 8D AB 5D 06 00 00" //LEA reg32_A, [reg32_B + 65D]
    + " AB"                //PUSH reg32_A
    + " E8"                //CALL MsgStr
    ;
    type = 2; //VC9 & VC11
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1) {
    code =
      " 8B AB AB"          //MOV reg32_A, DWORD PTR SS:[EBP-const]
    + " 81 AB 5D 06 00 00" //ADD reg32_A, 65D
    + " AB"                //PUSH reg32_A
    + " E8"                //CALL MsgStr
    ;
    type = 3; //VC10
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1a - Loop Beginning missing";

  offset += code.hexlength();
  
  //Step 1b - Extract the MsgStr address
  var MsgStr = exe.Raw2Rva(offset + 4) + exe.fetchDWord(offset);
  
  //Step 1c - Get Pattern for finding end of the loop (We need to RETN to location before Loop counter increment which is what jmpOff is for)
  switch (type) {
    case 1: {
      code =
        " 83 C4 04"          //ADD ESP, 4
      + " 8B AB AB"          //MOV reg32_A, DWORD PTR SS:[EBP-const1]
      + " 8B AB AB"          //MOV reg32_B, DWORD PTR SS:[EBP-const2]
      + " AB"                //INC reg32_A
      + " AB"                //INC reg32_B
      + " 89 AB AB"          //MOV DWORD PTR SS:[EBP-const3],reg32_C
      + " 89 AB AB"          //MOV DWORD PTR SS:[EBP-const4],reg32_C
      + " 89 AB AB"          //MOV DWORD PTR SS:[EBP-const5],reg32_C
      + " 89 AB AB"          //MOV DWORD PTR SS:[EBP-const1],reg32_A
      + " 89 AB AB"          //MOV DWORD PTR SS:[EBP-const2],reg32_B
      + " 0F 85 AB FF FF FF" //JNZ addr
      ;
      var jmpOff = 3;
      break;
    }
    
    case 2: {
      if (exe.getClientDate() < 20140000) {//VC9
        code =
          " FF 15 AB AB AB 00" //CALL DWORD PTR DS:[<&MSVCP#.$basic*>]
        + " AB"                //INC reg32_A
        + " 83 6C 24 AB 01"    //SUB DWORD PTR SS:[ESP+const], 1
        + " 75"                //JNZ SHORT addr
        ;
        var jmpOff = 6;
      }
      else {//VC11
        code =
          " 83 C4 04"             //ADD ESP, 4
        + " AB"                   //INC reg32_A
        + " C7 45 AB 0F 00 00 00" //MOV DWORD PTR SS:[EBP-const1], 0F
        + " C7 45 AB 00 00 00 00" //MOV DWORD PTR SS:[EBP-const2], 0
        + " C6 45 AB 00"          //MOV BYTE PTR SS:[EBP-const3], 0
        + " AB"                   //DEC reg32_B
        + " 0F 85 AB FF FF FF"    //JNZ addr
        ;
        var jmpOff = 3;
      }
      break;
    }
    case 3: {//VC10
      code =
        " AB 01 00 00 00"       //MOV reg32_A, 1
      + " 01 AB AB"             //ADD DWORD PTR SS:[EBP-const1], reg32_A
      + " 29 AB AB"             //SUB DWORD PTR SS:[EBP-const2], reg32_A
      + " C7 45 AB AB 00 00 00" //MOV DWORD PTR SS:[EBP-const3], 0F
      + " 89 AB AB"             //MOV DWORD PTR SS:[EBP-const4], reg32_B
      + " 88 AB AB"             //MOV BYTE PTR SS:[EBP-const5], reg8_B
      + " 75"                   //JNZ SHORT addr
      ;
      var jmpOff = 0;
      break;
    }
  }

  //Step 1d - Find the pattern 
  var retAddr = exe.findCode(code, PTYPE_HEX, true, "\xAB", offset + 5, offset + 0x100);
  if (retAddr === -1)
    return "Failed in Step 1b - Loop End missing";
  
  //Step 1e - Get RVA of location to RETN to.
  retAddr = exe.Raw2Rva(retAddr + jmpOff);
  
  //Step 2a - Get the Skip List file from User
  var fp = new TextFile();
  var inpFile = GetInputFile(fp, "$bookingList", "File Input - Remove Jobs From Booking", "Enter the Booking Skip List file", APP_PATH + "/Input/bookingSkipList.txt");
  if (!inpFile)
    return "Patch Cancelled";
  
  //Step 2b - Extract all the IDs from List file to an Array
  var idSet = [];
  while (!fp.eof()) {
    var line = fp.readline().trim();
    if (line.match(/^\d+/)) {
      var id = parseInt(line);
      if (id < 0x65D) continue;
      idSet.push(id.packToHex(2));
    }
  }
  fp.close();
  
  //Step 2c - Add NULL at end of the Array
  idSet.push(" 00 00");

  //Step 3a - Prep code for our function to check the ID  
  code =
    " 50"                //PUSH EAX
  + " 51"                //PUSH ECX
  + " 52"                //PUSH EDX
  + " 8B 44 24 10"       //MOV EAX, DWORD PTR SS:[ESP+10]; Arg0
  + " 40"                //INC EAX ; Needed because the ids start from 0
  + " B9" + GenVarHex(1) //MOV ECX, listaddr
  + " 0F B7 11"          //MOVZX EDX, WORD PTR DS:[ECX] ; addr3
  + " 85 D2"             //TEST EDX, EDX
  + " 74 08"             //JE SHORT addr1
  + " 39 D0"             //CMP EAX, EDX
  + " 74 0C"             //JE SHORT addr2
  + " 41"                //INC ECX
  + " 41"                //INC ECX
  + " EB F1"             //JMP SHORT addr3
  + " 5A"                //POP EDX
  + " 59"                //POP ECX
  + " 58"                //POP EAX
  + " E9" + GenVarHex(2) //JMP MsgStr
  + " 5A"                //POP EDX
  + " 59"                //POP ECX
  + " 58"                //POP EAX
  + " 83 C4 08"          //ADD ESP, 8
  + " 68" + GenVarHex(3) //PUSH retAddr
  + " C3"                //RETN
  ;
  
  //Step 3b - Allocate space for the IDs and the Function
  var size = idSet.length * 2 + code.hexlength();
  var free = exe.findZeros(size);
  if (free === -1)
    return "Failed in Step 3 - Not enough free space"
  
  var freeRva = exe.Raw2Rva(free);
  
  //Step 3c - Fill in the blanks
  code = ReplaceVarHex(code, 1, freeRva);
  code = ReplaceVarHex(code, 2, MsgStr - (freeRva + size - 12));
  code = ReplaceVarHex(code, 3, retAddr);
  
  //Step 4a - Insert the data and function in Allocated space
  exe.insert(free, size, idSet.join("") + code, PTYPE_HEX);

  //Step 4b - Change the MsgStr CALL with a CALL to our function.
  exe.replaceDWord(offset, (freeRva + idSet.length * 2) - exe.Raw2Rva(offset + 4));
  
  return true;
}