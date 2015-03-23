function ResizeFont() {
  ///////////////////////////////////////////////////////////////
  // GOAL: Change the Font height used in CreateFontA function // 
  ///////////////////////////////////////////////////////////////

  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do: Old clients have multiple reference for CreateFontA
  //        Need Fix for all of them
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  // Step 1a - Find CreateFontA function address
  var cfonta = exe.findFunction("CreateFontA", PTYPE_STRING, true);
  if (cfonta === -1)
    return "Failed in Step 1 - CreateFontA not found";
  
  // Step 1b - Find its reference
  var code =
      " 52"                           // PUSH EDX
    + " FF 15" + cfonta.packToHex(4) // CALL DWORD PTR DS:[<&GDI32.CreateFontA>]
    ;

  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - CreateFontA reference not found";

  // Step 2 - Find the FontHeight parameter setting
  code = "8B 56 04"; // MOV EDX, DS:[ESI+4] ; this EDX contains the original Font height and is pushed before call
  
  var preoffset = exe.find(code, PTYPE_HEX, false, " ", offset-0x30, offset);
  if (preoffset === -1)
    return "Failed in Step 2";
  
  // Step 3a - Extract the code to move up 
  code = exe.fetchHex(preoffset+3, offset - (preoffset+3));
  
  // Step 3b - Get the new Font height
  var inp = exe.getUserInput('$newFontHgt', XTYPE_BYTE, "Number Input", "Enter the new Font Height(1-127) - snaps to closest valid value", 10, 1, 127);
  
  // Step 4 - Replace with the extracted code + PUSH newFontHeight
  code = code + ' 90 90 6A' + (0-inp).packToHex(1);  
  exe.replace(preoffset, code, PTYPE_HEX);
  
  return true;
}