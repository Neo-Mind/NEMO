function IncreaseAtkDisplay() {
  /////////////////////////////////////////////////////////
  // GOAL: Haxor the hardcoded check against 6 digits    //
  //       in CGameActor::Am_Make_Number to check for 10 //
  /////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - Slight variation in code for old clients. Check it out
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1a - Find the location where 999999 is checked
  var code = 
      " 81 F9 3F 42 0F 00" // CMP ECX, 0F423F ; 999999 = 0x0F423F
    + " 7E 07"             // JLE SHORT addr1
    + " B9 3F 42 0F 00"    // MOV ECX, 0F423F
    ;

  var refOffset = exe.findCode(code, PTYPE_HEX, false);
  if (refOffset === -1)
    return "Failed in Part 1 - 999999 comparison missing";

  //Step 1b - Find the start of the Function
  code =
      " 6A FF"             // PUSH -1
    + " 68 AB AB AB 00"    // PUSH addr1
    + " 64 A1 00 00 00 00" // MOV EAX, DWORD PTR FS:[0]
    + " 50"                // PUSH EAX
    + " 83 EC"             // SUB ESP, const1
    ;
  
  var offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset - 100, refOffset);
  if (offset === -1)
    return "Failed in Part 1 - Function start missing";
  
  //Step 1c - Check if FPO is enabled (for 20130605+ clients)
  if (exe.fetchDWord(offset-3) === 0x6AEC8B55)
    var fpo = true;
  else
    var fpo = false;
  
  offset += code.hexlength();
  
  //Step 2a - Update the stack allocation to hold 4 more nibbles (each digit requires 4 bits) => decrease by 16
  offsetStack(offset, 1);
  
  if (fpo) {
    //Step 2b - Update the stack offset for MOV instruction before refOffset (if FPO is enabled). EBP-x will be just after the space allocated for digits
    offset = exe.find("89 AB AB 81", PTYPE_HEX, true, "\xAB", refOffset-6, refOffset);//MOV DWORD PTR SS:[EBP-x], reg32_A followed by the comparson
    
    if (offset === -1)
      offset = exe.find("89 AB AB 8B", PTYPE_HEX, true, "\xAB", refOffset-6, refOffset);//MOV DWORD PTR SS:[EBP-x], reg32_A followed by another MOV
    
    if (offset === -1)
      return "Failed in Part 2 - MOV missing";
    
    offsetStack(offset + 2);
  }
  else {
    //Step 2c - Update the stack offset for LEA instruction before refOffset (if FPO is not enabled). ESP+x will be before the space allocated for digits
    offset = exe.find("8D AB 24", PTYPE_HEX, true, "\xAB", offset, refOffset);//LEA EAX, [ESP+x]
    if (offset === -1)
      return "Failed in Part 2 - LEA missing";
    
    offsetStack(offset + 3, 1);
    
    //Step 2d - Update the stack offset for MOV ECX, DWORD PTR SS:[ARG.2] before refOffset. ARG.2 is now 10 bytes away
    offset = exe.find("8B AB 24", PTYPE_HEX, true, "\xAB", refOffset-8, refOffset);
    if (offset === -1)
      return "Failed in Part 2 - ARG.2 assignment missing";
    
    offsetStack(offset + 3, 1);
  }
  
  //Step 3a - Find Location where the digit counter starts
  if (fpo)
    code = "C7 45 AB 01 00 00 00";//MOV DWORD PTR SS:[EBP-x], 1
  else
    code = "C7 44 24 AB 01 00 00 00";//MOV DWORD PTR SS:[ESP+x], 1
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 4);
  if (offset === -1)
    return "Failed in Part 3 - Digit Counter missing";
  
  offset += code.hexlength();
  
  //Step 3b - Extract the stack offset from the instruction
  var offByte = exe.fetchByte(offset - 5);
  
  //Step 3c - Find Location where the digit extraction starts
  offset = exe.find("B8 67 66 66 66", PTYPE_HEX, false, "", offset);
  if (offset === -1)
    return "Failed in Part 3 - Digit Extractor missing";
  
  //Step 3d - Find the next division by 10 after offset.
  offset = exe.find("B8 67 66 66 66", PTYPE_HEX, false, "", offset + 5);
  if (offset === -1)
    return "Failed in Part 3 - Second division missing";
  
  //Step 3e - Extract the stack offset for the first digit from 3 bytes before (all the succeeding ones will be in increasing order from this one).
  //  MOV DWORD PTR SS:[LOCAL.x], reg32_A
  //  MOV ECX, reg32_B
  //  MOV EAX, 66666667
  var offByte2 = exe.fetchByte(offset - 3);
  
  //Step 3f - Find the location to Jump to after the calculations
  code = " B9 AB AB AB 00";//MOV ECX, g_modeMgr
  
  if (fpo)
    code += " 89 45" + (offByte2 + 0x14).packToHex(1);//MOV DWORD PTR SS:[EBP-const], EAX
  else
    code += " 89 44 24" + (offByte2 + 0x14).packToHex(1);//MOV DWORD PTR SS:[ESP+const], EAX
  
  code += " E8";//CALL CModeMgr::GetGameMode
 
  var offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 5);
  if (offset === -1)
    return "Failed in Part 3 - GetGameMode call missing";
  
  var offset2 = offset + code.hexlength() - 1;
  
  //Step 4a - Adjust the extracted stack offsets based on FPO
  if (fpo) {
    if (offByte < offByte2) //Location is above digit set in stack (offByte and offByte2 are negative)
      offByte -= 16;
    
    offByte2 -= 16;//Lowest digit is at 4 locations later.
  }
  else {
    if (offByte >= (offByte2 + 4*6)) //Location is below digit set in stack
      offByte += 16;
  }

  //Step 4b - Prep code to replace at refOffset - new digit splitter and counter combined
  code =
      " BB" + offByte2.packToHex(4) //MOV EBX, offByte2
    + " B8 67 66 66 66"    //MOV EAX,66666667
    + " F7 E9"             //IMUL ECX
    + " C1 FA 02"          //SAR EDX,2
    + " 8D 04 92"          //LEA EAX,[EDX*4+EDX]
    + " D1 E0"             //SHL EAX,1
    + " 29 C1"             //SUB ECX,EAX
    ;
  
  if (fpo)
    code += " 89 4C 1D 00";       //MOV DWORD PTR SS:[EBX+EBP],ECX
  else
    code += " 89 0C 1C 90";       //MOV DWORD PTR SS:[EBX+ESP],ECX ; followed by NOP to fit the same size as above
  
  code += 
      " 83 C3 04"          //ADD EBX,4
    + " 89 D1"             //MOV ECX,EDX
    + " 85 C9"             //TEST ECX,ECX
    + " 75 E2"             //JNE SHORT addr1 -> MOV EAX, 66666667
    + " 83 EB" + offByte2.packToHex(1) //SUB EBX, offByte2
    + " C1 FB 02"          //SAR EBX, 2
    ;
  
  if (fpo)
    code += " 89 5D" + offByte.packToHex(1); //MOV DWORD PTR SS:[EBP-offByte], EBX
  else
    code += " 89 5C 24" + offByte.packToHex(1) //MOV DWORD PTR SS:[ESP+offByte], EBX
    
  code +=     
      " B9" + genVarHex(1)            //MOV ECX, g_modeMgr
    + " E9" + genVarHex(2)            //JMP offset2
    ;
  
  //Step 4c - Fill in the blanks
  code = remVarHex(code, 1, exe.fetchHex(offset + 1, 4));
  code = remVarHex(code, 2, offset2 - (refOffset + code.hexlength()));
  
  //Step 4d - Replace code at refOffset
  exe.replace(refOffset, code, PTYPE_HEX);
  
  //Step 5a - Find all instructions using stack (offset to EBP for FPO and ESP for non FPO)
  var offsets = [];
  var opcodes = [" 89", " 8B", " 8D", " C7", " 3B", " 83"];
  for (var i = 0; i < 8; i++) {
    for (var j = 0; j < opcodes.length; j++) {
      if (fpo)
        code = opcodes[j] + (0x45 | (i << 3)).packToHex(1);
      else
        code = opcodes[j] + (0x44 | (i << 3)).packToHex(1) + " 24";
      
      offsets = offsets.concat(exe.findAll(code, PTYPE_HEX, false, "", offset, offset+0x200));    
    }
  }
  
  //Step 5b - Iterate through each and update the stack offset if needed
  for (var i = 0; i < offsets.length; i++) {
    if (fpo) {
      if (exe.fetchByte(offsets[i] + 2) < (offByte2 + 16))//i.e existing offset points to location above the previous starting digit in stack
        offsetStack(offsets[i] + 2);
    }
    else {
      if (exe.fetchByte(offsets[i] + 3) >= (offByte2 + 4*6))//i.e. existing offset points to location below the previous ending digit in stack
        offsetStack(offsets[i] + 3, 1);
    }
  }
  
  if (fpo) {
    //Step 5c - Look for one pattern that got missed (because it doesnt have the pattern as above)
    code = 
        " 8B AB AB" + (offByte2 + 16).packToHex(1) //MOV reg32_A, DWORD PTR SS:[reg32_B*8 + EBP - offByte2]; //original offByte2
      + " 8B"                                      //MOV DWORD PTR reg32_C, DS:[ESI]
      ;
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x200);
    if (offset2 === -1)
      return "Failed in Part 5 - Digit access missing";
    
    //Step 5d - Update the stack offset
    offsetStack(offset2 + 3);
  }
  else {
    //Step 5e - Look for the ADD ESP before RETN
    code =
        " 83 C4 AB" //ADD ESP, const
      + " C2 10 00" //RETN 10
      ;
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x200);
    if (offset2 === -1)
      return "Failed in Part 5 - Stack restore missing";
    
    //Step 5f - Update the const
    offsetStack(offset2 + 2, 1);
  }
  
  return true;
}

function offsetStack(loc, sign) {
  if (typeof(sign) === "undefined") sign = -1;
  var obyte = exe.fetchByte(loc) + sign * 16;
  exe.replace(loc, obyte.packToHex(1), PTYPE_HEX);
}
