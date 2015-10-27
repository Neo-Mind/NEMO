//################################################################################################
//# Purpose: Change the PUSHed argument & mode setting to Mode Setting calls after disconnection #
//#          to make it return to login window instead of exiting client.                        #
//################################################################################################

function DCToLoginWindow() {
  
  //Step 1a - Sanity Check. Make Sure Restore Login Window is enabled.
  if (getActivePatches().indexOf(40) === -1)
    return "Patch Cancelled - Restore Login Window patch is necessary but not enabled";

  //Step 1b - Find the MsgString ID references of "Sorry the character you are trying to use is banned for testing connection." - common in Login/Char & Map server DC
  var code = " 68 35 06 00 00"; //PUSH 635
  
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  if (offsets.length !== 2)//1 for Login/Char & 1 for Map
    return "Failed in Part 1 - MsgString ID missing";
  
  offsets[0] += 5;
  offsets[1] += 5;
  
  //******* First we will work on DC during Login/Char Selection screens ********//
  
  //Step 2a - Find the format string address
  var offset = exe.findString("%s(%d)", RVA);
  if (offset === -1)
    return "Failed in Part 2 - Format string missing";
  
  //Step 2b - Find its reference after the MsgString ID PUSH
  offset = exe.find(" 68" + offset.packToHex(4), PTYPE_HEX, false, "", offsets[1], offsets[1] + 0x120);
  if (offset === -1)
    return "Failed in Part 2 - Format reference missing";

  //Step 2c - Find the Mode refAddr movement after it. We will inject a Jump to our code here.
  code =
    " E8 AB AB AB FF"    //CALL addr
  + " 8B 0D AB AB AB 00" //MOV ECX, DWORD PTR DS:[refAddr]
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 0x5, offset + 0x80);
  if (offset === -1)
    return "Failed in Part 2 - Reference Address missing";
  
  offset += 5;

  //Step 2d - Extract the ECX assignment which we will need twice later on.
  var movEcx = exe.fetchHex(offset, 6);
  
  //Step 2e - Find the Mode Changer CALL after <offset>
  code =
    " 6A 02" //PUSH 2
  + " FF D0" //CALL EAX
  ;
  
  var offset2 = exe.find(code, PTYPE_HEX, false, "", offset + 0x6, offset + 0x20);

  if (offset2 === -1) {
    code = code.replace(" D0", " 50 18");
    offset2 = exe.find(code, PTYPE_HEX, false, "", offset + 0x6, offset + 0x20);
  }
  
  if (offset2 === -1)
    return "Failed in Part 2 - Mode Changer call missing";
  
  //Step 2f - Get the number of PUSH 0 s . We need to push the same number in our code
  var zeroPushes = exe.findAll(" 6A 00", PTYPE_HEX, false, "", offset + 6, offset2);
  if (zeroPushes.length === 0)
    return "Failed in Part 2 - Zero Pushes not found";

  //Step 2g - Set offset2 to after the CALL. which is the address we need to return to after Mode Changer call
  offset2 += code.hexlength();
  
  //Step 3a - Prep our code (same as what was there but arg1 will be 271D and [this + 3] is assigned 3 before the call)
  code = 
    movEcx                                    //MOV ECX, DWORD PTR DS:[refAddr]
  + " 8B 01"                                  //MOV EAX, DWORD PTR DS:[ECX]
  + " 6A 00".repeat(zeroPushes.length)        //PUSH 0 - n times
  + " 68 1D 27 00 00"                         //PUSH 271D
  + " C7 41 0C 03 00 00 00"                   //MOV DWORD PTR DS:[ECX+0C],3
  + " 68" + exe.Raw2Rva(offset2).packToHex(4) //PUSH offset2
  + " FF 60 18"                               //JMP DWORD PTR DS:[EAX+18]
  ;
  
  //Step 3b - Allocate space for the code
  var free = exe.findZeros(code.hexlength());
  if (free === -1)
    return "Failed in Part 3 - Not enough free space";

  //Step 3c - Insert at allocated location  
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);

  //Step 3d - Change the MOV ECX to a JMP to above code
  exe.replace(offset, " 90 E9" + (exe.Raw2Rva(free) - exe.Raw2Rva(offset + 6)).packToHex(4), PTYPE_HEX);
  
  //******* Next we will work on DC during Gameplay *******//

  //Step 4a - Check if there is a short Jump after the MsgString ID PUSH . If its there go to the address
  if (exe.fetchUByte(offsets[0]) === 0xEB) {
    offset = offsets[0] + 2 + exe.fetchByte(offsets[0] + 1);
  }
  else {
    //Step 4b - If not look for a Long Jump after the PUSH
    offset = exe.find(" E9 AB AB 00 00", PTYPE_HEX, true, "\xAB", offsets[0], offsets[0] + 0x100);
    if (offset === -1)
      return "Failed in Part 4 - JMP to Mode call missing";
    
    //Step 4c - Goto the JMP address
    offset += 5 + exe.fetchDWord(offset + 1);
  }
  
  //Step 4d - Look for the ErrorMsg (Error Message Window displayer function) CALL after the offset
  code =
    " B9 AB AB AB 00" //MOV ECX, OFFSET g_windowMgr
  + " E8 AB AB AB FF" //CALL UIWindowMgr::ErrorMsg
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x100);
  if (offset === -1)
    return "Failed in Part 4 - ErrorMsg call missing";

  //Step 4e - Set offset to location after the CALL
  offset += code.hexlength();
  
  //Step 4f - Now look for the Mode Changer CALL after <offset>
  code =
    " 6A 02"    //PUSH 2
  + " 8B CF"    //MOV ECX, EDI
  + " FF 50 18" //CALL DWORD PTR DS:[EAX+18]
  ;
  
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x20);
  
  if (offset2 === -1) {
    code = code.replace(" 50 18", " D0");
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x20);
  }
    
  if (offset2 === -1) {
    code = code.replace(" D0", " D2").replace(" 8B CF", "");
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x20);
  }
  
  if (offset2 === -1)
    return "Failed in Part 4 - Mode Call missing"; 
  
  //Step 4g - Set offset2 to after the CALL. This is the Return address
  offset2 += code.hexlength();
  
  //Step 5a - Prep code for insertion . Like Before we have done few changes 
  //         (arg1 is 8D and ECX is loaded from refAddr instead of depending on some local - value will be same either way)
  code = 
    movEcx                                    //MOV ECX, DWORD PTR DS:[refAddr]
  + " 8B 01"                                  //MOV EAX, DWORD PTR DS:[ECX]
  + " 6A 00".repeat(zeroPushes.length)        //PUSH 0 - n times
  + " 68 8D 00 00 00"                         //PUSH 8D
  + " 68" + exe.Raw2Rva(offset2).packToHex(4) //PUSH offset2
  + " FF 60 18"                               //JMP DWORD PTR DS:[EAX+18]
  ;
  
  //Step 5b - Allocate space for the code
  free = exe.findZeros(code.hexlength());
  if (free === -1)
    return "Failed in Part 5 - Not enough free space";
  
  //Step 5c - Insert to allocated location
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);

  //Step 5d - Replace the code at offset with JMP to our code.
  exe.replace(offset, " E9" + (exe.Raw2Rva(free) - exe.Raw2Rva(offset + 5)).packToHex(4), PTYPE_HEX);
  
  return true;
}

//==========================================================================//
// Disable for Unneeded Clients - Only Certain Client onwards tries to quit //
//==========================================================================//
function DCToLoginWindow_() {
  return (exe.getClientDate() > 20100730);
}