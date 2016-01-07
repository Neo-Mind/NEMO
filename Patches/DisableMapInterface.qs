//##################################################################
//# Purpose: Skip over all instances of World View Window creation #
//##################################################################

function DisableMapInterface() {
  
  //Step 1a - Find the creation pattern 1 - There should be exactly 2 matches (map button, shortcut)
  var code =
    " 68 8C 00 00 00"    //PUSH 8C
  + " B9 AB AB AB 00"    //MOV ECX, g_winMgr
  + " E8 AB AB AB AB"    //CALL UIWindowMgr::PrepWindow ?
  + " 84 C0"             //TEST AL, AL
  + " 0F 85 AB AB 00 00" //JNE addr
  + " 68 8C 00 00 00"    //PUSH 8C
  + " B9 AB AB AB 00"    //MOV ECX, g_winMgr
  + " E8"                //CALL UIWindowMgr::MakeWindow
  ;
  
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (offsets.length === 0)
    return "Failed in Step 1 - No matches found";
  
  //Step 1b - Change the First PUSH to a JMP to the JNE location and  change the JNE to JMP
  for (var i = 0; i < offsets.length; i++) {
    exe.replace(offsets[i], "EB 0F", PTYPE_HEX);
    exe.replace(offsets[i] + 17, "90 E9", PTYPE_HEX);
  }
  
  //Step 2a - Swap the JNE with a JNE SHORT and search pattern - Only for latest clients
  code = code.replace(" 0F 85 AB AB 00 00", " 75 AB");
  
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  
  //Step 2b - Repeat 1b for this set
  for (var i = 0; i < offsets.length; i++) {
    exe.replace(offsets[i], "EB 0F", PTYPE_HEX);
    exe.replace(offsets[i] + 17, "EB", PTYPE_HEX);
  }
  
  //Step 3a - Find pattern 2 - Only for latest clients (func calls functions from pattern 1)
  code = 
    " 68 8C 00 00 00" //PUSH 8C
  + " 8B AB"          //MOV ECX, reg32
  + " E8 AB AB AB FF" //CALL func ?
  + " 5E"             //POP ESI
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  //Step 3b - Replace PUSH with a JMP to the POP ESI
  if (offset !== -1) {
    exe.replace(offset, "EB 0A", PTYPE_HEX);
  }
  
  return true;
}