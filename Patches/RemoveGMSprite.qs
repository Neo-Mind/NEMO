function RemoveGMSprite() {
	
	//Step 1 : Find RVA of GM spr file
	var code = "\xC0\xCE\xB0\xA3\xC1\xB7\x5C\xBF\xEE\xBF\xB5\xC0\xDA\x5C\xBF\xEE\xBF\xB5\xC0\xDA\x32\x5F\xB3\xB2\x5F\xB0\xCB" + ".Spr";
			//ÀÎ°£Á·\¿î¿µÀÚ\¿î¿µÀÚ2_³²_°Ë.Spr
	var offset =  exe.findString(code, RVA) .packToHex(4);
	
	var ret = helper_RGMS(offset);
	if (ret !== "Completed") {
		return ret;
	}
	
	//Step 2 : Find RVA of GM act file
	code = "\xC0\xCE\xB0\xA3\xC1\xB7\x5C\xBF\xEE\xBF\xB5\xC0\xDA\x5C\xBF\xEE\xBF\xB5\xC0\xDA\x32\x5F\xB3\xB2\x5F\xB0\xCB" + ".Act";
			//ÀÎ°£Á·\¿î¿µÀÚ\¿î¿µÀÚ2_³²_°Ë.Act
	offset =  exe.findString(code, RVA) .packToHex(4);
	
	ret = helper_RGMS(offset);
	if (ret !== "Completed") {
		return ret;
	}
	
	return true;
}

function helper_RGMS(offset) {

	//Step 3 : Find Pushed location
	var code = '68' + offset;
	var finish = exe.findCode(code, PTYPE_HEX, false);
	if (finish == -1) {
		return "Failed in Step 3";
	}
	
	//Step 4 : Find Pattern within boundary from finish (lets say within 0x200 bytes)
	var code =	  ' 83 C4 04'			//add esp, 4
			+ ' 84 C0'				//test al,al
			+ ' 0F 84 AB AB 00 00'	//jz <location skipping GM sprite override>
			;
				
	var location = exe.find(code, PTYPE_HEX, true, "\xAB", finish - 0x200, finish);
	if (location == -1) {
		return "Failed in Step 4";
	}
	
	//Step 5 : replace jz with jmp
	exe.replace(location+5, " 90 E9", PTYPE_HEX);
	
	return "Completed";	
}