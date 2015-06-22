//=============================================================//
// Patch Functions wrapping over PacketEncryptionKeys function //
//=============================================================//

function PacketFirstKeyEncryption() {
  return PacketEncryptionKeys("$firstkey", 0);
}

function PacketSecondKeyEncryption() {
  return PacketEncryptionKeys("$secondkey", 1);
}

function PacketThirdKeyEncryption() {
  return PacketEncryptionKeys("$thirdkey", 2);
}  

//######################################################################################################
//# Purpose: Get the Packet Key Info for loaded client and according to what type of function is used, #
//#          Replace Packet PUSH Reference or Hijack the Obfuscate2 function to use our code.          #
//######################################################################################################

PEncKeys = [];//Initialize array to blank before Packet Key Patches are selected. Only needed for Obfuscate2
delete PEncInsert;//Removing any stray values before Packet Key Patches are selected. Only needed for Obfuscate2
delete PEncActive;

function PacketEncryptionKeys(varname, index) {

  //Step 1a - Sanity Check. Check if Packet Encryption is Disabled.
  if (getActivePatches().indexOf(61) !== -1)
    return "Patch Cancelled - Disable Packet Encryption is ON";
  
  //Step 1b - Get the Packet Info
  var keyInfo = FetchPacketKeyInfo();
  if (typeof(keyInfo) === "string")
    return keyInfo;//Error message
  
  if (keyInfo[1] === 0 && keyInfo[2] === 0 && keyInfo[3] === 0)
    return "Failed in Step 1 - No Packet Key Patterns matched";
  
  //Step 1c - Get new Key from user.
  var newKey = parseInt( exe.getUserInput(varname, XTYPE_HEXSTRING, "Hex input", "Enter the new key", keyInfo[index + 1].toBE()),  16);
  
  if (keyInfo[4] === 0)//Packet Key PUSHed as arguments
  {
    //Step 2a - Find all packet Key PUSHes
    var code =
      " 68" + keyInfo[3].packToHex(4) //PUSH key3
    + " 68" + keyInfo[2].packToHex(4) //PUSH key2
    + " 68" + keyInfo[1].packToHex(4) //PUSH key1
    + " E8"                           //CALL CRagConnection::Obfuscate
    ;
    
    var offsets = exe.findCodes(code, PTYPE_HEX, false);
    if (offsets.length === 0)//Not supposed to happen
      return "Failed in Step 2";
    
    //Step 2b - Replace the PUSHed argument for the index in all of them
    for ( var i = 0; i < offsets.length; i++) {
      exe.replace(offsets[i] + code.hexlength() - (index + 1) * 5, varname, PTYPE_STRING); 
    }
  }
  else {
    //Step 3a - Fill PEncKeys with existing values if it is empty
    if (PEncKeys.length === 0) {
      PEncKeys[0] = keyInfo[1];
      PEncKeys[1] = keyInfo[2];
      PEncKeys[2] = keyInfo[3];
    }
    
    //Step 3b - Now set the index of PEncKeys with new value
    PEncKeys[index] = newKey;
    
    //Step 3c - Prep code to insert
    code = 
      " C7 41 04" + PEncKeys[0].packToHex(4) //MOV DWORD PTR DS:[ECX+4], key1
    + " C7 41 08" + PEncKeys[1].packToHex(4) //MOV DWORD PTR DS:[ECX+8], key2
    + " C7 41 0C" + PEncKeys[2].packToHex(4) //MOV DWORD PTR DS:[ECX+C], key3
    + " 33 C0"                               //XOR EAX, EAX
    ;

    if (HasFramePointer())
      code += "5D";                          //POP EBP

    code += " C2 04 00";                     //RETN 4
    
    var csize = code.hexlength();
    
    //Step 3c - Check if PEncInsert is already defined. If it is we need to empty the other Patches.
    if (typeof(PEncInsert) !== "undefined") {
      for (var i = 0; i < 3; i++) {
        if (i === index) continue;
        exe.emptyPatch(92 + i);
      }
      
      var free = exe.Rva2Raw(PEncInsert);
    }
    else {
      //Step 3d - Allocate space for code.
      var free = exe.findZeros(csize);
      if (free === -1)
        return "Failed in Step 3";
      
      PEncInsert = exe.Raw2Rva(free);
    }
    
    //Step 3e - Insert it
    exe.insert(free, csize, code, PTYPE_HEX);
    
    //Step 3f - Hijack keyInfo[4] to jmp to PEncInsert
    code = " E9" + (PEncInsert - exe.Raw2Rva(keyInfo[4] + 5)).packToHex(4);//JMP PEncInsert
    exe.replace(keyInfo[4], code, PTYPE_HEX);

    //Step 3g - Set PEncActive to index indicating this one has the changes
    PEncActive = index;
  }
  
  return true;
}

//================================================================//
// Patch Destructor Functions wrapping over _PacketEncryptionKeys //
//================================================================//

function _PacketFirstKeyEncryption() {
  return _PacketEncryptionKeys(0);
}

function _PacketSecondKeyEncryption() {
  return _PacketEncryptionKeys(1);
}

function _PacketThirdKeyEncryption() {
  return _PacketEncryptionKeys(2);
}

//#########################################################################
//# Purpose: Move the insert operation to any of the other active patches #
//#########################################################################

function _PacketEncryptionKeys(index) {

  //Step 1a - Check if PEncInsert is defined. Remaining steps are needed only if it is
  if (typeof(PEncInsert) === "undefined")
    return;
  
  //Step 1b - Assign PEncActive to an active Packet Key Patch that is not associated with index
  if (PEncActive === index) {
    var patches = getActivePatches();
    for (var i = 0; i < 3; i++) {    
      if (patches.indexOf(92 + i) !== -1) {
        PEncActive = i;
        break;
      }
    }
  }
  
  //Step 1c - Clear Everything if no other patch is active
  if (PEncActive === index) {
    delete PEncActive;
    delete PEncInsert;
    PEncKeys = [];
    return false;
  }
  
  //Step 1d - Set Current Patch so the insert will be assigned to it
  exe.setCurrentPatch(92 + PEncActive);
  exe.emptyPatch(92 + PEncActive);
  
  //Step 2a - Get Packet Key Info
  var keyInfo = FetchPacketKeyInfo();
  
  //Step 2b - Change the Packet Key referred by index to the original one.
  PEncKeys[index] = keyInfo[index + 1];
  
  //Step 2c - Prep Code to insert
  var code = 
    " C7 41 04" + PEncKeys[0].packToHex(4) //MOV DWORD PTR DS:[ECX+4], key1
  + " C7 41 08" + PEncKeys[1].packToHex(4) //MOV DWORD PTR DS:[ECX+8], key2
  + " C7 41 0C" + PEncKeys[2].packToHex(4) //MOV DWORD PTR DS:[ECX+C], key3
  + " 33 C0"                               //XOR EAX, EAX
  ;
  
  if (HasFramePointer())
    code += "5D";                          //POP EBP
  
  code += " C2 04 00";                     //RETN 4
  
  var csize = code.hexlength();
  
  //Srep 2d - Insert the code
  exe.insert(exe.Rva2Raw(PEncInsert), csize, code, PTYPE_HEX);
  
  //Step 2e - Hijack keyInfo[4] to jmp to PEncInsert
  code = " E9" + (PEncInsert - exe.Raw2Rva(keyInfo[4] + 5)).packToHex(4);//JMP PEncInsert
  exe.replace(keyInfo[4], code, PTYPE_HEX);
  return true;
}