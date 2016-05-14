//################################################################
//# Purpose: Change the JNZ to JMP after CFile::Open result TEST #
//#         in CPaletteRes::Load function                        #
//################################################################

function IgnoreMissingPaletteError() {
  
  //Step 1a - Find the Error message string's offset
  var offset = exe.findString("CPaletteRes :: Cannot find File : ", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Error Message not found";
  
  //Step 1b - Find its reference
  var code =
    " 68" + offset.packToHex(4) //PUSH OFFSET addr; ASCII "CPaletteRes :: Cannot find File : "
  + " 8D"                       //LEA ECX, [LOCAL.x]
  ;
  offset2 = exe.findCode(code, PTYPE_HEX, false);
  
  if (offset2 === -1) {
    code = "BF" + offset.packToHex(4); //MOV EDI, OFFSET addr; ASCII "CPaletteRes :: Cannot find File : "
    offset2 = exe.findCode(code, PTYPE_HEX, false);
  }
  
  if (offset2 === -1)
    return "Failed in Step 1 - Message Reference missing";
  
  //Step 1c - Now Find the call to CFile::Open and its result comparison
  code = 
    " E8 AB AB AB 00"    //CALL CFile::Open
  + " 84 C0"             //TEST AL, AL
  + " 0F 85 AB AB 00 00" //JNZ addr
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x100, offset2);
  if (offset === -1)
    return "Failed in Step 1 - Function call missing";

  //Step 2 - Replace JNZ with NOP + JMP
  exe.replace(offset + code.hexlength() - 6, "90 E9", PTYPE_HEX);
  
  return true;
}