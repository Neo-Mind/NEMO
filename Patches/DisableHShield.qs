function DisableHShield() {
  ////////////////////////////////////////////////////////////////////
  // GOAL: Fix up all HackShield related functions/function calls & // 
  //       remove aossdk.dll import                                 //
  ////////////////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - 'webclinic.ahnlab.com' is not there in old client.
  //         Need to find which client onwards it got added
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1a - Construct the pattern to find the function containing 'webclinic.ahnlab.com' reference
  if (exe.getClientDate() <= 20130605) {//alternative to finding webclinic
    var code = 
        " 51"                   // PUSH ECX
      + " 83 3D AB AB AB 00 00" // CMP DWORD PTR DS:[addr1], 0
      + " 74 04"                // JZ SHORT addr2 -> PUSH 'webclinic.ahnlab.com'
      + " 33 C0"                // XOR EAX, EAX
      + " 59"                   // POP ECX
      + " C3"                   // RETN
      ;
  }
  else {
    var code =
        " 51"                   // PUSH ECX
      + " 83 3D AB AB AB 00 00" // CMP DWORD PTR DS:[addr1], 0
      + " 74 06"                // JZ SHORT addr2 -> PUSH 'webclinic.ahnlab.com'
      + " 33 C0"                // XOR EAX, EAX
      + " 8B E5"                // MOV ESP, EBP
      + " 5D"                   // POP EBP
      + " C3"                   // RETN
      ;
  }

  //Step 1b - Find the pattern
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";

  //Step 1c - Replace the JZ + XOR with XOR + INC of EAX to return 1 without initializing AhnLab
  exe.replace(offset+8, " 33 C0 40 90", PTYPE_HEX);
  
  //Step 2a - Find Failure message - this is there in newer clients (maybe all ragexe too?)
  offset = exe.findString("CHackShieldMgr::Monitoring() failed", RVA);
  
  //Step 2b - Find reference to Failure message
  if (offset !== -1)
    offset = exe.findCode(" 68" + offset.packToHex(4) + " FF 15", PTYPE_HEX, false);
  
  //Step 2c - Find Pattern before the referenced location within 0x40 bytes
  if (offset !== -1) {
    code = 
        " E8 AB AB AB AB"  // CALL func1
      + " 84 C0"           // TEST AL, AL
      + " 74 16"           // JZ SHORT addr1
      + " 8B AB"           // MOV ECX, ESI
      + " E8"              // CALL func2
      ;
 
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x40, offset);
  }
  
  //Step 2d - Replace the First call with code to return 1 and cleanup stack
  if (offset !== -1) {
    code = 
        " B0 01" // MOV AL, 1
      + " 5E"    // POP ESI
      + " C3"    // RETN
      ;
    
    exe.replace(offset, " B0 01 5E C3 90", PTYPE_HEX);
  }
  
  //Step 3a - FailSafe to avoid the calls just in case. Get offset of 0 'ERROR' 0
  offset = exe.findString("ERROR", RVA);
  if (offset === -1)
    return "Failed in part 3 - Unable to Find 'ERROR'";
  
  //Step 3b - Find its reference
  offset = exe.findCode(" 68" + offset.packToHex(4) + " 50", PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 3 - Unable to find reference";
  
  
  //Step 3c - Find the jne after it that skips the HShield calls
  code = 
      " 80 3D AB AB AB AB 00" // CMP BYTE PTR DS:[addr1], 0
    + " 75"                   // JNE SHORT addr2
    ;
    
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x80);
  if (offset === -1)
    return "Failed in part 3 - Unable to find the JNE";
  
  //Step 3d - Replace JNE with JMP to always skip
  exe.replace(offset+7, "EB", PTYPE_HEX);//change JNE to JMP

  //Step 4a - Now to remove aossdk.dll. Find offset of the 'aossdk.dll'
  var aOffset = exe.find("aossdk.dll", PTYPE_STRING, false);
  if (aOffset === -1)
    return "Failed in part 4";
    
  //Step 4b - COnstruct the Image Descriptor Pattern (Relative Virtual Address prefixed by 8 zeros)
  aOffset = " 00".repeat(8) + (exe.Raw2Rva(aOffset) - exe.getImageBase()).packToHex(4);
  
  //Step 4c - Check for Use Custom DLL patch - needed since it modifies the import table location
  var hasCustomDLL = (exe.getActivePatches().indexOf(211) !== -1);
  
  if (hasCustomDLL && typeof(Imp_DATA) !== "undefined") {
    //Step 4d - Accommodate for the above if true - does the import table fix here.
    var tblData = Imp_DATA.valueSuf;
    var newTblData = "";
    
    for (var i = 0; i < tblData.length; i+=20*3) {
      var curValue = tblData.substr(i, 20*3);
      if (curValue.indexOf(aOffset) === 3*4) continue;//Skip aossdk import rest all are copied
      newTblData = newTblData + curValue;
    }

    if (newTblData !== tblData) {
      //Add the changes to this patch instead.
      exe.emptyPatch(211);
      
      var PEoffset = exe.find("50 45 00 00", PTYPE_HEX, false);
      exe.insert(Imp_DATA.offset, (Imp_DATA.valuePre + newTblData).hexlength(), Imp_DATA.valuePre + newTblData, PTYPE_HEX);
      exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0x8, Imp_DATA.tblAddr);
      exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0xC, Imp_DATA.tblSize);
    }    
  }
  else {
    //Step 4e - If not present we swap out the aossdk entry with the last import and void the last import.
    var dir = GetDataDirectory(1);
    var finalValue = " 00".repeat(20);
    var offset = dir.offset;
    var dllOffset = false;
    
    var curValue = exe.fetchHex(offset,20);
    do {
      if (curValue.indexOf(aOffset) === 3*4) dllOffset = offset;
      offset += 20;
      curValue = exe.fetchHex(offset,20);
    } while(curValue !== finalValue);
    
    if (!dllOffset)
      return "Failed in Part 4 - aossdk import not found";
      
    var endOffset = offset - 20;//Last DLL Entry
    exe.replace(dllOffset, exe.fetchHex(endOffset, 20), PTYPE_HEX);//Replace aossdk.dll import with the last import
    exe.replace(endOffset, finalValue, PTYPE_HEX);//Replace last import with 0s to indicate end of table.  
  }
  
  return true;
}