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
  
  //Step 1a - Construct pattern for finding camera angle reference
  var code = 
      " 74 AB"             // JZ SHORT addr
    + " D9 05 AB AB AB 00" // FLD DWORD PTR DS:[angleAddr]
    ;
    
  if (exe.getClientDate() <= 20130605)
    code += " D9 5C 24 08"; // FSTP DWORD SS:[ESP+8]
  else
    code += " D9 5D FC";    // FSTP DWORD SS:[EBP-4]
  
  code += " 8B"; // MOV reg32_A, DWORD PTR DS:[reg32_B + regOff]
  
  //Step 1b - Find the pattern 
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";

  //Step 2 - Find Space to allocate the new angle
  var free = exe.findZeros(4);
  if (free === -1)
    return "Failed in Part 2: Not enough free space";
  
  //Step 3 - Add the angle and replace reference with the allocated area
  exe.insert(free, 4, newvalue, PTYPE_HEX);
  exe.replace(offset+4, exe.Raw2Rva(free).packToHex(4), PTYPE_HEX);
  
  return true;
}
