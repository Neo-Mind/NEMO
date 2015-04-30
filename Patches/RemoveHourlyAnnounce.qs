function RemoveHourlyAnnounce() {
  /////////////////////////////////////////////////////
  // GOAL: Remove Hourly Game Grade and Play Time    //
  //       Announcements by ignoring the comparisons //
  //       inside CRenderer::DrawAgeRate function    //
  /////////////////////////////////////////////////////

  // To do  - Find out which date onwards Play Time announcement started
  
  // Step 1a - Find the comparison for Game Grade
  var code =
      " 75 AB"       //JNZ SHORT addr1
    + " 66 8B 45 AB" //MOV AX, WORD PTR SS:[LOCAL.x]
    + " 66 85 C0"    //TEST AX, AX
    + " 75"          //JNZ SHORT addr2
    ;  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" 8B 45", " 8B 44 24");//change EBP-x to ESP+y
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1) {
    code = code.replace(" 66", "");//change the AX to EAX and WORD PTR to DWORD PTR in the MOV statement
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1) 
    return "Failed in part 1";

  // Step 2 - Change JNZ to JMP
  exe.replace(offset, "EB", PTYPE_HEX);

  // Step 3a - Find Time divider before the PlayTime Reminder comparison. Not there in old clients 
  code =  
      " B8 B1 7C 21 95" // MOV EAX, 95217CB1
    + " F7 E1"          // MUL ECX
    ;
    
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 3 - Magic Number not found";

  // Step 3b - Find the JLE after it (below the TEST/CMP instruction) 
  code = " 0F 8E AB AB 00 00" //JLE SHORT addr
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+7, offset+30);
  if (offset === -1)
    return "Failed in Part 3 - Comparison not found";
    
  // Step 4 - Change JLE to JMP
  exe.replace(offset, " 90 E9", PTYPE_HEX);
  
  return true;
}