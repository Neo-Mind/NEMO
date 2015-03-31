function ReadDataFolderFirst() {
  /////////////////////////////////////////////////////
  // GOAL: Set g_readFolderFirst to 1 always and set //
  //       conditional jump to regular JMP           //
  /////////////////////////////////////////////////////
  
  // Step 1a - Find offset of "readfolder"
  var offset = exe.findString("readfolder", RVA);
  if (offset === -1)
    return "Failed in Part 1 - readfolder not found";
  
  // Step 1b - Find its reference
  var code =  
      " 68" + offset.packToHex(4)   // PUSH addr1; "readfolder"
    + " 8B AB"                      // MOV ECX, EBP
    + " E8 AB AB AB AB"             // CALL XmlElement::FindChild
    + " 85 C0"                      // TEST EAX, EAX
    + " 74 07"                      // JZ SHORT addr2 -> skips to the next Element comparison
    + " C6 05 AB AB AB AB 01"       // MOV BYTE PTR DS:[g_readFolderFirst], 1
    ;
    
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1 - readfolder reference missing";
    
  //Step 2a - NOP out the JZ
  exe.replace(offset+14, " 90 90", PTYPE_HEX);
  
  //Step 2b - Extract g_readFolderFirst address
  var readFolder = exe.fetchHex(offset+18, 4);  // store variable address of ReadFolder
  
  //Step 3 - Find comparison of g_readFolderFirst . Not sure why this is needed but anyways. 
  if (exe.getClientDate() <= 20110810) { // not sure of actual date,
    code =  
        " 80 3D" + readFolder + " 00" // CMP g_readFolderFirst, 0
      + " 57"                          // PUSH EDI
      + " B9 AB AB AB 00"              // MOV ECX, offset
      + " 56"                          // PUSH ESI
      + " 74"                          // JZ addr
      ;    
  }
  else
  if (exe.getClientDate() <= 20130605) {
    code =  
        " 80 3D" + readFolder + " 00"  // CMP g_readFolderFirst, 0
      + " 53"                          // PUSH EBX
      + " 8B AB AB AB"                 // MOV  EBX, DWORD PTR SS:[ARG.1]
      + " 57"                          // PUSH EDI
      + " 8B AB AB AB"                 // MOV  EDI, DWORD PTR SS:[ARG.2]
      + " 57"                          // PUSH EDI
      + " 53"                          // PUSH EBX
      + " 74"                          // JZ addr
      ;
  }
  else {
    code =  
        " 80 3D" + readFolder + " 00"  // CMP g_readFolderFirst, 0
      + " 53"                          // PUSH EBX
      + " 8B AB AB"                    // MOV  EBX, DWORD PTR SS:[ARG.1]
      + " 57"                          // PUSH EDI
      + " 8B AB AB"                    // MOV  EDI, DWORD PTR SS:[ARG.2]
      + " 57"                          // PUSH EDI
      + " 53"                          // PUSH EBX
      + " 74"                          // JZ addr
      ;
  }

  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 3";
    
  //Step 4 - NOP out the JZ
  exe.replace(offset + code.hexlength() - 1, " 90 90", PTYPE_HEX);  
  
  return true;
}