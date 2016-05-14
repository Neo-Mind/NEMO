//###########################################################################
//# Purpose: Restore the original code that created the Login Window inside #
//#          CLoginMode::OnChangeState function and Add supporting Changes  #
//#          to make it work                                                #
//###########################################################################
  
function RestoreLoginWindow() {
  
  //Step 1a - Find the code where we need to make client call the login window
  var code =
    " 50"                     //PUSH EAX
  + " E8 AB AB AB FF"         //CALL g_ResMgr
  + " 8B C8"                  //MOV ECX, EAX
  + " E8 AB AB AB FF"         //CALL CResMgr::Get
  + " 50"                     //PUSH EAX
  + " B9 AB AB AB 00"         //MOV ECX, OFFSET g_windowMgr
  + " E8 AB AB AB FF"         //CALL UIWindowMgr::SetWallpaper
  + " 80 3D AB AB AB 00 00"   //CMP BYTE PTR DS:[g_Tparam], 0 <- The parameter push + call to UIWindowManager::MakeWindow originally here 
  + " 74 13"                  //JZ SHORT addr1 - after the JMP
  + " C6 AB AB AB AB 00 00"   //MOV BYTE PTR DS:[g_Tparam], 0
  + " C7 AB AB 04 00 00 00"   //MOV DWORD PTR DS:[EBX+0C], 4 <- till here we need to overwrite
  + " E9"                     //JMP addr2
  ;
      
  var codeOffset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (codeOffset === -1)
    return "Failed in Step 1";
   
  //Step 1b - Extract the MOV ECX, g_windowMgr statement
  var movEcx = exe.fetchHex(codeOffset + 14, 5);
  
  //==============================================//
  // Next we need to find UIWindowMgr::MakeWindow //
  //==============================================//
  
  //Step 2a - Find offset of NUMACCOUNT
  var offset = exe.findString("NUMACCOUNT", RVA);
  if (offset === -1)
    return "Failed in Step 2 - NUMACCOUNT not found";
  
  //Step 2b - Find the UIWindowMgr::MakeWindow call
  code =
    movEcx              //MOV ECX, OFFSET g_windowMgr
  + " E8 AB AB AB FF"   //CALL UIWindowMgr::MakeWindow
  + " 6A 00"            //PUSH 0
  + " 6A 00"            //PUSH 0
  + " 68" + offset.packToHex(4) //PUSH addr ; ASCII "NUMACCOUNT"
  ;
    
  var o2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (o2 === -1)
    return "Failed in Step 2 - MakeWindow not found";
  
  //Step 2c - Extract the Function address relative to target location
  var windowMgr = ((o2 + 10 + exe.fetchDWord(o2 + 6)) - (codeOffset + 24 + 2 + 5 + 5)).packToHex(4)
  
  //Step 3a - Prepare the code to overwrite with - originally present in old clients
  code =    
    " 6A 03"            //PUSH 3
  + movEcx              //MOV ECX, OFFSET g_windowMgr
  + " E8" + windowMgr   //CALL UIWindowMgr::MakeWindow
  + " EB 09"            //JMP SHORT addr ; skip over to the MOV [EBX+0C], 4
  //90".repeat(11)    //Bunch of NOPs
  ;
  
  //Step 3b - Overwrite with the code.
  exe.replace(codeOffset + 24, code, PTYPE_HEX);
  
  //===============================================//
  // Now for some additional stuff to make it work //
  //===============================================//
  
  //Step 4a - Force the client to send old login packet irrespective of LangType (Also inside CLoginMode::ChangeState)
  //          all JZ will be NOPed out
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE.length === 1)
    return "Failed in Step 4 - " + LANGTYPE[0];
    
  code =
    " 80 3D AB AB AB 00 00"   //CMP BYTE PTR DS:[g_passwordencrypt], 0
  + " 0F 85 AB AB 00 00"      //JNE addr1
  + " A1" + LANGTYPE          //MOV EAX, DWORD PTR DS:[g_serviceType]
  + " AB AB"                  //TEST EAX, EAX - (some clients use CMP EAX, EBP instead)
  + " 0F 84 AB AB 00 00"      //JZ addr2 -> Send SSO Packet (ID = 0x825. was 0x2B0 in Old clients)
  + " 83 AB 12"               //CMP EAX, 12
  + " 0F 84 AB AB 00 00"      //JZ addr2 -> Send SSO Packet (ID = 0x825. was 0x2B0 in Old clients)
  ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
 
  if (offset === -1) {
    code = code.replace(" A1", " 8B AB"); //MOV reg32_A, DWORD PTR DS:[g_serviceType]
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 4 - LangType comparison missing";
  
  offset += code.hexlength();
  
  if (exe.fetchUByte(offset) === 0x83 && exe.fetchByte(offset + 2) === 0x0C)//create a JMP to location after the JZs
    var repl = "EB 18";
  else
    var repl = "EB 0F";
  
  exe.replace(offset - 0x11, repl, PTYPE_HEX);
  
  /*===========================================================================================================================
  Shinryo: We need to make the client return to Login Interface when Error occurs (such as wrong password, failed to connect).
           For this in the CModeMgr::SendMsg function, we set the return mode to 3 (Login) and pass 0x271D as idle value 
           and skip the quit operation.
  =============================================================================================================================
  First we need to find the g_modeMgr & mode setting function address. The address is kept indirectly =>
  MOV ECX, DWORD PTR DS:[Reference]
  MOV EAX, DWORD PTR DS:[ECX]
  MOV EDX, DWORD PTR DS:[EAX+18]
  now ECX + C contains g_modeMgr & EDX is the function address we need. But these 3 instructions are not always kept together as of recent clients.
  ===========================================================================================================================*/
  
  //Step 5a - First we look for one location that appears always after g_modeMgr is retrieved
  code = 
    " 6A 00"            //PUSH 0
  + " 6A 00"            //PUSH 0
  + " 6A 00"            //PUSH 0
  + " 68 F6 00 00 00"   //PUSH F6
  + " FF"               //CALL reg32_A or CALL DWORD PTR DS:[reg32_A+const]
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 5 - Unable to find g_modeMgr code";
  
  //Step 5b - Find the start of the function
  code =
    " 83 3D AB AB AB AB 01"   //CMP DWORD PTR DS:[addr1], 1
  + " 75 AB"                  //JNE addr2
  + " 8B 0D"                  //MOV ECX, DWORD PTR DS:[Reference]
  ;
  
  var offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 30, offset);
  if (offset === -1)
    return "Failed in Step 5 - Start of Function missing";
  
  //Step 5c - Extract the reference and construct the code for getting g_modeMgr to ECX + C & mode setter to EDX (same as shown initially)
  var infix = 
    exe.fetchHex(offset + code.hexlength() - 2, 6) //MOV ECX, DWORD PTR DS:[Reference]
  + " 8B 01"      //MOV EAX, DWORD PTR DS:[ECX]
  + " 8B 50 18"   //MOV EDX, DWORD PTR DS:[EAX+18]
  ;
  
  //Step 5d - Find how many PUSH 0s are there. Older clients had 3 arguments but newer ones only have 3
  var pushes = exe.findAll("6A 00", PTYPE_HEX, false, "", offset + code.hexlength() + 4, offset + code.hexlength() + 16);
  
  //Step 5e - Find error handler = CModeMgr::Quit
  code =
    " 8B F1"                      //MOV ESI,ECX
  + " 8B 46 04"                   //MOV EAX,DWORD PTR DS:[ESI+4]
  + " C7 40 14 00 00 00 00"       //MOV DWORD PTR DS:[EAX+14], 0
  + " 83 3D" + LANGTYPE + " 0B"   //CMP DWORD PTR DS:[g_serviceType], 0B
  + " 75 1D"                      //JNE SHORT addr1 -> after CALL instruction below
  + " 8B 0D AB AB AB 00"          //MOV ECX,DWORD PTR DS:[g_hMainWnd]
  + " 6A 01"                      //PUSH 1
  + " 6A 00"                      //PUSH 0
  + " 6A 00"                      //PUSH 0
  + " 68 AB AB AB 00"             //PUSH addr2 ; ASCII "http://www.ragnarok.co.in/index.php"
  + " 68 AB AB AB 00"             //PUSH addr3 ; ASCII "open"
  + " 51"                         //PUSH ECX
  + " FF 15 AB AB AB 00"          //CALL DWORD PTR DS:[<&SHELL32.ShellExecuteA>]
  + " C7 06 00 00 00 00"          //MOV DWORD PTR DS:[ESI],0 (ESI is supposed to have g_modeMgr but it doesn't always point to it, so we assign it another way)
  ;
  /*==============================================================================
   Shinryo:
   The easiest way would be probably to set this value to a random value instead of 0,
   but the client would dimmer down/flicker and appear again at login interface.
  ===============================================================================*/ 
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {//For recent client g_hMainWnd is directly pushed instead of assigning to ECX first
 
    code = code.replace(" 75 1D 8B 0D AB AB AB 00", " 75 1C"); //remove the ECX assignment and fix the JNE address accordingly
    code = code.replace(" 51 FF 15 AB", " FF 35 AB AB AB 00 FF 15 AB"); //replace PUSH ECX with PUSH DWORD PTR DS:[g_hMainWnd]
    
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 5 - Unable to find SendMsg function";
  
  //Step 5f - Construct the replacement code
  var replace =    
    " 52"                   //PUSH EDX
  + " 50"                   //PUSH EAX
  + infix                   //MOV ECX,DWORD PTR DS:[Reference]
                            //MOV EAX,DWORD PTR DS:[ECX]
                            //MOV EDX,DWORD PTR DS:[EAX+18]
  + " 6A 00".repeat(pushes.length) //PUSH 0 sequence
  + " 68 1D 27 00 00"       //PUSH 271D
  + " C7 41 0C 03 00 00 00" //MOV DWORD PTR DS:[ECX+0C],3
  + " FF D2"                //CALL EDX
  + " 58"                   //POP EAX
  + " 5A"                   //POP EDX
  ;
  
  //replace += " 90".repeat(code.hexlength() - replace.hexlength()); // Bunch of NOPs
  replace += " EB" + (code.hexlength() - replace.hexlength() - 2).packToHex(1); //Skip to the POP ESI

  //Step 5g - Overwrite the SendMsg function.
  exe.replace(offset, replace, PTYPE_HEX);
  
  //==========================================================================//
  // Extra for certain 2013 - 2014 clients. Need to fix a function to return 1//
  //==========================================================================//
  
  if (exe.getClientDate() >= 20130320 && exe.getClientDate() <= 20140226) {
 
    //Step 6a - Find offset of "ID"
    offset = exe.findString("ID", RVA);
    if (offset === -1)
      return "Failed in Step 6 - ID not found";
    
    //Step 6b - Find its reference
    //  PUSH 1
    //  PUSH 0
    //  PUSH addr; "ID"    
    offset = exe.findCode("6A 01 6A 00 68" + offset.packToHex(4), PTYPE_HEX, false);
    if (offset === -1)
      return "Failed in Step 6 - ID reference not found";
    
    //Step 6c - Find the new function call in 2013 clients
    //  PUSH EAX
    //  CALL func
    //  JMP addr
    offset = exe.find("50 E8 AB AB AB 00 EB", PTYPE_HEX, true, "\xAB", offset - 80, offset);
    if (offset === -1)
      return "Failed in Step 6 - Function not found";
    
    //Step 6d - Extract the called address
    var call = exe.fetchDWord(offset + 2) + offset + 6;
    
    //Step 6e - Sly devils have made a jump here so search for that.
    offset = exe.find("E9", PTYPE_HEX, false, "", call);
    if (offset === -1)
      return "Failed in Step 6 - Jump Not found";
    
    //Step 6f - Now get the jump offset
    call = offset + 5 + exe.fetchDWord(offset+1);//rva conversions are not needed since we are referring to same code section.
    
    //Step 6g - Search for pattern to get func call <- need to remove that call
    //  PUSH 13 
    //  CALL DWORD PTR DS:[addr]
    //  AND EAX, 000000FF
    offset = exe.find(" 6A 13 FF 15 AB AB AB 00 25 FF 00 00 00", PTYPE_HEX, true, "\xAB", call);
    if (offset === -1)
      return "Failed in Step 6 - Pattern not found";
    
    //Step 6h - This part is tricky we are going to replace the call with xor eax,eax & add esp, c for now since i dunno what its purpose was anyways. 13 is a hint
    //  XOR EAX, EAX
    //  ADD ESP, 0C
    //  NOP
    exe.replace(offset + 2, " 31 C0 83 C4 0C 90", PTYPE_HEX);
  }
  
  return true;
}

//==============================================================//
// Disable for Unneeded Clients - Only VC9+ Client dont have it //
//==============================================================//
function RestoreLoginWindow_() {
  return (exe.getClientDate() > 20100803);
}