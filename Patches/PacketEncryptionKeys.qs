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
  var info = FetchPacketKeyInfo();
  if (typeof(info) === "string")
    return info;//Error message
  
  if (info.type === -1)
    return "Failed in Step 1 - No Packet Key Patterns matched";
  
  //Step 1c - Get new Key from user.
  var newKey = parseInt( exe.getUserInput(varname, XTYPE_HEXSTRING, "Hex input", "Enter the new key", info.keys[index].toBE()),  16);
  if (newKey === info.keys[index])
    return "Patch Cancelled - Key not changed";
  
  if (info.type === 0)//Packet Key PUSHed as arguments
  {
    //Step 2a - Find all packet Key PUSHes
    var code =
      " 68" + info.keys[2].packToHex(4) //PUSH key3
    + " 68" + info.keys[1].packToHex(4) //PUSH key2
    + " 68" + info.keys[0].packToHex(4) //PUSH key1
    + " E8"                             //CALL CRagConnection::Obfuscate
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
    //--- Code Preparation ---//
    code = "";
    
    //Step 3a - Fill PEncKeys with existing values if it is empty
    if (PEncKeys.length === 0) {
      PEncKeys = info.keys;
    }
    
    //Step 3b - Now set the index of PEncKeys with new value
    PEncKeys[index] = newKey;
    
    //Step 3c - Prep the stack restore + RETN suffix 
    var suffix = "";
    if (HasFramePointer())
      suffix += " 5D";
    
    suffix += " C2 04 00"; //RETN 4
    
    //Step 3d - First add encryption & zero assigner codes for Type 2 (function is Virtualized so we need to write the entire function not just part of it)
    if (info.type === 2) {
      
      if (HasFramePointer())
        code += " 8B 45 08";    //MOV EAX, DWORD PTR SS:[EBP+8]
      else
        code += " 8B 44 24 04"; //MOV EAX, DWORD PTR SS:[ESP+4]
      
      code +=
        " 85 C0"          //TEST EAX,EAX
      + " 75 19"          //JNE SHORT addr1
      + " 8B 41 08"       //MOV EAX,DWORD PTR DS:[ECX+8]
      + " 0F AF 41 04"    //IMUL EAX,DWORD PTR DS:[ECX+4]
      + " 03 41 0C"       //ADD EAX,DWORD PTR DS:[ECX+0C]
      + " 89 41 04"       //MOV DWORD PTR DS:[ECX+4],EAX
      + " C1 E8 10"       //SHR EAX,10
      + " 25 FF 7F 00 00" //AND EAX,00007FFF
      + suffix
      + " 83 F8 01"       //CMP EAX,1 <= addr1
      + " 74 0F"          //JE SHORT addr2 ; addr2 is after the RETN 4 below
      + " 31 C0"          //XOR EAX,EAX
      + " 89 41 04"       //MOV DWORD PTR DS:[ECX+4],EAX
      + " 89 41 08"       //MOV DWORD PTR DS:[ECX+8],EAX
      + " 89 41 0C"       //MOV DWORD PTR DS:[ECX+0C],EAX
      + suffix
      ;
      
      if (suffix.hexlength() !== 4) {//adjust the JE & JNE
        code = code.replace(" 75 19", "75 18").replace(" 74 0F", " 74 0E");
      }     
    }
    
    //Step 3e - Add the code for assigning the Initial Keys
    code += 
      " C7 41 04" + PEncKeys[0].packToHex(4) //MOV DWORD PTR DS:[ECX+4], key1
    + " C7 41 08" + PEncKeys[1].packToHex(4) //MOV DWORD PTR DS:[ECX+8], key2
    + " C7 41 0C" + PEncKeys[2].packToHex(4) //MOV DWORD PTR DS:[ECX+C], key3
    + " 33 C0"                               //XOR EAX, EAX
    + suffix
    ;
    
    
    //Step 4a - Check if PEncInsert is already defined. If it is we need to empty the other Patches.
    if (typeof(PEncInsert) !== "undefined") {
      for (var i = 0; i < 3; i++) {
        if (i === index) continue;
        exe.emptyPatch(92 + i);
      }
    }
    
    //Step 4b - Allocate space for code.
    var csize = code.hexlength();
    var free = exe.findZeros(csize);
    if (free === -1)
      return "Failed in Step 4 - Not Enough Free Space";
    
    PEncInsert = exe.Raw2Rva(free);
    
    //Step 4c - Insert it
    exe.insert(free, csize, code, PTYPE_HEX);
    
    //Step 4d - Hijack info.ovrAddr to jmp to PEncInsert
    code = " E9" + (PEncInsert - exe.Raw2Rva(info.ovrAddr + 5)).packToHex(4);//JMP PEncInsert
    exe.replace(info.ovrAddr, code, PTYPE_HEX);

    //Step 4e - Set PEncActive to index indicating this one has the changes
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
  var info = FetchPacketinfo();
  
  //Step 2b - Change the Packet Key referred by index to the original one.
  PEncKeys[index] = info.keys[index];
  
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
  
  //Step 2e - Hijack info.ovrAddr to jmp to PEncInsert
  code = " E9" + (PEncInsert - exe.Raw2Rva(info.ovrAddr + 5)).packToHex(4);//JMP PEncInsert
  exe.replace(info.ovrAddr, code, PTYPE_HEX);
  return true;
}