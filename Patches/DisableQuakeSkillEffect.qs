function DisableQuakeEffect() {
  ////////////////////////////////////////////////////////////
  // GOAL: Modify CView::SetQuakeInfo and CView::SetQuake   //
  //       functions to return without assigning any values //
  ////////////////////////////////////////////////////////////
  
  // To Do - The Pattern is different in old client. Find when it changed.
  
  // Step 1 - Prep codes to find the two functions
  if (exe.getClientDate() <= 20130605) {
    var code =
        " D9 44 24 04" // FLD DWORD PTR SS:[ARG.1]
      + " D9 59 04"    // FSTP DWORD PTR DS:[ECX+4]
      + " D9 44 24 0C" // FLD DWORD PTR SS:[ARG.3]
      + " D9 59 0C"    // FSTP DWORD PTR DS:[ECX+0C]
      + " D9 44 24 08" // FLD DWORD PTR SS:[ARG.2]
      + " D9 59 08"    // FSTP DWORD PTR DS:[ECX+8]
      + " C2 0C 00"    // RETN 0C
      ;
    
    var code2 = " 8B 44 24 04" ; // MOV EAX, DWORD PTR SS:[ARG.1]
  }
  else {
    var code =
        " 55"       // PUSH EBP
      + " 8B EC"    // MOV EBP, ESP
      + " D9 45 08" // FLD DWORD PTR SS:[ARG.1]
      + " D9 59 04" // FSTP DWORD PTR DS:[ECX+4]
      + " D9 45 10" // FLD DWORD PTR SS:[ARG.3]
      + " D9 59 0C" // FSTP DWORD PTR DS:[ECX+0C]
      + " D9 45 0C" // FLD DWORD PTR SS:[ARG.2]
      + " D9 59 08" // FSTP DWORD PTR DS:[ECX+8]
      + " 5D"       // POP EBP
      + " C2 0C 00" // RETN 0C
      ;
      
    var code2 = 
        " 55"       // PUSH EBP
      + " 8B EC"    // MOV EBP, ESP
      + " 8B 45 08" // MOV EAX, DWORD PTR SS:[ARG.1]
      ;
  }  

  //Step 2 - Find the functions. SetQuake should be next function after SetQuakeInfo
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 2 - SetQuakeInfo not found";

  var offset2 = exe.find(code2, PTYPE_HEX, false, "", offset + code.hexlength());
  if (offset2 === -1)
    return "Failed in part 2 - SetQuake not found";
    
  //Step 3 - Replace the functions.
  exe.replace(offset , " C2 0C 00", PTYPE_HEX);
  exe.replace(offset2, " C2 14 00", PTYPE_HEX);
  
  return true;
}