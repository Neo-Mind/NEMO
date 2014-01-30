function RemoveGravityLogo() {

	var code = "T_R%d.tga";
	var offset = exe.findAll(code, PTYPE_STRING, false);
	if (offset.length !== 1) {
		return "Failed in part 1";
	}
	
	exe.replace(offset[0], ' 00', PTYPE_HEX);
	return true;
}