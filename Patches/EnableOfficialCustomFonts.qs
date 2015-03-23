function EnableOfficialCustomFonts() {
  /////////////////////////////////////////////////////////////
  // GOAL: OVerride LangType check for reading .eot fonts //
  /////////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - Not present in old clients. Find when it started
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1 - Find the pattern
  var code =
        " 0F 85 AE 00 00 00"  //JNE addr - Skips .eot loading
      + " E8 AB AB AB FF"     //CALL func
      ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";

  //Step 2 - Replace JNE instruction with NOPs
  exe.replace(offset, " 90 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}