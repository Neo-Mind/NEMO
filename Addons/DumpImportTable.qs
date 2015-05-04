function DumpImportTable() {
  ////////////////////////////////////////////////////////////////////////
  // GOAL: Dump the Import Table (Full Hierarchy) for the loaded client //
  //       to a text file                                               //
  ////////////////////////////////////////////////////////////////////////
  
  //Step 1a - Get the Import Data Directory Offset
	var offset = GetDataDirectory(1).offset;
  
  //Step 1b - Open text file for writing
	fp = new TextFile();
	if (!fp.open(APP_PATH + "/Output/importTable_Dump_" + exe.getClientDate() + ".txt", "w"))
    throw "Error: Unable to create text file in Output folder";
  
  //Step 2a - Write the import address to file
	fp.writeline("IMPORT TABLE (RAW) = 0x" + convertToBE(offset));
  
	for (var flag = false; !flag; offset += 20) {
    //Step 2b - Iterate through each IMAGE_IMPORT_DESCRIPTOR 
		var ilt = exe.fetchDWord(offset); //Lookup Table address
		var ts = exe.fetchDWord(offset + 4);//TimeStamp
		var fchain = exe.fetchDWord(offset + 8);//Forwarder Chain
		var dllName = exe.fetchDWord(offset + 12);//DLL Name address
		var iatRva = exe.fetchDWord(offset + 16);//Import Address Table <- points to the First Thunk
    
    //Step 2c - Check if reached end (all 20 bytes will be NULLs)
		flag = (ilt == 0 && ts == 0 && fchain == 0 && dllName == 0 && iatRva == 0);
		if (flag) continue;
    
    //Step 2d - Write the Descriptor Info to file
    dllName = exe.Rva2Raw(dllName + exe.getImageBase());
    var offset2 = exe.find("00", PTYPE_HEX, false, "", dllName);
    
		fp.writeline( "Lookup Table = 0x" + convertToBE(ilt)
                + ", TimeStamp = " + ts 
                + ", Forwarder = " + fchain 
                + ", Name = " + exe.fetch(dllName, offset2 - dllName) 
                + ", Import Address Table = 0x" + convertToBE(iatRva)
                );        
    fp.writeline("  ---- Start of Functions ----");
      
    //Step 2e - Get the Raw offset of First Thunk                
		offset2 = exe.Rva2Raw(iatRva+exe.getImageBase());
      
	  for (var flag2 = false; !flag2; offset2 += 4) {
      //Step 2f - Iterate through each IMAGE_THUNK_DATA
		  var ordFlag = (exe.fetchByte(offset2 + 3) >> 7) & 0x1; //First Bit shows whether this functions is imported by Name (0) or Ordinal (1)
			var funcData = exe.fetchDWord(offset2);//Ordinal Number or Offset of Function Name
        
      //Step 2e - Check which type it is accordingly Write out the info to file
			flag2 = (funcData == 0);
      if (flag2) {
        fp.writeline("  ---- End of Functions ----");
      }
			else if (ordFlag == 0) {
        funcData = funcData & 0x7FFFFFFF;//Address pointing to IMAGE_IMPORT_BY_NAME struct (First 2 bytes is Hint, remaining is the Function Name)
        var offset3 = exe.Rva2Raw(funcData + exe.getImageBase());
        var offset4 = exe.find("00", PTYPE_HEX, false, "", offset3+2);
        fp.writeline( "  Thunk Address (RVA) = 0x" + convertToBE(offset2)
                    + ", Thunk Address(RAW) = 0x" + convertToBE(exe.Rva2Raw(offset2))
                    + ", Function Hint = 0x" + exe.fetchHex(offset3, 2).replace(/ /g, "")
                    + ", Function Name = " + exe.fetch(offset3+2, offset4 - (offset3+2))
                    );            
			}
			else {
        funcData = funcData & 0xFFFF;
        fp.writeline( "  Thunk Address (RVA) = 0x" + convertToBE(offset2)
                    + ", Thunk Address(RAW) = 0x" + convertToBE(exe.Rva2Raw(offset2))
                    + ", Function Ordinal = " + funcData
                    );
			}	
		}
	}
	fp.close();
	
	return "Import Table has been dumped to Output folder";
}