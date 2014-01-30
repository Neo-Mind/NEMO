function RemoveGravityAds() {

	// T_중력성인.tga
	var code = ' 54 5F C1 DF B7 C2 BC BA C0 CE 2E 74 67 61';
	var offset = exe.findAll(code, PTYPE_HEX, false);
	if (offset.length !== 1) {
		return "Failed in part 1";
	}

	exe.replace(offset[0], ' 00', PTYPE_HEX);
	
	// T_GameGrade.tga
	code = ' 54 5F 47 61 6D 65 47 72 61 64 65 2E 74 67 61';
	offset = exe.findAll(code, PTYPE_HEX, false);
	if (offset.length !== 1) {
		return "Failed in part 2";
	}
	
	exe.replace(offset[0], ' 00', PTYPE_HEX);

	// T_테입%d.tga
	code = ' 54 5F C5 D7 C0 D4 25 64 2E 74 67 61';
	offset = exe.findAll(code, PTYPE_HEX, false);
	if (offset.length !== 1) {
		return "Failed in part 3";
	}
	
	exe.replace(offset[0], ' 00', PTYPE_HEX);
	return true;
}