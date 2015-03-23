function ExtendNpcBox() {
  ///////////////////////////////////////////////////////////////////
 // GOAL: Modify the stack allocation in CGameMode::Zc_Say_Dialog //
 //       from 2052 to the user specified value                   //
  ///////////////////////////////////////////////////////////////////
 
  // Step 1a - Prep code to find the Stack allocation
  if (exe.getClientDate() <= 20130605) {
    var code =
        " 81 EC 08 08 00 00"    // SUB ESP,808 ; limit+4 = 804+4
      + " A1 AB AB AB 00"       // MOV EAX,DWORD PTR DS:[___security_cookie]
      + " 33 C4"                // XOR EAX,ESP
      + " 89 84 24 04 08 00 00" // MOV DWORD PTR SS:[ESP+804],EAX ; limit
      + " 56"                   // PUSH ESI
      + " 8B C1"                // MOV EAX, ECX
      + " 57"                   // PUSH EDI
      + " 8B BC 24 14 08 00 00" // MOV EDI, DWORD PTR SS:[ESP+814] ; ARG.1
      ;
  }
  else {
    var code =
        " 81 EC 08 08 00 00"             // SUB ESP,808 ; limit+4 = 804+4
      + " A1 AB AB AB 00"                // MOV EAX,DWORD PTR DS:[___security_cookie]
      + " 33 C5"                         // XOR EAX,ESP
      + " 89 45 FC"                      // MOV DWORD PTR SS:[EBP],EAX ; limit
      + " 56"                            // PUSH ESI
      + " 8B C1"                         // MOV EAX, ECX
      + " 57"                            // PUSH EDI
      + " 8B 7D 08"                      // MOV EDI, DWORD PTR SS:[ARG.1]
      + " C7 80 E0 02 00 00 01 00 00 00" // MOV DWORD PTR DS:[EAX+2E0], 1
      ;
  }

  //Step 1b - Find the code
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Get new value from user
  var value = exe.getUserInput("$npcBoxLength", XTYPE_DWORD, "Number Input", "Enter new NPC Dialog box length (2052 - 4096)", 0x804, 0x804, 0x1000);
  
  //Step 3a - Replace with new value
  exe.replaceDWord(offset+2, value+4);//For newest clients this is enough since it uses EBP for stack op
  
  if (exe.getClientDate() <= 20130605) {
    //Step 3b - Update the other locations where the value is used
    exe.replaceDWord(offset+16, value);
    exe.replaceDWord(offset+27, value + 0x10);

    //Step 3c - Adjust Stack cleanup with new value
    offset += code.hexlength();
    code =
        " FF D2"                // CALL EDX
      + " 8B 8C 24 0C 08 00 00" // MOV ECX, DWORD PTR SS:[ESP+80C]
      + " 5F"                   // POP EDI 
      + " 5E"                   // POP ESI
      + " 33 CC"                // XOR ECX, ESP  
      + " E8 AB AB AB AB"       // CALL addr
      + " 81 C4 08 08 00 00"    // ADD ESP, 808
      ;
        
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset);
    if (offset === -1)
      return "Failed in part 3";

    exe.replaceDWord(offset+5,  value+8);
    exe.replaceDWord(offset+20, value+4);
  }
  
  return true;
}