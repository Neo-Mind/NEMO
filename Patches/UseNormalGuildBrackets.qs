//#############################################
//# Purpose: Change the ¡º ¡» brackets to ( ) #
//#############################################
  
function UseNormalGuildBrackets() {
  
  //Step 1 - Find the format string used for displaying Guild names
  var offset = exe.findString("%s\xA1\xBA%s\xA1\xBB", RAW);
  if (offset === -1)
    return "Failed in Step 1";

  //Step 2 - Change the brackets to regular parentheses + blanks 
  //         (since we are converting from UNICODE to ASCII 1 extra byte would be there for each korean character)
  exe.replace(offset, "%s (%s) ", PTYPE_STRING);
  
  return true;
}