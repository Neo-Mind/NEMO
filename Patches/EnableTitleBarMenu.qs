function EnableTitleBarMenu() {
  //////////////////////////////////////////////////////////
  // GOAL: Change the Style parameter for CreateWindowExA //
  //////////////////////////////////////////////////////////
  
  //Step 1 - Find the pattern
  var code =
      " 68 00 00 C2 02" // PUSH 2C200000 - Style
    + " AB"             // PUSH reg32_A  - WindowName
    + " AB"             // PUSH reg32_B  - ClassName
    + " 6A 00"          // PUSH 0        - ExtStyle
    + " FF 15"          // CALL DWORD PTR DS:[<&USER32.CreateWindowExA>]
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Change 0x02C2 => 0x02C2 | WS_SYSMENU = 0x02CA
  exe.replace(offset+3, "CA", PTYPE_HEX);
  
  return true;
}