//############################################################
//# Purpose: Get Addresses of strings, functions & lua_state #
//#          used in Lua Function Calls                      #
//############################################################

delete D2S;
delete D2D;
delete EspAlloc;
delete StrAlloc;
delete AllocType;
delete LuaState;
delete LuaFnCaller;

function _GetLuaAddrs() {
  //Step 1a - d>s
  var offset = exe.findString("d>s", RVA);
  if (offset === -1)
    return "LUA: d>s not found";
  
  D2S = offset.packToHex(4);
  
  //Step 1b - d>d
  offset = exe.findString("d>d", RVA);
  if (offset === -1)
    return "LUA: d>d not found";
  
  D2D = offset.packToHex(4);
  
  //Step 2a - Find offset of ReqJobName
  offset = exe.findString("ReqJobName", RVA);
  if (offset === -1)
    return "LUA: ReqJobName not found";
  
  //Step 2b - Find its reference
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "LUA: ReqJobName reference missing";
  
  //Step 2c - Find the ESP allocation before the reference and Extract the subtracted value
  var code =
    " 83 EC AB" //SUB ESP, const
  + " 8B CC"    //MOV ECX, ESP
  ;
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x28, offset);
  if (offset2 === -1)
    return "LUA: ESP allocation missing";
  
  EspAlloc = exe.fetchByte(offset2 + 2);
  
  //Step 2d - Extract String Allocator Function Address based on which opcode follows the PUSH
  switch (exe.fetchUByte(offset + 5)) {
    case 0xFF: {//CALL DWORD PTR DS:[func] -> VC9 Clients
      offset += 11;
      StrAlloc = exe.fetchHex(offset - 4, 4);
      AllocType = 0;//0 means function is an MSVC import
      break;
    }
    case 0xE8: {//CALL func -> Older Clients
      offset += 10;
      StrAlloc = exe.Raw2Rva(offset) + exe.fetchDWord(offset - 4);
      AllocType = 1;//1 means there is an argument PUSH which is a pointer.
      break;
    }
    case 0xC6: {//MOV BYTE PTR DS:[ECX], 0 -> VC10+ Clients
      offset += 13;
      StrAlloc = exe.Raw2Rva(offset) + exe.fetchDWord(offset - 4);
      AllocType = 2;//2 means there needs to be an assignment of 0F and 0 to ECX+14 and ESP+10
      break;
    }
    default: {
      return "LUA: Unexpected Opcode after ReqJobName";
    }
  }
  
  //Step 2e - Find Lua_state assignment after offset and extract it
  code = "8B AB AB AB AB 00"; //MOV reg32_A, DWORD PTR DS:[lua_state]
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x10); //VC9 - VC10

  if (offset2 === -1) {
    code = "FF 35 AB AB AB 00"; //PUSH DWORD PTR DS:[lua_state]
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x10);//VC11
  }
  
  if (offset2 === -1) {
    code = "A1 AB AB AB 00"; //MOV EAX, DWORD PTR DS:[lua_state]
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x10);//Older Clients
  }
  
  if (offset2 === -1)
    return "LUA: Lua_state assignment missing";
  
  offset2 += code.hexlength();
  
  LuaState = exe.fetchHex(offset2 - 4, 4);
  
  //Step 2f - Find the Lua Function caller after offset2
  offset = exe.find(" E8 AB AB AB FF", PTYPE_HEX, true, "\xAB", offset2, offset2 + 0x10);
  if (offset === -1)
    return "LUA: Lua Function caller missing";
  
  LuaFnCaller = exe.Raw2Rva(offset + 5) + exe.fetchDWord(offset + 1);
  
  return true;
}

//###############################################
//# Purpose: Generate code to call Lua Function #
//###############################################

function GenLuaCaller(addr, name, nameAddr, format, inReg) {

  //Step 1a - Get the Global Addresses if not already obtained
  if (typeof(LuaFnCaller) === "undefined") {
    var result = _GetLuaAddrs();
    if (typeof(result) === "string")
      return result;
  }
  
  //Step 1b - Get Offset of the format specified - can be either d>s or d>d
  if (format === "d>s")
    var fmtAddr = D2S;
  else
    var fmtAddr = D2D;
  
  //Step 1c - Change nameAddr to PTYPE_HEX format
  if (typeof(nameAddr) === "number")
    nameAddr = nameAddr.packToHex(4);
  
  //===========================//
  // Now to construct the code //
  //===========================//
  //Step 2a - First we construct a template
  var code =
    " PrePush"
  + " 6A 00"                         //PUSH 0
  + " 54"                            //PUSH ESP
  + inReg                            //PUSH reg32_A
  + " 68" + fmtAddr                  //PUSH fmtAddr; ASCII format
  + " 83 EC" + EspAlloc.packToHex(1) //SUB ESP, const
  + " 8B CC"                         //MOV ECX, ESP
  + " StrAllocPrep"                   
  + " 68" + nameAddr                 //PUSH nameAddr; ASCII name
  + " FF 15" + StrAlloc              //CALL DWORD PTR DS:[StrAlloc]              
  + " FF 35" + LuaState              //PUSH DWORD PTR DS:[LuaState]
  + " E8" + GenVarHex(1)             //CALL LuaFnCaller
  ;
  
  //Step 2b - Fill PrePush ( Older clients ) 
  if (AllocType === 1) {
    code = code.replace(" PrePush", " 6A" + name.length.packToHex(1)); //PUSH length
  }
  else {
    code = code.replace(" PrePush", "");
  }
  
  //Step 2c - Fill StrAllocPrep (Older & VC10+ Clients )
  if (AllocType === 1) {
    code = code.replace(" StrAllocPrep",
      " 8D 44 24" + (EspAlloc + 16).packToHex(1) //LEA EAX, [ESP + const2]; const2 = const + 0x18
    + " 50"                                      //PUSH EAX
    );
  }
  else if (AllocType === 2) {
    code = code.replace(" StrAllocPrep",
      " C7 41 14 0F 00 00 00" //MOV DWORD PTR DS:[ECX+14], 0F
    + " C7 41 10 00 00 00 00" //MOV DWORD PTR DS:[ECX+10], 0
    + " C6 01 00"             //MOV BYTE PTR DS:[ECX], 0
    + " 6A" + name.length.packToHex(1) //PUSH length
    );
  }
  else {
    code = code.replace(" StrAllocPrep", "");
  }

  //Step 2d - Change the Indirect StrAlloc CALL to direct ( Non VC9 Clients )
  if (AllocType !== 0)
    code = code.replace(" FF 15" + StrAlloc, " E8" + (StrAlloc - exe.Raw2Rva(addr + code.hexlength() - 12)).packToHex(4));//CALL StrAlloc
  
  //Step 2e - Fill the Lua Function Caller
  code = ReplaceVarHex(code, 1, LuaFnCaller - exe.Raw2Rva(addr + code.hexlength()));
  
  //Step 2f - Now add the Stack restore and Function output retrieval
  code += 
    " 83 C4" + (EspAlloc + 16).packToHex(1) //ADD ESP, const3; const3 = const + 16
  + " 58"                                   //POP EAX
  ;

  if (AllocType === 1) {//For Older clients
    code += " 83 C4 04"; //ADD ESP, 4
  }
  
  return code;
}

//##########################################
//# Purpose: Inject code to load Lua Files #
//##########################################

function InjectLuaFiles(origFile, nameList, free) {
  
  //Step 1a - Find offset of origFile
  var origOffset = exe.findString(origFile, RVA);
  if (origOffset === -1)
    return "LUAFL: Filename missing";
  
  //Step 1b - Find its reference
  var offset = exe.findCode("68" + origOffset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "LUAFL: Filename Reference missing";
  
  //Step 1c - Find the ECX assignment before it - which is where we will jmp to our code
  var hookLoader = exe.find(" 8B 8E AB AB 00 00", PTYPE_HEX, true, "\xAB", offset - 10, offset);
  
  if (hookLoader === -1) {
    hookLoader = exe.find(" 8B 0D AB AB AB 00", PTYPE_HEX, true, "\xAB", offset - 10, offset);
  }
  
  if (hookLoader === -1)
    return "LUAFL: ECX assignment missing";
  
  //Step 1d - Extract the necessary items. We will use the name CLua::LoadFile for the function
  var retLoader = offset + 10;//point after PUSH filename and CALL instruction
  var loaderFunc = exe.Raw2Rva(retLoader) + exe.fetchDWord(retLoader - 4);//Lua file loader function
  
  //Step 2a - Create template code
  var template =
    exe.fetchHex(hookLoader, offset - hookLoader) //Preparation code before CALL - Contains ECX assignment and other PUSHes before filename PUSH
  + " 68" + GenVarHex(1)                          //PUSH OFFSET addr; fileName
  + " E8" + GenVarHex(2)                          //CALL CLua::LoadFile 
  ;
  
  var tSize = template.hexlength();
  
  //Step 2b - Construct string code.
  var nCode = nameList.join("\x00").toHex() + " 00"; 
  
  //Step 2c - Allocate space if free space is not provided.
  //          Size of code needed = size of String offsets + size of Loaders
  if (typeof(free) === "undefined" || free === -1) {
    var csize = (nameList.length + 1) * tSize + 6 + nCode.hexlength(); //6 is for the return JMP + a gap
    
    var free = exe.findZeros(csize);
    if (free === -1)
      return "LUAFL: Not enough free space";
    
    var argPresent = false;
  }
  else {
    var argPresent = true;
  }
  
  offset = exe.Raw2Rva(free);
  
  //Step 2d - Create a JMP at hookLoader to the allocated location
  exe.replace(hookLoader, "90 E9" + (offset - exe.Raw2Rva(hookLoader + 6)).packToHex(4), PTYPE_HEX);
  
  //Step 2e - Construct the file loader code for all the files using the template
  var lCode = "";
  loaderFunc -= (offset + tSize);//Relative offset to CLua::LoadFile
  offset += (nameList.length + 1) * tSize + 6;//Offset of first string
  
  for (var i = 0; i < nameList.length; i++) {
    lCode += ReplaceVarHex(template, [1, 2], [offset, loaderFunc]);
    offset += nameList[i].length + 1;//1 for NULL
    loaderFunc -= tSize;
  }
  
  lCode += ReplaceVarHex(template, [1, 2], [origOffset, loaderFunc]);//Load the origFile
  
  //Step 2f - Add the return Jump
  lCode += 
    " E9" + (exe.Raw2Rva(retLoader) - exe.Raw2Rva(free + lCode.hexlength() + 5)).packToHex(4)//JMP retLoader
  + " 00" //Just a Gap
  ; 

  //Step 2g - Insert/Overwrite with the loader + strings.
  if (argPresent)
    exe.replace(free, lCode + nCode, PTYPE_HEX);
  else
    exe.insert(free, csize, lCode + nCode, PTYPE_HEX);
}