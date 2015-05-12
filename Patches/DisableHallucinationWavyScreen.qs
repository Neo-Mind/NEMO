function DisableHallucinationWavyScreen() {
  /////////////////////////////////////////////////////////////////
  // GOAL: Find the special offset from CGameMode::Initialize    //
  //       function and check for its reference in Hallucination //
  //       Effect function and change the conditional jump to    //
  //       regular JMP to skip the Effect                        //
  /////////////////////////////////////////////////////////////////
  
  //Step 1a - Find offset of xmas_fild01.rsw
  var offset = exe.findString("xmas_fild01.rsw", RVA);
  if (offset === -1)
    return "Failed in Part 1 - xmas_fild01 not found";
  
  //Step 1b - Find its references. Preceding one of them is an assignment to our required offset (lets call it g_Special)
  var code = " B8" + offset.packToHex(4); //MOV EAX, OFFSET addr; ASCII "xmas_fild01.rsw"
  
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  
  if (offsets.length === 0)
    return "Failed in Part 1 - xmas_fild01 references missing";
  
  //Step 1c - Look for the correct location which gets used in CGameMode::Initialize
  code = " 89 AB AB AB AB 00"; //MOV DWORD PTR DS:[g_Special], reg32_A
  
  for (var i = 0; i < offsets.length; i++) {
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offsets[i]-8, offsets[i]);
    if (offset !== -1 && (exe.fetchByte(offset+1) & 0xC7) === 0x5) break;
    offset = -1;
  }
  
  if (offset === -1)
    return "Failed in Part 1 - no references matched";
  
  //Step 1d - Extract g_Special
  var spAddr = exe.fetchHex(offset+2, 4);

  //Step 2 - Find the Special Offset reference
  code =
      " 8B AB"                   // MOV ECX, reg32
    + " E8 AB AB AB AB"          // CALL addr1
    + " 83 3D" + spAddr + " 00"  // CMP DWORD PTR DS:[g_Special], 0
    + " 0F 84"                   // JE LONG addr2
    ;

  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 2";
  
  //Step 3 - Replace the JE with NOP + JMP
  exe.replace(offset+14, " 90 E9", PTYPE_HEX);
  return true;
}