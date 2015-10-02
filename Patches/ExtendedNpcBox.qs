//####################################################################
//# Purpose: Modify the stack allocation in CGameMode::Zc_Say_Dialog #
//#          from 2052 to the user specified value                   #
//####################################################################

function ExtendNpcBox() {
  
  //Step 1a - Find offset of '|%02x'
  var offset = exe.findString("|%02x", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Format string missing";
 
  //Step 1b - Find its references
  var offsets = exe.findCodes("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Step 1 - String reference missing";
  
  //Step 1c - Find the Stack allocation address => SUB ESP, 804+x . Only 1 of the offsets matches
  for (var i = 0; i < offsets.length; i++) {
    offset = exe.find("81 EC AB 08 00 00", PTYPE_HEX, true, "\xAB", offsets[i] - 0x80, offsets[i]);
    if (offset !== -1)
      break;
  }
  
  if (offset === -1)
    return "Failed in Step 1 - Function not found";
  
  //Step 1d - Extract the x in SUB ESP,x
  var stackSub = exe.fetchDWord(offset + 2);
  
  //Step 1e - Find the End of the Function.
  var fpEnb = HasFramePointer();
  if (fpEnb) {
    code =
      " 8B E5"    //MOV ESP, EBP
    + " 5D"       //POP EBP
    + " C2 04 00" //RETN 4
    ;
  }
  else {
    code =
      " 81 C4" + stackSub.packToHex(4) //ADD ESP, 804+x
    + " C2 04 00"                      //RETN 4
    ;
  }
  
  var offset2 = exe.find(code, PTYPE_HEX, false, "", offsets[i] + 5, offset + 0x200);//i is from the for loop
  if (offset2 === -1)
    return "Failed in Step 1 - Function end missing";

  //Step 2a - Get new value from user
  var value = exe.getUserInput("$npcBoxLength", XTYPE_DWORD, "Number Input", "Enter new NPC Dialog box length (2052 - 4096)", 0x804, 0x804, 0x1000);
  if (value === 0x804)
    return "Patch Cancelled - New value is same as old";
  
  //Step 2b - Change the Stack Allocation with new values
  exe.replaceDWord(offset + 2, value + stackSub - 0x804);//Change x in SUB ESP, x
  if (!fpEnb)
    exe.replaceDWord(offset2 + 2, value + stackSub - 0x804);//Change x in ADD ESP, x
  
  if (fpEnb) {
    //Step 2c - Update all EBP-x+i Stack references, for now we are limiting i to (0 - 3)
    for (var i = 0; i <= 3; i++) {
      code = (i - stackSub).packToHex(4);//-x+i
      offsets = exe.findAll(code, PTYPE_HEX, false, "", offset + 6, offset2);
      for (var j = 0; j < offsets.length; j++) {
        exe.replaceDWord(offsets[j], i - value);
      }
    }
  }
  else {
    //Step 2d - Update all ESP+i Stack references, where i is in (0x804 - 0x820)
    for (var i = 0x804; i <= 0x820; i += 4 ) {
      offsets = exe.findAll(i.packToHex(4), PTYPE_HEX, false, "", offset + 6, offset2);
      for (var j = 0; j < offsets.length; j++) {
        exe.replaceDWord(offsets[j], value + i - 0x804);
      }
    }
  }

  return true;
}