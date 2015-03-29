function EnableDNSSupport() {
  ///////////////////////////////////////////////////////////
  // GOAL: Modify the code before reading g_accountAddr to //
  //       call our DNS resolution function which replaces //
  //       g_accountAddr value                             //
  ///////////////////////////////////////////////////////////

  //To do - For old clients search patterns differs slightly
  
  // Step 1a - Find the code to hook our function to
  var code =
      " E8 AB AB AB FF" // CALL g_resMgr                 
    + " 8B C8"          // MOV ECX,EAX                   
    + " E8 AB AB AB FF" // CALL CResMgr::Get             
    + " 50"             // PUSH EAX                      
    + " B9 AB AB AB 00" // MOV ECX,OFFSET g_windowMgr    
    + " E8 AB AB AB FF" // CALL UIWindowMgr::SetWallpaper
    + " A1"             // MOV EAX,DWORD PTR DS:[g_accountAddr]
    ;

  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");  
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 1b - Extract g_resMgr and g_accountAddr
  var gResMgr = exe.Raw2Rva(offset+5) + exe.fetchDWord(offset+1);
  var gAccountAddr = exe.fetchDWord(offset+code.hexlength());
  
  //Step 2a - Construct our function
  var dnscode =
      " E8" + genVarHex(1)    // CALL g_ResMgr ; call the actual function that was supposed to be run
    + " 60"                // PUSHAD
    + " 8B 35" + genVarHex(2) // MOV ESI,DWORD PTR DS:[g_accountAddr]
    + " 56"                // PUSH ESI
    + " FF 15" + genVarHex(3) // CALL DWORD PTR DS:[<&WS2_32.#52>] ; WS2_32.gethostbyname()
    + " 8B 48 0C"          // MOV ECX,DWORD PTR DS:[EAX+0C]
    + " 8B 11"             // MOV EDX,DWORD PTR DS:[ECX]
    + " 89 D0"             // MOV EAX,EDX
    + " 0F B6 48 03"       // MOVZX ECX,BYTE PTR DS:[EAX+3]
    + " 51"                // PUSH ECX
    + " 0F B6 48 02"       // MOVZX ECX,BYTE PTR DS:[EAX+2]
    + " 51"                // PUSH ECX
    + " 0F B6 48 01"       // MOVZX ECX,BYTE PTR DS:[EAX+1]
    + " 51"                // PUSH ECX
    + " 0F B6 08"          // MOVZX ECX,BYTE PTR DS:[EAX]
    + " 51"                // PUSH ECX
    + " 68" + genVarHex(4)    // PUSH OFFSET addr1 ; ASCII "%d.%d.%d.%d"
    + " 68" + genVarHex(5)    // PUSH OFFSET addr2 ; location is at the end of the code with Initial value "127.0.0.1"
    + " FF 15" + genVarHex(6) // CALL DWORD PTR DS:[<&MSVCR90.sprintf>]
    + " 83 C4 18"          // ADD ESP,18
    + " C7 05" + genVarHex(7) + genVarHex(8) // MOV DWORD PTR DS:[g_accountAddr], addr2 ; Replace g_accountAddr current value with its ip address
    + " 61"                // POPAD
    + " C3"                // RETN
    + " 00" +  "127.0.0.1\x00".toHex() // addr2
    ;
  
  //Step 2b - Calculate free space that the code will need.
  var size = dnscode.hexlength();
    
  //Step 2c - Allocate space for it
  var free = exe.findZeros(size + 4 + 16); // Free space of enable multiple grf + space for dns support
  if (free === -1)
      return "Failed in part 2 - Not enough free space";
    
  //Step 3a - Create a call to our function at CALL g_ResMgr
  exe.replace(offset+1, (exe.Raw2Rva(free) - exe.Raw2Rva(offset+5)).packToHex(4), PTYPE_HEX);
  
  //Step 3b - Find gethostbyname() address
  if (exe.getClientDate() <= 20130605)
    code = " FF 15 AB AB AB 00 85 C0 75 29 8B AB AB AB AB 00";
  else
    code = " FF 15 AB AB AB 00 85 C0 75 2B 8B AB AB AB AB 00";

  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1) {
    code = " E8 AB AB AB 00 85 C0 75 35 8B AB AB AB AB 00";
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset !== -1)
      offset = exe.Raw2Rva(offset+5) + exe.fetchDWord(offset+1);
  }  
  if (offset === -1)
    return "Failed in part 3 - gethostbyname not found";
  
  var uGethostbyname = exe.fetchDWord(offset+2);
  
  //Step 3c - Find sprintf function address
  var uSprintf = exe.findFunction("sprintf", PTYPE_STRING, true);
  if (uSprintf === -1)
    return "Failed in part 3 - sprintf not found";
  
  //Step 3d - Find the ip address format string
  var uIPScheme = exe.findString("%d.%d.%d.%d", RVA);
  if (uIPScheme === -1)
    return "Failed in part 3 - ip string not found";
  
  //Step 3e - Adjust g_resMgr relative to function
  gResMgr = gResMgr - exe.Raw2Rva(free+5);
  
  //Step 3f - addr2 value
  uRVAfreeoffset = exe.Raw2Rva(free + 77);
  
  //Step 3g - Replace all the variables
  dnscode = remVarHex(dnscode, 1, gResMgr);
  dnscode = remVarHex(dnscode, 2, gAccountAddr);
  dnscode = remVarHex(dnscode, 3, uGethostbyname);
  dnscode = remVarHex(dnscode, 4, uIPScheme);
  dnscode = remVarHex(dnscode, 5, uRVAfreeoffset);
  dnscode = remVarHex(dnscode, 6, uSprintf);
  dnscode = remVarHex(dnscode, 7, gAccountAddr);
  dnscode = remVarHex(dnscode, 8, uRVAfreeoffset);
  
  //Step 4 - Finally, insert everything.
  exe.insert(free, size + 4, dnscode, PTYPE_HEX);        
  
  return true;
}