//######################################################################
//# Purpose: Modify the Cancel Button Case in UISelectCharWnd::SendMsg #
//#         to disconnect and show the Login Window                    #
//######################################################################

function CancelToLoginWindow() {

  //Step 1a - Sanity Check. Make Sure Restore Login Window is enabled.
  if (getActivePatches().indexOf(40) === -1)
    return "Patch Cancelled - Restore Login Window patch is necessary but not enabled";

  //Step 1b - Find the case branch that occurs before the Cancel Button case.
  //          The pattern will match multiple locations of which 1 (or recently 2) is the one we need 
  var code =
    " 8D AB AB AB AB AB 00"  //LEA reg32_B, [reg32_A*8 + refAddr]
  + " AB"                    //PUSH reg32_B
  + " 68 37 03 00 00"        //PUSH 337
  + " E8"                    //CALL addr
  ;
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (offsets.length === 0)
    return "Failed in Step 1 - Reference case missing";
  
  var csize = code.hexlength() + 4;
  
  //==============================//
  // Get all required common data //
  //==============================//
  
  //Step 2a - Find CConnection::Disconnect & CRagConnection::instanceR calls  
  code =
    " 83 C4 08"       //ADD ESP, 8
  + " E8 AB AB AB 00" //CALL CRagConnection::instanceR
  + " 8B C8"          //MOV ECX, EAX
  + " E8 AB AB AB 00" //CALL CConnection::Disconnect
  + " B9 AB AB AB 00" //MOV ECX, OFFSET addr
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(/ E8 AB AB AB 00/g, " E8 AB AB AB FF");
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 2 - connection functions missing";
  
  //Step 2b - Extract the RAW addresses. Not much point in converting to RVA (same section -_-)
  var crag = (offset +  8) + exe.fetchDWord(offset + 4);
  var ccon = (offset + 15) + exe.fetchDWord(offset + 11);
  
  //Step 2c - Find address of 메시지 => Korean version of "Message"
  offset = exe.findString("\xB8\xDE\xBD\xC3\xC1\xF6", RVA);
  if (offset === -1)
    return "Failed in Step 2 - Message not found";
  
  //Step 2d - Prep Cancel case pattern to look for
  var canceller = 
    " 68" + offset.packToHex(4) //PUSH addr ; "메시지"
  + " AB"    //PUSH reg32_A ; contains 0
  + " AB"    //PUSH reg32_A
  + " 6A 01" //PUSH 1
  + " 6A 02" //PUSH 2
  + " 6A 11" //PUSH 11
  ;
  
  var cansize = canceller.hexlength();
  var matchcount = 0;
  
  for (var i = 0; i < offsets.length; i++) {
    
    //======================================//
    // First we find all required addresses //
    //======================================//
  
    //Step 3a - Find the cancel case after offsets[i] using the 'canceller' pattern
    //          We are looking for the msgBox creator that shows the quit message
    offsets[i] += csize;
    offset = exe.find(canceller, PTYPE_HEX, true, "\xAB", offsets[i], offsets[i] + 0x80);
    
    if (offset === -1) {
      var zeroPush = " 6A 00";
      offset = exe.find(canceller.replace(" AB AB", " 6A 00 6A 00"), PTYPE_HEX, true, "\xAB", offsets[i], offsets[i] + 0x80);
    }
    else {
      var zeroPush = exe.fetchHex(offset + 5, 1);
    }
    
    if (offset === -1)
      continue;

    //Step 3b - Check for PUSH 118 before offset (only 2013+ clients have that for msgBox creation)
    if (exe.fetchHex(offset - 5, 5) === " 68 18 01 00 00")
      offset -= 7;
    
    //Step 3c - Find the end point of the msgBox call.
    //          There will be a comparison for the return code
    code = 
      " 3D AB 00 00 00"    //CMP EAX, const
    + " 0F 85 AB AB 00 00" //JNE addr; skip quitting.
    ;
    var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + cansize, offset + cansize + 40);
  
    if (offset2 === -1) {
      code = code.replace(" 3D AB 00 00 00", " 83 F8 AB");
      offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + cansize, offset + cansize + 40);
    }
    
    if (offset2 === -1)
      continue;
    
    offset2 += code.hexlength();
    
    //Step 3d - Lastly we find PUSH 2 below offset2 which serves as argument to the register call (CALL reg32 / CALL DWORD PTR DS:[reg32+18]) - Window Maker?.
    //          What we need to do is to substitute the 2 with 2723 for it to show Login Window instead of quitting.
    code =
      zeroPush.repeat(3) //PUSH reg32 x3 or PUSH 0 x3
    + " 6A 02";
    
    var offset3 = exe.find(code, PTYPE_HEX, false, "", offset2, offset2 + 0x20);
    if (offset3 === -1)
      continue;
    
    offset3 += zeroPush.hexlength() * 3;  
    
    //===================================//
    // Now to construct the replace code //
    //===================================//
    
    //Step 4a - First Disconnect from Char Server
    code =
      " E8" + GenVarHex(1) //CALL CRagConnection::instanceR
    + " 8B C8"             //MOV ECX, EAX
    + " E8" + GenVarHex(2) //CALL CConnection::disconnect
    ;
    
    //Step 4b - Extract and paste all the code between offset2 and offset3 to prep the register call (Window Maker)
    code += exe.fetchHex(offset2, offset3 - offset2);
    
    //Step 4c - PUSH 2723 and go to the location after the original PUSH 2 => offset3 + 2
    code +=
      " 68 23 27 00 00"    //PUSH 2723
    + " EB XX"             //JMP addr; after PUSH 2.  
    ;
    
    //Step 4d - Fill in the blanks
    code = ReplaceVarHex(code, 1, crag - (offset + 5));
    code = ReplaceVarHex(code, 2, ccon - (offset + 12));
    code = code.replace(" XX", ((offset3 + 2) - (offset + code.hexlength())).packToHex(1));
      
    //Step 4e - Replace with prepared code
    exe.replace(offset, code, PTYPE_HEX);
    
    matchcount++;
  }
  
  if (matchcount === 0)
    return "Failed in Step 3 - No references matched";
  
  return true;
}

//==========================================================================//
// Disable for Unneeded Clients - Only Certain Client onwards tries to quit //
//==========================================================================//
function CancelToLoginWindow_() {
  return (exe.getClientDate() > 20100803);
}