//#######################################################################################
//# Purpose: Change all JZ/JNZ/CMOVNZ after g_readFolderFirst comparison to NOP/JMP/MOV #
//#          (Also sets g_readFolderFirst to 1 in the process as failsafe).             #
//#######################################################################################

function ReadDataFolderFirst() {

  //Step 1a - Find address of "loading" (g_readFolderFirst is assigned just above it)
  var offset = exe.findString("loading", RVA);
  if (offset === -1)
    return "Failed in Step 1 - loading not found";
  
  //Step 1b - Find its reference
  var code = 
    " 74 07"                    //JZ SHORT addr - skip the below code
  + " C6 05 AB AB AB AB 01"     //MOV BYTE PTR DS:[g_readFolderFirst], 1
  + " 68" + offset.packToHex(4) //PUSH offset ; "loading"
  ;
  
  var repl = " 90 90";//Change JZ SHORT to NOPs
  var gloc = 4;//relative position from offset2 where g_readFolderFirst is
  
  var offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset2 === -1) {
    code = 
      " 0F 45 AB"                 //CMOVNZ reg32_A, reg32_B
    + " 88 AB AB AB AB AB"        //MOV BYTE PTR DS:[g_readFolderFirst], reg8_A
    + " 68" + offset.packToHex(4) //PUSH offset ; "loading"
    ;
    
    repl = " 90 8B";//change CMOVNZ to NOP + MOV
    gloc = 5;
    
    offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");    
  }
  
  if (offset2 === -1)
    return "Failed in Step 1 - loading reference missing";
  
  //Step 1c - Change conditional instruction to permanent setting - as a failsafe
  exe.replace(offset2, repl, PTYPE_HEX);
  
  //===================================================================//
  // Client also compares g_readFolderFirst even before it is assigned //
  // sometimes hence we also fix up the comparisons.                   //
  //===================================================================//
  
  //Step 2a - Extract g_readFolderFirst
  var gReadFolderFirst = exe.fetchDWord(offset2+gloc, 4);
  
  //Step 2b - Look for Comparison Pattern 1 - VC9+ Clients
  var offsets = exe.findCodes(" 80 3D" + gReadFolderFirst.packToHex(4) + " 00"); //CMP DWORD PTR DS:[g_readFolderFirst], 0
  
  if (offsets.length !== 0) {
    for (var i = 0; i < offsets.length; i++) {
      //Step 2c - Find the JZ SHORT below each Comparison
      offset = exe.find(" 74 AB E8", PTYPE_HEX, true, "\xAB", offsets[i] + 0x7, offsets[i] + 0x20);//JZ SHORT addr followed by a CALL
      if (offset === -1)
        return "Failed in Step 2 - Iteration No." + i;
      
      //Step 2d - NOP out the JZ
      exe.replace(offset, " 90 90", PTYPE_HEX);
    }
    
    return true;
  }
  
  //Step 3a - Look for Comparison Pattern 2 - Older clients
  offsets = exe.findCodes(" A0" + gReadFolderFirst.packToHex(4)); //MOV AL, DWORD PTR DS:[g_readFolderFirst]
  if (offsets === -1)
    return "Failed in Step 3 - No Comparisons found";
  
  for (var i = 0; i < offsets.length; i++) {
    //Step 4b - Find the JZ below each Comparison
    offset = exe.find(" 0F 84 AB AB 00 00", PTYPE_HEX, true, "\xAB", offsets[i] + 0x5, offsets[i] + 0x20);//JZ addr
    if (offset === -1)
      return "Failed in Step 3 - Iteration No." + i;
    
    //Step 4c - Replace with 6 NOPs
    exe.replace(offset, " 90 90 90 90 90 90", PTYPE_HEX);
  }
  
  return true;
}