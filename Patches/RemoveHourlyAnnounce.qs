//###################################################################
//# Purpose: Change the JNE and JLE to JMP after Hourly Comparisons #
//#          inside CRenderer::DrawAgeRate & PlayTime functions     #
//###################################################################

function RemoveHourlyAnnounce() {//PlayTime comparison is not there in Pre-2010 clients
  
  //Step 1a - Find the comparison for Game Grade
  var code = 
    " 75 AB"    //JNE SHORT addr1
  + " MovAx"    //Frame Pointer Specific MOV
  + " 66 85 C0" //TEST AX, AX
  + " 75"       //JNE SHORT addr2
  ;
  
  var fpEnb = HasFramePointer();
  if (fpEnb)
    code = code.replace(" MovAx", " 66 8B 45 AB"); //MOV AX, WORD PTR SS:[EBP-x]
  else
    code = code.replace(" MovAx", " 66 8B 44 24 AB"); //MOV AX, WORD PTR SS:[ESP+x]
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");//VC9+ Clients
  
  if (offset === -1) {
    code = code.replace(" 66", "");//Change MOV AX to MOV EAX and thereby WORD PTR becomes DWORD PTR
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");//Older clients and some new clients
  }

  if (offset === -1 && !fpEnb) {
    code = code.replace(" 8B 44 24 AB", " 66 8B 45 AB"); // HasFramePointer() broke? [Secret]
	offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1";

  //Step 1b - Change JNE to JMP
  exe.replace(offset, "EB", PTYPE_HEX);

  //Step 2a - Find Time divider before the PlayTime Reminder comparison
  code =  
    " B8 B1 7C 21 95" //MOV EAX, 95217CB1
  + " F7 E1"          //MUL ECX
  ;
    
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  if (offsets.length === 0)
    return "Failed in Step 2 - Magic Divisor not found";
  
  for (var i = 0; i < offsets.length; i++) {
    //Step 2b - Find the JLE after each (below the TEST/CMP instruction) 
    offset = exe.find(" 0F 8E AB AB 00 00", PTYPE_HEX, true, "\xAB", offsets[i] + 7, offsets[i] + 30);//JLE addr
    
    //Step 2c - Change to NOP + JMP
    if (offset !== -1)
      exe.replace(offset, " 90 E9", PTYPE_HEX);
    
    /*
    offset = exe.find(" 0F 85 AB AB 00 00", PTYPE_HEX, true, "\xAB", offsets[i] + 7, offsets[i] + 30);//JNE addr
    if (offset === -1)
      return "Failed in Step 2 - Iteration No." + i;
    */
  }
  
  return true;
}