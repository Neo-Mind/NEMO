function FixChatAt() {
  ///////////////////////////////////////////////////////
  // GOAL: Make the Function checking @ to return true //
  //       when @ is found. The return value is set in //
  //       (this + const) pointer instead of EAX       //
  ///////////////////////////////////////////////////////
  
  // Step 1 - Find the Checker
  var code =
      " 74 04"       //JZ SHORT addr -> POP EDI below
    + " C6 AB AB 00" //MOV BYTE PTR DS:[reg32_A+const], 0 ;this pointer + const
    + " 5F"          //POP EDI
    + " 5E"          //POP ESI
    ;
  //Note: The above will be followed by a MOV AL,1 and POP EBP/EBX statements
  
  // Step 1b - Find the code*/
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  // Step 2 - Change 0 to 1
  exe.replace(offset+5, " 01", PTYPE_HEX);

  return true;
}