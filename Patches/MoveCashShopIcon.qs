//##########################################################################
//# Purpose: Modify the coordinates send as argument to UIWindow::UIWindow #
//#          for Cash Shop Button to the user specified ones               #
//##########################################################################

function MoveCashShopIcon() {
  
  //Step 1a - Find the XCoord calculation pattern
  var code =
    " 81 EA BB 00 00 00" //SUB EDX, 0BB
  + " 52"                //PUSH EDX 
  ;
  var tgtReg = 2;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace("81 EA", "2D").replace("52", "50");//change EDX to EAX
    tgtReg = 0;
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1) {
    code = code.replace("50", "6A 10 50");//PUSH 10 before PUSH EAX
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    
    if (offset !== -1) {//put the PUSH 10 before the CALL
      exe.replace(offset, " 6A 10", PTYPE_HEX);
      offset += 2;
    }
  }
  
  if (offset === -1)
    return "Failed in Step 1 - Coord calculation missing";
  
  //Step 1b - Accomodate for extra bytes by NOPing those
  if (tgtReg === 2) {//EDX
    exe.replace(offset, "90", PTYPE_HEX);
    offset++;
  }
  
  //Step 1c - Find the pattern where the Screen Size is picked up (Width is at 0x24, Height is at 0x28) - We need the address of g_ScreenStats
  code = 
    " 8B 0D AB AB AB 00" //MOV ECX, DWORD PTR DS:[g_ScreenStats]
  + " 8B"                //MOV reg32_A, DWORD PTR DS:[reg32_B+const]
  ;
  
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x18, offset);
  
  if (offset2 === -1) {
    code = code.replace("8B 0D", "A1");
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x18, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Step 1 - Screen Size retrieval missing";
  
  //Step 1d - Extract the g_ScreenStats
  var g_ScreenStats = exe.fetchHex(offset2 + code.hexlength() - 5, 4);
  
  //Step 2a - Get User Coords
  var xCoord = exe.getUserInput("$cashShopX", XTYPE_WORD, "Number Input", "Enter new X coordinate:", -0xBB, -0xFFFF, 0xFFFF);
  var yCoord = exe.getUserInput("$cashShopY", XTYPE_WORD, "Number Input", "Enter new Y coordinate:", 0x10, -0xFFFF, 0xFFFF);
  
  if (xCoord === -0xBB && yCoord === 0x10)
    return "Patch Cancelled - New coordinate is same as old";
  
  //Step 2b - Prep code to insert based on the sign of each coordinate (negative values are relative to width and height respectively)
  code = "";
  
  if (yCoord < 0) {
    code +=
      " 8B 0D" + g_ScreenStats          //MOV ECX, DWORD PTR DS:[g_ScreenStats]
    + " 8B 49 28"                       //MOV ECX, DWORD PTR DS:[ECX+28]
    + " 81 E9" + (-yCoord).packToHex(4) //SUB ECX, -yCoord
    ;
  }
  else {
    code += " B9" + yCoord.packToHex(4)  //MOV ECX, yCoord
  }
  
  code += " 89 4C 24 04";               //MOV DWORD PTR DS:[ESP+4], ECX
  
  if (xCoord < 0) {
    code +=
      " 8B 0D" + g_ScreenStats          //MOV ECX, DWORD PTR DS:[g_ScreenStats]
    + " 8B 49 24"                       //MOV ECX, DWORD PTR DS:[ECX+24]
    + " 81 E9" + (-xCoord).packToHex(4) //SUB ECX, -xCoord
    ;
  }
  else {
    code += " B9" + xCoord.packToHex(4)  //MOV ECX, xCoord
  }
  
  code += 
    " 89" + (0xC8 | tgtReg).packToHex(1) //MOV tgtReg, ECX
  + " C3"                                //RETN
  ;
  
  //Step 2c - Allocate space for it
  var free = exe.findZeros(code.hexlength());
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";

  //Step 3a - Insert the code
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);

  //Step 3b - Change the 0xBB subtraction with a call to our code
  exe.replace(offset, "E8" + (exe.Raw2Rva(free) - exe.Raw2Rva(offset + 5)).packToHex(4), PTYPE_HEX);
  
  return true;
}

//=====================================================//
// Only Enable for Clients that actually have the icon //
//=====================================================//
function MoveCashShopIcon_() {
  return (exe.findString("NC_CashShop", RAW) !== -1);
}