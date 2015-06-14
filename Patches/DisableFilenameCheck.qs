//#######################################################################
//# Purpose: Change the JNZ inside WinMain (or function called from it) #
//#          to JMP which will skip showing the "Invalid Exe" Message   #
//#######################################################################

function DisableFilenameCheck() {
  
  //Step 1 - Find the Comparison pattern
  var code = 
    " 84 C0"          //TEST AL, AL
  + " 74 07"          //JZ SHORT addr1
  + " E8 AB AB FF FF" //CALL SearchProcessIn9X
  + " EB 05"          //JMP SHORT addr2
  + " E8 AB AB FF FF" //CALL SearchProcessInNT <= addr1
  + " 84 C0"          //TEST AL, AL <= addr2
  + " 75"             //JNZ addr3
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace("74 07", "74 0C").replace("EB 05", "EB 0A BE 01 00 00 00");//insert MOV ESI, 1 after the JMP and update addr1 & addr2
    exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1";

  //Step 2 - Replace JNZ/JNE to JMP
  exe.replace(offset + code.hexlength() - 1, "EB", PTYPE_HEX);
  
  return true;
}