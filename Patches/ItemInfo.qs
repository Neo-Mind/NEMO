function ItemInfo() {
  /////////////////////////////////////////////
  // GOAL: Change the iteminfo.lub reference //
  //       to custom file specified by user  //
  /////////////////////////////////////////////
  
  //Step 1a - Find offset of "System/iteminfo.lub"
  var offset = exe.findString("System/iteminfo.lub", RVA);
  if (offset === -1)
    return "Failed in part 1 - iteminfo.lub not found";
  
  //Step 1b - Find its reference  
  offset = exe.findCode("68" + offset.packToHex(4),  PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in part 1 - iteminfo reference not found";
  
  //Step 2a - Get the new filename from user
  var myfile = exe.getUserInput("$newItemInfo", XTYPE_STRING, "String input - maximum 28 characters including folder name/", "Enter the new ItemInfo path (should be relative to RO folder)", "System/iteminfo.lub", 1, 28);
  if (myfile ===  "System/iteminfo.lub")
    return "Patch Cancelled";
  
  //Step 2b - Allocate space for the new name
  var zero = exe.findZeros(myfile.length);
  if (zero === -1)
    return "Failed in part 2";
  
  //Step 3 - Insert the new name and replace the iteminfo reference
  exe.insert(zero, myfile.length, "$newItemInfo", PTYPE_STRING);    
  exe.replace(offset+1, exe.Raw2Rva(zero).packToHex(4), PTYPE_HEX);
  
  return true;
}