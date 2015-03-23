function IncreaseScreenshotQuality() {
  ///////////////////////////////////////////////////////////////////////
  // GOAL: Modify the JPEG_CORE_PROPERTIES structure assignment inside //
  //       CRenderer::SaveJPG function to set jquality member to user  //
  //       specified value. DIBChannels = 3 assignment is overwritten  //
  ///////////////////////////////////////////////////////////////////////
  
  // Step 1 - Find the JPEG_CORE_PROPERTIES Assignments
  var code = 
      " C7 85 AB AB FF FF 03 00 00 00" // MOV DWORD PTR SS:[EBP-x], 3 ; DIBChannels = 3
    + " C7 85 AB AB FF FF 02 00 00 00" // MOV DWORD PTR SS:[EBP-y], 2 ; DIBColor = 2
    ;
  var type = 1;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1) {
    code =
        " C7 44 24 AB 03 00 00 00" // MOV DWORD PTR SS:[ESP+x], 3 ; DIBChannels = 3
      + " C7 44 24 AB 02 00 00 00" // MOV DWORD PTR SS:[ESP+y], 2 ; DIBColor = 2
      ;
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    type = 2;
  }
  if (offset === -1)
    return "Failed in part 1";

  //Step 2 - Get new quality value from user
  exe.getUserInput("$uQuality", XTYPE_BYTE, "Number Input", "Enter the new quality factor (0-100)", 50, 0, 100);
  
  //Step 3 - Convert the DIBChannels member assignment to jquality member assignment to new value
  if (type === 1) {
    var ebpOffset = exe.fetchDWord(offset+2) + 60;//jquality
    exe.replaceDWord(offset+2, ebpOffset);
    exe.replace(offset+6, "$uQuality", PTYPE_STRING);
  }
  else {
    var espOffset = exe.fetchByte(offset+3) + 60;//jquality
    exe.replace(offset, " C7 84 24" + espOffset.packToHex(4), PTYPE_HEX);//This will also overwrite the DIBColor assignment which is ok
    exe.replace(offset+7, "$uQuality", PTYPE_STRING);
    exe.replace(offset+8, " 00 00 00 90 90 90 90 90", PTYPE_HEX);//Filling remaining
  }
  
  return true;
}
