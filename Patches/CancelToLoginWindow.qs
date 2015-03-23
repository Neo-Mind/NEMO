function CancelToLoginWindow() {
  ////////////////////////////////////////////////
  // GOAL: Modify the Cancel Button Callback to //
  //       Disconnect and show the login Window //
  ////////////////////////////////////////////////
  
  //Step 1a - Find the offset of korean version of "Message"
  var offset = exe.findString("메시지", RVA);
  if (offset === -1)
    return "Failed in Step 1 - Message not found";
  
  var msg = offset.packToHex(4);
    
  //Step 1b - Prep the code to find the Cancel Button callback
  //          by default, Message Box gets displayed & client closes
  var prefix =  
        " 6A 78"          //PUSH 78
      + " 68 18 01 00 00" //PUSH 118
      ;

  var code =  
        " 68" + msg // PUSH addr; "메시지"
      + " AB"       // PUSH reg32_A (contains 0)
      + " AB"       // PUSH reg32_B (contains 0)
      + " 6A 01"    // PUSH 1
      + " 6A 02"    // PUSH 2
      + " 6A 11"    // PUSH 11
      ;
  
  //Step 1c - Find the callback
  var overwriter = exe.findCode(prefix + code, PTYPE_HEX, true, "\xAB");
  
  if (overwriter === -1) {
    prefix = "";
    overwriter = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }    
  
  if (overwriter === -1)
    return "Failed in Step 1 - callback not found";
  
  //Step 1d - Calculate the location where the window call will be. Do not use this for searching
  code +=
      " E8 AB AB AB AB"    // CALL addr1
    + " 83 C8 AB"          // ADD ESP, x
    + " 51"                // PUSH reg32
    + " B8 AB AB AB AB"    // MOV reg32, addr2
    + " E8 AB AB AB AB"    // CALL addr3
    + " 3D AB AB AB AB"    // CMP EAX, const
    + " 0F 85 AB AB AB 00" // JNE addr4
    ;
    
  var winoffset = prefix.hexlength() + code.hexlength();
  
  //Step 2a - Find CConnection::Disconnect & CRagConnection::instanceR
  code =
      " 68 AB AB AB 00" // PUSH addr ; ASCII "5,01,2600,1832"
    + " 51"             // PUSH ECX
    + " FF D0"          // CALL EAX
    + " 83 C4 08"       // ADD ESP, 8
    + " E8 AB AB AB AB" // CALL CRagConnection::instanceR
    + " 8B C8"          // MOV ECX, EAX
    + " E8"             // CALL CConnection::Disconnect
    ;

  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 2 - ";

  //Step 2b - Extract the function addresses. NO RVA conversion needed since we are traversing same section.
  var crag = offset + 16 + exe.fetchDWord(offset+12);
  var ccon = offset + 23 + exe.fetchDWord(offset+19);

  //Step 3a - Prep Replace code: Disconnect from Char server
  code =    
      " E8" + (crag - (overwriter + 5 )).packToHex(4) // CALL CRagConnection::instanceR
    + " 8B C8"                                         // MOV ECX, EAX
    + " E8" + (ccon - (overwriter + 12)).packToHex(4) // CALL CConnection::disconnect
    ;
        
  //Step 3b - Prep Replace code: Assign Window maker code (already present a little down below. just need to extract and use it).
  //          this is what the winoffset was calculating. Window maker's address would be in EDX
  code += exe.fetchHex(overwriter + winoffset, 15);

  //Step 3c - Prep Replace code: Provide Login Window"s code and call the Window maker.
  code +=
      " 68 23 27 00 00"  //PUSH 2723
    + " FF D0"           //CALL EAX
    + " EB" +  ((winoffset + 15 + 4) - (12 + 15 + 9)).packToHex(1) //JMP to PUSH ESI below - skipping rest.
    ;
    
  //Step 4 - Replace with the prepared code
  exe.replace(overwriter, code, PTYPE_HEX);
  
  return true;
}