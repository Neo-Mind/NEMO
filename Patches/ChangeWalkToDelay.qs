//============================================================//
// Patch Functions wrapping over ChangeWalkToDelay function   //
//============================================================//

function DisableWalkToDelay() {
  return ChangeWalkToDelay(0);
}

function SetWalkToDelay() {
  return ChangeWalkToDelay(exe.getUserInput("$walkDelay", XTYPE_WORD, "Number Input", "Enter the new walk delay(0-1000) - snaps to closest valid value", 40, 0, 1000));
}

//########################################################################
//# Purpose: Find the walk delay and replace it with the value specified #
//########################################################################

function ChangeWalkToDelay(value) {

  //Step 1a - Find the delay addition
  var code =
    " 81 C1 58 02 00 00" //ADD ECX,00000258   ;  600ms
  + " 3B C1"             //CMP EAX,ECX
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - Walk Delay Code not found.";
  
  //Step 2 - Replace the value
  exe.replace(offset + 2, value.packToHex(4) , PTYPE_HEX);

  return true;
}