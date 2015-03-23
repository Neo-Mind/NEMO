function FixChatAt() {
  ///////////////////////////////////////////////////////
  // GOAL: Make the Function checking @ to return true //
  //       when @ is found. The return value is set in //
  //       (this + const) pointer instead of EAX       //
  ///////////////////////////////////////////////////////
  
  // Step 1a - Prep code to find the checker
  if (exe.getClientDate() <= 20130605)
    var code = 
        " C6 46 29 00" // MOV BYTE PTR DS:[ESI+29], 0 ;this+29
      + " 5F"          // POP EDI
      + " 5E"          // POP ESI
      + " 5D"          // POP EBP
      + " B0 01"       // MOV AL, 1
    ;
  else
    var code =
        " C6 46 2D 00" // MOV BYTE PTR DS:[ESI+2D], 0 ;this+2D
      + " 5F"          // POP EDI
      + " 5E"          // POP ESI
      + " B0 01"       // MOV AL, 1
      + " 5B"          // POP EBX
    ;
    
  // Step 1b - Find the code
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 1";
  
  // Step 2 - Change 0 to 1
  exe.replace(offset+3, "01", PTYPE_HEX);

  return true;
}