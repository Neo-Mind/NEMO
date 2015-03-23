function RemoveHourlyAnnounce() {
  /////////////////////////////////////////////////////
  // GOAL: Remove Hourly Game Grade and Play Time    //
  //       Announcements by ignoring the comparisons //
  //       inside CRenderer::DrawAgeRate function    //
  /////////////////////////////////////////////////////
  
  // Step 1a - Prep code to find the comparison for Game Grade
  if (exe.getClientDate() <= 20130605) {
    var code =
        " 75 34"       // JNZ SHORT addr
      + " 66 8B 44 24" // MOV AX, WORD PTR SS:[LOCAL.x]
      ;
  }
  else {
    var code =
        " 75 33"       // JNZ SHORT addr
      + " 66 8B 45 E8" // MOV AX, WORD PTR SS:[LOCAL.x]
      ;
  }
  
  // Step 1b - Find the code
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 1";

  // Step 2 - Change JNZ to JMP
  exe.replace(offset, "EB", PTYPE_HEX);

  // Step 3 - Find comparison for PlayTime Reminder. Not there in old clients
  code =  
      " B8 B1 7C 21 95" // MOV EAX, 95217CB1
    + " F7 E1"          // MUL ECX
    ;
    
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 3";

  // Step 4 - Change JLE to JMP which will be at specific location from offset
  if (exe.getClientDate() <= 20130605)
    exe.replace(offset+14, " 90 E9", PTYPE_HEX);
  else
    exe.replace(offset+29, " 90 E9", PTYPE_HEX);
  
  return true;
}