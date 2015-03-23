function EnableShowName() {
  ////////////////////////////////////////////////////
  // GOAL: Skip LangType check when using /showname //
  //       inside CSession::SetTextType function    //
  ////////////////////////////////////////////////////
  
  //Step 1 - Find the Comparison
  var code =
      " 85 C0"    //TEST EAX, EAX
    + " 74 AB"    //JZ SHORT addr -> loading setting for showname
    + " 83 F8 06" //CMP EAX, 06
    + " 74 AB"    //JZ SHORT addr -> loading setting for showname
    + " 83 F8 0A" //CMP EAX, 0A
    ;
    
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset == -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace the first JZ with JMP - rest of JZ have no need to change
  exe.replace(offset+2, "EB", PTYPE_HEX);
  
  return true;
}