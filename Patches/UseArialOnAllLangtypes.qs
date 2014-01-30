function UseArialOnAllLangtypes() {
// 10.12.2010 - Changed behaviour of this diff to always (in any case) use Arial on all language types. [Shinryo]
			
	if (exe.getClientDate() <= 20130605) {
		var code =' 75 5B 8D 57 FF 83 FA 0A 77 53';
	}
	else {
		var code =' 75 5A 8D 57 FF 83 FA 0A 77 52';
	}
	
    var offset = exe.findCode(code, PTYPE_HEX, false);	
	if (offset == -1) {
		return 'Failed in part 1';
	}
	
    exe.replace(offset+8, ' EB 0C', PTYPE_HEX);	
    return true;
}