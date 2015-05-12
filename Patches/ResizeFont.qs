function ResizeFont() {
  ///////////////////////////////////////////////////////////////
  // GOAL: Change the Font height used in CreateFontA function // 
  ///////////////////////////////////////////////////////////////

  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do: Old clients have multiple reference for CreateFontA
  //        Need Fix for all of them
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  // Step 1a - Find CreateFontA function address
  var offset = getFuncAddr("CreateFontA");
  if (offset === -1)
    return "Failed in Step 1 - CreateFontA not found";
  
  // Step 1b - Find its reference
  var code = " FF 15" + offset.packToHex(4); // CALL DWORD PTR DS:[<&GDI32.CreateFontA>]
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - CreateFontA reference not found";

  // Step 2a - Check how the FontHeight is PUSHed.
  code = exe.fetchByte(offset-1);
  
  if (code >= 0x50 && code <= 0x57) {//PUSH reg32_A
    //Step 2b - Find the reg32_A value assignment
    code = ((code-0x50) << 3) | 0x46;
    code = " 8B" + code.packToHex(1) + " 04"; // MOV reg32_A, DS:[ESI+4] ; this reg32_A contains the original Font height and is pushed before call

    var preoffset = exe.find(code, PTYPE_HEX, false, " ", offset-0x30, offset);
    if (preoffset === -1)
      return "Failed in Step 2";
  
    // Step 2c - Extract the code to move up (Removing the MOV statement)
    code = exe.fetchHex(preoffset+3, (offset-1) - (preoffset+3));
    
    //Step 2d - Overwrite with the extracted code and NOP at the end.
    code += " 90";
    exe.replace(preoffset, code, PTYPE_HEX);
  }
  
  //Step 3a - Get the new Font height
  var inp = exe.getUserInput('$newFontHgt', XTYPE_BYTE, "Number Input", "Enter the new Font Height(1-127) - snaps to closest valid value", 10, 1, 127);
  
  //Step 3b - Replace with the PUSH newFontHeight
  code = " 6A" + (0-inp).packToHex(1) + " 90";
  exe.replace(offset-3, code, PTYPE_HEX);
  
  return true;
}