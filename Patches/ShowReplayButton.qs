//########################################################################
//# Purpose : Change the coordinates of selectserver and replay buttons. #
//#           Also modify the ShowMsg function for Replay List box to    #
//#           make it return to Select Service window.                   #
//########################################################################

function ShowReplayButton() {

  //Step 1 - Move Select Server Button to visible area
  var result = _SRB_FixupButton("replay_interface\\btn_selectserver_b", " C7", " 89");
  if (typeof(result) === "string")
    return "Failed in Step 1." + result;
  
  //Step 2 - Move Replay Button to visible area
  result = _SRB_FixupButton("replay_interface\\btn_replay_b", " E8", " E8");
  if (typeof(result) === "string")
    return "Failed in Step 2." + result;
 
  //Step 2.6 - Service and Server select both use the same Window. 
  //           So look for the mode comparison to distinguish
  var code =
    " 83 78 04 1E" //CMP DWORD PTR DS:[EAX+4], 1E
  + " 75"          //JNE SHORT addr
  ;
  var offset = exe.find(code, PTYPE_HEX, false, "", result, result + 0x40);
  if (offset === -1)
    return "Failed in Step 2.6 - Mode comparison missing";
  
  //Step 2.7 - Change the value to Mode 6 (Server Select) 
  exe.replace(offset + 3, "06", PTYPE_HEX);
  
  //Step 3a - Find the ShowMsg case
  code =
    " 6A 00"          //PUSH 0
  + " 6A 00"          //PUSH 0
  + " 6A 00"          //PUSH 0
  + " 68 29 27 00 00" //PUSH 2729
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 3 - Select Server case missing";
  
  offset += code.hexlength();

  //Step 3b - Find the Replay Mode Enable bit setting  
  code =
    " C6 40 AB 01"          //MOV BYTE PTR DS:[EAX + const], 1
  + " C7 AB 0C 1B 00 00 00" //MOV DWORD PTR DS:[reg32_A + 0C], 1B
  ;
  
  var offset2 = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset2 === -1)
    return "Failed in Step 3 - Replay mode setter missing";
  
  //Step 3c - Get the Function address before the setter & the assigner
  var func = exe.Raw2Rva(offset2) + exe.fetchDWord(offset2 - 4);
  var assigner = exe.fetchHex(offset2, 4).replace(" 01", " 00");

  //Step 4a - Prep code to disable the Replay Mode and send 2722 instead of 2729
  code =
    " 60"                //PUSHAD
  + " E8" + GenVarHex(1) //CALL func
  + assigner             //MOV BYTE PTR DS:[EAX + const], 1
  + " 61"                //POPAD
  + " 68 22 27 00 00"    //PUSH 2722
  + " E9" + GenVarHex(2) //JMP retn
  ;
  
  //Step 4b - Allocate space for it
  var free = exe.findZeros(code.hexlength());
  if (free === -1)
    return "Failed in Step 4 - Not enough free space";
  
  var freeRva = exe.Raw2Rva(free);
  
  //Step 4c - Fill in the blanks  
  code = ReplaceVarHex(code, 1, func - (freeRva + 6));
  code = ReplaceVarHex(code, 2, exe.Raw2Rva(offset) - (freeRva + code.hexlength()));
  
  //Step 4d - Insert in allocated space
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);
  
  //Step 4e - Create a JMP to our code from ShowMsg
  exe.replace(offset - 5, "E9" + (freeRva - exe.Raw2Rva(offset)).packToHex(4), PTYPE_HEX);
  
  return true;
}

//====================================================================//
// Helper Function for Fixing the coordinates of the specified button //
//====================================================================//

function _SRB_FixupButton(btnImg, suffix, suffix2) {
  
  //Step .0 - Find the Button Image address
  var offset = exe.findString(btnImg, RVA, false);
  if (offset === -1)
    return "0 - Button String missing";
  
  //Step .1 - Find its reference inside the UI*Wnd::OnCreate function
  var code = offset.packToHex(4);
  offset = exe.findCode(code + " C7", PTYPE_HEX, false); 
  
  if (offset === -1)
    offset = exe.findCode(code + " 89", PTYPE_HEX, false); 
  
  if (offset === -1)
    return "1 - OnCreate function missing";
  
  offset += 5;

  //Step .2 - Find the coordinate assignment for the Cancel/Exit button
  var offset2 = exe.find(" EA 00 00 00", PTYPE_HEX, false, "", offset, offset + 0x50);
  if (offset2 === -1)
    return "2 - 2nd Button asssignment missing";
  
  //Step .3 - Find the coordinate assignment for the button we need
  var type = 1; //VC9
  var code =
    " 89 AB 24 AB" //MOV DWORD PTR SS:[ESP + x], reg32_A ; x-coord
  + " 89 AB 24 AB" //MOV DWORD PTR SS:[ESP + y], reg32_A ; y-coord
  ;                //followed by suffix which would be either CALL addr or MOV DWORD PTR SS:[ESP+const], 0
  var jmpAddr = exe.find(code + suffix, PTYPE_HEX, true, "\xAB", offset2, offset2 + 0x50);
  
  if (jmpAddr === -1) {
    type = 2;//VC10
    code = code.replace(/ 89 AB 24/g, " 89 AB");//change ESP + to EBP -
    jmpAddr = exe.find(code + suffix, PTYPE_HEX, true, "\xAB", offset2, offset2 + 0x50);
  }
  
  if (jmpAddr === -1) {
    type = 3; //VC11
    code = code.replace(/ 89 AB AB/g, " C7 45 AB 9C FF FF FF");//change ESI to -64
    jmpAddr = exe.find(code + suffix2, PTYPE_HEX, true, "\xAB", offset2, offset2 + 0x50);
  }
  
  if (jmpAddr === -1)
    return "3 - Coordinate assignment missing";

  //Step .3b - Save the location after the match  
  var retAddr = jmpAddr + code.hexlength();
  
  //Step .4a - Prep code to replace/insert
  switch (type) {
    case 1: {
      offset2 = exe.fetchByte(jmpAddr + 3);
      code = 
        " C7 44 24" + offset2.packToHex(1) + " 04 00 00 00" //MOV DWORD PTR DS:[ESP + x], 4
      + " 89 44 24" + (offset2 + 4).packToHex(1)            //MOV DWORD PTR DS:[ESP + y], EAX
      + " E9" + GenVarHex(1)                                //JMP retAddr
      ;
      break;
    }
    case 2: {
      offset2 = exe.fetchByte(jmpAddr + 2);
      code = 
        " 50"                                            //PUSH EAX ; needed since we lost the y-coord we need to retrieve it from the OK button
      + " 8B 45" + (offset2 - 20).packToHex(1)           //MOV EAX, DWORD PTR DS:[EBP - yOk]
      + " C7 45" + offset2.packToHex(1) + " 04 00 00 00" //MOV DWORD PTR DS:[EBP - x], 4
      + " 89 45" + (offset2 + 4).packToHex(1)            //MOV DWORD PTR DS:[EBP - y], EAX
      + " 58"                                            //POP EAX
      + " E9" + GenVarHex(1)                             //JMP retAddr
      ;
      break;
    }
    case 3: {
      code = 
        " 04 00 00 00"                          //MOV DWORD PTR DS:[EBP - x], 4
      + " 89 45" + exe.fetchHex(retAddr - 5, 1) //MOV DWORD PTR DS:[EBP - y], EAX
      + " 90 90 90 90"                          //NOP x4
      ;
      break;
    }
  }

  //Step .4b - For VC11 we can simply replace at appropriate area after the match 
  var size = code.hexlength();
  if (type === 3) {//VC11
    exe.replace(retAddr - size, code, PTYPE_HEX);
  }
  else {//VC9 & VC10
    //Step .5a - For previous client there is not enough space so we allocate space for our code
    var free = exe.findZeros(size);
    if (free === -1)
      return "5 - Not enough free space";

    //Step .5b - Fill in the blanks    
    code = ReplaceVarHex(code, 1, exe.Raw2Rva(retAddr) - exe.Raw2Rva(free + size));
    
    //Step .5c - Insert the code
    exe.insert(free, size, code, PTYPE_HEX);
    
    //Step .5d - Create a JMP to our code at jmpAddr
    exe.replace(jmpAddr, "E9" + (exe.Raw2Rva(free) - exe.Raw2Rva(jmpAddr + 5)).packToHex(4), PTYPE_HEX);
  }
  
  return jmpAddr;//We return the address since we need it for the Mode comparison
}

//=====================================================================//
// Disable for Unneeded Clients - Only Clients with the string need it //
//=====================================================================//
function ShowReplayButton_() {
  return (exe.findString("replay_interface\\btn_replay_b", RAW, false) !== -1);
}