function DisableNagleAlgorithm() {
  ///////////////////////////////////////////////////////
  // GOAL: Replace all socket calls with injected code //
  //       which sets up TCP_NODELAY                   //
  ///////////////////////////////////////////////////////
  
  //Step 1 - Construct the Function to overwrite with - Missing addresses to be added later
  //         we will use constants starting from CC CC CC C1 as fillers (to avoid keeping offsets)
  var code = 
      genVarHex(0)
    + " 55"                    // PUSH EBP
    + " 8B EC"                 // MOV EBP,ESP
    + " 83 EC 0C"              // SUB ESP,0C
    + " C7 45 F8 01 00 00 00"  // MOV DWORD PTR SS:[EBP-8],1
    + " 8B 45 10"              // MOV EAX,DWORD PTR SS:[EBP+10]
    + " 50"                    // PUSH EAX
    + " 8B 4D 0C"              // MOV ECX,DWORD PTR SS:[EBP+0C]
    + " 51"                    // PUSH ECX
    + " 8B 55 08"              // MOV EDX,DWORD PTR SS:[EBP+8]
    + " 52"                    // PUSH EDX
    + " FF 15" + genVarHex(1)  // CALL DWORD PTR DS:[<&WS2_32.#23>] ; WS2_32.socket() => genVarHex(1)
    + " 89 45 FC"              // MOV DWORD PTR SS:[EBP-4],EAX
    + " 83 7D FC FF"           // CMP DWORD PTR SS:[EBP-4],-1
    + " 74 3C"                 // JE SHORT addr1
    + " E8 0B 00 00 00"        // JMP &PUSH ; a little trick to directly push the following string onto the stack
    + " 73 65 74 73 6F 63 6B 6F 70 74 00" // DB "setsockopt\x00"
    + " 68" + genVarHex(2)     // PUSH OFFSET addr2; ASCII "ws2_32.dll"  => genVarHex(2)
    + " FF 15" + genVarHex(3)  // CALL DWORD PTR DS:[<&KERNEL32.GetModuleHandleA>] ; genVarHex(3)
    + " 50"                    // PUSH EAX
    + " FF 15" + genVarHex(4)  // CALL DWORD PTR DS:[<&KERNEL32.GetProcAddress>]   ; genVarHex(4)
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
    + " 8B 45 FC"              // MOV EAX,DWORD PTR SS:[EBP-4]; addr1
    + " 8B E5"                 // MOV ESP,EBP
    + " 5D"                    // POP EBP
    + " C2 0C 00"              // RETN 0C
    ;
  
  // Step 2a - Allocate Free Space for adding the code above.
  var size = code.hexlength();
  var free = exe.findZeros(size);
  if (free === -1)
    return "Failed in part 2 - Not enough free space";
 
  var freeRva = exe.Raw2Rva(free);
  
  //Step 2b - Find address of ws2_32.socket (#23 when imported by ordinal)
  var sockFunc = getFuncAddr("socket", "ws2_32.dll", 23);
  if (sockFunc === -1)
    return "Failed in Part 2 - socket function missing";
 
  //Step 2c - Insert all the missing values into the replace code.
  code = remVarHex(code, 0, freeRva+4);
  code = remVarHex(code, 1, sockFunc);
  code = remVarHex(code, 2, exe.findString("ws2_32.dll", RVA));
  code = remVarHex(code, 3, getFuncAddr("GetModuleHandleA"));
  code = remVarHex(code, 4, getFuncAddr("GetProcAddress"));
  
  //Step 2d - Insert the code to allocated area
  exe.insert(free, size, code, PTYPE_HEX);
  
  //Step 3a - Find all JMP DWORD PTR to socket function
  var offsets = exe.findCodes(" FF 25" + sockFunc.packToHex(4), PTYPE_HEX, false);
  
  //Step 3b - Replace the address with our function.
  for (var i = 0; i < offsets.length; i++)
    exe.replaceDWord(offsets[i]+2, freeRva);
  
  //Step 3c - Find all CALL DWORD PTR to socket function
  offsets = exe.findCodes(" FF 15" + sockFunc.packToHex(4), PTYPE_HEX, false);
  
  //Step 3d - Replace the address with our function.
  for (var i = 0; i < offsets.length; i++)
    exe.replaceDWord(offsets[i]+2, freeRva);
  
  return true;
}