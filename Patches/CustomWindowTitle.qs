function CustomWindowTitle() {
  /////////////////////////////////////////////////////////////////////////
  // GOAL: Set Custom Window Title by Replacing the reference of         //
  //       "Ragnarok" to User Specified Title. The new title string will //
  //       be stored by overwriting an existing url which is unused      //
  /////////////////////////////////////////////////////////////////////////
  
  //Step 1a - Find the offset of the URL to overwrite  
  var strOff = exe.findString("http://ro.hangame.com/login/loginstep.asp?prevURL=/NHNCommon/NHN/Memberjoin.asp", RAW);
  if (strOff === -1)
    return "Failed in part 1";
  
  //Step 1b - Get the new Title from User
  var title = exe.getUserInput("$customWindowTitle", XTYPE_STRING, "String Input - maximum 60 characters", "Enter the new window Title", "Ragnarok", 1, 60);
  if (title.trim() === "Ragnarok")
    return true;
    
  //Step 1c - Overwrite URL with the new Title
  exe.replace(strOff, "$customWindowTitle", PTYPE_STRING);
  
  //Step 2a - Find offset of 'Ragnarok'
  var code = exe.findString("Ragnarok", RVA).packToHex(4);  
  
  //Step 2b - Find its reference
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if( offset === -1)
    return "Failed in part 2";

  //Step 3 - Replace the original reference with the URL offset.
  exe.replaceDWord(offset, exe.Raw2Rva(strOff));
  
  return true;
}