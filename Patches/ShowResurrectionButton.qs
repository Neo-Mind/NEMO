//#############################################################
//# Purpose: Modify the CGameMode::HaveSiegfriedItem function #
//#          to ignore map type comparisons                   #
//#############################################################
  
function ShowResurrectionButton() {//To do - When on PVP/GVG map the second time u die, the char gets warped to save point anyways.
  
  //Step 1 - Find the "Token of Siegfried" id PUSH in CGameMode::HaveSiegfriedItem function.
  var offset = exe.findCode(" 68 C5 1D 00 00", PTYPE_HEX, false); //PUSH 1D5C
  if (offset === -1)
    return "Failed in Step 1";
  
  offset += 15;//Skipping over the PUSH, MOV ECX and CALL . Any other statements in between can vary
  
  //Step 2a - Find the triple comparisons after the PUSH (unknown param, PVP, GVG)
  
  var code = 
    " 8B 48 AB" //MOV ECX, DWORD PTR DS:[EAX+const]
  + " 85 C9"    //TEST ECX, ECX
  + " 75 AB"    //JNE SHORT addr
  ;
  
  var type = 1;//VC6 style
  var offset2 = exe.find(code + code + code, PTYPE_HEX, true, "\xAB", offset, offset + 0x40);
  
  if (offset2 === -1) {
    code =
      " 83 78 AB 00" //CMP DWORD PTR DS:[EAX+const], 0
    + " 75 AB"       //JNE SHORT addr
    ;
    
    type = 2;//VC9 & VC11 style
    offset2 = exe.find(code + code + code, PTYPE_HEX, true, "\xAB", offset, offset + 0x40);
  }
  
  if (offset2 === -1) {
    code =
      " 39 58 AB"          //CMP DWORD PTR DS:[EAX+const], reg32
    + " 0F 85 AB 00 00 00" //JNE addr
    ;
    
    type = 3;//VC10 style
    offset2 = exe.find(code + code + code, PTYPE_HEX, true, "\xAB", offset, offset + 0x40);
  }
 
  if (offset2 === -1) {
    code =
      " 83 78 AB 00" //CMP DWORD PTR DS:[EAX+const], 0
    + " 0F 85 AB 00 00 00" //JNE addr
    ;
    
    type = 4;//VC17 style
    offset2 = exe.find(code + code + code, PTYPE_HEX, true, "\xAB", offset, offset + 0x40);
  }
  
  if (offset2 === -1) { // late 2017 clients [Secret]
    code = code.replace(" 0F 85 AB 00", " 0F 85 AB 01");
    offset2 = exe.find(code + code + code, PTYPE_HEX, true, "\xAB", offset, offset + 0x40);
  }
  
  if (offset2 === -1)
    return "Failed in Step 2 - No comparisons matched";
  
  //Step 2b - Skip over the 3 comparisons using a short JMP
  exe.replace(offset2, "EB" + (3 * code.hexlength() - 2).packToHex(1), PTYPE_HEX);
  
  return true;
}
