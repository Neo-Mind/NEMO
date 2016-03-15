//###############################################################################
//# Purpose: Modify the comparisons in cases for Hair Style and Color arrows in #
//#          UIMakeCharWnd::SendMsg and also update the scrollbar length        #
//###############################################################################

function IncreaseHairLimits() {//To Do - Doram client is different need to explore

  //Step 1a - Find the reference PUSH before the switch cases for the arrows
  var refOffset = exe.findCodes(" 68 14 27 00 00", PTYPE_HEX, false);
  if (refOffset.length === 0)
    return "Failed in Step 1 - PUSH missing";
  
  refOffset = refOffset[refOffset.length-1];//Assumption : The last one is the one we need. Previously there was only one match but recent clients have 2
    
  //Step 1b -  Find the Comparison for Hair Color after it
  var code = 
    " 8B 8B AB AB 00 00" //MOV ECX, DWORD PTR DS:[EBX + hCPtr]
  + " 41"                //INC ECX
  + " 8B C1"             //MOV EAX, ECX
  + " 89 8B AB AB 00 00" //MOV DWORD PTR DS:[EBX + hCPtr], ECX
  + " 83 F8 08"          //CMP EAX, 8
  + " 7E 06"             //JLE SHORT addr
  + " 89 BB AB AB 00 00" //MOV DWORD PTR DS:[EBX + hCPtr], EDI
  ;
  var type = 1;//VC6
  var cmpLoc = 15;
  var offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 0x60, refOffset + 0x220);

  if (offset === -1) {
    code =
      " FF 83 AB AB 00 00"             //INC DWORD PTR DS:[EBX + hCPtr]   
    + " 83 BB AB AB 00 00 08"          //CMP DWORD PTR DS:[EBX + hCPtr], 8
    + " 7E 0A"                         //JLE SHORT addr
    + " C7 83 AB AB 00 00 00 00 00 00" //MOV DWORD PTR DS:[EBX + hCPtr], 0
    ;
    type = 2;//VC9 - Style 1
    cmpLoc = 6;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 0x160, refOffset + 0x1C0);
  }
  
  if (offset === -1) {
    code =
      " BB 01 00 00 00"       //MOV EBX, 1
    + " 01 9D AB AB 00 00"    //ADD DWORD PTR SS:[EBP + hCPtr], EBX
    + " 83 BD AB AB 00 00 08" //CMP DWORD PTR SS:[EBP + hCPtr], 8
    + " 7E 06"                //JLE SHORT addr
    + " 89 BD AB AB 00 00"    //MOV DWORD PTR SS:[EBP + hCPtr], EDI
    ;
    type = 3;//VC9 - Style 2
    cmpLoc = 11;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 0x160, refOffset + 0x1C0);
  }
  
  if (offset === -1) {
    code =
      " 83 BB AB AB 00 00 00"           //CMP DWORD PTR DS:[EBX + hCPtr], 0
    + " 7D 0A"                          //JGE SHORT addr
    + " C7 83 AB AB 00 00 00 00 00 00"  //MOV DWORD PTR DS:[EBX + hCPtr], 0
    + " B8 07 00 00 00"                 //MOV EAX, 7 ; addr
    + " 39 83 AB AB 00 00"              //CMP DWORD PTR DS:[EBX + hCPtr], EAX
    + " 7E 06"                          //JLE SHORT addr2
    + " 89 83 AB AB 00 00"              //MOV DWORD PTR DS:[EBX + hCPtr], EAX
    ;
    type = 4;//VC9 & VC10 - New Make Char Style. Both color and style have scrollbars with a common case for switch
    cmpLoc = 0;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 0x300, refOffset + 0x3C0);
  }

  if (offset === -1) {
    code =
      " 89 AB AB AB 00 00"              //MOV DWORD PTR DS:[EBX + hCPtr], reg32_A
    + " 85 C0"                          //TEST EAX,EAX
    + " 79 0C"                          //JNS SHORT addr
    + " C7 83 AB AB 00 00 00 00 00 00"  //MOV DWORD PTR DS:[EBX + hCPtr], 0
    + " EB 0F"                          //JMP SHORT addr2
    + " 83 F8 08"                       //CMP EAX, 8 ; addr
    + " 7E 0A"                          //JLE SHORT addr2
    + " C7 83 AB AB 00 00 08 00 00 00"  //MOV DWORD PTR DS:[EBX + hCPtr], 8
    ;
    type = 5;//VC11 & VC10 (March 2014 onwards)
    cmpLoc = 6;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", refOffset + 0x300, refOffset + 0x3C0);
  }
  
  if (offset === -1)
    return "Failed in Step 1 - HairColor comparison missing";

  //Step 1c - Extract the EBX/EBP offset refering to Hair color index, Hair color limit and save the comparison location
  var hCPtr = exe.fetchHex(offset + 2, 4);
  var hCBegin = offset + cmpLoc;
  var hCEnd = offset + code.hexlength();
  
  if (type === 4)
    var hCLimit = 7;
  else 
    var hCLimit = 8;
  
  //Step 2a - Prep code for Hair style comparison
  switch (type) {
    case 1://VC6
    {
      var code2 =
        " 66 FF 8B AB 00 00 00"       //DEC WORD PTR DS:[EBX + hSPtr]
      + " 66 39 BB AB 00 00 00"       //CMP WORD PTR DS:[EBX + hSPtr], DI
      + " 75 09"                      //JNE SHORT addr
      + " 66 C7 83 AB 00 00 00 17 00" //MOV WORD PTR DS:[EBX + hSPtr], 17
      ;
      
      var code3 = 
        " 66 FF 83 AB 00 00 00"       //INC WORD PTR DS:[EBX + hSPtr]
      + " 66 8B 83 AB 00 00 00"       //MOV AX, WORD PTR DS:[EBX + hSPtr]
      + " 66 3D 18 00"                //CMP AX, 18
      + " 75 09"                      //JNE SHORT addr
      + " 66 C7 83 AB 00 00 00 01 00" //MOV WORD PTR DS:[EBX + hSPtr], 1
      ;
      
      cmpLoc = 7;
      break;
    }
    case 2://VC9 Style 1
    {
      var code2 =
        " 66 FF 8B AB 00 00 00" //DEC WORD PTR DS:[EBX + hSPtr]
      + " 0F B7 83 AB 00 00 00" //MOVZX EAX, WORD PTR DS:[EBX + hSPtr]
      + " 33 C9"                //XOR ECX, ECX
      + " 66 3B C8"             //CMP CX, AX
      + " 75 0C"                //JNE SHORT addr
      + " BA 17 00 00 00"       //MOV EDX, 17
      + " 66 89 93 AB 00 00 00" //MOV WORD PTR DS:[EBX + hSPtr], DX
      ;
      
      var code3 =
        " 66 FF 83 AB 00 00 00" //INC WORD PTR DS:[EBX + hSPtr]
      + " 0F B7 83 AB 00 00 00" //MOVZX EAX, WORD PTR DS:[EBX + hSPtr]
      + " B9 18 00 00 00"       //MOV ECX, 18
      + " 66 3B C8"             //CMP CX, AX
      + " 75 0C"                //JNE SHORT addr
      + " BA 01 00 00 00"       //MOV EDX, 1
      + " 66 89 93 AB 00 00 00" //MOV WORD PTR DS:[EBX + hSPtr], DX
      ;
      
      cmpLoc = 7;
      break;
    }
    case 3://VC9 Style 2
    {
      var code2 =
        " 66 01 B5 AB 00 00 00" //ADD WORD PTR SS:[EBP + hSPtr], SI ; ESI is ORed to -1 in prev statement
      + " 0F B7 85 AB 00 00 00" //MOVZX EAX, WORD PTR SS:[EBP + hSPtr]
      + " 33 C9"                //XOR ECX, ECX
      + " 66 3B C8"             //CMP CX, AX
      + " 75 0C"                //JNE SHORT 0046EECF
      + " BA 17 00 00 00"       //MOV EDX, 17
      + " 66 89 95 AB 00 00 00" //MOV WORD PTR SS:[EBP + hSPtr], DX
      ;
      
      var code3 =
        " 66 FF 85 AB 00 00 00" //INC WORD PTR DS:[EBP + hSPtr]
      + " 0F B7 85 AB 00 00 00" //MOVZX EAX, WORD PTR DS:[EBP + hSPtr]
      + " B9 18 00 00 00"       //MOV ECX, 18
      + " 66 3B C8"             //CMP CX, AX
      + " 75 0C"                //JNE SHORT addr
      + " BA 01 00 00 00"       //MOV EDX, 1
      + " 66 89 95 AB 00 00 00" //MOV WORD PTR DS:[EBP + hSPtr], DX
      ;
      
      cmpLoc = 7;
      break;
    }
    case 4:
    {
      if (exe.getClientDate() < 20130605) {//VC9
        var code2 = " 83 BB AB AB 00 00 00"; //CMP DWORD PTR DS:[EBX + hSPtr], 0
        cmpLoc = 0;
      }
      else {//VC10
        var code2 =
          " 89 93 AB AB 00 00"  //MOV DWORD PTR DS:[EBX + hSPtr], EDX
        + " 85 D2"              //TEST EDX, EDX
        ;
        cmpLoc = 6;
      }
      
      code2 +=
        " 7D 0A"                         //JGE SHORT addr
      + " C7 83 AB AB 00 00 00 00 00 00" //MOV DWORD PTR DS:[EBX + hSPtr], 0
      + " B8 16 00 00 00"                //MOV EAX, 16 ; addr
      + " 39 83 AB AB 00 00"             //CMP DWORD PTR DS:[EBX + hSPtr], EAX
      + " 7E 06"                         //JLE SHORT addr2
      + " 89 83 AB AB 00 00"             //MOV DWORD PTR DS:[EBX + hSPtr], EAX
      ;
      break;
    }
    case 5://VC11 & VC10 Style 2
    {
      var code2 =
        " 89 AB AB AB 00 00"              //MOV DWORD PTR DS:[EBX + hSPtr], reg32_A
      + " 85 C0"                          //TEST EAX,EAX
      + " 79 0C"                          //JNS SHORT addr
      + " C7 83 AB AB 00 00 00 00 00 00"  //MOV DWORD PTR DS:[EBX + hSPtr], 0
      + " EB 0F"                          //JMP SHORT addr2
      + " 83 F8 16"                       //CMP EAX, 16 ; addr
      + " 7E 0A"                          //JLE SHORT addr2
      + " C7 83 AB AB 00 00 16 00 00 00"  //MOV DWORD PTR DS:[EBX + hSPtr], 16
      ;
      cmpLoc = 6;
      break;
    }
  }
  
  //Step 2b - Find the Hair Style comparison
  offset = exe.find(code2, PTYPE_HEX, true, "\xAB", hCBegin - 0x300, hCBegin);
  
  if (offset === -1)
    offset = exe.find(code2, PTYPE_HEX, true, "\xAB", hCEnd, hCEnd + 0x200);
  
  if (offset === -1)
    return "Failed in Step 2 - HairStyle comparison missing";
  
  //Step 2c - Extract the EBX/EBP offset refering to Hair style index, Hair style limit addon and save the comparison location
  var hSPtr = exe.fetchHex(offset + 2, 4);
  var hSBegin = offset + cmpLoc;
  var hSEnd = offset + code2.hexlength();
  
  if (type < 4)//For old Make char window the values were in the range (0x01 - 0x17) instead of (0x00 - 0x16)
    var hSAddon = 1;
  else
    var hSAddon = 0;
  
  //Step 2d - Find the second comparison for Pre-VC9 clients (Left and Right arrows have seperate cases)
  if (typeof(code3) === "string") {
    offset = exe.find(code3, PTYPE_HEX, true, "\xAB", hSEnd + 0x50, hSEnd + 0x400);
    if (offset === -1)
      return "Failed in Step 2 - 2nd HairStyle comparison missing";
    
    var hSBegin2 = offset + cmpLoc;
    var hSEnd2 = offset + code3.hexlength();
  }
  
  //Step 3a - Get new Hair color limit from user
  var hCNewLimit = exe.getUserInput("$hairColorLimit", XTYPE_WORD, "Number Input", "Enter new hair color limit", hCLimit, hCLimit, 1000);//Sane Limit of 1000
  
  //Step 3b - Get new Hair style limit from user
  var hSNewLimit = exe.getUserInput("$hairStyleLimit", XTYPE_WORD, "Number Input", "Enter new hair style limit", 0x16, 0x16, 1000);//Sane Limit of 1000
  
  //Step 3c - Check if both limits are unchanged by user
  if (hCNewLimit === hCLimit && hSNewLimit === 0x16)
    return "Patch Cancelled - No limits changed";
  
  //Step 3d - Extract the Register code (for VC9 clients with new make char window Ref Register is EBP)
  if (type === 3)
    var rcode = 5;//EBP
  else
    var rcode = 3;//EBX
    
  if (hCNewLimit !== hCLimit) {
    //Step 4a - Prep & Inject new Hair Color comparison
    var free = _IHL_InjectComparison(rcode, hCPtr, 0, hCNewLimit, 4);
    if (free === -1)
      return "Failed in Step 4 - Not enough free space";
    
    //Step 4b - Put a JMP at Original Hair Color comparison & a CALL before the End of comparison
    _IHL_JumpNCall(hCBegin, hCEnd, free);
    
    //Step 4c - Fixup the Scrollbar for Hair Color
    if (_IHL_UpdateScrollBar(hCLimit, hCNewLimit) === -2)
      return "Failed in Step 4 - Not enough free space(2)";
  }
  
  if (hSNewLimit !== 0x16) {    
    //Step 5a - Prep & Inject mew Hair Style comparison
    var free = _IHL_InjectComparison(rcode, hSPtr, hSAddon, hSNewLimit + hSAddon, (type < 4) ? 2 : 4);
    if (free === -1)
      return "Failed in Step 5 - Not enough free space";
    
    //Step 5b - Put a JMP at Original Hair Style comparison & a CALL before the End of comparison
    _IHL_JumpNCall(hSBegin, hSEnd, free);
    
    //Step 5c - Put a JMP at Second Hair Style comparison & a CALL before the End of the comparison
    if (typeof(hSBegin2) !== "undefined")
      _IHL_JumpNCall(hSBegin2, hSEnd2, free);
    
    //Step 5d - Fixup the Scrollbar for Hair Style
    if (_IHL_UpdateScrollBar(0x16, hSNewLimit) === -2)
      return "Failed in Step 4 - Not enough free space(2)";
  }
  
  return true; 
}

function _IHL_InjectComparison(rcode, ptr, min, limit, opsize) {
  
  //Step 1a - Prep code for New comparison
  if (opsize === 2) {
    var pre = " 66";
  }
  else {
    var pre = "";
  }

  var code =
    pre + " 83" + (0xB8 + rcode).packToHex(1) + ptr + min.packToHex(1)      //CMP (D)WORD PTR DS:[reg32_A + hCPtr], 0
  + " 7D 0A"                                                                //JGE SHORT addr
  + pre + " C7" + (0x80 + rcode).packToHex(1) + ptr + min.packToHex(opsize) //MOV (D)WORD PTR DS:[reg32_A + hCPtr], 0
  + " 90"                                                                   //NOP
  ;
  
  if (limit > 0x7F)
    code += pre + " 81" + (0xB8 + rcode).packToHex(1) + ptr + limit.packToHex(opsize);//CMP (D)WORD PTR DS:[reg32_A + hCPtr], hCNewLimit
  else
    code += pre + " 83" + (0xB8 + rcode).packToHex(1) + ptr + limit.packToHex(1);     //CMP (D)WORD PTR DS:[reg32_A + hCPtr], hCNewLimit
  
  code +=
    " 7E 0A"                                                                  //JLE SHORT addr2
  + pre + " C7" + (0x80 + rcode).packToHex(1) + ptr + limit.packToHex(opsize) //MOV (D)WORD PTR DS:[reg32_A + hCPtr], hCNewLimit
  + " 90"                                                                     //NOP
  + " C3"                                                                     //RETN
  ;
  
  //Step 1b - Allocate space for it.
  var free = exe.findZeros(code.hexlength());
  
  //Step 1c - Insert the code in allocated space
  if (free !== -1)
    exe.insert(free, code.hexlength(), code, PTYPE_HEX);
  
  return free;
}

function _IHL_JumpNCall(begin, end, func) {//func is RAW

  //Step 1 - Create the JMP SHORT
  code = " EB" + ((end - 5) - (begin + 2)).packToHex(1);
  exe.replace(begin, code, PTYPE_HEX);
  
  //Step 2 - Next CALL the Comparison function   
  code = " E8" + (exe.Raw2Rva(func) - exe.Raw2Rva(end)).packToHex(4);
  exe.replace(end - 5, code, PTYPE_HEX); 
}

function _IHL_UpdateScrollBar(oldLimit, newLimit) {
  
  //Step 1a - Find the Scrollbar create CALLs
  code =
    " 6A" + (oldLimit+1).packToHex(1) //PUSH oldLimit+1
  + " 6A 01"                          //PUSH 1
  + " 6A" + oldLimit.packToHex(1)     //PUSH oldLimit
  + " E8"                             //CALL UIScrollBar::Create?
  ;
  
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  if (offsets.length === 0)
    return -1;
  
  //Step 1b - Extract the create function address
  var csize = code.hexlength();
  var func = exe.Raw2Rva(offsets[0] + csize + 4) + exe.fetchDWord(offsets[0] + csize);
  
  //Step 2a - Prep code to call the function with updated limit as arguments
  if (newLimit > 0x7E)
    code = " 68" + (newLimit + 1).packToHex(4);
  else
    code = " 6A" + (newLimit + 1).packToHex(1);
  
  code += " 6A 01";
  
  if (newLimit > 0x7F)
    code += " 68" + newLimit.packToHex(4);
  else
    code += " 6A" + newLimit.packToHex(1);
   
  code += 
    " E8" + GenVarHex(1)
  + " C3"
  ;
  
  //Step 2b - Allocate space for it
  var free = exe.findZeros(code.hexlength());
  if (free === -1)
    return -2;
  
  var freeRva = exe.Raw2Rva(free);
  
  //Step 2c - Fill in the blanks
  code = ReplaceVarHex(code, 1, func - (freeRva + code.hexlength() - 1));
  
  //Step 3a - Insert to allocated space
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);

  //Step 3b - Create a NOP sequence + CALL to the above at each of the matches
  for (var i = 0; i < offsets.length; i++) {    
    exe.replace(offsets[i], " 90".repeat(csize - 1), PTYPE_HEX);
    exe.replaceDWord(offsets[i] + csize, freeRva - exe.Raw2Rva(offsets[i] + csize + 4));
  }
  
  return 0;
}