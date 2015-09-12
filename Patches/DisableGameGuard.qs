//##############################################################
//# Purpose: Skip the call to ProcessFindHack function and the #
//#          Conditional Jump after it.                        #
//##############################################################

function DisableGameGuard() {
  //Step 1a - Find the Error String
  var offset = exe.findString("GameGuard Error: %lu", RVA);
  if (offset === -1)
    return "Failed in Step 1 - GameGuard String missing";

  //Step 1b - Find its Reference
  offset = exe.findCode(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - GG String Reference missing";
  
  //Step 1c - Find the starting point of function containing the Reference i.e. ProcessFindHack
  var code = 
    " 55"     //PUSH EBP
  + " 8B EC"  //MOV EBP, ESP
  + " 6A FF"  //PUSH -1
  + " 68"     //PUSH value
  ;
  
  offset = exe.find(code, PTYPE_HEX, false, "", offset - 0x160, offset);
  if (offset === -1)
    return "Failed in Step 1 - ProcessFindHack Function missing";
  
  offset = exe.Raw2Rva(offset);
  
  //Step 2a - Find calls matching to ProcessFindHack call
  code =
    " E8 AB AB 00 00"  //CALL ProcessFindHack
  + " 84 C0"           //TEST AL, AL
  + " 74 04"           //JE SHORT addr
  + " C6 AB AB 01"     //MOV BYTE PTR DS:[reg32+byte], 1; addr2
  ;
    
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (offsets.length === 0)
    return "Failed in Step 2 - No Calls found matching ProcessFindHack";
  
  //Step 2b - Replace the CALL with a JMP skipping the CALL, TEST and JE 
  code = " EB 07 90 90 90"; //JMP addr2
  
  for (var i = 0; i < offsets.length; i++) {
    var offset2 = exe.fetchDWord(offsets[i] + 1) + exe.Raw2Rva(offsets[i] + 5);
    if (offset2 === offset) {
      exe.replace(offsets[i], code, PTYPE_HEX);
      return true;
    }
  }
  
  return "Failed in Step 2 - No Matched calls are to ProcessFindHack";
}

//============================//
// Disable Unsupported client //
//============================//
function DisableGameGuard_() {
  return (exe.findString("GameGuard Error: %lu", RAW) !== -1);  
}