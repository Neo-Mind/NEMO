function CancelToLoginWindow() {
  ////////////////////////////////////////////////
  // GOAL: Modify the Cancel Button Callback to //
  //       Disconnect and show the login Window //
  ////////////////////////////////////////////////
  
  //Step 1a - Find the case branch before the one we need (the one we need is similar to many)
  var code = 
      " 8D AB 49"              //LEA reg32_A, [ECX*2 + ECX]
    + " 8D AB AB AB AB AB 00"  //LEA reg32_B, [reg32_A*8 + refAddr]
    + " AB"                    //PUSH reg32_B
    + " 68 37 03 00 00"        //PUSH 337
    + " E8"                    //CALL addr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1 - Reference case not found";
  
  offset += code.hexlength() + 4;
  
  //Step 1b - Now look for our case after it. should be within around 0x80 bytes
  code =
      " 6A 01"    // PUSH 1
    + " 6A 02"    // PUSH 2
    + " 6A 11"    // PUSH 11
    ; 
  offset = exe.find(code, PTYPE_HEX, false, "", offset, offset + 0x80);
  if (offset === -1)
    return "Failed in Part 1 - Cancel call not found";
  
  //Step 2a - Find the offset of korean version of "Message"
  var offset1 = exe.findString("메시지", RVA);
  if (offset1 === -1)
    return "Failed in Part 2 - Message not found";
  
  //Step 2b - Find the start of our case, which will push 0x78 & 0x118 before pushing above string 
  //          For 2012 & older clients the 78 and 118 push is not there.
  var prefix =  
      " 6A 78"          //PUSH 78
    + " 68 18 01 00 00" //PUSH 118
    ;  
  code = " 68" + offset1.packToHex(4); //PUSH addr; "메시지"
  
  offset1 = exe.find( prefix + code, PTYPE_HEX, false, "", offset-10, offset);
  
  if (offset1 === -1)
    offset1 = exe.find( code, PTYPE_HEX, false, "", offset-10, offset);
  
  if (offset1 === -1)
    return "Failed in Part 2 - Case start missing";
  
  //Step 2c - Find the end point of the Message Box call.
  code = 
      " 0F 85 AB AB 00 00" //JNE addr
    + " 8B 0D"             //MOV reg32_A, DWORD PTR DS:[addr2]
    ;
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+40);
  if (offset2 === -1)
    return "Failed in Part 2 - End point missing";
  
  offset2 += code.hexlength() - 2;
  
  //Step 2d - Find the last argument push of Window Maker.
  code = 
      " 6A 02" //PUSH 2
    + " FF"    //CALL reg32_A or CALL DWORD PTR DS:[reg32_A+const]
    ;
  var offset3 = exe.find(code, PTYPE_HEX, false, "", offset2+6, offset2+30);
  if (offset3 === -1)
    return "Failed in Part 3 - Window Maker missing";
  
  //Step 3a - Find CConnection::Disconnect & CRagConnection::instanceR
  code =
      " 83 C4 08"       //ADD ESP, 8
    + " E8 AB AB AB 00" //CALL CRagConnection::instanceR
    + " 8B C8"          //MOV ECX, EAX
    + " E8 AB AB AB 00" //CALL CConnection::Disconnect
    + " B9 AB AB AB 00" //MOV ECX, OFFSET addr
    ;

  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 3";

  //Step 3b - Extract the function addresses. NO RVA conversion needed since we are traversing same section.
  var crag = offset +  8 + exe.fetchDWord(offset+4);
  var ccon = offset + 15 + exe.fetchDWord(offset+11);
  
  //Now we construct the replace code
  //Step 4a - First Disconnect from Char Server
  code =
      " E8" + genVarHex(1) //CALL CRagConnection::instanceR
    + " 8B C8"             //MOV ECX, EAX
    + " E8" + genVarHex(2) //CALL CConnection::disconnect
    ;
  
  //Step 4b - Prep args for Window Maker call which is same as the one between offset2 and offset3.
  //          Just need to extract and paste here
  code += exe.fetchHex(offset2, offset3-offset2);

  //Step 4c - Now add the Login Window code as the First argument (i.e. Last Push) and JMP to Window Maker call
  code += 
      " 68 23 27 00 00"    //PUSH 2723
    + " EB" + genVarHex(3) //JMP addr -> the CALL after PUSH 2
    ;
  
  //Step 4d - Fill in the Blanks
  code = remVarHex(code, 1, crag - (offset+5));
  code = remVarHex(code, 2, ccon - (offset+12));
  code = remVarHex(code, 3, (offset3+2) - (offset+code.hexlength()));
  
  //Step 5 - Replace with the prepared code
  exe.replace(offset, code, PTYPE_HEX);
  
  return true;
}