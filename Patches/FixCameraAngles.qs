//All three patches have same procedure only the replacement angle changes

function FixCameraAnglesRecomm() {
  return FixCameraAngles(" 00 00 28 42"); //little endian hex of 42.00
}
  
function FixCameraAnglesLess() {
  return FixCameraAngles(" 00 00 EC 41"); //little endian hex of 29.50
}

function FixCameraAnglesFull() {
  return FixCameraAngles(" 00 00 82 42"); //little endian hex of 65.00
}
  
function FixCameraAngles(newvalue) {
  ////////////////////////////////////////////////////////////
  // GOAL: Find the Camera Angle and replace with new angle //
  ////////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // Note - VC9 compiler finally recognized to store float values 
  //        which are used more than once at an offset and 
  //        use FLD/FSTP to place those in registers.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1a - Find the common pattern after the function call we need.
  var code = 
      " 6A 01" //PUSH 1
    + " 6A 5D" //PUSH 5D
    + " EB"    //JMP SHORT addr
    ;
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 1 - Common Pattern missing";

  //Step 1b - Now find the function call we need (should be within 0x50 bytes before)
  code =
      " 8B CE"          //MOV ECX, ESI
    + " E8 AB AB AB AB" //CALL addr1 <- this is the one we want
    + " AB"             //PUSH reg32_A
    + " 8B CE"          //MOV ECX, ESI
    + " E8 AB AB AB AB" //CALL addr2
    ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x50, offset);
  if (offset === -1)
    return "Failed in Part 1 - Function Call Missing";
  
  //Step 1c - Extract the Function Address (RAW)
  offset += exe.fetchDWord(offset+3) + 7;
  
  //Step 2a - Find the angle value assignment in the function (should be within 0x800 bytes)
  code =
      " 74 AB"             //JZ SHORT addr
    + " D9 05 AB AB AB 00" //FLD DWORD PTR DS:[angleAddr]
    ;
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x800);
  
  if (offset2 === -1) {
    code =
      " 74 AB"                   //JZ SHORT addr
    + " F3 0F 10 AB AB AB AB 00" //MOVSS XMM#, DWORD PTR DS:[angleAddr]
    ;
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x800);
  }
  
  if (offset2 === -1)
    return "Failed in Part 2 - Angle Address missing";
  
  offset2 += code.hexlength() - 4;
  
  //Step 2b - Find Space to allocate the new angle
  var free = exe.findZeros(4);
  if (free === -1)
    return "Failed in Part 2 - Not enough free space";
  
  //Step 3a - Add the angle to the allocated space
  exe.insert(free, 4, newvalue, PTYPE_HEX);
  
  //Step 3b - Replace angleAddr reference with the allocated address
  exe.replace(offset2, exe.Raw2Rva(free).packToHex(4), PTYPE_HEX);
  
  return true;
}