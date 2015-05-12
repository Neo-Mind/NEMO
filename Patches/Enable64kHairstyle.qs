function Enable64kHairstyle() {
  ///////////////////////////////////////////////////
  // CODE: Disable hard-coded hair style table and //
  //       generate hair style IDs ad-hoc instead  //
  ///////////////////////////////////////////////////
  
  //--- Client Date Check ---//
  if (exe.getClientDate() <= 20111102)
    return "Unsupported client date";
  
  //Step 1a - Find address of Format String
  var offset = exe.findString("인간족\\머리통\\%s\\%s_%s.%s", RAW);
  if (offset === -1)
    return "Failed in part 1 - String not found";
  
  //Step 1b - Change the 2nd %s to %u
  exe.replace(offset+18, "75", PTYPE_HEX);
  
  //Step 1c - Find the string reference
  offset = exe.findCode("68" + exe.Raw2Rva(offset).packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 1 - String reference missing";
  
  offset -= 3;
  
  //Step 2a - Check which byte is at offset. if its 0x8D then stack is referred with EBP (i.e. no FPO enabled) else stack is referred with ESP (FPO is enabled)
  var code = exe.fetchByte(offset) & 0xFF;
  if (code === 0x8D)
    var fpo = false;
  else
    var fpo = true;
  
  if (fpo)
    offset--;
  
  //Step 2b - Extract the register code used in the second last PUSH reg32 before LEA instruction (0x8D) above.
  var tgtReg = exe.fetchByte(offset-2) - 0x50;
  
  if (fpo)
    var regc = (0x44 | (tgtReg << 3)).packToHex(1);
  else
    var regc = (0x45 | (tgtReg << 3)).packToHex(1);
    
  //Step 2c - Now look for the location where it is assigned. Dont remove the AB at the end, the code size is used later.
  if (fpo) {
    code =
        " 83 7C 24 AB 10"       //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
      + " 8B" + regc + " 24 AB" //MOV reg32, DWORD PTR SS:[LOCAL.z]; z = y+5
      + " 73 04"                //JAE SHORT ;after LEA below
      + " 8D" + regc + " 24 AB" //LEA reg32, [LOCAL.z]; z = y+5
      ;
  }
  else {
    code =
        " 83 7D AB 10"       //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
      + " 8B" + regc + " AB" //MOV reg32, DWORD PTR SS:[LOCAL.z]; z = y+5
      + " 73 03"             //JAE SHORT ;after LEA below
      + " 8D" + regc + " AB" //LEA reg32, [LOCAL.z]; z = y+5
      ;
  }

  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x50, offset);
  if (offset2 === -1) {
    if (fpo) {
      code = 
          " 83 7C 24 AB 10"          //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
        + " 8D" + regc + " 24 AB"    //LEA reg32, [LOCAL.z]; z = y+5
        + " 0F 43" + regc + " 24 AB" //CMOVAE reg32, DWORD PTR SS:[LOCAL.z]; z = y+5
        ;      
    }
    else {
      code = 
          " 83 7D AB 10"          //CMP DWORD PTR SS:[LOCAL.y], 10 ; y is unknown
        + " 8D" + regc + " AB"    //LEA reg32, [LOCAL.z]; z = y+5
        + " 0F 43" + regc + " AB" //CMOVAE reg32, DWORD PTR SS:[LOCAL.z]; z = y+5 
        ;
    }
    
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x50, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Part 2 - Register assignment missing";
  
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
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset2-0x1B0, offset2);
  if (offset === -1)
    return "Failed in Part 3 - Function start missing";
  
  offset += code.hexlength();
  
  //Step 3b - Calculate the ESP/EBP offset to reach Arg.5
  var arg5Off = 5*4;
  
  if (fpo) {
    arg5Off += 4 + 4 + 4 + exe.fetchByte(offset) + 4*4;//PUSH -1 -> PUSH value -> PUSH EAX -> SUB ESP, const -> PUSH reg32 x 4
  
    //Step 3c - Check for an additional PUSH instruction that is there in 2012 & some 2013 clients
    code = 
        " A1 AB AB AB 00" //MOV EAX, DWORD PTR DS:[addr]; __security_cookie
      + " 33 C4"          //XOR EAX, ESP
      + " 50"             //PUSH EAX
      ;
    
    if (exe.find(code, PTYPE_HEX, true, "\xAB", offset+0x4, offset+0x20) !== -1)
      arg5Off += 4;
  }
  else {
    arg5Off += 4;//PUSH EBP at the beginning
  }
  
  //Step 4 - Replace with register assignment to hairstyle index (not as a string)
  if (fpo)
    if (arg5Off > 0x7F)
      code = " 8B" + (0x84 | (tgtReg << 3)).packToHex(1) + " 24" + arg5Off.packToHex(4); //MOV reg32, DWORD PTR SS:[ARG.5]
    else
      code = " 8B" + regc + " 24" + arg5Off.packToHex(1); //MOV reg32, DWORD PTR SS:[ARG.5]
  else
    code = " 8B" + regc + arg5Off.packToHex(1); //MOV reg32, DWORD PTR SS:[ARG.5]
  
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
  
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset+4, offset+0x50);
  if (offset2 === -1){
    code = code.replace("7C", "78");//changing JL to JS
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset+4, offset+0x50);
  }
    
  if (offset2 === -1)
    return "Failed in Part 5 - Limit checker missing";
  
  //Step 5b - Extract the register being compared.
  tgtReg = exe.fetchByte(offset2+3) ^ 0xF8;
  
  //Step 5d - Replace with change JL/JS to JLE and make it set value to 2 & change original JLE to JMP
  code = 
      " 7E 05"    //JLE SHORT addr1
    + " 90 90 90" //NOPs
    + " EB"       //JMP SHORT addr2
    ;
  exe.replace(offset2, code, PTYPE_HEX);
  
  offset2 = exe.find(" 0D 00 00 00", PTYPE_HEX, false, "\xAB", offset2 + code.hexlength() + 2);//if EBP is used it appears 1 byte later so making sure.
  exe.replace(offset2, "02", PTYPE_HEX);
  
  return true;
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
    return "Failed in part 3";
  
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
      return "Failed in part 3 - New Client Special";

    exe.replace(offset+11, " 11 90", PTYPE_HEX); //MOV EDX,DWORD PTR DS:[ECX]
  }
  */