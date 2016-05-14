//####################################################################
//# Purpose: Change the Conditional Jump in License screen displayer #
//#          case of switch to JMP inside WinMain                    #
//####################################################################

function ShowLicenseScreen() {
  
  //Step 1a - Find guildflag90_1 string address
  var offset = exe.findString("model\\3dmob\\guildflag90_1.gr2", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Guild String missing";
  
  //Step 1b - Find its reference (which will come right before the conditional jump)
  var code =
    " 6A 05"                      //PUSH 5
  + " 68" + offset.packToHex(4)   //PUSH addr; ASCII "model\3dmob\guildflag90_1.gr2"
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - String Reference missing";
  
  offset += code.hexlength();
  
  //Step 2a - Find the conditional jump after the reference.
  code =
    " 83 F8 04" //CMP EAX, 4
  + " 74 AB"    //JE SHORT addr
  + " 83 F8 08" //CMP EAX, 8
  + " 74 AB"    //JE SHORT addr
  + " 83 F8 09" //CMP EAX, 9
  + " 74 AB"    //JE SHORT addr
  + " 83 F8 06" //CMP EAX, 6
  + " 75"       //JNE SHORT addr2
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x60);
  if (offset === -1)
    return "Failed in Step 2 - LangType comparison missing";
  
  //Step 2b - Change the first JE to JMP
  exe.replace(offset + 3, "EB", PTYPE_HEX);
  
  return true;
}