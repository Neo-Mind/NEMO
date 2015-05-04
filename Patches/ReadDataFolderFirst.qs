function ReadDataFolderFirst() {
  /////////////////////////////////////////////////////
  // GOAL: Set g_readFolderFirst to 1 always and set //
  //       conditional jump to regular JMP/NOP       //
  /////////////////////////////////////////////////////
  
  // Step 1 - Find address of "loading" (g_readFolderFirst is assigned just above it)
  var offset = exe.findString("loading", RVA);
  if (offset === -1)
    return "Failed in Part 1";
  
  // Step 2a - Find its reference
  var code = 
      " 74 07"                    // JZ SHORT addr - skip the below code
    + " C6 05 AB AB AB AB 01"     // MOV BYTE PTR DS:[g_readFolderFirst], 1
    + " 68" + offset.packToHex(4) // PUSH offset ; "loading"
  
  var repl = " 90 90";//NOP out JZ
  var gloc = 4;//relative position from offset2 where g_readFolderFirst is
  var offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset2 === -1) {
    code = 
      " 0F 45 AB"                 // CMOVNZ reg32_A, reg32_B
    + " 88 AB AB AB AB AB"        // MOV BYTE PTR DS:[g_readFolderFirst], reg8_A
    + " 68" + offset.packToHex(4) // PUSH offset ; "loading"
    ;
    repl = " 90 8B";//change CMOVNZ to MOV
    gloc = 5;
    offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");    
  }
  
  if (offset2 === -1)
    return "Failed in Part 2";
  
  //Step 2b - Change conditional instruction to permanent setting (as a safety precaution. we are anyways NOPing out the JZs)
  exe.replace(offset2, repl, PTYPE_HEX);
  
  //Client also compares g_readFolderFirst even before reading from folder
  //so we need to fix that comparison as well.
  
  //Step 3a - Extract g_readFolderFirst
  var gReadFolderFirst = exe.fetchDWord(offset2+gloc, 4);
  
  //Step 3b - Look for Comparison Pattern 1 - Optional not all clients have it
  code =
      " 80 3D" + gReadFolderFirst.packToHex(4) + " 00"  //CMP DWORD PTR DS:[g_readFolderFirst], 0
    + " AB"                                             //PUSH reg32_A
    + " B9" + (gReadFolderFirst+4).packToHex(4)         //MOV ECX, addr; g_readFolderFirst+4
    + " AB"                                             //PUSH reg32_B 
    + " 74"                                             //JZ SHORT addr2
    ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  //Step 3c - NOP out the JZ
  if (offset !== -1)
    exe.replace(offset + code.hexlength()-1, " 90 90", PTYPE_HEX);

  //Step 3d - Look for Comparison Pattern 2 - This is there in all the clients inside CFile::Open function
  code =   
      " 80 3D" + gReadFolderFirst.packToHex(4) + " 00" //CMP DWORD PTR DS:[g_readFolderFirst], 0
    + " AB"                                            //PUSH reg32_A
    + " 8B"                                            //MOV reg32_A, DWORD PTR SS:[ARG.1]
    ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1)
    return "Failed in Part 3 - Comparison not found";
  
  //Step 3e - Find the JZ below it - position sometimes changes from client to client 
  offset = exe.find(" 74 AB E8", PTYPE_HEX, true, "\xAB", offset+0x10, offset+0x20);
  if (offset === -1)
    return "Failed in Part 3 - JZ not found";
  
  //Step 3f - NOP out the JZ
  exe.replace(offset, " 90 90", PTYPE_HEX);
  
  return true;
}