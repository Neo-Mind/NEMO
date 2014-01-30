function KoreaServiceTypeXMLFix() {

	// 10.12.2010 - I think the diff I've placed inside SkipServiceSelect was
	//              KoreaServiceTypeXMLFix. Even though, the previous version of this diff
	//              just replaced the properties with those of america in the wrong way. [Shinryo]
	
	// Shinryo:
	// Gravity has their clientinfo hardcoded and seperated the initialization, screw 'em.. :(
	// SelectKoreaClientInfo() has for example global variables like g_extended_slot set
	// which aren't set by SelectClientInfo(). Just call both functions will fix this as the
	// changes from SelectKoreaClientInfo() will persist and overwritten by SelectClientInfo().
	// TO-DO: Maybe use a seperate diff? Dunno.

	var code = ' E8 AB AB FF FF E9 AB AB FF FF 6A 00 E8 AB AB FF FF 83 C4 04';
	var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
	if (offset == -1) {
		return "Failed in part 1";
	}
	
	exe.replace(offset+5, ' 90 90 90 90 90', PTYPE_HEX);
	return true;
}