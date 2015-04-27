function IgnoreMissingPaletteError() {
  //////////////////////////////////////////////////
  // GOAL: Skip the CFile::Open result comparison //
  //       result in CPaletteRes::Load function   //
  //////////////////////////////////////////////////
  
  //Step 1a - Find the Error message string's offset
  var offset = exe.findString("CPaletteRes :: Cannot find File : ", RVA);
  if (offset === -1)
    return "Failed in Part 1 - Error Message not found";
  
  //Step 1b - Find its reference (For old client the string is assigned to register instead of direct PUSH)
  var code =
      " 68" + offset.packToHex(4) //PUSH OFFSET addr; ASCII "CPaletteRes :: Cannot find File : "
    + " 8D"                       //LEA ECX, [LOCAL.x]
    ;
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1) {
    code = code.replace(" 68", " BF").slice(0, -3);//Change PUSH with MOV EDI, OFFSET and remove the LEA
    offset = exe.findCode(code, PTYPE_HEX, false);  
  }
  if (offset === -1)
    return "Failed in Part 1 - Message Reference missing";
  
  //Step 1c - Now Find the call to CFile::Open and its result comparison
  code = 
      " E8 AB AB AB 00"    // CALL CFile::Open
    + " 84 C0"             // TEST AL, AL
    + " 0F 85 AB AB 00 00" // JNZ addr
    ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x100, offset);
  if (offset === -1)
    return "Failed in part 1 - CFile::Open not found";

  //Step 2 - Replace JNZ with NOP+JMP
  exe.replace(offset+7, " 90 E9", PTYPE_HEX);
  
  return true;
}