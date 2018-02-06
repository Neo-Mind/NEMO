//################################################
//# Purpose: Change the clientinfo.xml reference #
//#          to custom file specified by user    #
//################################################

function LoadCustomClientInfo() {
  
  //Step 1a - Check if the client is Sakray (clientinfo file name is "sclientinfo.xml" for some Sakray clients)
  var ciName = "sclientinfo.xml";
  var offset = exe.findString(ciName, RVA);

  if (offset === -1) { // if sclientinfo.xml does not exist then it is a main server exe
    ciName = "clientinfo.xml";
    offset = exe.findString(ciName, RVA);
  }
  
  if (offset === -1)
      return "s?clientinfo.xml not found.";

  if (offset === -1)
    return "Failed in Step 1 - clientinfo file name not found";
  
  //Step 1b - Find its reference
  offset = exe.findCode(" F3 0F AB AB" + offset.packToHex(4),  PTYPE_HEX, true, "\xAB"); // MOVQ XMM0, clientinfo_xml
  if (offset === -1)
    return "Failed in Step 1 - clientinfo reference not found";
  
  //Step 2a - Get the new filename from user
  var myfile = exe.getUserInput("$newclientinfo", XTYPE_STRING, "String input - maximum 28 characters", "Enter the new clientinfo path", ciName, 1, 28);
  if (myfile === ciName)
    return "Patch Cancelled - New value is same as old";
  
  //Step 2b - Allocate space for the new name
  var free = exe.findZeros(myfile.length);
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";
  
  //Step 3 - Insert the new name and replace the clientinfo reference
  exe.insert(free, myfile.length, "$newclientinfo", PTYPE_STRING);    
  exe.replace(offset+4, exe.Raw2Rva(free).packToHex(4), PTYPE_HEX);
  
  return true;
}

//=================================//
// Disable for Unsupported clients //
//=================================//
function LoadCustomClientInfo_() {
  return (exe.findString("sclientinfo.xml", RAW) !== -1 || exe.findString("clientinfo.xml", RAW) !== -1);
}
