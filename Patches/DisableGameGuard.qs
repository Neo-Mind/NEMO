//##################################################################
//# Purpose: Skip the call to ProcessFindHack function and the     #
//#          Conditional Jump after it. Also ignore nProtect tests #
//##################################################################

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
  
  //Step 2a - Find pattern matching ProcessFindHack call
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
      break;
    }
  }
  
  if (offset2 !== offset)
    return "Failed in Step 2 - No Matched calls are to ProcessFindHack";
  
  //Step 3a - Find address of nProtect string
  offset = exe.findString("nProtect GameGuard", RVA);
  if (offset === -1)
    return "Failed in Step 3 - nProtect string missing";
  
  //Step 3b - Find its references
  code = 
    " 68" + offset.packToHex(4) //PUSH addr; ASCII "nProtect GameGuard"
  + " 50"                       //PUSH EAX
  + " FF 35"                    //PUSH DWORD PTR DS:[addr2]
  ;
  
  offsets = exe.findCodes(code, PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Step 3 - nProtect references missing";
  
  //Step 4a - Find the short JE before each reference
  code =
    " 84 C0"          //TEST AL, AL
  + " 74 AB"          //JE SHORT addr
  + " E8 AB AB AB FF" //CALL addr2
  + " 8B C8"          //MOV ECX, EAX
  + " E8"             //CALL addr3
  ;
  
  for (var i = 0; i < offsets.length; i++) {
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offsets[i] - 0x50, offsets[i]);
    
    //Step 4b - Replace JE with JMP
    if (offset !== -1)
      exe.replace(offset + 2, "EB", PTYPE_HEX);  
  }
  
  return true;
}

//============================//
// Disable Unsupported client //
//============================//
function DisableGameGuard_() {
  return (exe.findString("GameGuard Error: %lu", RAW) !== -1);  
}