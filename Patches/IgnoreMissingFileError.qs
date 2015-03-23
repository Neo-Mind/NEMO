function IgnoreMissingFileError() {
  ////////////////////////////////////////////////////////////
  // GOAL: Make "ErrorMsg" function which shows the Missing //
  //       File Errors return without doing anything        //
  ////////////////////////////////////////////////////////////
  
  // Step 1a - Prep code for finding the ErrorMsg(msg) function
  if (exe.getClientDate() <= 20130605) {
    var code = 
        " E8 AB AB AB FF"    // CALL GDIFlip
      + " 8B 44 24 04"       // MOV EAX, DWORD PTR SS:[ARG.1]
      + " 8B 0D AB AB AB AB" // MOV ECX, DWORD PTR DS:[g_hMainWnd]
      + " 6A 00"             // PUSH 0
      ;
  }
  else {
    var code = 
        " E8 AB AB AB FF"    // CALL GDIFlip
        " 8B 45 08"          // MOV EAX, DWORD PTR SS:[ARG.1]
      + " 8B 0D AB AB AB AB" // MOV ECX, DWORD PTR DS:[g_hMainWnd]
      + " 6A 00"             // PUSH 0
      ;
  }
  
  // Step 1b - Find the function
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  // Step 2 - Replace with a simple return + stack cleanup
  if (exe.getClientDate() <= 20130605)
    exe.replace(offset+5, " 31 C0 C3 90 90", PTYPE_HEX);
  else
    exe.replace(offset+5, " 31 C0 5D C3 90", PTYPE_HEX);

  return true;
}