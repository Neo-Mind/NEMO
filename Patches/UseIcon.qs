function ReadIconFile(fname) {
  //////////////////////////////////////////////////////////////
  // GOAL: Helper Function to read the data from an icon file //
  //       to a useful structure (object)                     //
  //////////////////////////////////////////////////////////////
  
  //Step 1 - Open the icon file 
  var fp = new BinFile();
  fp.open(fname);
  
  //Step 2 - Create a icondir structure/object which will hold all the info & images
  var icondir = new Object();
  var pos = 0;
  
  //Step 3 - Read Header Entries
  icondir.idReserved = fp.readHex(pos,2).unpackToInt();
  icondir.idType     = fp.readHex(pos+2,2).unpackToInt();
  icondir.idCount    = fp.readHex(pos+4,2).unpackToInt();
  icondir.idEntries  = [];
  pos += 6;
  
  //Step 4 - Read all the image entry + data
  for(var i = 0; i < icondir.idCount; i++) {
    var icondirentry = new Object();
    icondirentry.bWidth        = fp.readHex(pos,1).unpackToInt();
    icondirentry.bHeight       = fp.readHex(pos+1,1).unpackToInt();
    icondirentry.bColorCount   = fp.readHex(pos+2,1).unpackToInt();
    icondirentry.bReserved     = fp.readHex(pos+3,1).unpackToInt();
    icondirentry.wPlanes       = fp.readHex(pos+4,2).unpackToInt();
    icondirentry.wBitCount     = fp.readHex(pos+6,2).unpackToInt();
    icondirentry.dwBytesInRes  = fp.readHex(pos+8,4).unpackToInt();
    icondirentry.dwImageOffset = fp.readHex(pos+12,4).unpackToInt();
    icondirentry.iconimage     = fp.readHex(icondirentry.dwImageOffset, icondirentry.dwBytesInRes);
    icondir.idEntries[i]       = icondirentry;
    pos += 16;
  }
  
  //Step 5 - Close the file
  fp.close();
  
  //Step 6 - Return the structure created
  return icondir;
}

// Both patches use similar steps in the beginning. 
// For custom icon some extra steps are needed obviously

function UseRagnarokIcon() {
  UseCustomIcon(true);
}

function UseCustomIcon(nomod) {
  /////////////////////////////////////////////////////////////////
  // GOAL: Modify te resources table to use the 8bpp 32x32 icon  //
  //       present in the client. For Custom Icon patch this     //
  //       data will be overwritten with data from the icon file //
  /////////////////////////////////////////////////////////////////

  //Step 1 - Find PE Header & then Resource Table
  var PEoffset = exe.find("50 45 00 00", PTYPE_HEX, false);
  if (PEoffset === -1)
    return "Failed in Part 1 - Unable to find the PE header";

  var offset = PEoffset + 0x18 + 0x60 + 0x10;
  var rsrcRva = exe.fetchDWord(offset) + exe.getImageBase(); //should be same as RSRC
  var rsrcRaw = exe.Rva2Raw(rsrcRva);
  
  //Step 2 - Get the Resource Tree (Check the function in core)
  var rsrcTree = new ResourceDir(rsrcRaw, 0, 0);
  
  //Step 3a - Find the resource dir of RT_GROUP_ICON = 0xE (check the function in core)
  var entry = GetResourceEntry(rsrcTree, [0xE]);
  if (entry === -1)
    return "Failed in Part 3 - Unable to find icongrp";
  
  offset = entry.addr;
  var id = exe.fetchDWord(offset+0x10);
  
  //Step 3b - Adjust 114 subdir to use 119 data - thus same icon will be used for both
  if (id === 119) {
    var newvalue = exe.fetchDWord(offset+0x10+0x4);
    exe.replaceDWord(offset+0x10+0x8+0x4, newvalue);
  }
  else {
    var newvalue = exe.fetchDWord(offset+0x10+0x8+0x4);
    exe.replaceDWord(offset+0x10+0x4, newvalue);
  }
  
  if(nomod)
    return true;
    
  //---- Use Ragnarok Icon patch stops here ----
  
  //Step 4 - Find the RT_GROUP_ICON , 119, 1042 resource entry address
  var entry = GetResourceEntry(rsrcTree, [0xE, 0x77, 0x412]);//RT_GROUP_ICON , 119, 1042  
  switch (entry) {
    case -2: return "Failed in Part 4 - Unable to find icongrp/lang";
    case -3: return "Failed in Part 4 - Unable to find icongrp/lang/bundle";
  }
  
  var icogrpOff = entry.dataAddr;
  
  //Step 5a - Load the new icon
  var fp = new BinFile();
  var iconfile = getInputFile(fp, "$inpIconFile", "File Input - Use Custom Icon", "Enter the Icon File", APP_PATH);
  if (!iconfile)
    return "Patch Cancelled";
  fp.close();
  
  var icondir = ReadIconFile(iconfile);
  
  //Step 5b - Find the image that meets the spec = 8bpp 32x32
  for (var i = 0; i < icondir.idCount; i++) {
    var entry = icondir.idEntries[i];
    if (entry.bHeight == 32 && entry.bWidth == 32 && entry.wBitCount == 8 && entry.bColorCount == 0)
      break;
  }
  
  if (i === icondir.idCount)
    return "Invalid icon file specified";
  
  var icondirentry = icondir.idEntries[i];
  
  //Step 6 - Find a valid RT_ICON - colorcount = 0, bpp = 8, and ofcourse the id will belong to valid resource
  var idCount = exe.fetchWord(icogrpOff+4);
  var pos = icogrpOff+6;
  
  for (var i = 0; i < idCount; i++) {
    var memicondirentry = new Object();
    memicondirentry.bWidth       = exe.fetchByte(pos);
    memicondirentry.bHeight      = exe.fetchByte(pos+1);
    memicondirentry.bColorCount  = exe.fetchByte(pos+2);
    memicondirentry.bReserved    = exe.fetchByte(pos+3);
    memicondirentry.wPlanes      = exe.fetchWord(pos+4);
    memicondirentry.wBitCount    = exe.fetchWord(pos+6);
    memicondirentry.dwBytesInRes = exe.fetchDWord(pos+8);
    memicondirentry.nID          = exe.fetchWord(pos+12);
    
    if (memicondirentry.bColorCount == 0 && memicondirentry.wBitCount == 8 && memicondirentry.bWidth == 32 && memicondirentry.bWidth == 32) {//8bit image
      entry = GetResourceEntry(rsrcTree, [0x3, memicondirentry.nID, 0x412]);//returns negative number on fail or ResourceEntry object on success
      if (entry < 0) continue;
      break;
    }
    
    pos += 14;
  }
  
  if (i === idCount)
    return "Failed in Part 6 - no suitable icon found in exe";

  if (memicondirentry.dwBytesInRes < icondirentry.dwBytesInRes)
    return "Failed in Part 6 - Icon wont fit";//size should be 40 (header) + 256*4 (palette) + 32*32 (xor mask) + 32*32/8 (and mask)

  //Step 7 - Update the size in bytes dwBytesInRes and wPlanes as per the uploaded icon
  exe.replaceWord(pos-14+4, icondirentry.wPlanes);
  exe.replaceWord(pos-14+8, icondirentry.dwBytesInRes);

  //Step 8 - Finally update the icon image
  exe.replaceDWord(entry.addr+4, icondirentry.dwBytesInRes);
  exe.replace(entry.dataAddr, icondirentry.iconimage, PTYPE_HEX);

  return true;
}