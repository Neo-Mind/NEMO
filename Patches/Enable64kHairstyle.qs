function Enable64kHairstyle() {
  ///////////////////////////////////////////////////
  // CODE: Disable hard-coded hair style table and //
  //       generate hair style IDs ad-hoc instead  //
  ///////////////////////////////////////////////////
  
  //--- Client Date Check ---//
  if (exe.getClientDate() <= 20111102)
    return "Unsupported client date";
  
  // Step 1a - Find the pattern string
  var code = " C0 CE B0 A3 C1 B7 5C B8 D3 B8 AE C5 EB 5C 25 73 5C 25 73 5F 25 73 2E 25 73 00"; // 인간족\머리통\%s\%s_%s.%s
  
  var offset = exe.find(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 1 - String not found";
  
  // Step 1b - Change the last %s to %u
  exe.replace(offset+18, "75", PTYPE_HEX);
  
  // Step 2a - Prep Code to Find the location before the pattern push,
  //           Which PUSHes the argument for %s (ECX)
  
  if (exe.getClientDate() <= 20130605) {
    code =
        " 8B 4C 24 AB" // MOV ECX, DWORD PTR SS:[LOCAL.x] ; ESP+const
      + " 73 04"       // JNB SHORT addr -> CMP EAX, 10
      + " 8D 4C 24 AB" // LEA ECX, SS:[LOCAL.x] ; ESP+const
      + " 83 FE 10"    // CMP EAX, 10
      ;

    var type = 0;
  }
  else {
    code =
        " 83 7D AB AB" // CMP DWORD PTR SS:[LOCAL.y], const1 ; EBP+const2
      + " 8B 4D D4"    // MOV ECX, DWORD PTR SS:[LOCAL.x] ; EBP+const3
      + " 73 03"       // JNB SHORT addr -> CMP EAX, 10
      + " 8D 4D D4"    // LEA ECX, SS:[LOCAL.x] ;  EBP+const3
      + " 83 F8 10"    // CMP EAX, 10
      ;

    var type = 1;
  }
  
  // Step 2b - Find the code
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 2";
  
  // Step 2c - Prep code to replace with - ECX is loaded from first argument
  if (type === 0) {
    code = " 8B 4D 00"; // MOV ECX,DWORD PTR SS:[EBP]
  }
  else {
    code =
        " 8B 4D 18" // MOV ECX, DWORD PTR SS:[EBP+18]
      + " 8B 09"    // MOV ECX, DWORD PTR DS:[ECX]
      ;
  }
  
  code +=
      " 90"        // NOP
    + " 85 C9"    // TEST ECX,ECX
    + " 75 02"    // JNZ  SHORT addr -> CMP EAX, 10h
    + " 41"       // INC ECX
    + " 41"       // INC ECX
    ;
    
  exe.replace(offset, code, PTYPE_HEX);
  
  // Step 3a - Void Table lookup.
  if (type === 0) {
    code =
        " 8B 45 00"  // MOV  EAX,DWORD PTR SS:[EBP]
      + " 8B 14 81"  // MOV  EDX,DWORD PTR DS:[ECX+EAX*4]
      ;
  }
  else {
    code =
        " 75 19"             // JNE SHORT addr1
      + " 8B 0E"             // MOV ECX, DWORD PTR DS:[ESI]
      + " 8B 15 AB AB AB 00" // MOV EDX, DWORD PTR DS:[addr2]
      + " 8B 14 8A"          // MOV EDX, DWORD PTR DS:[EDX+ECX*4]
      ;
  }
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 3";
  
  // Step 3b - Replace the lookup with ad-hoc
  if (type === 0) {
    exe.replace(offset+4 , " 11 90", PTYPE_HEX); //MOV EDX,DWORD PTR DS:[ECX]
  }
  else {
    exe.replace(offset+11, " 12 90", PTYPE_HEX); //MOV EDX,DWORD PTR DS:[EDX]
  }
    
  //Step 3c - New client special
  if (type === 1) {
    code =
        " 75 23"             // JNE SHORT addr1
      + " 8B 06"             // MOV EAX, DWORD PTR DS:[ESI]
      + " 8B 0D AB AB AB 00" // MOV ECX, DWORD PTR DS:[addr2]
      + " 8B 14 81"          // MOV EDX, DWORD PTR DS:[EDX+ECX*4]
      ;
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");

    if (offset == -1)
      return "Failed in part 3 - New Client Special";

    exe.replace(offset+11, " 11 90", PTYPE_HEX); //MOV EDX,DWORD PTR DS:[ECX]
  }

  //Step 4 - Lift limit that protects table from invalid access.
  if (type === 0) {
    code = 
        " 7C 05"                // JL SHORT addr1 -> MOV DWORD PTR SS:[EBP], 0D
      + " 83 F8 AB"             // CMP EAX, const
      + " 7E 07"                // JLE SHORT addr2 -> after next statement
      + " C7 45 00 0D 00 00 00" // MOV DWORD PTR SS:[EBP],0D
      ;
  }
  else {
    code =
        " 7C 05"             // JL SHORT addr1 -> MOV DWORD PTR SS:[ESI],0D
      + " 83 F8 AB"          // CMP EAX, const
      + " 7E 06"             // JLE SHORT addr2 -> after next statement
      + " C7 06 0D 00 00 00" // MOV DWORD PTR SS:[ESI],0D
      ;
  }
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 4";
  
  //Change JLE to JMP
  exe.replace(offset+5, "EB", PTYPE_HEX);
  
  return true;
}