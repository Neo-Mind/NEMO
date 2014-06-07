function ReadIconFile(fname) {
	var fp = new BinFile();
	fp.open(fname);
	var icondir = new Object();	
	var pos = 0;
	
	icondir.idReserved = fp.readHex(pos,2).unpackToInt();
	icondir.idType     = fp.readHex(pos+2,2).unpackToInt();
	icondir.idCount    = fp.readHex(pos+4,2).unpackToInt();
	icondir.idEntries  = new Array();
	pos += 6;
	
	for(var i = 0; i < icondir.idCount; i++) {
		var icondirentry = new Object();
		icondirentry.bWidth  			= fp.readHex(pos,1).unpackToInt();
		icondirentry.bHeight 			= fp.readHex(pos+1,1).unpackToInt();
		icondirentry.bColorCount  = fp.readHex(pos+2,1).unpackToInt();
		icondirentry.bReserved    = fp.readHex(pos+3,1).unpackToInt();
		icondirentry.wPlanes      = fp.readHex(pos+4,2).unpackToInt();
		icondirentry.wBitCount    = fp.readHex(pos+6,2).unpackToInt();
		icondirentry.dwBytesInRes = fp.readHex(pos+8,4).unpackToInt();
		icondirentry.dwImageOffset= fp.readHex(pos+12,4).unpackToInt();
		icondirentry.iconimage 	  = fp.readHex(icondirentry.dwImageOffset, icondirentry.dwBytesInRes);
		icondir.idEntries[i] 			= icondirentry;
		pos += 16;
	}
	fp.close();
	return icondir;
}

function UseRagnarokIcon() {
	UseCustomIcon(true);
}

function UseCustomIcon(nomod) {
	var PEoffset = exe.find("50 45 00 00", PTYPE_HEX, false);
	if (PEoffset === -1)
		return "Unable to find the PE header";

	var offset = PEoffset + 0x18 + 0x60 + 0x10;
	var rsrcRva = exe.fetchDWord(offset) + exe.getImageBase(); //should be same as RSRC
	var rsrcRaw = exe.Rva2Raw(rsrcRva);
	
	//Step 1 - Get the Resource Tree.
	var rsrcTree = new ResourceDir(rsrcRaw, 0, 0);
	
	//Step 2 - Find the resource dir of RT_GROUP_ICON and adjust 114 subdir to use 119 data as well
	var entry = GetResourceEntry(rsrcTree, [0xE]);	
	if (entry === -1) 
		return "Failed in Part 2 - Unable to find icongrp";
	
	offset = entry.addr;
	var id = exe.fetchDWord(offset+0x10);
	
	if (id == 119) {
		var newvalue = exe.fetchDWord(offset+0x10+0x4);
		exe.replaceDWord(offset+0x10+0x8+0x4, newvalue);
	}
	else {
		var newvalue = exe.fetchDWord(offset+0x10+0x8+0x4);
		exe.replaceDWord(offset+0x10+0x4, newvalue);
	}
	
	if(nomod) 
		return true;
		
	//Step 3 - Find the RT_GROUP_ICON , 119, 1042 resource entry address	
/*
	var debug = GetResourceEntry(rsrcTree, [0x3]);
	var debugList = new Array();
	for ( var i = 0; i < debug.numEntries; i++) {
		debugList[i] = debug.entries[i].id;
	}
	return "RESULT = " + debugList;
*/
	var entry = GetResourceEntry(rsrcTree, [0xE, 0x77, 0x412]);//RT_GROUP_ICON , 119, 1042	
	switch (entry) {
		case -2: return "Failed in Part 2 - Unable to find icongrp/lang";
		case -3: return "Failed in Part 2 - Unable to find icongrp/lang/bundle";
	}
	var icogrpOff = entry.dataAddr;
	
	//Step 4 - Load the new icon & get the feasible image data we can use	
	var fp = new BinFile();
	var iconfile = getInputFile(fp, '$inpIconFile', 'File Input - Use Custom Icon', 'Enter the Icon File', APP_PATH);
	if (!iconfile)
		return "Patch Cancelled";
	fp.close();
	
	var icondir = ReadIconFile(iconfile);	
	for (var i = 0; i < icondir.idCount; i++) {
		var entry = icondir.idEntries[i];
		if (entry.bHeight == 32 && entry.bWidth == 32 && entry.wBitCount == 8 && entry.bColorCount == 0) 
			break;
	}
	if (i == icondir.idCount)
		return "Invalid icon file specified";
	
	var icondirentry = icondir.idEntries[i];
	
	//Step 5 - Find a valid RT_ICON - colorcount = 0, bpp = 8, and ofcourse the id will belong to valid resource
	/*
	var memicondir = new Object();	
	memicondir.idReserved = exe.fetchWord(icogrpOff);
	memicondir.idType     = exe.fetchWord(icogrpOff+2);
	memicondir.idEntries  = new Array();
	*/
	
	var idCount = exe.fetchWord(icogrpOff+4);
	var pos = icogrpOff+6;
	
	for (var i = 0; i < idCount; i++) {
		var memicondirentry = new Object();
		memicondirentry.bWidth  			= exe.fetchByte(pos);
		memicondirentry.bHeight 			= exe.fetchByte(pos+1);
		memicondirentry.bColorCount  	= exe.fetchByte(pos+2);
		memicondirentry.bReserved    	= exe.fetchByte(pos+3);
		memicondirentry.wPlanes      	= exe.fetchWord(pos+4);
		memicondirentry.wBitCount    	= exe.fetchWord(pos+6);
		memicondirentry.dwBytesInRes 	= exe.fetchDWord(pos+8);
		memicondirentry.nID						= exe.fetchWord(pos+12);
		
		if (memicondirentry.bColorCount == 0 && memicondirentry.wBitCount == 8 && memicondirentry.bWidth == 32 && memicondirentry.bWidth == 32) {//8bit image
			entry = GetResourceEntry(rsrcTree, [0x3, memicondirentry.nID, 0x412]);
			if (entry < 0) 
				continue;
			break;
		}
		//memicondir.idEntries[i]				= memicondirentry;
		pos += 14;
	}
	
	if (i === idCount)
		return "Failed in Part 5 - no suitable icon found in exe";

	//size should be 40 (header) + 256*4 (palette) + 32*32 (xor mask) + 32*32/8 (and mask)
	if (memicondirentry.dwBytesInRes < icondirentry.dwBytesInRes)
		return "Failed in Part 5 - Unable to overwrite icon size issue";

	//Step 6 - Update the size in bytes dwBytesInRes and wPlanes as per the uploaded icon.	
	exe.replaceWord(pos-14+4, icondirentry.wPlanes);
	exe.replaceWord(pos-14+8, icondirentry.dwBytesInRes);
	
	//Step 7 - update the image
	exe.replaceDWord(entry.addr+4, icondirentry.dwBytesInRes);
	exe.replace(entry.dataAddr, icondirentry.iconimage, PTYPE_HEX);
	return true;
}