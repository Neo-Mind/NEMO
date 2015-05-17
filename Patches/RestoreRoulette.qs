function RestoreRoulette() {
  //Step 1 - Find the address of the icon bmp (if its not there patch wont work)
  var offset = exe.findString("유저인터페이스\\basic_interface\\roullette\\RoulletteIcon.bmp", RAW);
  if (offset === -1)
    return "Patch Cancelled - Roulette is not available for this client";
  
  //Step 2a - Find offset of NUMACCOUNT
  var offset = exe.findString("NUMACCOUNT", RVA);
  if (offset === -1)
    return "Failed in Part 2 - NUMACCOUNT not found";
  
  //Step 2b - Find its reference
  var code = 
      " 6A 00"                    //PUSH 0
    + " 6A 00"                    //PUSH 0
    + " 68" + offset.packToHex(4) //PUSH addr; ASCII "NUMACCOUNT"
    ;
  offset = exe.findCode(code, PTYPE_HEX, false);
  
  if (offset === -1)
    return "Failed in Part 2 - NUMACCOUNT reference missing";
  
  //Step 2c - The above code is preceded by MOV ECX, g_windowMgr and CALL UIWindowMgr::MakeWindow
  //          Extract both
  var movWin = exe.fetchHex(offset-10, 5);
  var makeWin = exe.fetchDWord(offset-4) + exe.Raw2Rva(offset);
  
  //Step 3a - Find the location where the roulette icon was supposed to be created
  code = 
      " 74 0F"           //JE addr; skips to location after the call for creating vend search window below
    + " 68 B5 00 00 00"  //PUSH 0B5
    + movWin             //MOV ECX, OFFSET g_windowMgr
    + " E8"              //CALL UIWindowMgr::MakeWindow
    ;
    
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 3";
  debugValue(convertToBE(exe.Raw2Rva(offset)));
  var offset2 = offset + code.hexlength() + 4;
  
  //Step 3b - Check if the roulette icon is already created (check for PUSH 11D after the CALL)
  if (exe.fetchDWord(offset2 + 1) === 0x11D)
    return "Patch Cancelled - Roulette is already enabled";
  
  //Step 4a - Prep insert code (starting portion is same as above hence we dont repeat it)
  code += 
      genVarHex(1)      //CALL UIWindowMgr::MakeWindow ; E8 opcode is already there
    + " 68 1D 01 00 00" //PUSH 11D
    + movWin            //MOV ECX, OFFSET g_windowMgr
    + " E8" + genVarHex(2)//CALL UIWindowMgr::MakeWindow
    + " E9" + genVarHex(3)//JMP offset2; jump back to offset2
    ;
  
  //Step 4b - Allocate space for it
  var free = exe.findZeros(code.hexlength());
  if (free === -1)
    return "Failed in Part 4 - Not enough space";
  
  var refAddr = exe.Raw2Rva(free + (offset2 - offset));
  
  //Step 4c - Fill in the blanks.
  code = remVarHex(code, 1, makeWin - (refAddr));
  code = remVarHex(code, 2, makeWin - (refAddr + 15));// (PUSH + MOV + CALL)
  code = remVarHex(code, 3, exe.Raw2Rva(offset2) - (refAddr + 20));// (PUSH + MOV + CALL + JMP)
  
  //Step 5 - Insert the code and create the JMP to it.
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);
  exe.replace(offset, "E9" + (exe.Raw2Rva(free) - exe.Raw2Rva(offset + 5)).packToHex(4), PTYPE_HEX);
  
  return true;
}