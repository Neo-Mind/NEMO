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
  ////////////////////////////////////////////////////////////////
  // GOAL: Override the data.grf loading with a custom function //
  //       that reads file names from an ini file and loads all //
  //       of them in order.                                    //
  ////////////////////////////////////////////////////////////////
  
  //Step 1a - Find data.grf location
  var grf = exe.findString("data.grf", RVA).packToHex(4);
  
  //Step 1b - Find its reference
  var code =
      " 68" + grf       // PUSH OFFSET addr1; "data.grf"
    + " B9 AB AB AB 00" // MOV ECX, OFFSET g_fileMgr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2a - Extract the g_FileMgr assignment
  var setECX = exe.fetchHex(offset+5, 5);
    
  //Step 2b - Find the AddPak call after the push 
  code =
      " E8 AB AB AB AB"    // CALL CFileMgr::AddPak()
    + " 8B AB AB AB AB 00" // MOV reg32, DWORD PTR DS:[addr1]
    + " A1 AB AB AB 00"    // MOV EAX, DWORD PTR DS:[addr2]
    ;

  var fnoffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10);
  if (fnoffset === -1) {
    code =
        " E8 AB AB AB AB" // CALL CFileMgr::AddPak()
      + " A1 AB AB AB 00" // MOV EAX, DWORD PTR DS:[addr2]
      ;

    fnoffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10);
  }
  if (fnoffset === -1)
    return "Failed in part 2";
  
  //Step 2c - Extract AddPak function address
  var AddPak = exe.Raw2Rva(fnoffset + 5) + exe.fetchDWord(fnoffset + 1);
  
  //Step 3a - Prep code for reading INI file and loading GRFs
  var code =
        " C8 80 00 00"       // ENTER 80, 0
      + " 60"                // PUSHAD
      + " 68" + genVarHex(1)    // PUSH addr1 ; "KERNEL32" => genVarHex(1)
      + " FF 15" + genVarHex(2) // CALL DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>] ; genVarHex(2) 
      + " 85 C0"             // TEST EAX, EAX
      + " 74 23"             // JZ SHORT addr2
      + " 8B 3D" + genVarHex(3) // MOV EDI,DWORD PTR DS:[<&KERNEL32.GetProcAddress>] ; genVarHex(3)
      + " 68" + genVarHex(4)    // PUSH addr3 ; "GetPrivateProfileStringA" => genVarHex(4)
      + " 89 C3"             // MOV EBX, EAX
      + " 50"                // PUSH EAX ; hModule
      + " FF D7"             // CALL EDI ; GetProcAddress()
      + " 85 C0"             // TEST EAX, EAX
      + " 74 0F"             // JZ SHORT addr2
      + " 89 45 F6"          // MOV DWORD PTR SS:[EBP-0A], EAX
      + " 68" + genVarHex(5)    // PUSH addr4 ; "WritePrivateProfileStringA" => genVarHex(5)
      + " 89 D8"             // MOV EAX, EBX
      + " 50"                // PUSH EAX ; hModule
      + " FF D7"             // CALL EDI ; GetProcAddress() 
      + " 85 C0"             // TEST EAX, EAX
      + " 74 6E"             // JZ SHORT loc_735E71
      + " 89 45 FA"          // MOV DWORD PTR SS:[EBP-6], EAX
      + " 31 D2"             // XOR EDX, EDX
      + " 66 C7 45 FE 39 00" // MOV DWORD PTR SS:[EBP-2], 39 ; char 9
      + " 52"                // PUSH EDX
      + " 68" + genVarHex(6)    // PUSH addr5 ; INI filename => genVarHex(6)
      + " 6A 74"             // PUSH 74
      + " 8D 5D 81"          // LEA EBX, [EBP-7F]
      + " 53"                // PUSH EBX
      + " 8D 45 FE"          // LEA EAX, [EBP-2]
      + " 50"                // PUSH EAX
      + " 50"                // PUSH EAX
      + " 68" + genVarHex(7)    // PUSH addr6 ; "Data" => genVarHex(7)
      + " FF 55 F6"          // CALL DWORD PTR SS:[EBP-0A]
      + " 8D 4D FE"          // LEA ECX, [EBP-2]
      + " 66 8B 09"          // MOV CX, WORD PTR DS:[ECX]
      + " 8D 5D 81"          // LEA EBX, [EBP-7F]
      + " 66 3B 0B"          // CMP CX, WORD PTR DS:[EBX]
      + " 5A"                // POP EDX
      + " 74 0E"             // JZ SHORT addr7
      + " 52"                // PUSH EDX
      + " 53"                // PUSH EBX
      +   setECX             // MOV ECX, g_fileMgr
      + " E8" + genVarHex(8)    // CALL CFileMgr::AddPak() ; genVarHex(8)
      + " 5A"                // POP EDX
      + " 42"                // INC EDX
      + " FE 4D FE"          // DEC BYTE PTR SS:[EBP-2]
      + " 80 7D FE 30"       // CMP BYTE PTR SS:[EBP-2], 30
      + " 73 C1"             // JNB SHORT addr8
      + " 85 D2"             // TEST EDX, EDX
      + " 75 20"             // JNZ SHORT addr9
      + " 68" + genVarHex(9)    // PUSH addr10 ; INI filename => genVarHex(9)
      + " 68" + grf          // push addr11 ; "data.grf"
      + " 66 C7 45 FE 32 00" // MOV DWORD PTR SS:[EBP-2], 32
      + " 8D 45 FE"          // LEA EAX, [EBP-2]
      + " 50"                // PUSH EAX
      + " 68" + genVarHex(10)   // PUSH addr12 ; "Data" => genVarHex(10)
      + " FF 55 FA"          // CALL DWORD PTR SS:[EBP-6]
      + " 85 C0"             // TEST EAX, EAX
      + " 75 97"             // JNZ SHORT 
      + " 61"                // POPAD
      + " C9"                // LEAVE
      + " C3 00"             // RETN
      ;
  
  //Step 4 - Get the INI file name from user
  var iniFile = exe.getUserInput("$dataINI", XTYPE_STRING, "String Input", "Enter the name of the INI file", "DATA.INI", 1, 20);
  if (iniFile === "")
    iniFile = ".\\DATA.INI";
  else
    iniFile = ".\\" + iniFile;
  
  //Step 5a - Put all the strings in an array
  var strings = ["KERNEL32", "GetPrivateProfileStringA", "WritePrivateProfileStringA", "Data", iniFile];
  
  //Step 5b - Calculate size of free space that the code & strings will need
  var size = code.hexlength();
  for (var i=0; strings[i]; i++) {
    size = size + strings[i].length + 1;//1 for NULL
  }  
  
  //Step 5c - Find free space to inject our code
  var free = exe.findZeros(size+4);
  if (free === -1)
    return "Failed in part 3: Not enough free space";

  var freeRva = exe.Raw2Rva(free);

  //Step 5d - Create a call to the free space that was found before
  exe.replace(offset, " B9", PTYPE_HEX);//Little trick to avoid changing 10 bytes - apparently the push gets nullified in the original
  exe.replaceDWord(fnoffset + 1, freeRva - exe.Raw2Rva(fnoffset + 5));
  
  //Step 5e - Replace the variables used in code
  var memPosition = freeRva + code.hexlength();
  code = remVarHex(code, 1, memPosition);//KERNEL32  
  code = remVarHex(code, 2, exe.findFunction("GetModuleHandleA"));
  code = remVarHex(code, 3, exe.findFunction("GetProcAddress"));
  
  memPosition = memPosition + strings[0].length + 1;//1 for null
  code = remVarHex(code, 4, memPosition);//GetPrivateProfileStringA
  
  memPosition = memPosition + strings[1].length + 1;//1 for null
  code = remVarHex(code, 5, memPosition);//WritePrivateProfileStringA

  memPosition = memPosition + strings[2].length + 1;//1 for null
  code = remVarHex(code, 7, memPosition);//INI file
  code = remVarHex(code, 10, memPosition);//INI file
  
  memPosition = memPosition + strings[3].length + 1;//1 for null
  code = remVarHex(code, 6, memPosition);//Data
  code = remVarHex(code, 9, memPosition);//Data
   
  code = remVarHex(code, 8, (AddPak - (freeRva + 115) - 5));//AddPak function
  
  //Step 5f - Add the strings into our code as well
  for (var i=0; strings[i]; i++) {
    code = code + strings[i].toHex() + " 00";
  }
  code = code + " 00".repeat(8);
  
  //Step 6 - Finally, insert everything.
  exe.insert(free, size+4, code, PTYPE_HEX);
  
  return true;
}

// 26.11.2010 - Organized DiffPatch into a working state for vc9 compiled clients [Yom]
// 12.10.2010 - The complete diff would take 247+9+14 = 264 bytes.
//              Note that if you are using k3dt"s diff patcher, you have to use 2.30
//              since 2.31 and all before have a limit of 255 byte changes. [Shinryo]
