function FixTetraVortex() {
	for (var i = 1; i <= 8; i++) {
		var code = "effect\\tv-" + i + ".bmp";
		var offset = exe.findString(code, RAW);
		if (offset == -1) {
			return "Failed in Step 1." + i;
		}
		exe.replace(offset, "00", PTYPE_HEX);
	}
}