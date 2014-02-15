function EnableCustom3DBones() {
	//Step 1 - Find location of the sprintf control string for 3d mob bones
	var mob_bone = exe.findString('model\\3dmob_bone\\%d_%s.gr2', RVA);
	if (mob_bone == -1) {
		return 'Failed in Part 1';
	}		
	
	//Step 2 - Find C3dGrannyBoneRes::GetAnimation by bone 
	// MOV <R32>, [ARRAY] <= Find offset of this instruction
	// PUSH <R32>
	// PUSH <R32>
	// PUSH <$mob_bone>
	var finish = exe.findCode('68' + mob_bone.packToHex(4), PTYPE_HEX, false);
	if (finish == -1) {
		return 'Failed in Part 2';
	}
	finish -= 9;
	//Step 3 - Find Limiting CMP
	// Find offset of instruction after CMP ESI, 9h within this function before $finish
	// We use $finish - 0x70 as an approximate location where the function starts
	
	var offset = exe.find(' 83 FE 09', PTYPE_HEX, false, " ", finish - 0x70, finish);
	if (offset == -1) {	
		// For VC9 images the valus is 09h but for earlier VC6 images the value is 10h
		offset = exe.find(' 83 FE 0A', PTYPE_HEX, false, " ", finish - 0x70, finish);
	}
	
	if (offset == -1) {
		return 'Failed in Part 3';
	}
	
	offset = offset + 3;
	
	//Step 4 - Make it always use 3dmob_bone
	// Modify JGE/JA to always address bones. Do not care about which CMP we hit, the important thing is the conditional
    // JGE/JA after it, be it SHORT or LONG. Also let's trust the client here, that it never calls the function with nAniIdx outside of [0;4]
	var bite = exe.fetchByte(offset);
	if (bite == 0x77 || bite == 0x7D) {
		// Short Jump
		exe.replace(offset+1, (finish-offset-2).packToHex(1), PTYPE_HEX);
	} 
	else if (bite == 0x0F) {
		// Long Jump
		exe.replace(offset+2, (finish-offset-6).packToHex(4), PTYPE_HEX);
	}
	else {
		return "Failed in Part 4";
	}	
	return true;
}