//########################################################################
//# Purpose: Hijack CreateFontA function calls to change the pushed Font #
//#          height before Jumping to actual CreateFontA                 #
//########################################################################

function ResizeFont() {
  
  //Step 1a - Find CreateFontA function address
  var offset = GetFunction("CreateFontA", "GDI32.dll");
  if (offset === -1)
    return "Failed in Step 1 - CreateFontA not found";
  
  //Step 1b - Find its references i.e. all called locations
  var offsets = exe.findCodes(" FF 15" + offset.packToHex(4), PTYPE_HEX, false); //CALL DWORD PTR DS:[<&GDI32.CreateFontA>]
  if (offsets.length === 0)
    return "Failed in Step 1 - CreateFontA calls missing";
 
  //Step 2a - Construct the Pseudo-CreateFontA function which changes the Font Height
  var code =
    GenVarHex(1)                  //This will contain RVA of 4 bytes later
  + " C7 44 E4 04" + GenVarHex(2) //MOV DWORD PTR SS:[ESP+4], newHeight
  + " FF 25" + GenVarHex(3)       //JMP DWORD PTR DS:[<&GDI32.CreateFontA>]
  ;
  
  var csize = code.hexlength();
  
  //Step 2b - Allocate space for the function.
  var free = exe.findZeros(csize);
  if (free === -1)
    return "Failed in Step 2 - Not enough space";
  
  var freeRva = exe.Raw2Rva(free);
  
  //Step 2c - Get the new Font height
  var newHeight = exe.getUserInput("$newFontHgt", XTYPE_BYTE, "Number Input", "Enter the new Font Height(1-127) - snaps to closest valid value", 10, 1, 127);
  if (newHeight === 10)
    return "Patch Cancelled - New value is same as old";
  
  //Step 2d - Fill in the Blanks
  code = ReplaceVarHex(code, 1, freeRva + 4);
  code = ReplaceVarHex(code, 2, -newHeight);
  code = ReplaceVarHex(code, 3, offset);
  
  //Step 3a - Insert it
  exe.insert(free, csize, code, PTYPE_HEX);
  
  for (var i = 0; i < offsets.length; i++) {
    //Step 3b - Replace CreateFontA calls with call to freeRva
    exe.replaceDWord(offsets[i] + 2, freeRva);
  }
  
  //Step 3c - Look for any JMP to CreateFontA calls as a failsafe 
  offset = exe.findCode(" FF 25" + offset.packToHex(4), PTYPE_HEX, false);
  
  //Step 3d - Same step as 3b
  if (offset !== -1)
    exe.replaceDWord(offset + 2, freeRva);
  
  return true;
}