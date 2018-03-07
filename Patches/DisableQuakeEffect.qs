//#############################################################
//# Purpose: Modify CView::SetQuakeInfo and CView::SetQuake   #
//#          functions to return without assigning any values #
//#############################################################

function DisableQuakeEffect() {
  
  //Step 1a - Find offset of .BMP
  var offset = exe.findString(".BMP", RVA);
  if (offset === -1)
    return "Failed in Step 1 - BMP not found";
  
  //Step 1b - Find its reference
  var code = 
    " 68" + offset.packToHex(4) //PUSH OFFSET addr; ASCII ".BMP"
  + " 8B"                       //MOV ECX, reg32_A
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - BMP reference missing";
  
  //Step 2a - Find the SetQuakeInfo call (should be within 0x80 bytes before offset)
  code =
    " E8 AB AB AB AB" //CALL CView::SetQuakeInfo
  + " 33 C0"          //XOR EAX, EAX
  + " E9 AB AB 00 00" //JMP addr
  ;
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x80, offset);
  
  if (offset2 === -1) {
    code = code.replace("33 C0 E9 AB AB 00 00", "AB AB 33 C0");//Remove the JMP and Insert two bytes before XOR to represent POP reg32 instructions
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x100, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Step 2 - SetQuakeInfo call missing";
  
  //Step 2b - Extract the Raw Address of SetQuakeInfo
  offset2 += exe.fetchDWord(offset2 + 1) + 5;
  
  //Step 2c - Replace the start with RETN 0C
  exe.replace(offset2, " C2 0C 00", PTYPE_HEX);
  
  //Step 3a - Find the SetQuake call (should be within 0xA0 bytes before offset)
  code =
    " 6A 01"          //PUSH 1
  + " E8 AB AB AB AB" //CALL CView::SetQuake
  + " 33 C0"          //XOR EAX, EAX
  + " E9 AB AB 00 00" //JMP addr
  ;
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0xA0, offset);
  
  if (offset2 === -1) {
    code = code.replace("33 C0 E9 AB AB 00 00", "AB AB 33 C0");//Remove the JMP and Insert two bytes before XOR to represent POP reg32 instructions
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x120, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Step 3 - SetQuake call missing";
  
  //Step 3b - Extract the Raw Address of SetQuake
  offset2 += exe.fetchDWord(offset2 + 3) + 7;
  
  //Step 3c - Replace the start with RETN 14
  exe.replace(offset2, " C2 14 00", PTYPE_HEX);
  
  return true;
}