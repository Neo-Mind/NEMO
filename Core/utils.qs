function getInputFile(f, varname, title, prompt, fpath) {
	var inp = "";
	while (inp === "") {
		inp = exe.getUserInput(varname, XTYPE_FILE, title, prompt, fpath);		
		if (inp === "") {
			return false;
		}
		
		f.open(inp);
		if (f.eof()) {
			f.close();
			inp = "";
		}
	}
	return true;
}