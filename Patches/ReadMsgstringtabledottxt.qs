function ReadMsgstringtabledottxt() {
  //////////////////////////////////////////////////////////////////
  // GOAL: Convert the conditional jump from LangType check       //
  //       to regular JMP so as to always load msgStringTable.txt //
  //       inside "InitMsgStrings" function                       //
  //////////////////////////////////////////////////////////////////
  
  //Step 1 - Find the comparison which is at the start of the function
  //         Old clients have slightly different pattern <- To Do
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceTypes
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found"

  var code = 
      " 83 3D " + LANGTYPE +" 00" // CMP DWORD PTR DS:[g_serviceType], 0
    + " 56"                       // PUSH ESI
    + " 75 24"                    // JNZ addr -> continue with string loading
    + " 33 C9"                    // XOR ECX, ECX
    + " 33 C0"                    // XOR EAX, EAX
    + " 8B FF"                    // MOV EDI, EDI
    ;

  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Change JNZ to JMP
  exe.replace(offset+8, "EB", PTYPE_HEX);
  
  return true;
}