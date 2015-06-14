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
  + " 89"
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" FF AB", " FF AB AB"); //CALL DWORD PTR DS:[reg32_C + x]
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1) {
    code = code.replace(" A3", " 89 AB"); //MOV DWORD PTR DS:[CGameMode::m_lastLockOnPcGid], reg32_B
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    
    if (offset !== -1 && exe.fetchByte(offset + code.hexlength() - 5) < 0)//Skip the false match
      offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset + code.hexlength());
  }
  
  if (offset === -1)
    return "Failed in Step 1";
  
  offset += code.hexlength();
  
  //Step 2 - NOP out the assignment
  if (exe.fetchByte(offset - 7) !== 0)
    exe.replace(offset - 7, "90", PTYPE_HEX);
  
  exe.replace(offset - 6, " 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}