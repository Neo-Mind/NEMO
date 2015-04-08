function LoadCustomQuestLua() {
  //////////////////////////////////////////////////////////////
  // GOAL: Hijack Quest_function lua loading to load          //
  //       specified files first then load the Quest_function.//
  //       Files to load is specified in a list file          //
  //////////////////////////////////////////////////////////////
  
  //Step 1a - Find the Quest_function string
  var prefix = "lua files\\quest\\";
  var qfuncoff = exe.findString(prefix + "Quest_function", RVA);
  if (qfuncoff === -1)
    return "Failed in Part 1 - Quest_function not found";
  
  //Step 1b - Find its reference
  var offset = exe.findCode( "68" + qfuncoff.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 1 - Quest_function reference missing";
  
  var jmpback = offset + 10;
  
  //Step 1c - Find the starting part of the lua file loading code 
  var jmpfrom = exe.find(" 8B AB AB AB AB 00", PTYPE_HEX, true, "\xAB", offset - 10, offset);//Need to overwrite to a jump at this location
  if (jmpfrom === -1)
    return "Failed in Part 3";
  
  var luacodesize  = jmpback - jmpfrom;//needed later.
  
  //Step 1d - Extract the lua file loader prep code (looks similar to below code)
  //  MOV ECX, DWORD PTR DS:[ESI+const] ; lua_state
  //  PUSH 0
  //  PUSH 1
  //  PUSH OFFSET addr ; "filename"
  //  CALL lua_file_loader
  
  var luacode = exe.fetchHex(jmpfrom, luacodesize);

  //Step 1e - Extract the lua file loader function address
  var lualoader = exe.Raw2Rva( jmpback + exe.fetchDWord(offset + 6) );//Function which loads Lua file
  
  //Step 2a - Get the List file
  var f = new TextFile();
  if (!getInputFile(f, '$inpQuest', 'File Input - Load Custom Quest Lua', 'Enter the Lua list file', APP_PATH))
    return "Patch Cancelled";
  
  //Step 2b - Get the filenames from the list file
  var files = [];
  var size = 0;
  while (!f.eof()) {
    var line = f.readline().trim();
    if (line.charAt(0) !== "/" && line.charAt(1) !== "/") {
      files.push(line);
      size += prefix.length + line.length + 1;
    }
  }
  f.close();

  if (files.length > 0) {
    //Step 3a - Calculate size required for loading all the files
    var blocksize = size + (files.length + 1) * luacodesize + 5; //string data + loading instructions + last 5 bytes for jumping back.
    
    //Step 3b - Allocate space for loading all the files + Quest_function 
    var free = exe.findZeros(blocksize);
    if (free === -1)
      return "Failed to find enough free space";
      
    var freeRva = exe.Raw2Rva(free);
    
    //Step 3c - Prep the code (load all the files) 
    var code = prefix + files.join("\x00" + prefix) + "\x00"; //the strings.
    var stroffset = 0;
    var callpos = lualoader - (freeRva + code.length + luacodesize);
    
    code = code.toHex();
    for (var i = 0; i < files.length; i++) {
      code += luacode.replaceAt(-4*3, callpos.packToHex(4)).replaceAt(-9*3, (freeRva + stroffset).packToHex(4));
      stroffset += prefix.length + files[i].length + 1;
      callpos -= luacodesize;
    }
    
    //Step 3d - Add Quest_function loader
    code += luacode;
    code = code.replaceAt(-4*3, callpos.packToHex(4));
    code = code.replaceAt(-9*3, qfuncoff.packToHex(4));
    
    //Step 3e - Add the return jmp
    code += " E9" + (exe.Raw2Rva(jmpback) - (freeRva + blocksize)).packToHex(4);
    
    //Step 4a - Insert the code
    exe.insert(free, blocksize, code, PTYPE_HEX);
    
    //Step 4b - Modify the Quest_function loader with a jmp
    exe.replace(jmpfrom, "E9" + (freeRva + size - exe.Raw2Rva(jmpfrom+5)).packToHex(4), PTYPE_HEX);
  }
  
  return true;
}