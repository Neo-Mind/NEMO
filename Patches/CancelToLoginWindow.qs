function CancelToLoginWindow() {
  ////////////////////////////////////////////////
  // GOAL: Modify the Cancel Button Callback to //
  //       Disconnect and show the login Window //
  ////////////////////////////////////////////////
  
  //Step 1a - Find the case branch that occurs before the Cancel Button callback case.
  var code = 
      " 8D AB 49"              //LEA reg32_A, [ECX*2 + ECX]
    + " 8D AB AB AB AB AB 00"  //LEA reg32_B, [reg32_A*8 + refAddr]
    + " AB"                    //PUSH reg32_B
    + " 68 37 03 00 00"        //PUSH 337
    + " E8"                    //CALL addr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1 - Reference case missing";
  
  offset += code.hexlength() + 4;
  
  //Step 1b - Find address of 메시지 => Korean version of "Message"
  var offset2 = exe.findString("\xB8\xDE\xBD\xC3\xC1\xF6", RVA);
  if (offset2 === -1)
    return "Failed in Part 1 - Message not found";
  
  //Step 1c - Find the Callback case
  code = 
      " 68" + offset2.packToHex(4) //PUSH addr ; "메시지"
    + " AB"    //PUSH reg32_A ; contains 0
    + " AB"    //PUSH reg32_A
    + " 6A 01" //PUSH 1
    + " 6A 02" //PUSH 2
    + " 6A 11" //PUSH 11
    ;
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x80);
  
  if (offset2 === -1) {
    var zeroPush = " 6A 00";
    code = code.replace(" AB AB", " 6A 00 6A 00");
    offset2 = exe.find(code, PTYPE_HEX, false, "", offset, offset + 0x80);//no wildcard needed since we dont have them anymore
  }
  else {
    var zeroPush = exe.fetchHex(offset2+5, 1);
  }
  
  if (offset2 === -1)
    return "Failed in Part 1 - Callback case missing";
  
  //Step 1d - Check if there is a PUSH 118 before offset2. If yes the case begins with a PUSH 78 followed by PUSH 118 then the above code
  //          for 2013+ clients
  if (exe.fetchHex(offset2-5, 5) === " 68 18 01 00 00")
    offset = offset2 - 7;
  else
    offset = offset2;
  
  offset2 += code.hexlength();
  
  //Step 2a - Find the end point of the message box call. There will be a comparison for the return code.
  code = 
      " 3D AB 00 00 00"    //CMP EAX, const
    + " 0F 85 AB AB 00 00" //JNE addr; skip quitting.
    ;
  
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset2, offset2 + 40);
  if (offset2 === -1)
    return "Failed in Part 2 - MsgBox End missing";
  
  offset2 += code.hexlength();
  
  //Step 2b - Next we find PUSH 2 below as argument to the register call (CALL reg32 / CALL DWORD PTR DS:[reg32+18]) - Window Maker?.
  //          What we need to do is to substitute the 2 with 2723 for it to show Login Window instead of quitting.
  code =
      zeroPush.repeat(3) //PUSH reg32 x3 or PUSH 0 x3
    + " 6A 02";
  
  var offset3 = exe.find(code, PTYPE_HEX, false, "", offset2, offset2+30);
  if (offset3 === -1)
    return "Failed in Part 2 - Argument PUSH missing";
  
  offset3 += code.hexlength()-2;
  
  //Step 3a - Find CConnection::Disconnect & CRagConnection::instanceR
  code =
      " 83 C4 08"       //ADD ESP, 8
    + " E8 AB AB AB 00" //CALL CRagConnection::instanceR
    + " 8B C8"          //MOV ECX, EAX
    + " E8 AB AB AB 00" //CALL CConnection::Disconnect
    + " B9 AB AB AB 00" //MOV ECX, OFFSET addr
    ;
  
  var offsetT = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offsetT === -1)
    return "Failed in Step 3";

  //Step 3b - Extract the function addresses. NO RVA conversion needed since we are traversing same section.
  var crag = (offsetT +  8) + exe.fetchDWord(offsetT + 4);
  var ccon = (offsetT + 15) + exe.fetchDWord(offsetT + 11);
  
  //Now we Construct the replace code
  
  //Step 4a - First Disconnect from Char Server
  code =
      " E8" + genVarHex(1) //CALL CRagConnection::instanceR
    + " 8B C8"             //MOV ECX, EAX
    + " E8" + genVarHex(2) //CALL CConnection::disconnect
    ;
  
  //Step 4b - Extract and paste all the code between offset2 and offset3 to prep the register call (Window Maker)
  code += exe.fetchHex(offset2, offset3 - offset2);
  
  //Step 4c - PUSH 2723 and go to the location after the original PUSH 2 => offset3 + 2
  code +=
      " 68 23 27 00 00"    //PUSH 2723
    + " EB" + genVarHex(3) //JMP addr; after PUSH 2 . It is supposed to be 1 byte but the extra zeros wont matter.
    ;
  
  //Step 4d - Fill in the Blanks
  code = remVarHex(code, 1, crag - (offset + 5));
  code = remVarHex(code, 2, ccon - (offset + 12));
  code = remVarHex(code, 3, (offset3 + 2) - (offset + code.hexlength()-3));
  
  //Step 4e - Replace with prepared code at offset.
  exe.replace(offset, code, PTYPE_HEX);
  
  return true;
}