function UsePlainTextDescriptions() {
  ///////////////////////////////////////////////////////
  // GOAL: Modify the condition inside 'DataTxtDecode' //
  //       function so as to always use plain text     //
  //       irrespective of LangType                    //
  ///////////////////////////////////////////////////////
  
  //To Do - Pattern is different in old clients. Find when it changed
  
  // Step 1 - Find the comparison in the DataTxtDecode function
  if (exe.getClientDate() <= 20130605) {
    var code = 
        " 75 54"       // JNZ SHORT addr
      + " 56"          // PUSH ESI
      + " 57"          // PUSH EDI
      + " 8B 7C 24 0C" // MOV EDI, DWORD PTR SS:[ARG.1]
      ;
  }
  else {
    var code =
        " 75 51"    // JNZ SHORT addr
      + " 56"       // PUSH ESI
      + " 57"       // PUSH EDI
      + " 8B 7D 08" // MOV EDI, DWORD PTR SS:[ARG.1]
      ;
  }
  
  var offset = exe.findCode(code, PTYPE_HEX, false);  
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Change JNE/JNZ to JMP
  exe.replace(offset, "EB", PTYPE_HEX);
  
  return true;
}