function RestoreLoginWindow() {
  ///////////////////////////////////////////////////////////////////
  // GOAL: Restore the original code that created the Login Window //
  //       inside CLoginMode::OnChangeState function               //
  ///////////////////////////////////////////////////////////////////
  
  //Step 1a - Find the code where we need to make client call the login window
  var code =
      " 50"                   // PUSH EAX
    + " E8 AB AB AB FF"       // CALL g_ResMgr
    + " 8B C8"                // MOV ECX, EAX
    + " E8 AB AB AB FF"       // CALL CResMgr::Get
    + " 50"                   // PUSH EAX
    + " B9 AB AB AB 00"       // MOV ECX, OFFSET g_windowMgr
    + " E8 AB AB AB FF"       // CALL UIWindowMgr::SetWallpaper
    + " 80 3D AB AB AB 00 00" // CMP BYTE PTR DS:[g_Tparam], 0 <- The parameter push + call to UIWindowManager::MakeWindow originally here 
    + " 74 13"                // JZ SHORT addr1 - after the JMP
    + " C6 AB AB AB AB 00 00" // MOV BYTE PTR DS:[g_Tparam], 0
    + " C7 AB AB 04 00 00 00" // MOV DWORD PTR DS:[EBX+0C], 4 <- till here we need to overwrite
    + " E9"                   // JMP addr2
    ;
      
  var codeOffset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (codeOffset === -1)
    return "Failed in part 1";
   
  //Step 1b - Extract the MOV ECX, g_windowMgr statement
  var mov = exe.fetchHex(codeOffset+14, 5);
  
  //Now we need to find UIWindowMgr::MakeWindow
  
  //Step 2a - Find offset of NUMACCOUNT
  var offset = exe.findString("NUMACCOUNT", RVA);
  if (offset === -1)
    return "Failed in Part 2 - NUMACCOUNT not found";
  
  var numaccount = offset.packToHex(4);
  
  //Step 2b - Find the UIWindowMgr::MakeWindow call
  code =
      mov                  // MOV ECX, OFFSET g_windowMgr
    + " E8 AB AB AB FF"    // CALL UIWindowMgr::MakeWindow
    + " 6A 00"             // PUSH 0
    + " 6A 00"             // PUSH 0
    + " 68" + numaccount   // PUSH addr ; "NUMACCOUNT"
    + " 8B F8"             // MOV EDI, EAX
    + " 8B 17"             // MOV EDX, DWORD PTR DS:[EDI]
    + " 8B 82 AB 00 00 00" // MOV EAX, DWORD PTR DS:[EDX+offset]
    + " 68 23 27 00 00"    // PUSH 2723
    ;
      
  var o2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (o2 === -1)
    return "Failed in Part 2 - MakeWindow not found";
  
  //Step 2c - Extract the Function address relative to target location
  var windowMgr = ((o2 + 10 + exe.fetchDWord(o2 + 6)) - (codeOffset + 24 + 2 + 5 + 5)).packToHex(4)
  
  //Step 3a - Prepare the code to overwrite with - originally present in old clients
  code =    
      " 6A 03"          // PUSH 3
    +   mov             // MOV ECX, OFFSET g_windowMgr
    + " E8" + windowMgr // CALL UIWindowMgr::MakeWindow
    + " 90".repeat(11)  // Bunch of NOPs
    ;
  
  //Step 3b - Overwrite with the code.
  exe.replace(codeOffset + 24, code, PTYPE_HEX);
  
  //Additional stuff to make it work
  
  //Step 4 - Force the client to send old login packet irrespective of LangType (Also inside CLoginMode::ChangeState)
  //          all JZ will be NOPed out
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 4 - LangType not found";
    
  code =
      " 80 3D AB AB AB 00 00" // CMP BYTE PTR DS:[g_passwordencrypt], 0
    + " 0F AB AB AB 00 00"    // JNE addr1
    + " A1" + LANGTYPE        // MOV EAX, DWORD PTR DS:[g_serviceType]
    + " AB AB"                // TEST EAX, EAX - (some clients use CMP EAX, EBP instead)
    + " 0F AB AB AB 00 00"    // JZ addr2 -> Skip sending packet
    + " 83 F8 12"             // CMP EAX, 12
    + " 0F 84 AB AB 00 00"    // JZ addr2 -> Skip sending packet
    + " 83 F8 0C"             // CMP EAX, 0C
    + " 0F 84 AB AB 00 00"    // JZ addr2 -> Skip sending packet
  ;

  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 5";
  
  var repl = " 90 90 90 90 90 90";
  exe.replace(offset+20, repl, PTYPE_HEX);
  exe.replace(offset+29, repl, PTYPE_HEX);
  exe.replace(offset+38, repl, PTYPE_HEX);
  
  // Shinryo: We need to make the client return to Login Interface when Error occurs (such as wrong password, failed to connect).
  //          For this in the CModeMgr::SendMsg function, we set the return mode to 3 (Login) and pass 0x271D as idle value 
  //          and skip the quit operation.
  
  //Step 5a - First we find the code to get g_modeMgr & the mode setting function
  code = 
      " 8B 0D AB AB AB 00" // MOV ECX, DWORD PTR DS:[Reference]
    + " 8B 01"             // MOV EAX, DWORD PTR DS:[ECX]
    + " 8B 50 18"          // MOV EDX, DWORD PTR DS:[EAX+18]
    ;
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");//there are plenty of matches but they are all same
  if (offset === -1)
    return "Failed in Step 5 - Unable to find g_modeMgr code";
  
  var infix = exe.fetchHex(offset, 11);
  
  //Step 5b - Now we find the error handler - CModeMgr::SendMsg
  code =
      " 8B F1"                    // MOV ESI,ECX
    + " 8B 46 04"                 // MOV EAX,DWORD PTR DS:[ESI+4]
    + " C7 40 14 00 00 00 00"     // MOV DWORD PTR DS:[EAX+14], 0
    + " 83 3D" + LANGTYPE + " 0B" // CMP DWORD PTR DS:[g_serviceType], 0B
    + " 75 1D"                    // JNE SHORT addr1 -> after CALL instruction below
    + " 8B 0D AB AB AB 00"        // MOV ECX,DWORD PTR DS:[g_hMainWnd]
    + " 6A 01"                    // PUSH 1
    + " 6A 00"                    // PUSH 0
    + " 6A 00"                    // PUSH 0
    + " 68 AB AB AB 00"           // PUSH addr2 ; ASCII "http://www.ragnarok.co.in/index.php"
    + " 68 AB AB AB 00"           // PUSH addr3 ; ASCII "open"
    + " 51"                       // PUSH ECX
    + " FF 15 AB AB AB 00"        // CALL DWORD PTR DS:[<&SHELL32.ShellExecuteA>]
    + " C7 06 00 00 00 00"        // MOV DWORD PTR DS:[ESI],0 (ESI is supposed to have g_modeMgr but it doesn't always point to it, so we assign it another way)
    ;
    // Shinryo:
    // The easiest way would be propably to set this value to a random value instead of 0,
    // but the client would dimmer down/flicker and appear again at login interface.

  //Step 5c - Construct the replacement code
  var replace =    
      " 52"                   // PUSH EDX
    + " 50"                   // PUSH EAX
    + infix                   // MOV ECX,DWORD PTR DS:[Reference]
                              // MOV EAX,DWORD PTR DS:[ECX]
                              // MOV EDX,DWORD PTR DS:[EAX+18]
    + " 6A 00"                // PUSH 0
    + " 6A 00"                // PUSH 0
    + " 6A 00"                // PUSH 0
    + " 6A 00"                // PUSH 0
    + " 68 1D 27 00 00"       // PUSH 271D
    + " C7 41 0C 03 00 00 00" // MOV DWORD PTR DS:[ECX+0C],3
    + " FF D2"                // CALL EDX
    + " 58"                   // POP EAX
    + " 5A"                   // POP EDX
    + " 90".repeat(19)        // Bunch of NOPs
    ;

  //Step 5d - Find the SendMsg function and overwrite.
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 5 - Unable to find SendMsg function";
 
  exe.replace(offset, replace, PTYPE_HEX);
  
  //Extra for 2013 clients - Need to set return value to 1.
  
  if(exe.getClientDate() >= 20130320 && exe.getClientDate() <= 20140226) {
  
    //Step 6a - Find offset of "ID"
    offset = exe.findString("ID", RVA);
    if (offset === -1)
      return "Failed in Part 6 - ID not found";
    
    //Step 6b - Find its reference
    //  PUSH 1
    //  PUSH 0
    //  PUSH addr; "ID"    
    offset = exe.findCode("6A 01 6A 00 68" + offset.packToHex(4), PTYPE_HEX, false);
    if (offset === -1)
      return "Failed in Part 6 - ID reference not found";
    
    //Step 6c - Find the new function call in 2013 clients
    //  PUSH EAX
    //  CALL func
    //  JMP addr
    offset = exe.find("50 E8 AB AB AB 00 EB", PTYPE_HEX, true, "\xAB", offset-80, offset);
    if (offset === -1)
      return "Failed in Part 6 - Function not found";
    
    //Step 6d - Extract the called address
    var call = exe.fetchDWord(offset+2) + offset + 6;
    
    //Step 6e - Sly devils have made a jump here so search for that.
    offset = exe.find(" E9", PTYPE_HEX, false, "", call);
    if (offset === -1)
      return "Failed in part 6 - Jump Not found";
    
    //Step 6f - Now get the jump offset
    call = offset + 5 + exe.fetchDWord(offset+1);//rva conversions are not needed since we are referring to same code section.
    
    //Step 6g - Search for pattern to get func call <- need to remove that call
    //  PUSH 13 
    //  CALL DWORD PTR DS:[addr]
    //  AND EAX, 000000FF
    offset = exe.find(" 6A 13 FF 15 AB AB AB 00 25 FF 00 00 00", PTYPE_HEX, true, "\xAB", call);
    if (offset === -1)
      return "Failed in part 6 - Pattern not found";
    
    //Step 6h - This part is tricky we are going to replace the call with xor eax,eax & add esp, c for now since i dunno what its purpose was anyways. 13 is a hint
    //  XOR EAX, EAX
    //  ADD ESP, 0C
    //  NOP
    exe.replace(offset+2, " 31 C0 83 C4 0C 90", PTYPE_HEX);
  }
  
  return true;
}