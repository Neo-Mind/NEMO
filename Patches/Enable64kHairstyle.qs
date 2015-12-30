//####################################################
//# Purpose: Disable hard-coded hair style table and #
//#          generate hair style IDs ad-hoc instead  #
//####################################################

function Enable64kHairstyle() {
  
  //Step 1a - Find address of Format String 
  var doramOn = false;
  var code = "\xC0\xCE\xB0\xA3\xC1\xB7\\\xB8\xD3\xB8\xAE\xC5\xEB\\%s\\%s_%s.%s";// "인간족\머리통\%s\%s_%s.%s"
  var offset = exe.findString(code, RAW);
  
  
  if (offset === -1) {//Doram Client 
    doramOn = true;
    code = "\\\xB8\xD3\xB8\xAE\xC5\xEB\\%s\\%s_%s.%s";// "\머리통\%s\%s_%s.%s"
    offset = exe.findString(code, RAW);
  }
  
  if (offset === -1)
    return "Failed in Step 1 - String not found";
  
  //Step 1b - Change the 2nd %s to %u
  exe.replace(offset + code.length - 6, "75", PTYPE_HEX);
  
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
  
  if (exe.fetchUByte(offset) !== 0x8D);// x > 0x7F => accomodating for the extra 3 bytes of x
    offset = offset - 3;
  
  if (exe.fetchUByte(offset) !== 0x8D)
    return "Failed in Step 2 - Unknown instruction before reference";
  
  //Step 2b - Extract the register code used in the second last PUSH reg32 before LEA instruction (0x8D) above.
  var tgtReg = exe.fetchUByte(offset - 2) - 0x50;
  if (tgtReg < 0 || tgtReg > 7)
    return "Failed in Step 2 - Missing Reg PUSH";
  
  if (fpEnb)
    var regc = (0x45 | (tgtReg << 3)).packToHex(1);
  else
    var regc = (0x44 | (tgtReg << 3)).packToHex(1);
    
  //Step 2c - Now look for the location where it is assigned. Dont remove the AB at the end, the code size is used later.
  if (fpEnb) {
    code =
      " 83 7D AB 10"       //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
    + " 8B" + regc + " AB" //MOV reg32, DWORD PTR SS:[LOCAL.z]; z = y+5
    + " 73 03"             //JAE SHORT ;after LEA below
    + " 8D" + regc + " AB" //LEA reg32, [LOCAL.z]; z = y+5
    ;
  }
  else {
    code =
      " 83 7C 24 AB 10"       //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
    + " 8B" + regc + " 24 AB" //MOV reg32, DWORD PTR SS:[LOCAL.z]; z = y+5
    + " 73 04"                //JAE SHORT ;after LEA below
    + " 8D" + regc + " 24 AB" //LEA reg32, [LOCAL.z]; z = y+5
    ;
  }

  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x50, offset);
  if (offset2 === -1) {
    if (fpEnb) {
      code = 
        " 83 7D AB 10"          //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
      + " 8D" + regc + " AB"    //LEA reg32, [LOCAL.z]; z = y+5
      + " 0F 43" + regc + " AB" //CMOVAE reg32, DWORD PTR SS:[LOCAL.z]; z = y+5 
      ;
    }
    else {
      code = 
        " 83 7C 24 AB 10"          //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
      + " 8D" + regc + " 24 AB"    //LEA reg32, [LOCAL.z]; z = y+5
      + " 0F 43" + regc + " 24 AB" //CMOVAE reg32, DWORD PTR SS:[LOCAL.z]; z = y+5
      ;
    }
    
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x50, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Step 2 - Register assignment missing";
  
  //Step 2d - Save the length of code that we need to replace. 
  var repLen = code.hexlength();
  
  //Step 3a - Find the start of the function - uses a common signature like many others.
  code =
    " 6A FF"             //PUSH -1
  + " 68 AB AB AB 00"    //PUSH value
  + " 64 A1 00 00 00 00" //MOV EAX, FS:[0]
  + " 50"                //PUSH EAX
  + " 83 EC"             //SUB ESP, const
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x1B0, offset2);
  
  if (offset === -1) {
    code = code.replace(" 83", " 81");//const is > 0x7F
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x280, offset2);
  }
  
  if (offset === -1)
    return "Failed in Step 3 - Function start missing";
  
  offset += code.hexlength();
  
  //Step 3b - Calculate the ESP/EBP offset to reach Arg.5
  var arg5Off = 5*4;//5 PUSHes
  
  if (fpEnb) {
    arg5Off += 4;//PUSH EBP at the beginning
  }
  else {
    arg5Off += 4 + 4 + 4 + 4*4;//PUSH -1 -> PUSH value -> PUSH EAX -> PUSH reg32 x 4
    
    if (fetchUByte(offset) > 0x7F)//-> SUB ESP, const 
      arg5Off += exe.fetchDWord(offset);
    else
      arg5Off += exe.fetchByte(offset);
  
    //Step 3c - Check for an additional PUSH instruction that is there in 2012 & some 2013 clients
    code = 
      " A1 AB AB AB 00" //MOV EAX, DWORD PTR DS:[addr]; __security_cookie
    + " 33 C4"          //XOR EAX, ESP
    + " 50"             //PUSH EAX
    ;
    
    if (exe.find(code, PTYPE_HEX, true, "\xAB", offset + 0x4, offset + 0x20) !== -1)
      arg5Off += 4;
  }
  
  //Step 4 - Replace with register assignment to hairstyle index (not as a string)
  if (fpEnb) { 
    code = " 8B" + regc + arg5Off.packToHex(1); //MOV reg32, DWORD PTR SS:[ARG.5]
  }
  else {
    if (arg5Off > 0x7F)
      code = " 8B" + (0x84 | (tgtReg << 3)).packToHex(1) + " 24" + arg5Off.packToHex(4); //MOV reg32, DWORD PTR SS:[ARG.5]
    else
      code = " 8B" + regc + " 24" + arg5Off.packToHex(1); //MOV reg32, DWORD PTR SS:[ARG.5]
  }
  
  code += " 8B" + ((tgtReg << 3) | tgtReg).packToHex(1); //MOV reg32, DWORD PTR DS:[reg32]
  
  code += " 90".repeat(repLen - code.hexlength());//Fill rest with NOPs
  
  exe.replace(offset2, code, PTYPE_HEX);
  
  //Step 5a - Find the Hairstyle limiter within the function
  code = 
    " 7C 05"    //JL SHORT addr1; skips the next two instructions
  + " 83 AB AB" //CMP reg32_A, const; const = max hairstyle ID
  + " 7E AB"    //JLE SHORT addr2; skip the next assignment - AB should be 06 or 07
  + " C7"       //MOV DWORD PTR DS:[reg32_B], 0D
  ;
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 4, offset + 0x50);
  
  if (offset2 === -1) {
    code = code.replace(" 7C", " 78");//changing JL to JS
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 4, offset + 0x50);
  }
    
  if (offset2 === -1 && doramOn) {//For Doram Client, its farther away since there are extra checks for Job ID within Doram Range or Human Range
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 0x100, offset + 0x200);
  }
  
  if (offset2 === -1)
    return "Failed in Step 5 - Limit checker missing";
  
  //Step 5b - Extract the register being compared.
  tgtReg = exe.fetchUByte(offset2 + 3) ^ 0xF8;
  
  //Step 5d - Change JL/JS to JLE and make it set value to 2 & Change original JLE to JMP
  code = 
    " 7E 05"    //JLE SHORT addr1
  + " 90 90 90" //NOPs
  + " EB"       //JMP SHORT addr2
  ;
  exe.replace(offset2, code, PTYPE_HEX);
  
  offset2 = exe.find(" 0D 00 00 00", PTYPE_HEX, false, "\xAB", offset2 + code.hexlength() + 2);//If EBP is used it appears 1 byte later so making sure.
  exe.replace(offset2, "02", PTYPE_HEX);
  
  if (doramOn) {//There is an extra comparison for Doram race before this one - we need to do similar steps for it
  
    //Step 5e - Find Hairstyle limiter for Doram race before Human race
    code = 
      " 7C 05"    //JL SHORT addr1; skips the next two instructions
    + " 83 AB AB" //CMP reg32_A, const; const = max hairstyle ID
    + " 7C AB"    //JLE SHORT addr2; skip the next assignment - AB should be 06 or 07
    + " C7"       //MOV DWORD PTR DS:[reg32_B], 06
    ;
  
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2 - 0x75, offset2 - 0x10);
    if (offset === -1)
      return "Failed in Step 5 - Doram Limit Checker missing";
    
    //Step 5f - Extract the register being compared.
    tgtReg = exe.fetchUByte(offset + 3) ^ 0xF8;
    
    //Step 5g - Change JL to JLE and make it set value to 1 & Change JLE to JMP
    code = 
      " 7E 05"    //JLE SHORT addr1
    + " 90 90 90" //NOPs
    + " EB"       //JMP SHORT addr2
    ;
    exe.replace(offset, code, PTYPE_HEX);
  
    offset = exe.find(" 06 00 00 00", PTYPE_HEX, false, "\xAB", offset + code.hexlength() + 2);//If EBP is used it appears 1 byte later so making sure.
    exe.replace(offset, "01", PTYPE_HEX);
  }
  return true;
}

//=================================//
// Disable for Unsupported Clients //
//=================================//
function Enable64kHairstyle_() {
  return (exe.getClientDate() > 20111102);
}

/*  Not Done - not sure if its needed
  // Step 3a - Void Table lookup.
  if (type === 0) {
    code =
        " 8B 45 00"  // MOV  EAX,DWORD PTR SS:[EBP]
      + " 8B 14 81"  // MOV  EDX,DWORD PTR DS:[ECX+EAX*4]
      ;
  }
  else {
    code =
        " 75 19"             // JNE SHORT addr1
      + " 8B 0E"             // MOV ECX, DWORD PTR DS:[ESI]
      + " 8B 15 AB AB AB 00" // MOV EDX, DWORD PTR DS:[addr2]
      + " 8B 14 8A"          // MOV EDX, DWORD PTR DS:[EDX+ECX*4]
      ;
  }
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 3";
  
  // Step 3b - Replace the lookup with ad-hoc
  if (type === 0) {
    exe.replace(offset+4 , " 11 90", PTYPE_HEX); //MOV EDX,DWORD PTR DS:[ECX]
  }
  else {
    exe.replace(offset+11, " 12 90", PTYPE_HEX); //MOV EDX,DWORD PTR DS:[EDX]
  }
    
  //Step 3c - New client special
  if (type === 1) {
    code =
        " 75 23"             // JNE SHORT addr1
      + " 8B 06"             // MOV EAX, DWORD PTR DS:[ESI]
      + " 8B 0D AB AB AB 00" // MOV ECX, DWORD PTR DS:[addr2]
      + " 8B 14 81"          // MOV EDX, DWORD PTR DS:[EDX+ECX*4]
      ;
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");

    if (offset == -1)
      return "Failed in Step 3 - New Client Special";

    exe.replace(offset+11, " 11 90", PTYPE_HEX); //MOV EDX,DWORD PTR DS:[ECX]
  }
  */