//#########################################################################
//# Purpose: Find the 1rag1 comparison and change the JNZ after it to JMP #
//#########################################################################

function Disable1rag1Params() {

  //Step 1a - Find offset of '1rag1'
  var offset = exe.findString("1rag1", RVA);
  if (offset === -1)
    return "Failed in Step 1 - 1rag1 not found";
  
  //Step 1b - Find its reference
  var code =
    " 68" + offset.packToHex(4) //PUSH OFFSET addr ; ASCII "1rag1"
  + " AB"                       //PUSH reg32_A
  + " FF AB"                    //CALL ESI         ; strstr function compares reg32_A with "1rag1"
  + " 83 C4 08"                 //ADD ESP, 8
  + " 85 AB"                    //TEST EAX, EAX
  + " 75"                       //JNZ SHORT addr2
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
 
  if (offset === -1) {
    code = code.replace("FF AB 83 C4", "E8 AB AB AB AB 83 C4");
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace JNZ/JNE with JMP
  exe.replace(offset + code.hexlength() - 1, "EB", PTYPE_HEX);
  
  return true;
}