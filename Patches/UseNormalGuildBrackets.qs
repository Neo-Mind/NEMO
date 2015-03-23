function UseNormalGuildBrackets() {
  /////////////////////////////////////////
  // GOAL: Change the ¡º ¡» brackets to ( ) //
  /////////////////////////////////////////
  
  //Step 1 - Find the format string used for displaying Guild names
  var offset = exe.findString("%s" + "¡º" + "%s" + "¡»", RAW);
  if (offset === -1)
    return "Failed in part 1";

  //Step 2 - Change the brackets to regular parentheses + blanks 
  //         (since we are converting from UNICODE to ASCII 1 extra byte would be there for each character)
  exe.replace(offset, "%s (%s) ", PTYPE_STRING);
  
  return true;
}