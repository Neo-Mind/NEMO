//##############################################################
//# Purpose: Change the 'boldtext' comparison JE to JMP inside #
//#          UIFrameWnd::DrawItemWithCount function            #
//##############################################################

function MoveItemCountUpwards() {
  
  //Step 1 - Find the pattern after the comparison inside DrawItemWithCount function
  var code =
    " 68 FF FF FF 00" //PUSH 0FFFFFF
  + " 0F BF CE"       //MOVSX ECX, SI
  ;
  var type = 1;//VC6 & Early VC9
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  
  if (offsets.length === 0) {
    code =
      " 68 FF FF FF 00" //PUSH 0FFFFFF
    + " 6A 0B"          //PUSH 0B
    + " 6A 00"          //PUSH 0
    + " 0F"             //MOVSX reg32_A, reg16_B
    ;
    if (HasFramePointer())
      type = 3; //VC10
    else
      type = 2; //VC9
    offsets = exe.findCodes(code, PTYPE_HEX, false);
  }
  
  if (offsets.length === 0) {
    code =
      " 68 FF FF FF 00" //PUSH 0FFFFFF
    + " B8 0E 00 00 00" //MOV EAX, 0E    
    + " 0F 4D C1"       //CMOVGE EAX, ECX
    + " 6A 0B"          //PUSH 0B
    + " 98"             //CWDE
    ;
    type = 4; //VC11
    offsets = exe.findCodes(code, PTYPE_HEX, false);
  }
  
  if (offsets.length === 0)
    return "Failed in Step 1 - No Patterns matched";
  
  //Step 2a - Get the comparison pattern 
  if (type === 1) {//VC6 & Early VC9
    code = 
      " 8A 45 18" //MOV AL, BYTE PTR SS:[EBP+18]
    + " 83 C4 0C" //ADD ESP, 0C
    + " 84 C0"    //TEST AL, AL
    ;
  }
  else if (type === 2) {//VC9
    code = " 80 7C 24 3C 00"; //CMP DWORD PTR SS:[ESP+3C], 0
  }
  else {//VC10 & VC11
    code = " 80 7D 18 00"; //CMP DWORD PTR SS:[EBP+18], 0
  }
  
  if (type === 4)//VC11 has an extra PUSH in between
    code += " 6A 00"; //PUSH 0
  
  code += " 74"; //JE SHORT addr
  
  //Step 2b - Find the comparison within 0x50 bytes before one of the patterns
  var offset = -1;
  for (var i = 0; i < offsets.length; i++) {
    offset = exe.find(code, PTYPE_HEX, false, "", offsets[i] - 0x50, offsets[i]);
    if (offset !== -1)
      break;
  }
  if (offset === -1)
    return "Failed in Step 2 - Comparison missing";

  //Step 2c - Change the JE to JMP  
  exe.replace(offset + code.hexlength() - 1, "EB", PTYPE_HEX);  
  return true;
}