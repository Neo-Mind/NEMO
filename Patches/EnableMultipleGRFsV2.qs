function EnableMultipleGRFsV2() {
  ////////////////////////////////////////////////////////////////
  // GOAL: Override the data.grf loading with a custom function //
  //       that loads set of grfs directly instead of from INI  //
  //       INI file is still needed as input to the patch       //
  ////////////////////////////////////////////////////////////////
  
  //Step 1a - Find data.grf location
  var grf = exe.findString("data.grf", RVA).packToHex(4);
  
  //Step 1b - Find its reference
  var code =
      " 68" + grf       // PUSH OFFSET addr1; "data.grf"
    + " B9 AB AB AB 00" // MOV ECX, OFFSET g_fileMgr
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2a - Extract the g_FileMgr assignment
  var setECX = exe.fetchHex(offset+5, 5);
    
  //Step 2b - Find the AddPak call after the push 
  code =
      " E8 AB AB AB AB"    // CALL CFileMgr::AddPak()
    + " 8B AB AB AB AB 00" // MOV reg32, DWORD PTR DS:[addr1]
    + " A1 AB AB AB 00"    // MOV EAX, DWORD PTR DS:[addr2]
    ;

  var fnoffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10);
  if (fnoffset === -1) {
    code =
        " E8 AB AB AB AB" // CALL CFileMgr::AddPak()
      + " A1 AB AB AB 00" // MOV EAX, DWORD PTR DS:[addr2]
      ;

    fnoffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+10);
  }
  if (fnoffset === -1)
    return "Failed in part 2";
  
  //Step 2c - Extract AddPak function address
  var AddPak = exe.Raw2Rva(fnoffset + 5) + exe.fetchDWord(fnoffset + 1);
  
  //Step 3a - Get the INI file from user to read
  var f = new TextFile();
  if (!getInputFile(f, '$inpMultGRF', 'File Input - Enable Multiple GRF', 'Enter your INI file', APP_PATH) )
    return "Patch Cancelled";
  
  //Step 3b - Read the GRF filenames from the INI
  var temp = [];  
  while (!f.eof()) {
    var str = f.readline().trim();
    if (str.charAt(1) === "=") {
      var key = parseInt(str.charAt(0));
      if (!isNaN(key))
        temp[key] = str.substr(2);//full length is retrieved.
    }
  }
  
  f.close();
  
  //Step 3c - Put into an array in order.
  var grfs = [];  
  for (var i = 0; i < 10; i++) {
    if (temp[i])
      grfs.push(temp[i]);
  }
  if (!grfs[0])
    grfs.push("data.grf");
  
  //Step 4a - Prep code for GRF loading
  var template = 
      " 68" + genVarHex(1) // PUSH OFFSET addr; GRF name
    + setECX            // MOV ECX, OFFSET g_fileMgr
    + " E8" + genVarHex(2) // CALL CFileMgr::AddPak()
    ;
    
  //Step 4b - Get Size of code & strings to allocate
  var strcode = grfs.join("\x00") + "\x00";
  var size = strcode.length + grfs.length * template.hexlength() + 2;

  //Step 4c - Allocate space to inject
  var free = exe.findZeros(size);
  if (free === -1)
    return "Unable to find enough free space";
  
  var freeRva = exe.Raw2Rva(free);
  
  //Step 4d - Starting offsets to replace genVarHex with
  var o2 = freeRva + grfs.length * template.hexlength() + 2;
  var fn = AddPak - o2 + 2;
  
  //Step 4e - Create the full code from template for each grf & add strings
  var code = "";  
  for (var j = 0; grfs[j]; j++) {
    code = remVarHex(template, [1, 2], [o2, fn]) + code;
    o2 += grfs[j].length + 1; //Extra 1 for NULL byte
    fn += template.hexlength();
  }
  code += " C3 00";//RETN and 1 extra NULL
  code += strcode.toHex();
  
  //Step 4f - Create a call to the free space that was found before.
  exe.replace(offset, ' B9', PTYPE_HEX);//Little trick to avoid changing 10 bytes - apparently the push gets nullified in the original
  exe.replaceDWord(fnoffset + 1, freeRva - exe.Raw2Rva(fnoffset + 5));
  
  //Step 5 - Insert everything.
  exe.insert(free, size, code, PTYPE_HEX);
  
  return true;
}