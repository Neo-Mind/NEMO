//#############################################################
//# Purpose: Modify the CGameMode::HaveSiegfriedItem function #
//#          to skip showing the Resurrection Button.         #
//#############################################################
  
function SkipResurrectionButton() {
  
  //Step 1 - Find the "Token of Siegfried" id PUSH in CGameMode::HaveSiegfriedItem function.
  var offset = exe.findCode(" 68 C5 1D 00 00", PTYPE_HEX, false); //PUSH 1D5C
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace the id with 0xFFFF - Fastest & Easiest method
  exe.replace(offset + 1, " FF FF", PTYPE_HEX);
  
  return true;
}
