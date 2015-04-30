function UsePlainTextDescriptions() {
  ///////////////////////////////////////////////////////
  // GOAL: Modify the condition inside 'DataTxtDecode' //
  //       function so as to always use plain text     //
  //       irrespective of LangType                    //
  ///////////////////////////////////////////////////////
  
  //To Do - Pattern is different in old clients. Find when it changed
  
  // Step 1 - Find the comparison in the DataTxtDecode function
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";
 
  var code =
      " 83 3D" + LANGTYPE + " 00" //CMP DWORD PTR DS:[g_serviceType], 0
    + " 75 AB" //JNZ SHORT addr
    + " 56"    //PUSH ESI
    + " 57"    //PUSH EDI
    ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" 75 AB 56 57", " 75 AB 57");//remove PUSH ESI
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Change JNE/JNZ to JMP
  exe.replace(offset+7, "EB", PTYPE_HEX);
  
  return true;
}