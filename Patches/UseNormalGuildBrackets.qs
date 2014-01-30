function UseNormalGuildBrackets() {

	var offset = exe.findString("%s" + "\xA1\xBA" + "%s" + "\xA1\xBB", RAW);
	if (offset == -1) {
		return 'Failed in part 1';
	}

	exe.replace(offset, "%s (%s) ", PTYPE_STRING);
    return true;
}