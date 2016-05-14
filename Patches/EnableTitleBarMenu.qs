//###########################################################################################
//# Purpose: Change the Style parameter used for CreateWindowExA call to include WS_SYSMENU #
//###########################################################################################

function EnableTitleBarMenu() {
  
  //Step 1a - Find the function's address
  var offset = GetFunction("CreateWindowExA", "USER32.dll");
  if (offset === -1)
    return "Failed in Step 1 - CreateWindowExA not found";
  
  //Step 1b - Find the Style pushes
  var code = " 68 00 00 C2 02"; //PUSH 2C200000 - Style
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Step 1 - Style not found";
 
  //Step 1c - Find which one precedes Function call
  code = " FF 15" + offset.packToHex(4); //CALL DWORD PTR DS:[<&USER32.CreateWindowExA>]
  
  for (var i = 0; i < offsets.length; i++) {
    offset = exe.find(code, PTYPE_HEX, false, "", offsets[i] + 8, offsets[i] + 29);//5 + 3 for minimum operand pushes, 5 + 18 for maximum operand pushes + 6 for function call
    if (offset !== -1) {
      offset = offsets[i];//Get the corresponding Style push offset
      break;
    }
  }
  
  if (offset === -1)
    return "Failed in Step 1 - Function call not found";
  
  //Step 2 - Change 0x02C2 => 0x02C2 | WS_SYSMENU = 0x02CA
  exe.replace(offset + 3, "CA", PTYPE_HEX);
  
  return true;
}