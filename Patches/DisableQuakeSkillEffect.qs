function QuakeSkillEffect() {
	
	// MISSION: Find CView::SetQuake and CView::SetQuakeInfo.
	// You are pretty much lost, if you are not able to hunt
	// either of them down, as they are next to each other. One
	// VC6 hint being: Look for PUSH 3E4CCCCDh, PUSH 3E75C28F
	// and PUSH 3F800000h. The next call after these 3 PUSHs is
	// CView::SetQuake, right above it is CView::SetQuakeInfo.
	// VC9 does not push float values like longs, but pull them
	// out of somewhere. The tail of CView::SetQuake can serve
	// for comparison.
	
	if (exe.getClientDate() <= 20130605)
		var code =  ' D9 44 24 04 D9 59 04 D9 44 24 0C D9 59 0C D9 44 24 08 D9 59 08 C2 0C 00 CC CC CC CC CC CC CC CC 8B 44 24 04';
    else
		var code =  ' 55 8B EC D9 45 08 D9 59 04 D9 45 10 D9 59 0C D9 45 0C D9 59 08 5D C2 0C 00 CC CC CC CC CC CC CC 55 8B EC 8B 45 08';
		
    var offset = exe.findCode(code, PTYPE_HEX, false);
	if (offset == -1) {
		return "Failed in part 1";
	}

	if (exe.getClientDate() <= 20130605) {
		exe.replace(offset, ' C2 0C 00', PTYPE_HEX);
	}
	else {
		exe.replace(offset  , ' 90 90 90', PTYPE_HEX);
		exe.replace(offset+3, ' C2 0C 00', PTYPE_HEX);
	}
	
	exe.replace(offset+32, ' C2 14 00', PTYPE_HEX);
    return true;
}