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
  
  //Step 1a - Find the Swear Filter call. Based on client date the starting portion of the pattern changes.
  var code = 
      " E8 AB AB AB AB" //CALL func -> Contains CInsultFilter::IsBadSentence
    + " 33 C9"          //XOR ECX,ECX
    + " 84 C0"          //TEST AL,AL
    + " 0F 94"          //SETE reg8 ; reg8 could be either AL or CL, of-course the code could change all over again
    ;
  
  var prefix = " 50"; //PUSH EAX
  var offset = exe.findCode(prefix + code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    prefix = " FF 75 08"; //PUSH DWORD PTR SS:[ARG.1]
    offset = exe.findCode(prefix + code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Part 1";
  
  var repOffset = prefix.hexlength() + 7;
  
  //Step 1b - Find the return point in the function
  if (exe.getClientDate() > 20130605)
    code = " 5D"; //POP EBP
  else
    code = "";
    
  code += " C2 04 00"; //RETN 4
  
  var retOffset = exe.find(code, PTYPE_HEX, false, "", offset+11, offset+20);
  if (retOffset === -1)
    return "Failed in Part 1 - return not found";
  
  //Step 2 - Replace the AL assignment
  code = 
      " 30 C0" //XOR AL, AL
    + " 90".repeat(retOffset-(repOffset+2))//Fill with NOPs till RETN
    ;
  exe.replace(repOffset, code, PTYPE_HEX);

  return true;
}