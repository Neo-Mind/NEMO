function IncreaseZoomOut50Per() {
	return IncreaseZoomOut('FF 43');
}

function IncreaseZoomOut75Per() {
	return IncreaseZoomOut('4C 44');
}

function IncreaseZoomOutMax() {
	return IncreaseZoomOut('99 44');
}

function IncreaseZoomOut(newvalue) {
	var code = ' 00 00 66 43 00 00 C8 43 00 00 96 43';
	var offsets = exe.findAll(code, PTYPE_HEX, false);
	if (!offsets[0]) {
		return "Failed in part 1";
	}
	
	exe.replace(offsets[0]+6, newvalue, PTYPE_HEX);	
	return true;
}