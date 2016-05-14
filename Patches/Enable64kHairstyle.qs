//####################################################
//# Purpose: Disable hard-coded hair style table and #
//#          generate hair style IDs ad-hoc instead  #
//####################################################

function Enable64kHairstyle() {
  //Step 1a - Find address of Format String 
  var code = "\xC0\xCE\xB0\xA3\xC1\xB7\\\xB8\xD3\xB8\xAE\xC5\xEB\\%s\\%s_%s.%s"; // "인간족\머리통\%s\%s_%s.%s"
  var doramOn = false;
  var offset = exe.findString(code, RAW);
  
  if (offset === -1) {//Doram Client 
    code = "\\\xB8\xD3\xB8\xAE\xC5\xEB\\%s\\%s_%s.%s"; // "\머리통\%s\%s_%s.%s"
    doramOn = true;
    offset = exe.findString(code, RAW);
  }
  
  if (offset === -1)
    return "Failed in Step 1 - String not found";
  
  //Step 1b - Change the 2nd %s to %u
  exe.replace(offset + code.length - 7, "75", PTYPE_HEX);
  
  //Step 1c - Find the string reference
  offset = exe.findCode("68" + exe.Raw2Rva(offset).packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - String reference missing";
  
  //Step 2a - Move offset to previous instruction which should be an LEA reg, [ESP+x] or LEA reg, [EBP-x]
  var fpEnb = HasFramePointer();
  if (!fpEnb)
    offset = offset - 4;
  else 
    offset = offset - 3;
  
  if (exe.fetchUByte(offset) !== 0x8D) // x > 0x7F => accomodating for the extra 3 bytes of x
    offset = offset - 3;
  
  if (exe.fetchUByte(offset) !== 0x8D)
    return "Failed in Step 2 - Unknown instruction before reference";
  
  //Step 2b - Extract the register code used in the second last PUSH reg32 before the LEA instruction (0x8D)
  var regNum = exe.fetchUByte(offset - 2) - 0x50;
  if (regNum < 0 || regNum > 7)
    return "Failed in Step 2 - Missing Reg PUSH";
  
  if (fpEnb)
    regc = (0x45 | (regNum << 3)).packToHex(1);
  else
    regc = (0x44 | (regNum << 3)).packToHex(1);
  
  //Step 2c - Now look for the location where it is assigned. Dont remove the AB at the end, the code size is used later.
  if (fpEnb) {//VC9-VC10
    code =
      " 83 7D AB 10"       //CMP DWORD PTR SS:[EBP-y], 10 ; y is unknown
    + " 8B" + regc + " AB" //MOV reg32, DWORD PTR SS:[EBP-z] ; z = y+5*4
    + " 73 03"             //JAE SHORT addr ; after LEA below
    + " 8D" + regc + " AB" //LEA reg32, [EBP-z]
    ;
  }
  else {
    code =
      " 83 7C 24 AB 10"       //CMP DWORD PTR SS:[ESP+y], 10 ; y is unknown
    + " 8B" + regc + " 24 AB" //MOV reg32, DWORD PTR SS:[ESP+z] ; z = y+5*4
    + " 73 04"                //JAE SHORT addr ; after LEA below
    + " 8D" + regc + " 24 AB" //LEA reg32, [ESP+z]
    ;
  }
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x50, offset);
  
  if (offset2 === -1) {//VC11
    if (fpEnb) {
      code = 
        " 83 7D AB 10"          //CMP DWORD PTR SS:[EBP-y], 10 ; y is unknown
      + " 8D" + regc + " AB"    //LEA reg32, [EBP-z] ; z = y+5*4
      + " 0F 43" + regc + " AB" //CMOVAE reg32, DWORD PTR SS:[EBP-z]
      ;
    }
    else {
      code = 
        " 83 7C 24 AB 10"          //CMP DWORD PTR SS:[ESP+y], 10 ; y is unknown
      + " 8D" + regc + " 24 AB"    //LEA reg32, [ESP+z] ; z = y+5*4
      + " 0F 43" + regc + " 24 AB" //CMOVAE reg32, DWORD PTR SS:[ESP+z]
      ;
    }
    
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x50, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Step 2 - Register assignment missing";
  
  //Step 2d - Save the offset2 and code size (We need to NOP out the excess)
  var assignOffset = offset2;
  var csize = code.hexlength();
  
  //Step 3a - Find the start of the function (has a common signature like many others)
  code =
    " 6A FF"             //PUSH -1
  + " 68 AB AB AB 00"    //PUSH value
  + " 64 A1 00 00 00 00" //MOV EAX, FS:[0]
  + " 50"                //PUSH EAX
  + " 83 EC"             //SUB ESP, const
  ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x1B0, offset2);

  if (offset === -1) {//const is > 0x7F
    code = code.replace(" 83", " 81");
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x280, offset2);
  }
  
  offset += code.hexlength();
  
  if (offset === -1)
    return "Failed in Step 3 - Function start missing";
  
  //Step 3b - Get the Stack offset w.r.t. ESP/EBP for Arg.5
  var arg5Dist = 5*4; //for the 5 PUSHes of the arguments
  
  if (fpEnb) {
    arg5Dist += 4; //Account for the PUSH EBP in the beginning
  }
  else {
    arg5Dist += 7*4;//Account for PUSH -1, PUSH addr and 5 reg32 PUSHes
    
    if (exe.fetchUByte(offset - 2) === 0x81) // Add the const from SUB ESP, const
      arg5Dist += exe.fetchDWord(offset);
    else
      arg5Dist += exe.fetchByte(offset);
    
    //Step 3c - Account for an extra PUSH instruction (security related) in VC9 clients
    code =
      " A1 AB AB AB 00" //MOV EAX, DWORD PTR DS:[__security_cookie]; 
    + " 33 C4"          //XOR EAX, ESP
    + " 50"             //PUSH EAX
    ;
    if (exe.find(code, PTYPE_HEX, true, "\xAB", offset + 0x4, offset + 0x20) !== -1)
      arg5Dist += 4;
  }
  //Step 3d - Prep code to change assignment (hairstyle index instead of the string)
  if (fpEnb) {
    code = " 8B" + regc + arg5Dist.packToHex(1); //MOV reg32_A, DWORD PTR SS:[EBP + arg5Dist]; ARG.5
  }
  else if (arg5Dist > 0x7F) {
    code = " 8B" + (0x84 | (regNum << 3)).packToHex(1) + " 24" + arg5Dist.packToHex(4); //MOV reg32_A, DWORD PTR SS:[ESP + arg5Dist]; ARG.5
  }
  else {
    code = " 8B" + regc + " 24" + arg5Dist.packToHex(1); //MOV reg32_A, DWORD PTR SS:[ESP + arg5Dist]; ARG.5
  }
  
  code += " 8B" + ((regNum << 3) | regNum).packToHex(1); //MOV reg32_A, DWORD PTR DS:[reg32_A]
  code += " 90".repeat(csize - code.hexlength());//Fill rest with NOPs
  
  //Step 3e - Replace the original at assignOffset
  exe.replace(assignOffset, code, PTYPE_HEX);
  
  //Step 4a - Find the string table fetchers
  code =
    " 8B AB AB AB AB 00" //MOV reg32_A, DWORD PTR DS:[addr]
  + " 8B AB 00"          //MOV reg32_B, DWORD PTR DS:[EBP]
  + " 8B 14"             //MOV EDX, DWORD PTR DS:[reg32_B * 4 + reg32_A]
  ;
  var offsets = exe.findAll(code, PTYPE_HEX, true, "\xAB", offset, assignOffset);
  
  if (offsets.length === 0) {
    code =
      " 8B AB"             //MOV reg32_B, DWORD PTR DS:[reg32_C]
    + " 8B AB AB AB AB 00" //MOV reg32_A, DWORD PTR DS:[addr]
    + " 8B 14"             //MOV EDX, DWORD PTR DS:[reg32_B * 4 + reg32_A]
    ;
    offsets = exe.findAll(code, PTYPE_HEX, true, "\xAB", offset, assignOffset);
  }
  
  if (offsets.length === 0) {
    code = code.replace(" 8B AB AB", " A1 AB");//reg32_A is EAX
    offsets = exe.findAll(code, PTYPE_HEX, true, "\xAB", offset, assignOffset);
  }
 
  if (offsets.length === 0)
    return "Failed in Step 4 - Table fetchers missing";
  
  //Step 4b - Remove the reg32_B * 4 from all the matches
  for (var i = 0; i < offsets.length; i++) {
    offset2 = offsets[i] + code.hexlength();
    exe.replaceWord(offset2 - 1, 0x9010 + (exe.fetchByte(offset2) & 0x7));
  }
  
  //Step 5a - Find the Hairstyle limiting comparison within the function
  code = 
    " 7C 05"    //JL SHORT addr1; skips the next two instructions
  + " 83 AB AB" //CMP reg32_A, const; const = max hairstyle ID
  + " 7E AB"    //JLE SHORT addr2; skip the next assignment - AB should be 06 or 07
  + " C7"       //MOV DWORD PTR DS:[reg32_B], 0D
  ;
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 4, offset + 0x50);//VC9 - VC10
  
  if (offset2 === -1) {
    code = code.replace(" 7C", " 78");//changing JL to JS
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 4, offset + 0x50);//VC11
  }
  
  if (offset2 === -1 && doramOn) {//For Doram Client, its farther away since there are extra checks for Job ID within Doram Range or Human Range
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 0x100, offset + 0x200);
  }
  
  if (offset2 === -1)
    return "Failed in Step 5 - Limit checker missing";
  
  offset2 += code.hexlength();
  
  //Step 5b - Change the JLE to JMP
  exe.replace(offset2 - 3, "EB", PTYPE_HEX);
  
  //Step 5c - Change 0D to 02 in MOV instruction
  code = exe.fetchUByte(offset2);
  if (code === 0x04 || code > 0x07)
    exe.replace(offset2 + 2, "02");
  else
    exe.replace(offset2 + 1, "02");
  
  //Remove the && 0 to enable for Doram
  if (doramOn && 0) {//Repeat 5a & 5b for Doram race which appears before offset2. 
    //Step 6a - Find the Hairstyle limiting comparison within the function for Doram race
    code = 
      " 7C 05"    //JL SHORT addr1; skips the next two instructions
    + " 83 AB AB" //CMP reg32_A, const; const = max hairstyle ID
    + " 7C AB"    //JLE SHORT addr2; skip the next assignment - AB should be 06 or 07
    + " C7"       //MOV DWORD PTR DS:[reg32_B], 06
    ;
    
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x75, offset2 - 0x10);
    if (offset === -1)
      return "Failed in Step 6 - Doram Limit Checker missing";
  
    offset += code.hexlength();
    
    //Step 6b - Change the JLE to JMP
    exe.replace(offset - 3, "EB", PTYPE_HEX);
    
    //Step 6c - Change 0D to 02 in MOV instruction
    code = exe.fetchUByte(offset);
    if (code === 0x04 || code > 0x07)
      exe.replace(offset + 2, "02");
    else
      exe.replace(offset + 1, "02");
  }
  
  return true;
}

//=================================//
// Disable for Unsupported Clients //
//=================================//
function Enable64kHairstyle_() {
  return (exe.getClientDate() > 20111102);
}