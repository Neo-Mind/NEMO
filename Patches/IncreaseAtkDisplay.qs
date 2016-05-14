//#######################################################################################
//# Purpose: Modify the stack allocation and code to account for 10 digits instead of 6 #
//#          in CGameActor::Am_Make_Number. To avoid redundannt code we will use loop   #
//#######################################################################################

function IncreaseAtkDisplay() {
  
  //Step 1a - Find the location where 999999 is checked
  var code = 
    " 81 AB 3F 42 0F 00" //CMP reg32_A, 0F423F ; 999999 = 0x0F423F
  + " 7E 07"             //JLE SHORT addr1
  + " AB 3F 42 0F 00"    //MOV reg32_A, 0F423F
  ;
  var refOffset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (refOffset === -1) {
    code = code.replace(" 7E", " AB 7E");//Insert Byte before JLE to represent PUSH reg32
    refOffset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (refOffset === -1)
    return "Failed in Step 1 - 999999 comparison missing";

  //Step 1b - Find the start of the Function
  code =
    " 6A FF"             //PUSH -1
  + " 68 AB AB AB 00"    //PUSH addr1
  + " 64 A1 00 00 00 00" //MOV EAX, DWORD PTR FS:[0]
  + " 50"                //PUSH EAX
  + " 83 EC"             //SUB ESP, const1
  ;
  var offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset - 0x40, refOffset);
  
  if (offset === -1) {
    code = code.replace(" 50", " 50 64 89 25 00 00 00 00"); //Insert MOV DWORD PTR FS:[0], ESP after PUSH EAX
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset - 0x40, refOffset);
  }
  
  if (offset === -1)
    return "Failed in Step 1 - Function start missing";
  
  offset += code.hexlength();
  
  //Step 1c - Update the stack allocation to hold 4 more nibbles (each digit requires 4 bits) => decrease by 16
  offsetStack(offset, 1);
  
  //Step 2a - Find Location where the digit counter starts
  var fpEnb = HasFramePointer();
  
  if (fpEnb)
    code = "C7 45 AB 01 00 00 00";//MOV DWORD PTR SS:[EBP-x], 1
  else
    code = "C7 44 24 AB 01 00 00 00";//MOV DWORD PTR SS:[ESP+x], 1
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 0x10, refOffset + 0x28);
  
  if (offset === -1) {
    code = 
      " 7E 07"          //JLE SHORT addr
    + " AB 06 00 00 00" //MOV reg32_B, 6
    + " EB"             //JMP SHORT addr2
    ;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 0x10, refOffset + 0x28);
  }
  
  if (offset === -1)
    return "Failed in Step 2 - Digit Counter missing";
  
  //Step 2b.1 - Extract the stack offset from the instruction if it is a stack assignment
  if (exe.fetchUByte(offset) === 0xC7) {
    var offByte = exe.fetchByte(offset + code.hexlength() - 5);
  }
  else {
    //Step 2b.2 - If its a register assignment extract the register and see if it assigns to stack later
    var offByte = exe.fetchUByte(offset + 2) - 0xB8;
  
    code = (offByte << 3) | 0x44;//modrm for MOV
    if (fpEnb)
      code = " 89" + (code+1).packToHex(1) + " AB 8D";//MOV DWORD PTR SS:[EBP-x], reg32_B . followed by LEA
    else
      code = " 89" + code.packToHex(1) + " 24 AB 8D" ;//MOV DWORD PTR SS:[ESP+x], reg32_B . followed by LEA
    
    var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x80);
    
    if (offset2 === -1)
      offByte = " 89" + (0xF0 | offByte).packToHex(1);//MOV reg32_B, ESI ; because ESI will be holding the digit count finally
    else
      offByte = exe.fetchByte(offset2 + code.hexlength() - 2);
  }
  
  //Step 2c - Find Location where the digit extraction starts
  offset = exe.find("B8 67 66 66 66", PTYPE_HEX, false, "", offset);//MOV EAX, 66666667
  if (offset === -1)
    return "Failed in Step 2 - Digit Extractor missing";
  
  //Step 2d - Find the first digit movement to allocated stack after it
  if (fpEnb)
    code = " 89 AB AB"; //MOV DWORD PTR SS:[EBP-x], reg32_A
  else
    code = " 89 AB 24 AB"; //MOV DWORD PTR SS:[ESP+x], reg32_A
  
  var offset2 = exe.find(code + " 8B", PTYPE_HEX, true, "\xAB", offset + 0x5, offset + 0x28);//MOV instruction following assignment - VC9+ clients

  if (offset2 === -1)
    offset2 = exe.find(code + " F7", PTYPE_HEX, true, "\xAB", offset + 0x5, offset + 0x28);//IMUL instruction following assignment - Older clients
  
  if (offset2 === -1)
    return "Failed in Step 2 - Digit movement missing";
  
  offset2 += code.hexlength();
  
  //Step 2e - Extract the stack offset for the first digit (all the succeeding ones will be in increasing order from this one).
  var offByte2 = exe.fetchByte(offset2 - 1);
  
  //Step 2f - Find the g_modeMgr assignment  
  offset = exe.find(" B9 AB AB AB 00", PTYPE_HEX, true, "\xAB", offset2);//MOV ECX, g_modeMgr
  if (offset === -1)
    return "Failed in Step 2 - g_modeMgr assignment missing";
  
  //Step 2g - Extract the assignment
  var movECX = exe.fetchHex(offset, 5);
  
  //Step 2h - Now find the CModeMgr::GetGameMode call after it - this is where we need to Jump to after digit count and extraction
  offset = exe.find(" E8 AB AB AB FF", PTYPE_HEX, true, "\xAB", offset + 5);//CALL CModeMgr::GetGameMode
  if (offset === -1)
    return "Failed in Step 2 - GetGameMode call missing";

  //Step 3a - Adjust the extracted stack offsets based on FPO
  if (fpEnb) {
    if (typeof(offByte) === "number" && offByte < offByte2) //Location is above digit set in stack (offByte and offByte2 are negative)
      offByte -= 16;
    
    offByte2 -= 16;//Lowest digit is at 4 locations later.
  }
  else {
    if (typeof(offByte) === "number" && offByte >= (offByte2 + 4*6)) //Location is below digit set in stack
      offByte += 16;
  }

  //Step 3b - Prep code to replace at refOffset - new digit splitter and counter combined
  code =
    " 89" + (0xC1 + ((exe.fetchByte(refOffset + 1) & 0x7) << 3)).packToHex(1) //MOV ECX, reg32_A
  + " BE" + offByte2.packToHex(4) //MOV ESI, offByte2
  + " B8 67 66 66 66"    //MOV EAX,66666667
  + " F7 E9"             //IMUL ECX
  + " C1 FA 02"          //SAR EDX,2
  + " 8D 04 92"          //LEA EAX,[EDX*4+EDX]
  + " D1 E0"             //SHL EAX,1
  + " 29 C1"             //SUB ECX,EAX
  + " MovDigit"          //Frame Pointer Specific MOV (extracted digit) to Stack
  + " 83 C6 04"          //ADD ESI,4
  + " 89 D1"             //MOV ECX,EDX
  + " 85 C9"             //TEST ECX,ECX
  + " 75 E2"             //JNE SHORT addr1 -> MOV EAX, 66666667
  + " 83 EE" + offByte2.packToHex(1) //SUB ESI, offByte2
  + " C1 FE 02"          //SAR ESI, 2
  + " MovEsi"            //Frame Pointer Specific MOV (digit count) for VC9+ clients
  +  movECX              //MOV ECX, g_modeMgr
  + " E9" + GenVarHex(1) //JMP offset
  ;

  //Step 3c - Fill in the blanks
  if (fpEnb) {
    code = code.replace(" MovDigit", " 89 4C 35 00"); //MOV DWORD PTR SS:[ESI+EBP],ECX
    if (typeof(offByte) === "number")
      code = code.replace(" MovEsi", " 89 75" + offByte.packToHex(1)); //MOV DWORD PTR SS:[EBP-offByte], ESI
    else
      code = code.replace(" MovEsi", offByte); //MOV reg32_B, ESI
  }
  else {
    code = code.replace(" MovDigit", " 89 0C 34 90"); //MOV DWORD PTR SS:[ESI+ESP],ECX ; followed by NOP to fit 4 byte
    code = code.replace(" MovEsi", " 89 74 24" + offByte.packToHex(1)); //MOV DWORD PTR SS:[ESP+offByte], ESI
  }
  
  code = ReplaceVarHex(code, 1, offset - (refOffset + code.hexlength()));
  
  //Step 3d - Replace code at refOffset
  exe.replace(refOffset, code, PTYPE_HEX);
  
  //Step 4a - Find the end of the function
  if (fpEnb)
    code = "8B E5 5D"; //MOV ESP, EBP and POP EBP
  else
    code = "83 C4 AB"; //ADD ESP, const
  
  code += "C2 10 00";//RETN 10
  
  var offset3 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x200);
  if (offset3 === -1)
    return "Failed in Step 4 - Function end missing";
  
  offset2 = offset + 5;
  if (fpEnb)
    var soff = 16;
  else
    var soff = 4*6;
  
  while (offset2 < offset3) {
    //Step 4b - Get current opcode and modrm
    var opcode = exe.fetchUByte(offset2);
    var modrm = exe.fetchUByte(offset2 + 1);
     
    //Step 4c - Get the instruction details
    var details = GetOpDetails(opcode, modrm, offset2);//contains length of instruction, distance to next offset, optional destination operand, optional source operand. Usually index 0 and 1 are same
    
    //Step 4d - Change stack offsets for relevant locations
    switch(opcode) {
      case 0x89:
      case 0x8B:
      case 0x8D:
      case 0xC7:
      case 0x3B:
      case 0xFF:
      case 0x83: {
        if (opcode === 0xFF && !fpEnb && details.ro === 2)
          soff = 6*4;
        
        if (fpEnb && details.mode === 1) {
          if (details.rm === 5 && exe.fetchByte(offset2 + 2) <= (offByte2 + soff) ) {
            offsetStack(offset2 + 2);
          }
          else if (details.rm === 4 && (exe.fetchByte(offset2 + 2) & 0x7) === 5 &&  exe.fetchByte(offset2 + 3) <= (offByte2 + soff)) {
            offsetStack(offset2 + 3);
          }
        }
        else if (!fpEnb && details.mode === 1 && details.rm === 4 && (exe.fetchByte(offset2 + 2) & 0x7) === 4 && exe.fetchByte(offset2 + 3) >= (offByte2 + soff) ) {
          offsetStack(offset2 + 3, 1);
        }
        
        break;
      }
      
      case 0x68:
      case 0x6A: {
        if (!fpEnb)
          soff += 4;
        
        break;
      }
      
      case 0xE8: {
        if (!fpEnb)
          soff = 6*4;
        
        break;
      }
      
    }
    
    //Step 4e - Update offset2
    offset2 = details.nextOff;
  }
  
  if (fpEnb) {
    if (typeof(offByte) === "number")//Only saw it in VC10+ clients
    {
      //Step 5a - Look for MOV instruction to stack that occurs before refOffset
      offset = exe.find("89 AB AB 81", PTYPE_HEX, true, "\xAB", refOffset - 6, refOffset);//MOV DWORD PTR SS:[EBP-x], reg32_A followed by the comparson
    
      if (offset === -1)
        offset = exe.find("89 AB AB 8B", PTYPE_HEX, true, "\xAB", refOffset-6, refOffset);//MOV DWORD PTR SS:[EBP-x], reg32_A followed by another MOV
    
      if (offset === -1)
        return "Failed in Step 2 - MOV missing";
    
      //Step 5b - Update the stack offset
      offsetStack(offset + 2);
    }
  }
  else {
    //Step 5c - Update the stack offset at offset3 + 2 (change x in ADD ESP, x)
    offsetStack(offset3 + 2, 1);
    
    //Step 5d - Look for LEA instruction before refOffset (FPO client). ESP+x will be before the space allocated for digits
    offset = exe.find("8D AB 24", PTYPE_HEX, true, "\xAB", refOffset - 0x28, refOffset);//LEA EAX, [ESP+x]
    if (offset === -1)
      return "Failed in Step 2 - LEA missing";
    
    //Step 5e - Update the stack offset
    offsetStack(offset + 3, 1);
    
    //Step 5f - Look for MOV ECX, DWORD PTR SS:[ARG.2] before refOffset. ARG.2 is now 0x10 bytes farther
    offset = exe.find("8B AB 24", PTYPE_HEX, true, "\xAB", refOffset - 8, refOffset);
    if (offset === -1)
      return "Failed in Step 2 - ARG.2 assignment missing";
    
    //Step 5g - Update the stack offset
    offsetStack(offset + 3, 1);
  }
  
  return true;
}

//#########################################################
//# Purpose: Add/Sub stack offset value at location by 16 #
//#########################################################

function offsetStack(loc, sign) {
  if (typeof(sign) === "undefined") sign = -1;
  var obyte = exe.fetchByte(loc) + sign * 16;
  exe.replace(loc, obyte.packToHex(1), PTYPE_HEX);
}
