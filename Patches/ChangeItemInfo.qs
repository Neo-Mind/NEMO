//##############################################
//# Purpose: Change the iteminfo.lub reference #
//#          to custom file specified by user  #
//##############################################

function GetItemInfoName() {
  if (IsRenewal())
      var iiName = "System/iteminfo_Sak.lub";
  else {
      var iiName = "System/iteminfo.lub";
      if(exe.findString(iiName, RAW) === -1)
		return "System/iteminfo_true.lub"; // late 2017 clients use 'iteminfo_true.lub' instead.
  }
  return iiName;
}
function ChangeItemInfo() {
  
  //Step 1a - Check if the client is Renewal (iteminfo file name is "System/iteminfo_Sak.lub" for Renewal clients)
  var iiName = GetItemInfoName();
  
  //Step 1b - Find offset of the original string
  var offset = exe.findString(iiName, RVA);
  if (offset === -1)
    return "Failed in Step 1 - iteminfo file name not found";
  
  //Step 1b - Find its reference
  offset = exe.findCode("68" + offset.packToHex(4),  PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - iteminfo reference not found";
  
  //Step 2a - Get the new filename from user
  var myfile = exe.getUserInput("$newItemInfo", XTYPE_STRING, "String input - maximum 28 characters including folder name/", "Enter the new ItemInfo path (should be relative to RO folder)", iiName, 1, 28);
  if (myfile === iiName)
    return "Patch Cancelled - New value is same as old";
  
  //Step 2b - Allocate space for the new name
  var free = exe.findZeros(myfile.length);
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";
  
  //Step 3 - Insert the new name and replace the iteminfo reference
  exe.insert(free, myfile.length, "$newItemInfo", PTYPE_STRING);    
  exe.replace(offset+1, exe.Raw2Rva(free).packToHex(4), PTYPE_HEX);
  
  return true;
}

//=================================//
// Disable for Unsupported clients //
//=================================//
function ChangeItemInfo_() {
  return (exe.findString(GetItemInfoName(), RAW) !== -1);
}