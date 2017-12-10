//########################################################################
//# Purpose: Disable the CGameMode::m_lastLockOnPcGid assignment         #
//#          inside CGameMode::ProcessPcPick to ignore shift right click #
//########################################################################

function DisableAutofollow() {
  
  //Step 1 - Find the assignment statement
  var code =
    " 6A 01"             //PUSH 1
  + " 6A 1A"             //PUSH 1A
  + " 8B CE"             //MOV ECX, ESI
  + " FF AB"             //CALL reg32_A
  + " 8B AB AB AB 00 00" //MOV reg32_B, DWORD PTR DS:[reg32_C+const]
  + " A3 AB AB AB 00"    //MOV DWORD PTR DS:[CGameMode::m_lastLockOnPcGid], EAX ;in this instance reg32_B = EAX
  ;
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  
  if (offsets.length === 0) {
    code = code.replace(" FF AB", " FF AB AB"); //CALL DWORD PTR DS:[reg32_C + x]
    offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offsets.length === 0) { // 2017 clients [Secret]
    code = code.replace(" A3 AB AB AB 00", " A3 AB AB AB AB");
	offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offsets.length === 0) {
    code = code.replace(" A3", " 89 AB"); //MOV DWORD PTR DS:[CGameMode::m_lastLockOnPcGid], reg32_B
    offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offsets.length === 0)
    return "Failed in Step 1";
  
  //Step 2 - NOP out the assignment for the correct match (pattern might match more than one location)
  for (var i = 0; i < offsets.length; i++) {
    var offset = offsets[i] + code.hexlength() - 4;
    var opcode = exe.fetchUByte(offset);
    if (opcode === 0xA3) {//MOV from EAX
      exe.replace(offset - 1, " 90 90 90 90 90");
      break;
    }
    else if (opcode & 0xC7 === 0x5) {//MOV from other registers (mode bits should be 0 & r/m bits should be 5)
      exe.replace(offset - 2, " 90 90 90 90 90 90");
      break;
    }
  }
  
  return true;
}