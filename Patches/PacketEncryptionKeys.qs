//All the patches have same procedure - only position is different
function PacketFirstKeyEncryption() {
  return PacketEncryptionKeys('$firstkey', 0);
}

function PacketSecondKeyEncryption() {
  return PacketEncryptionKeys('$secondkey', 1);
}

function PacketThirdKeyEncryption() {
  return PacketEncryptionKeys('$thirdkey', 2);
}  

function PacketEncryptionKeys(varname, keyindex) {
  ////////////////////////////////////////////////////////
  // GOAL: Find the Packet Key references and replace   //
  //       all occurences of index with specified value //
  ////////////////////////////////////////////////////////
  
  //Step 1 - Find the addresses of the Packet Keys - the same function is used in a utility.
  var keyaddrs = fetchPacketKeyAddrs();
  if (typeof(keyaddrs) === "string") {
    return keyaddrs;//Error message
  }
  
  //Step 2 - Check for one key being duplicate of another
  switch(keyindex) {
    case 0:
      if (keyaddrs[2] === keyaddrs[0]) {
        return "Patch Cancelled - First Key is copy of third, change Third one instead";
      }
      if (keyaddrs[1] === keyaddrs[0]) {
        return "Patch Cancelled - First Key is copy of second, change Second one instead";
      }
      break;
    case 1:
      if (keyaddrs[2] == keyaddrs[1]) {
        return "Patch Cancelled - Second Key is copy of third, change Third one instead";
      }
      break;
  }
  
  //Step 3 - Extract Current Key Value
  var curValue = convertToBE(exe.fetchHex(keyaddrs[keyindex], 4));
  
  //Step 4 - Get new value from User
  exe.getUserInput(varname, XTYPE_HEXSTRING, 'Hex input', 'Enter the new key', curValue);
  
  //Step 5 - Replace with new value
  exe.replace(keyaddrs[keyindex], varname, PTYPE_STRING);
  if (keyaddrs.length === 6) {//if its pushed at multiple locations
    exe.replace(keyaddrs[keyindex+3], varname, PTYPE_STRING);
  }
  
  return true;
}