function IgnoreMissingPaletteError() {
  //////////////////////////////////////////////////
  // GOAL: Skip the CFile::Open result comparison //
  //       result in CPaletteRes::Load function   //
  //////////////////////////////////////////////////
  
  //To Do - The code is different in old clients
  
  // Step 1a - Prep code to find the CFile::Open call in CPaletteRes::Load
  if (exe.getClientDate() <= 20130605) {
    var code =  
        " E8 AB AB AB 00"    // CALL CFile::Open
      + " 84 C0"             // TEST AL, AL
      + " 0F 85 AC 00 00 00" // JNZ addr
      + " 56"                // PUSH ESI
      ;
  }
  else {
    var code =
        " E8 AB AB AB 00"    // CALL CFile::Open
      + " 84 C0"             // TEST AL, AL
      + " 0F 85 30 01 00 00" // JNZ addr
      + " BF"                // MOV EDI, const
      ;
  }
  
  //Step 1b - Find the function
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";

  //Step 2 - Replace JNZ with NOP+JMP
  exe.replace(offset+7, " 90 E9", PTYPE_HEX);
  
  return true;
}