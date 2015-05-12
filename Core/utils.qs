function genVarHex(num) {
  //////////////////////////////////////////////
  // GOAL: Generate "CC CC CC C0+num" hexcode //
  //       to use as variable in insert codes //
  //////////////////////////////////////////////
  return (0xCCCCCCC0 + num).packToHex(4);
}

function remVarHex(code, nums, values) {
  ////////////////////////////////////////////
  // GOAL: Remove "CC CC CC C0+num" hexcode //
  //       used as variable in insert codes //
  ////////////////////////////////////////////
  if (typeof(nums) === "number") {
    nums = [nums];
    values = [values];
  }
  
  for (var i = 0; i < nums.length; i++) {
    var num = nums[i];
    var value = values[i];
    if (typeof(value) === "number")
      value = value.packToHex(4);
    code = code.replace(genVarHex(num), value);
  }
  
  return code;
}

function getLangType() {
  ////////////////////////////////////////////////////
  // GOAL: Find and Extract "g_serviceType" address //
  ////////////////////////////////////////////////////
  
  var offset = exe.findString("america", RVA);
  if (offset === -1)
    return -1;
  
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return -1;
  
  offset = exe.find("C7 05 AB AB AB AB 01 00 00 00", PTYPE_HEX, true, "\xAB", offset + 5);
  if (offset === -1)
    return -1;

  return exe.fetchHex(offset+2, 4);
}

function getInputFile(f, varname, title, prompt, fpath) {
  ///////////////////////////////////////////////////////
  // GOAL: Helper Function to receive a valid Filename //
  //       as a string from User.                      //
  ///////////////////////////////////////////////////////  
  var inp = "";
  while (inp === "") {
    inp = exe.getUserInput(varname, XTYPE_FILE, title, prompt, fpath);
    if (inp === "") return false;
    
    f.open(inp);
    if (f.eof()) {
      f.close();
      inp = "";
    }
  }
  return inp;
}

function fetchPacketKeys() {
  /////////////////////////////////////////////
  // GOAL: Extract the 3 Packet Keys used in //
  //       client for Encryption             //
  /////////////////////////////////////////////
  return _fetchPacketKeyInfo(1);
}

function fetchPacketKeyAddrs() {
  /////////////////////////////////////////////
  // GOAL: Get the addresses where the 3 Keys//
  //       are PUSHed                        //
  /////////////////////////////////////////////
  return _fetchPacketKeyInfo(2);
}

function _fetchPacketKeyInfo(retType) {
  /////////////////////////////////////////////////////
  // GOAL: Helper Function which does the actual job //
  //       for the above two                         //
  /////////////////////////////////////////////////////
  
  //Step 1 - Look for PACKET_CZ_ENTER push
  var offset = exe.findString("PACKET_CZ_ENTER", RVA);
  if (offset === -1)
    return "Failed in Step 1 - PACKET_CZ_ENTER not found";
  
  offset = exe.findCode(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - PACKET_CZ_ENTER reference missing";
  
  var returnValue = [];
 
  //Step 2a - Previous Form => Keys are pushed along with call to encryptor.
  var code =    
      " 8B 0D AB AB AB 00" //MOV ecx, DS:[ADDR1] dont care what
    + " 68 AB AB AB AB"     //PUSH key3 <- modify these
    + " 68 AB AB AB AB"     //PUSH key2 <-
    + " 68 AB AB AB AB"     //PUSH key1 <-
    + " E8"                 //CALL encryptor
    ;
    
  var coffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x100, offset);
  if (coffset !== -1) {  
    switch(retType) {
      case 1:        
        returnValue[0] = exe.fetchDWord(coffset+17);
        returnValue[1] = exe.fetchDWord(coffset+12);
        returnValue[2] = exe.fetchDWord(coffset+07);
        break;
      case 2:
        //We need two locations for retType = 2
        code = exe.fetchHex(coffset, code.hexlength());//replacing all the wildcards
        coffset = exe.findAll(code, PTYPE_HEX, false);
        
        if (coffset.length !== 2)
          return "Failed in Step 3 - Triple push not present in 2 locations";
        
        returnValue[0] = coffset[0]+17;
        returnValue[1] = coffset[0]+12;
        returnValue[2] = coffset[0]+07;
        
        returnValue[3] = coffset[1]+17;
        returnValue[4] = coffset[1]+12;
        returnValue[5] = coffset[1]+07;
        break;
    }
    return returnValue;
  }
  
  //Step 2b - New Function is used which means we will have to go inside it.
  code =
      " 8B 0D AB AB AB 00" //MOV ecx, DS:[ADDR1] dont care what
    + " 6A 01"             //PUSH 1
    + " E8"                //CALL combofunction - encryptor and other related functions combined.
    ;
    
  coffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x100, offset);
  if (coffset === -1)
    return "Failed in Step 2 - Unable to find combofunction";

  offset = coffset + 13 + exe.fetchDWord(coffset+9);
  
  //Step 2c - Now again there are 2 varieties (shared key for december clients and unshared key for jan ones =_=)
  var part1 =
      " 83 F8 01" //CMP EAX,1
    + " 75 AB"    //JNE short
    ;
    
  code =   part1
    + " C7 41 AB AB AB AB AB"  //MOV DWORD PTR DS:[ECX+4], <First Key>
    + " C7 41 AB AB AB AB AB"  //MOV DWORD PTR DS:[ECX+8],  <Second Key>
    + " C7 41 AB AB AB AB AB"  //MOV DWORD PTR DS:[ECX+0C],<Third Key> 
    ;//now ofcourse the order could change so we take preparations :D
  
  coffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x50);
  if (coffset !== -1) {
    switch(retType) {
      case 1:        
        returnValue[(exe.fetchByte(coffset+07)/4)-1] = exe.fetchDWord(coffset+08);
        returnValue[(exe.fetchByte(coffset+14)/4)-1] = exe.fetchDWord(coffset+15);
        returnValue[(exe.fetchByte(coffset+21)/4)-1] = exe.fetchDWord(coffset+22);
        break;
      case 2:
        returnValue[(exe.fetchByte(coffset+07)/4)-1] = coffset+08;
        returnValue[(exe.fetchByte(coffset+14)/4)-1] = coffset+15;
        returnValue[(exe.fetchByte(coffset+21)/4)-1] = coffset+22;
        break;
    }
    return returnValue;
  }
  
  //Step 2d - Shared key clients ugh
  code =   part1
    + " B8 AB AB AB AB"  // MOV EAX, Third Key
    + " 89 41 AB"    // MOV DWORD PTR DS:[ECX+8], EAX -- Second key
    + " 89 41 AB"    // MOV DWORD PTR DS:[ECX+0C], EAX -- Third key
    + " C7 41 AB"    // MOV DWORD PTR DS:[ECX+4], First Key/
    ;//like before they could try switching the orders with a shared key again.
      
  coffset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x50);
  if (coffset !== -1) {
    switch(retType) {
      case 1:        
        returnValue[(exe.fetchByte(coffset+12)/4)-1] = exe.fetchDWord(coffset+06);
        returnValue[(exe.fetchByte(coffset+15)/4)-1] = exe.fetchDWord(coffset+06);
        returnValue[(exe.fetchByte(coffset+18)/4)-1] = exe.fetchDWord(coffset+19);
        break;
      case 2:
        returnValue[(exe.fetchByte(coffset+12)/4)-1] = coffset+06;
        returnValue[(exe.fetchByte(coffset+15)/4)-1] = coffset+06;
        returnValue[(exe.fetchByte(coffset+18)/4)-1] = coffset+19;
        break;
    }
    return returnValue;
  }
  
  //Step 2e - All known options exhausted
  return "Failed in Step 2 - packet key assignment has been changed";
}

function convertToBE(le) {
  /////////////////////////////////////////////////////////////
  // GOAL: Helper Function which converts input in PTYPE_HEX //
  //       format to Big Endian format (no space in between) //
  //       If the input is a number it outputs corresponding //
  //       hex number in Big Endian format                   //
  /////////////////////////////////////////////////////////////
  
  if (typeof(le) === "number")
    le = le.packToHex(4);
  
  var be = "";
  for (var i = le.length-3; i >= 0; i-=3) {
    be += le.substr(i,3);
  }
  return be.replace(/ /g,"");  
}

function getFuncAddr(funcName, dllName, ordinal) {
  ///////////////////////////////////////////////////////////////
  // GOAL: Find the virtual address of the Function specified. //
  //       Additionally you can also pinpoint it to a DLL and  //
  //       an alternative ordinal number to use                //
  ///////////////////////////////////////////////////////////////
  
  //Step 1a - Prep the optional arguments 
  if (typeof(dllName) === "undefined")
    dllName = "";
  else
    dllName = dllName.toUpperCase();
  
  if (typeof(ordinal) === "undefined")
    ordinal = -1;
  
  //Step 1b - Prep the constants and return variable
  var funcAddr = -1; //The address will be stored here.
  var offset = GetDataDirectory(1).offset;//Import Table
  var imgBase = exe.getImageBase();//The Image Base
  
  //Step 1c - Iterate through each IMAGE_IMPORT_DESCRIPTOR
  for ( ;true; offset += 20) {
    var nameOff = exe.fetchDWord(offset+12);//Dll Name Offset (VA - ImageBase)
    var iatOff  = exe.fetchDWord(offset+16); //Thunk Offset - Start of the Imported Functions
    
    if (nameOff <= 0) break;//Ending entry wont have dll name so its offset will be 0
    if (iatOff  <= 0) continue;//Import Address Table <- points to the First Thunk
    
    //Step 1d - If DLL name is provided, only check if it matches with current DLL Name (case insensitively)
    if (dllName !== "") {
      nameOff = exe.Rva2Raw(nameOff + imgBase);
      var nameEnd = exe.find("00", PTYPE_HEX, false, "", nameOff);
      if (dllName !== exe.fetch(nameOff, nameEnd - nameOff).toUpperCase()) continue;
    }
    
    //Step 1e - Get Raw Offset of FIrst Thunk
    var offset2 = exe.Rva2Raw(iatOff + imgBase);
    
    //Step 2a - Iterate through each IMAGE_THUNK_DATA
    for ( ;true; offset2 += 4) {
      var funcData = exe.fetchDWord(offset2);//Ordinal Number or Offset of Function Name and Hint
      
      //Step 2b - Ends with a NULL DWORD
      if (funcData === 0) break;
      
      //Step 2c - Sign Bit also serves as an indicator of whether this functions is imported by Name (0) or Ordinal (1)
      if (funcData > 0) {
       
       //Step 2d - The Thunk will point to a location with first 2 bytes as Hint followed by Function Name.
        //          So extract it after 2nd byte
        nameOff = exe.Rva2Raw((funcData & 0x7FFFFFFF) + imgBase) + 2;
        nameEnd = exe.find("00", PTYPE_HEX, false, "", nameOff);

        //Step 2e - Check if the Function name matches. If it does, save the address in IAT and break
        if (funcName === exe.fetch(nameOff, nameEnd - nameOff)) {
          funcAddr = exe.Raw2Rva(offset2);
          break;
        }
      }
      else if ((funcData & 0xFFFF) === ordinal) {//If ordinal import then just compare directly.
        funcAddr = exe.Raw2Rva(offset2);
        break;
      }
    }
   
    //Step 2f - If we already got the address break out of the loop   
    if (funcAddr !== -1) break;
  }
  
  return funcAddr;
}

function GetDataDirectory(index) {
  ///////////////////////////////////////////////////////////////////
  // GOAL: Gets the Offset and Size of the required Data Directory //
  ///////////////////////////////////////////////////////////////////
  var offset = exe.getPEOffset() + 0x18 + 0x60;//Skipping header bytes unnecessary here.
  if (offset === 0x67) //i.e. PE Offset === -1
    return -2;
  
  var size = exe.fetchDWord(offset + 0x8*index + 0x4);
  offset = exe.Rva2Raw(exe.fetchDWord(offset + 0x8*index) + exe.getImageBase());
  
  return {"offset":offset, "size":size};
}

//Functions for extracting Resource Tree - currently used only in Custom Icon Function
function GetResourceEntry(rTree, hierList) {
  
  for (var i = 0; i < hierList.length; i++) {
    if (typeof(rTree.numEntries) === "undefined") 
      break;
    for (var j = 0; j < rTree.numEntries; j++) {
      if (rTree.entries[j].id === hierList[i]) break;
    }
    if (j === rTree.numEntries) {
      rTree = -(i+1);
      break;
    }
    rTree = rTree.entries[j];
  }
  return rTree;
}

function ResourceDir(rsrcAddr, addrOffset, id) {
  this.id = id;
  this.addr = rsrcAddr + addrOffset;
  this.numEntries = exe.fetchWord(this.addr + 12) + exe.fetchWord(this.addr + 14)
  this.entries = [];
  
  for (var i = 0; i < this.numEntries; i++) {
    id = exe.fetchDWord(this.addr + 16 + i*8);
    addrOffset = exe.fetchDWord(this.addr + 16 + i*8 + 4);
    
    if (addrOffset < 0)
      this.entries.push( new ResourceDir(rsrcAddr, addrOffset & 0x7FFFFFFF, id));
    else
      this.entries.push( new ResourceFile(rsrcAddr, addrOffset, id));
  }
}

function ResourceFile(rsrcAddr, addrOffset, id) {
  this.id = id;
  this.addr = rsrcAddr + addrOffset;
  this.dataAddr = exe.Rva2Raw(exe.fetchDWord(this.addr) + exe.getImageBase());
  this.dataSize = exe.fetchDWord(this.addr + 4);
}