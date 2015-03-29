function DisableNagleAlgorithm() {
  ///////////////////////////////////////////////////////
  // GOAL: Replace all socket calls with injected code //
  //       which sets up TCP_NODELAY                   //
  ///////////////////////////////////////////////////////
  
  //Step 1 - Construct the Function to overwrite with - Missing addresses to be added later
  //         we will use constants starting from CC CC CC C1 as fillers (to avoid keeping offsets)
  var code =    
      " 55"                    // PUSH EBP
    + " 8B EC"                 // MOV EBP,ESP
    + " 83 EC 0C"              // SUB ESP,0C
    + " C7 45 F8 01 00 00 00"  // MOV DWORD PTR SS:[EBP-8],1
    + " 8B 45 10"              // MOV EAX,DWORD PTR SS:[EBP+10]
    + " 50"                    // PUSH EAX
    + " 8B 4D 0C"              // MOV ECX,DWORD PTR SS:[EBP+0C]
    + " 51"                    // PUSH ECX
    + " 8B 55 08"              // MOV EDX,DWORD PTR SS:[EBP+8]
    + " 52"                    // PUSH EDX
    + " A1" + genVarHex(1)       // MOV EAX,DWORD PTR DS:[<&WS2_32.#23>] ; WS2_32.socket() => genVarHex(1)
    + " FF D0"                 // CALL EAX
    + " 89 45 FC"              // MOV DWORD PTR SS:[EBP-4],EAX
    + " 83 7D FC FF"           // CMP DWORD PTR SS:[EBP-4],-1
    + " 74 4B"                 // JE SHORT addr1
    + " E8 0B 00 00 00"        // JMP &PUSH ; a little trick to directly push the following string onto the stack
    + " 73 65 74 73 6F 63 6B 6F 70 74 00" // DB "setsockopt\x00"
    + " E8 0B 00 00 00"        // JMP &PUSH
    + " 57 53 32 5F 33 32 2E 44 4C 4C 00" // DB "WS2_32.DLL\x00"
    + " 8B 0D" + genVarHex(2)     // MOV ECX,DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>] ; genVarHex(2)
    + " FF D1"                 // CALL ECX
    + " 50"                    // PUSH EAX
    + " 8B 15" + genVarHex(3)     // MOV EDX,DWORD PTR DS:[<&KERNEL32.GetProcAddress>]   ; genVarHex(3)
    + " FF D2"                 // CALL EDX
    + " 89 45 F4"              // MOV DWORD PTR SS:[EBP-0C],EAX
    + " 83 7D F4 00"           // CMP DWORD PTR SS:[EBP-0C],0
    + " 74 11"                 // JE SHORT addr1
    + " 6A 04"                 // PUSH 4
    + " 8D 45 F8"              // LEA EAX,[EBP-8]
    + " 50"                    // PUSH EAX
    + " 6A 01"                 // PUSH 1
    + " 6A 06"                 // PUSH 6
    + " 8B 4D FC"              // MOV ECX,DWORD PTR SS:[EBP-4]
    + " 51"                    // PUSH ECX
    + " FF 55 F4"              // CALL DWORD PTR SS:[EBP-0C]
    + " 8B 45 FC"              // MOV EAX,DWORD PTR SS:[EBP-4]
    + " 8B E5"                 // MOV ESP,EBP
    + " 5D"                    // POP EBP
    + " C2 0C 00"              // RETN 0C
    ;
  
  // Step 2 - Allocate Free Space for adding the code above.
  var size = code.hexlength();
  var free = exe.findZeros(size+4);
  if (free === -1)
    return "Failed in part 2 - Not enough free space";
 
  var freeRva = exe.Raw2Rva(free);
  //$free += 247 + 4 + 4 + 90 + 4; ??dunno what this is
  
  //Now we get the addresses of the dll imported functions
  
  //Step 3a - Find a call to ds:[<&ws2_32.socket>] - indirect call or ws2_32.socket - direct call.
  //          Needed since it could be imported by ordinal instead of name
  
  var sockcode_pre =
      " E8 AB AB 00 00" // CALL CPacketQueue::Init
    + " 6A 00"          // PUSH 0
    + " 6A 01"          // PUSH 1
    + " 6A 02"          // PUSH 2
  
  var sockcode_indirect = "FF 15 AB AB AB 00"; //CALL DWORD PTR DS:[<&socket>]
  var sockcode_direct = "E8 AB AB AB 00" ; //CALL socket
  
  var bIndirectCALL = true;
  var sockoff = sockcode_pre.hexlength() + 2;
  
  var offset = exe.findCode(sockcode_pre + sockcode_indirect, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    offset = exe.findCode(sockcode_pre + sockcode_direct, PTYPE_HEX, true, "\xAB");
    sockoff--;
    bIndirectCALL = false;
  }
  
  if (offset === -1)
    return "Failed in Part 3 - Unable to find socket call";
  
  //Step 3b - Extract the socket function address
  var sockFunc = exe.fetchDWord(offset + sockoff);
  if (!bIndirectCALL)
    sockFunc = exe.Raw2Rva(offset + sockoff + 4) + sockFunc;
  
  if (sockFunc < 0)
    return "Failed in Part 3 - Function address is unknown";
  
  //Step 3c - Insert all the missing values into the replace code.
  code = remVarHex(code, 1, sockFunc); // socket function at 26
  code = remVarHex(code, 2, exe.findFunction("GetModuleHandleA"));
  code = remVarHex(code, 3, exe.findFunction("GetProcAddress"));
  
  //Step 4a - Now the allocated code needs to be called from the area where JMP to socket() found in each client.
  offset = exe.findCode("FF 25" + sockFunc.packToHex(4), PTYPE_HEX, false);//JMP DWORD PTR DS:[<&WS2_32.#23>]
  if (offset === -1)
    return "Failed in part 4 - Unable to find socket jmp";
  
  //Step 4b - Replace the socket call with our function call
  exe.replace(offset+2, freeRva.packToHex(4), PTYPE_HEX);
  
  //Step 4c - If socket is called Indirectly then we need to find all the instances of it and replace with call to our code.
  if (bIndirectCALL) {
    var offsets = exe.findCodes("FF 15" + sockFunc.packToHex(4), PTYPE_HEX, false);
    if (!offsets[0])
      return "Failed in Part 4 - unable to find indirect calls";
        
    for (var i = 0; offsets[i]; i++) {
      var offset = offsets[i];
      exe.replace(offset, " E8" + (freeRva - exe.Raw2Rva(offset) - 5).packToHex(4) + " 90", PTYPE_HEX);
    }
  }
  
  //Step 5 - Insert the code
  exe.insert(free, size + 4, code, PTYPE_HEX);
  
  return true;
}