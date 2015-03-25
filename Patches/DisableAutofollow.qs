function DisableAutofollow() {
  //////////////////////////////////////////////////////
  // GOAL: Disable the CGameMode::m_lastLockOnPcGid   //
  //       assignment inside CGameMode::ProcessPcPick //
  //       to ignore shift right click                //
  //////////////////////////////////////////////////////
  
  //To Do - Pattern varies slightly in old client
  
  //Step 1 - Find the assignment statement
  var code =
      " 6A 01" //PUSH 1
    + " 6A 1A" //PUSH 1A
    + " 8B CE" //MOV ECX, ESI
    + " FF D2" //CALL EDX
    + " 8B AB AB AB 00 00" // MOV reg32_A, DWORD PTR DS:[reg32_B+const]
    + " A3"    //MOV DWORD PTR DS:[CGameMode::m_lastLockOnPcGid], EAX
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1";
  
  //Step 2 - NOP out the assignment
  exe.replace(offset + code.hexlength()-1, " 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}

