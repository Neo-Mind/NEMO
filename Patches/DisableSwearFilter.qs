function DisableSwearFilter() {
  ///////////////////////////////////////////////////////////
  // GOAL: Ignore the Swear Filter call and return 0 always//
  ///////////////////////////////////////////////////////////

  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // Note: It"s better to use a generic approach as some calls to 
  //       CInsultFilter::IsBadSentence can not be found, else it
  //       would be a huge pain to ensure for every location.
  //       However this wont work on old clients ~ To Do
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  if (exe.getClientDate() <= 20130605) {
    //Step 1 - Find the Swear Filter call - pattern matches twice but only the first one is the one we want
    var code =    
        " 8B 44 24 04"    // MOV EAX,DWORD PTR SS:[ARG.1]
      + " 50"             // PUSH EAX
      + " E8 AB AB FF FF" // CALL func -> Contains CInsultFilter::IsBadSentence
      + " 33 C9"          // XOR ECX,ECX
      + " 84 C0"          // TEST AL,AL
      + " 0F 94 C1"       // SETE CL
      + " 8A C1"          // MOV AL,CL
      + " C2 04 00"       // RETN 4
      ;

    var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
    if (offsets.length !== 2)
      return "Failed in part 1";

    //Step 2 - Replace the TEST instruction with XOR AL, AL then SETE will make CL = 0 i.e. AL = 0
    exe.replace(offsets[0]+17, " 30 C0", PTYPE_HEX);
  }
  else {
    //Step 1 - Find the Swear Filter call
    var code =
        " 8B 45 08"       // MOV EAX,DWORD PTR SS:[ARG.1]
      + " 50"             // PUSH EAX
      + " E8 AB AB AB FF" // CALL func -> Contains CInsultFilter::IsBadSentence
      + " 33 C9"          // XOR ECX,ECX
      + " 84 C0"          // TEST AL,AL
      + " 0F 94 C0"       // SETZ AL
      + " 5D"             // POP EBP
      + " C2 04 00"       // RETN 4
      ;

    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset === -1)
      return "Failed in part 1";
    
    //Step 2 - Replace the TEST + SETZ instruction with XOR AL, AL followed by NOP which will make AL = 0
    exe.replace(offset+13, " 30 C0 90", PTYPE_HEX);
  }
  
  return true;
}