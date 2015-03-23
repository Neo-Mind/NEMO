function IncreaseViewID() {
  //////////////////////////////////////////////////////////////
  // GOAL: To change the limit used for memory allocation and //
  //       looping through Headgear View IDs                  //
  //////////////////////////////////////////////////////////////
  
  //Step 1a - Find "ReqAccName" offset
  var offset = exe.findString("ReqAccName", RVA);
  if (offset === -1)
    return "Failed in Part 1 - Can't find ReqAccName";
      
  //Step 1b - Find where it is PUSHed - only 1 match would occur
  offset = exe.findCode(" 68" + offset.packToHex(4), PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1 - Can't find Function reference";
  
  //Step 2 - Get the new limit from user
  if (exe.getClientDate() > 20130000)//increased for newer clients.
    var oldValue = 2000;
  else
    var oldValue = 1000;

  exe.getUserInput("$newValue", XTYPE_DWORD, "Number input", "Enter the new Max Headgear View ID", oldValue, oldValue, 32000);//32000 could prove fatal.
  
  //Step 3 - Find and replace all occurrences of the old limit with the user specified value
  if (exe.getClientDate() > 20130605)
    var count = 3; //there are two cmp and 1 mov instruction
  else
    var count = 2; //there is 1 push and 1 cmp instruction
    
  offset -= 400;//Starting off 400 bytes before ReqAccName - should be more than enough
  for (var i = 1; i <= count; i++) {
    offset = exe.find(oldValue.packToHex(4), PTYPE_HEX, false, " ", offset);    
    if (offset === -1)
      return "Failed at Part 3: iteration no. " + i;
    
    exe.replace(offset, "$newValue", PTYPE_STRING);
    offset += 4;
  }
  
  return true;
}