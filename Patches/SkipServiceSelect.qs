//##############################################
//# Purpose: Set g_hideAccountList always to 1 #
//##############################################

function SkipServiceSelect() {
  
  //Step 1 - Find address of "passwordencrypt" (g_hideAccountList is assigned just above it)
  var offset = exe.findString("passwordencrypt", RVA);
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2a - Find its reference
  var code = 
    " 74 07"                    //JZ SHORT addr - skip the below code
  + " C6 05 AB AB AB AB 01"     //MOV BYTE PTR DS:[g_hideAccountList], 1
  + " 68" + offset.packToHex(4) //PUSH offset ; "passwordencrypt"
  ;
  var repl = " 90 90"; //NOP out JZ
  var offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset2 === -1) {
    code = 
      " 0F 45 AB"                 //CMOVNZ reg32_A, reg32_B
    + " 88 AB AB AB AB AB"        //MOV BYTE PTR DS:[g_hideAccountList], reg8_A
    + " 68" + offset.packToHex(4) //PUSH offset ; "passwordencrypt"
    ;
    repl = " 90 8B";//change CMOVNZ to MOV
    offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");    
  }
  
  if (offset2 === -1)
    return "Failed in Step 2";
  
  //Step 2b - Change conditional instruction to permanent setting
  exe.replace(offset2, repl, PTYPE_HEX);
  
  return true;
}