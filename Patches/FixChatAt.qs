//#############################################################################
//# Purpose: Change the failure return value in the function looking for '@'  # 
//#          in Chat text to 1 (i.e. no @ found). For old clients, we need to #
//#          hijack a call inside UIWindowMgr::ProcessPushButton.             #
//#############################################################################

function FixChatAt() {
  
  //Step 1a - Find the JZ after '@' Comparison
  var code =
    " 74 04"       //JZ SHORT addr -> POP EDI below
  + " C6 AB AB 00" //MOV BYTE PTR DS:[reg32_A+const], 0 ; <- this is the value we need to change
  + " 5F"          //POP EDI
  + " 5E"          //POP ESI
  ;  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset !== -1) {//VC9+ Clients
    //==============================================//
    // Note: The above will be followed by MOV AL,1 //
    //       and POP EBP/EBX statements             //
    //==============================================//
    
    //Step 1b - Change 0 to 1
    exe.replace(offset + 5, "01", PTYPE_HEX);
  }
  else {//Older clients
    //Step 2a - Find the call inside UIWindowMgr::ProcessPushButton
    code = 
      " 8B CE"             //MOV ECX, ESI
    + " E8 AB AB 00 00"    //CALL func <- this is what we need to hijack
    + " 84 C0"             //TEST AL, AL
    + " 74 AB"             //JZ SHORT addr 
    + " 8B AB AB AB 00 00" //MOV reg32_A, DWORD PTR DS:[ESI+const]
    ;
    
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset === -1)
      return "Failed in Step 2 - Function call missing";
    
    //Step 2b - Extract the called address (RVA).
    var func = exe.Raw2Rva(offset + 7) + exe.fetchDWord(offset + 3);
    
    //Step 3a - Construct our function.
    code =
      " 60"                   //PUSHAD
    + " 0F B6 41 2C"          //MOVZX EAX,BYTE PTR DS:[ECX+2C]
    + " 85 C0"                //TEST EAX,EAX
    + " 74 1C"                //JE SHORT addr
    + " 8B 35" + GenVarHex(1) //MOV ESI, DWORD PTR DS:[<&USER32.GetAsyncKeyState>]
    + " 6A 12"                //PUSH 12 ; VirtualKey = VK_ALT
    + " FF D6"                //CALL ESI; [<&USER32.GetAsyncKeyState>]
    + " 85 C0"                //TEST EAX,EAX
    + " 74 0E"                //JE SHORT addr
    + " 6A 11"                //PUSH 11;  VirtualKey = VK_CONTROL
    + " FF D6"                //CALL ESI; [<&USER32.GetAsyncKeyState>]
    + " 85 C0"                //TEST EAX,EAX
    + " 74 06"                //JE SHORT addr
    + " 61"                   //POPAD
    + " 33 C0"                //XOR EAX,EAX
    + " C2 04 00"             //RETN 4
    + " 61"                   //POPAD <- addr
    + " 68" + GenVarHex(2)    //PUSH func
    + " C3"                   //RETN; Alternative to 'JMP func' with no relative offset calculation needed
    ;
    
    var csize = code.hexlength();
    
    //Step 3b - Allocate space for it.
    var free = exe.findZeros(csize);
    if (free === -1)
      return "Failed in Step 3 - Not enough free space";
    
    //Step 4a - Fill in the blanks
    code = ReplaceVarHex(code, 1, GetFunction("GetAsyncKeyState", "USER32.dll"));
    code = ReplaceVarHex(code, 2, func);
    
    //Step 4b - Change called address from func to our function.
    exe.replaceDWord(offset + 3, exe.Raw2Rva(free) - exe.Raw2Rva(offset + 7));
    
    //Step 4c - Insert our function
    exe.insert(free, csize, code, PTYPE_HEX);
  }
  
  return true;
}