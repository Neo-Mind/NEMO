//This one needs work since it replaces with Iteminfo.lua rather than Load this first.
function ItemInfo() {

	var offset = exe.findString("System/iteminfo.lub", RVA);
	if (offset == -1 ) {
		return "Failed in part 1";
	}
	
	offset = exe.findCode('68' + offset.packToHex(4),  PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in part 2";
	}
	
	var myfile = exe.getUserInput('$newItemInfo', XTYPE_STRING, 'String input - maximum 28 characters including folder name/', 'Enter the new ItemInfo path (should be relative to RO folder)', "System/iteminfo.lub", 1, 28);
	if (myfile !== "System/iteminfo.lub") {
		var zero = exe.findZeros(myfile.length);
		if (zero == -1) {
			return "Failed in part 3";
		}
		
		exe.insert(zero, myfile.length, '$newItemInfo', PTYPE_STRING);
		
		zero = exe.Raw2Rva(zero).packToHex(4);		
		exe.replace(offset+1, zero, PTYPE_HEX);
	}
    return true;
}