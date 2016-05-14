//###################################################################
//# Purpose: Fix up all HackShield related functions/function calls #
//#          and remove aossdk.dll import                           #
//###################################################################

delete Import_Info;//Removing any stray values before Patches are selected

function DisableHShield() {
    
  //Step 1a - Find address of 'webclinic.ahnlab.com'
  var offset = exe.findString("webclinic.ahnlab.com", RVA);
  if (offset === -1)
    return "Failed in Step 1 - webclinic address missing";
  
  //Step 1b - Find its reference
  var code = " 68" + offset.packToHex(4);  //PUSH OFFSET addr; ASCII 'webclinic.ahnlab.com'
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - webclinic reference missing";
  
  //Step 1c - Find the JZ before the RETN that points to the PUSH
  code = 
    " 74 AB" //JZ addr2 -> PUSH OFFSET addr; ASCII 'webclinic.ahnlab.com'    
  + " 33 C0" //XOR EAX, EAX
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x10, offset);
  if (offset === -1)
    return "Failed in Step 1 - JZ not found";
  
  //Step 1d - Replace the JZ + XOR with XOR + INC of EAX to return 1 without initializing AhnLab
  exe.replace(offset, " 33 C0 40 90", PTYPE_HEX);
  
  //Step 2a - Find Failure message - this is there in newer clients (maybe all ragexe too?)
  offset = exe.findString("CHackShieldMgr::Monitoring() failed", RVA);
   
  if (offset !== -1) {
    //Step 2b - Find reference to Failure message
    offset = exe.findCode(" 68" + offset.packToHex(4) + " FF 15", PTYPE_HEX, false);

    //Step 2c - Find Pattern before the referenced location within 0x40 bytes
    if (offset !== -1) {
      code = 
        " E8 AB AB AB AB"  //CALL func1
      + " 84 C0"           //TEST AL, AL
      + " 74 16"           //JZ SHORT addr1
      + " 8B AB"           //MOV ECX, ESI
      + " E8"              //CALL func2
      ;
      offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x40, offset);
    }
  
    //Step 2d - Replace the First call with code to return 1 and cleanup stack
    if (offset !== -1) {
      code = 
        " 90"    //NOP
      + " B0 01" //MOV AL, 1
      + " 5E"    //POP ESI
      + " C3"    //RETN
      ;    
      exe.replace(offset, code, PTYPE_HEX);
    }
  }
  
  //===================================================================//
  // Now for a failsafe to avoid calls just in case - for VC9+ clients //
  //===================================================================//
  
  //Step 3a - Find address of 'ERROR'
  offset = exe.findString("ERROR", RVA);
  if (offset === -1)
    return "Failed in Step 3 - ERROR string missing";
  
  //Step 3b - Find address of MessageBoxA function
  var offset2 = GetFunction("MessageBoxA", "USER32.dll");
  if (offset2 === -1)
    return "Failed in Step 3 - MessageBoxA not found";
  
  //Step 3c - Find ERROR reference followed by MessageBoxA call 
  code = 
    " 68" + offset.packToHex(4)     //PUSH OFFSET addr; ASCII "ERROR"
  + " AB"                           //PUSH reg32_A
  + " AB"                           //PUSH reg32_B
  + " FF 15" + offset2.packToHex(4) //CALL DWORD PTR DS:[<&USER32.MessageBoxA>]
  ;
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" AB AB FF 15", " AB 6A 00 FF 15");//Change PUSH reg32_B with PUSH 0
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset !== -1) {
    //Step 3c - Find the JNE after it that skips the HShield calls
    code = 
      " 80 3D AB AB AB 00 00" //CMP BYTE PTR DS:[addr1], 0
    + " 75"                   //JNE SHORT addr2
    ;
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x80);
    
    if (offset2 === -1) {
      code = 
        " 39 AB AB AB AB 00" //CMP DWORD PTR DS:[addr1], reg32_A
      + " 75"                //JNE SHORT addr2
      ;
      offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x80);
    }
    
    //Step 3d - Replace JNE with JMP to always skip
    if (offset2 !== -1)
      exe.replace(offset2 + code.hexlength() - 1, "EB", PTYPE_HEX);//change JNE to JMP
  }
  
  if (exe.getClientDate() > 20140700)
    return true;
  
  //======================================//
  // Now we will remove aossdk.dll Import //
  //======================================//
  
  //Step 4a - Find address of the "aossdk.dll"
  var aOffset = exe.findString("aossdk.dll", PTYPE_STRING, false);
  if (aOffset === -1)
    return "Failed in Step 4";
    
  //Step 4b - Construct the Image Descriptor Pattern (Relative Virtual Address prefixed by 8 zeros)
  aOffset = " 00".repeat(8) + (exe.Raw2Rva(aOffset) - exe.getImageBase()).packToHex(4);
  
  //Step 4c - Check for Use Custom DLL patch - needed since it modifies the import table location
  var hasCustomDLL = (getActivePatches().indexOf(211) !== -1);
  
  if (hasCustomDLL && typeof(Import_Info) !== "undefined") {
    //Step 4d - If it is used, it means the table has been shifted and all related data is available in Import_Info.
    //          First we will remove the asssdk import entry from the table saved in Import_Info
    var tblData = Import_Info.valueSuf;
    var newTblData = "";
    
    for (var i = 0; i < tblData.length; i += 20*3) {
      var curValue = tblData.substr(i, 20*3);
      if (curValue.indexOf(aOffset) === 3*4) continue;//Skip aossdk import rest all are copied
      newTblData = newTblData + curValue;
    }

    if (newTblData !== tblData) {
      //Step 4e - If the removal was not already done then Empty the Custom DLL patch and make the changes here instead.
      exe.emptyPatch(211);
      
      var PEoffset = exe.getPEOffset();
      exe.insert(Import_Info.offset, (Import_Info.valuePre + newTblData).hexlength(), Import_Info.valuePre + newTblData, PTYPE_HEX);
      exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0x8, Import_Info.tblAddr);
      exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0xC, Import_Info.tblSize);
    }
  }
  else {
    //Step 4f - If Custom DLL is not present then we need to traverse the Import table and remove the aossdk entry.
    //          First we get the Import Table address and prep variables
    var dir = GetDataDirectory(1);
    var finalValue = " 00".repeat(20);
    var curValue;
    var lastDLL = "";//
    code = "";//will contain the import table
    
    for (offset = dir.offset; (curValue = exe.fetchHex(offset, 20)) !== finalValue; offset += 20) {
      //Step 4e - Get the DLL Name for the import entry
      offset2 = exe.Rva2Raw(exe.fetchDWord(offset + 12) + exe.getImageBase());
      var offset3 = exe.find("00", PTYPE_HEX, false, "", offset2);
      var curDLL = exe.fetch(offset2, offset3 - offset2);
      
      //Step 4f - Make sure its not a duplicate or aossdk.dll
      if (lastDLL === curDLL || curDLL === "aossdk.dll") continue;
      
      //Step 4g - Add the entry to code and save current DLL to compare next iteration
      code += curValue;
      lastDLL = curDLL;
    }
    
    code += finalValue;
    
    //Step 4h - Overwrite import table with the one we got
    exe.replace(dir.offset, code, PTYPE_HEX);
  }
  
  return true;
}

//============================//
// Disable Unsupported client //
//============================//
function DisableHShield_() {
  return (exe.findString("aossdk.dll", RAW) !== -1);
}

//#######################################################################
//# Purpose: Rerun the UseCustomDLL function if the Custom DLL patch is #
//#          selected so that it doesnt accomodate for HShield patch    #
//#######################################################################

function _DisableHShield() {
  if (getActivePatches().indexOf(211) !== -1)
  {
    exe.setCurrentPatch(211);
    exe.emptyPatch(211);
    UseCustomDLL();
  }
}