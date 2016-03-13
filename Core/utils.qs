//###########################################################################
//# Purpose: Generate Hex Filler for use in Insert Codes. Pattern generated #
//#          will be a sequence of CC followed by (C0 + num)                #
//###########################################################################

function GenVarHex(num) {
  return (0xCCCCCCC0 + num).packToHex(4);
}

//##################################################################################
//# Purpose: Substitute the Patterns generated from GenVarHex function with values #
//#          provided. Number to PTYPE_HEX conversion is done automatically        #
//##################################################################################  
  
function ReplaceVarHex(code, nums, values) {
  
  //Account for single values instead of arrays
  if (typeof(nums) === "number") {
    nums = [nums];
    values = [values];
  }
  
  for (var i = 0; i < nums.length; i++) {
    var value = values[i];
    
    //If Value is a Number convert it
    if (typeof(value) === "number")
      value = value.packToHex(4);
    
    code = code.replace(GenVarHex(nums[i]), value);
  }
  
  return code;
}

//###########################################################
//# Purpose: Check whether client is Renewal or Main client # 
//###########################################################

function IsRenewal() {
    return(exe.findString("rdata.grf", RAW) !== -1);
}

//###########################################################
//# Purpose: Extract the g_serviceType address from Client. # 
//#          Returned value will be in PTYPE_HEX format     #
//###########################################################

function GetLangType() {
  
  //Step 1a - Get address of the string 'america'
  var offset = exe.findString("america", RVA);
  if (offset === -1)
    return ["'america' not found"];
  
  //Step 1b - Find its reference
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return ["'america' reference missing"];

  //Step 2a - Look for the g_serviceType assignment to 1 after it.   
  offset = exe.find(" C7 05 AB AB AB AB 01 00 00 00", PTYPE_HEX, true, "\xAB", offset + 5);
  if (offset === -1)
    return ["g_serviceType assignment missing"];

  //Step 2b - Extract and return
  return exe.fetchHex(offset + 2, 4);
  
}

//#####################################################################
//# Purpose: Extract g_windowMgr assignment & UIWindowMgr::MakeWindow #
//#          address. Returned value is a hash array or error string  #
//#####################################################################

function GetWinMgrInfo() {
  
  //Step 1a - Find offset of NUMACCOUNT
  var offset = exe.findString("NUMACCOUNT", RVA);
  if (offset === -1)
    return "NUMACCOUNT missing";
  
  //Step 1b - Find its reference which comes after a Window Manager call
  var code =
    " 6A 00"                    //PUSH 0
  + " 6A 00"                    //PUSH 0
  + " 68" + offset.packToHex(4) //PUSH addr; ASCII "NUMACCOUNT"
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "NUMACCOUNT reference missing";
  
  return {
    "gWinMgr": exe.fetchHex(offset-10, 5),
    "makeWin": exe.fetchDWord(offset - 4) + exe.Raw2Rva(offset)
  };
}

//###############################################################
//# Purpose: Return true if Frame Pointer is used in Functions. #
//#          i.e. Stack is referenced w.r.t. EBP instead of ESP #
//###############################################################

function HasFramePointer() {
  
  //Fastest way to check - First 3 bytes of CODE Section would be PUSH EBP and MOV EBP, ESP
  return (exe.fetch(exe.getROffset(CODE), 3) === "\x55\x8B\xEC");
}

//#################################################################################################
//# Purpose: Wrapper over exe.getUserInput function with XTYPE_FILE to loop till an existing file #
//#          is specified or the Input box is closed/cancelled                                    #
//#################################################################################################

function GetInputFile(f, varname, title, prompt, fpath) {
  
  var inp = "";
  while (inp === "") {
    //Step 1 - Get the filename
    inp = exe.getUserInput(varname, XTYPE_FILE, title, prompt, fpath);
    if (inp === "") 
      return false;
    
    //Step 2 - Check if file is there.
    f.open(inp);
    if (f.eof()) {
      f.close();
      inp = "";
    }
  }
  return inp;
}

//#################################################################################
//# Purpose: Extract the 3 Packet Keys used for Header Obfuscation/Encryption and #
//#          address of the function that assigns them into ECX+4, ECX+8, ECX+0C  #
//#          In case the keys are unobtainable then we use clientdate - keys map. #
//#################################################################################

function FetchPacketKeyInfo() {
  var retVal = 
  {
    "type": -1,        //Type of Function (0 = Packet Keys are PUSHED as arguments, 1 = Mode is PUSHed as argument, 2 = same as Type 1 but Function is virtualized)
    "funcRva": -1,     //Virtual Address of the Function which assigns the packetKeys to ECX+4, ECX+8, ECX+12 (encrypted key in new clients)
    "keys": [0, 0, 0], //Extracted / Mapped Keys
    "refMov" : "",     //The MOV ECX code before the Function is called
    "ovrAddr": -1,     //Physical Address to overwrite with a JMP when patching packetKeys - not needed for Type 0
  };
  
  //Step 1a - Find address of string 'PACKET_CZ_ENTER' . 
  //          If its not present then its probably new client and chances are packet keys will need a map
  var offset = exe.findString("PACKET_CZ_ENTER", RVA);
  
  //Step 1b - Find its reference
  if (offset !== -1)
    offset = exe.findCode(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  
  //Step 1c - In case its not there look for the Reference Pattern present usually after PACKET_CZ_ENTER
  if (offset === -1) {
    
    var code =          //template call format
      " E8 AB AB AB AB" //CALL CRagConnection::instanceR
    + " 8B C8"          //MOV ECX, EAX
    + " E8 AB AB AB AB" //CALL func
    ;
    
    code = 
      code     //CALL CRagConnection::instanceR
               //MOV ECX, EAX
               //CALL CRagConnection::GetPacketSize
    + " 50"    //PUSH EAX
    + code     //CALL CRagConnection::instanceR
               //MOV ECX, EAX
               //CALL CRagConnection::SendPacket
    + " 6A 01" //PUSH 1
    + code     //CALL CRagConnection::instanceR
               //MOV ECX, EAX
               //CALL CConnection::SetBlock
    + " 6A 06" //PUSH 6
    ;
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "PKI: Failed to find any reference locations";
  
  //Step 2a - Find Pattern 1 - Keys pushed to the Key assigner function (Type 0)
  var code =
    " 8B 0D AB AB AB 00" //MOV ECX, DWORD PTR DS:[refAddr]
  + " 68 AB AB AB AB"    //PUSH key3
  + " 68 AB AB AB AB"    //PUSH key2
  + " 68 AB AB AB AB"    //PUSH key1
  + " E8"                //CALL CRagConnection::Obfuscate ; We will call it this for the time being
  ;
  
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x100, offset);
  if (offset2 !== -1) {
    //Step 2b - In case it succeeded Get the ECX assignment, RVA of the Obfuscate function & the packetKeys.
    retVal.type = 0;
    retVal.refMov = exe.fetchHex(offset2, 6);
    
    offset2 += code.hexlength();
    retVal.funcAddr = exe.Raw2Rva(offset2 + 4) + exe.fetchDWord(offset2);
    retVal.keys = [exe.fetchDWord(offset2 - 5), exe.fetchDWord(offset2 - 10), exe.fetchDWord(offset2 - 15)];
    
    //Step 2c - Return the hash array
    return retVal;
  }
  
  //Step 3a - Find Pattern 2 - Encryption + Key assignment fused into one function with mode argument. 
  //          0 = Encrypt & Assign Keys, 1 = Assign Base Keys, 2 = Assign 0s = No Encryption
  code =
    " 8B 0D AB AB AB 00" //MOV ECX, DWORD PTR DS:[refAddr]
  + " 6A 01"             //PUSH 1
  + " E8"                //CALL CRagConnection::Obfuscate2
  ;
  
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x100, offset);
  if (offset2 == -1)
    return "PKI: Failed to find Encryption call";
  
  //Step 3b - Get the ECX assignment & Function RVA
  retVal.refMov = exe.fetchHex(offset2, 6);
  
  offset2 += code.hexlength();
  offset = offset2 + 4 + exe.fetchDWord(offset2);
  
  retVal.funcAddr = exe.Raw2Rva(offset);

  //Step 3c - Go Inside and look for Base Key assignment (No Shared Key format)
  var prefix =
    " 83 F8 01" //CMP EAX,1
  + " 75 AB"    //JNE short
  ;
  code = 
    prefix
  + " C7 41 AB AB AB AB AB"  //MOV DWORD PTR DS:[ECX+x], <Key 1> ; Keys may not be assigned in order - depends on x, y and z values
  + " C7 41 AB AB AB AB AB"  //MOV DWORD PTR DS:[ECX+y], <Key 2>
  + " C7 41 AB AB AB AB AB"  //MOV DWORD PTR DS:[ECX+z], <Key 3>
  ;
  
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x50);
  
  if (offset2 !== -1) {
    //Step 3c - Since it matched we can finally extract the keys.
    retVal.type = 1;
    offset2 += prefix.hexlength();    
    
    retVal.keys[exe.fetchByte(offset2 + 2)/4]  = exe.fetchDWord(offset2 + 3);
    retVal.keys[exe.fetchByte(offset2 + 9)/4]  = exe.fetchDWord(offset2 + 10);
    retVal.keys[exe.fetchByte(offset2 + 16)/4] = exe.fetchDWord(offset2 + 17);
    retVal.keys.shift();//Shift all elements left
    
    retVal.ovrAddr = offset2;//Offset where the assignment occurs
    
    //Step 3d - Return the hash array
    return retVal;
  }
  
  //Step 4a - Look for Shared Key format
  code =
    prefix
  + " B8 AB AB AB AB" // MOV EAX, Shared Key
  + " 89 41 AB"       // MOV DWORD PTR DS:[ECX+x], EAX
  + " 89 41 AB"       // MOV DWORD PTR DS:[ECX+y], EAX
  + " C7 41"          // MOV DWORD PTR DS:[ECX+z], Unique Key 
  ;
  
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x50);
    
  if (offset2 != -1) {
    //Step 4b - Extract all the keys. For Shared Set, extract from the MOV EAX statement
    retVal.type = 1;
    offset2 += prefix.hexlength();
    
    retVal.keys[exe.fetchByte(offset2 + 7)/4]   = exe.fetchDWord(offset2 + 1);
    retVal.keys[exe.fetchByte(offset2 + 10)/4]  = exe.fetchDWord(offset2 + 1);
    retVal.keys[exe.fetchByte(offset2 + 13)/4]  = exe.fetchDWord(offset2 + 14);
    retVal.keys.shift();//Shift all elements left
    
    retVal.ovrAddr = offset2;//Offset where the assignment occurs
    
    //Step 4c - Return the hash array
    return retVal;
  }
  
  //Step 5a - Open PacketKeyMap.txt from inputs folder
  var f = new TextFile();
  if (!f.open(APP_PATH + "/Input/PacketKeyMap.txt") )
    return "PKI: Unable to open map file";
  
  var cdate = exe.getClientDate();
  while (!f.eof()) {
    //Step 5b - Iterate through file and look for any entry for the clients date. Extract the keys after the clientdate
    var str = f.readline().trim();
    if (str.length < 16) continue;
    if (str.search(cdate) === 0) {
      var keys = str.split('=')[1].trim().split(",");
      if (keys.length === 3)
        break;
      
      delete keys;
    }
  }
  
  if (typeof(keys) !== "undefined") {
    //Step 5c - Assign the values to hash array
    retVal.type = 2;
    retVal.keys = [parseInt(keys[0], 16), parseInt(keys[1], 16), parseInt(keys[2], 16)];
    retVal.ovrAddr = exe.Rva2Raw(retVal.funcAddr);
    
    if (HasFramePointer())//Account for PUSH EBP and MOV EBP, ESP
      retVal.ovrAddr += 3;
     
    //Step 5c - Return the hash array
    return retVal;
  }
  
  //Step 6 - All known options exhausted - return the default hash array (with all keys as 0 & type = -1)
  return retVal;
}

//######################################################################################
//# Purpose: Find the RVA of the Function specified. Optionally dllName can be used    #
//#          to pinpoint to a DLL and ordinal can be used in case of import by ordinal #
//######################################################################################

function GetFunction(funcName, dllName, ordinal) {
  
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

//###############################################################################
//# Purpose: Get the offset and size of the Data Directory specified with index #
//###############################################################################
 
function GetDataDirectory(index) {
  var offset = exe.getPEOffset() + 0x18 + 0x60;//Skipping header bytes unnecessary here.
  if (offset === 0x67) //i.e. PE Offset === -1 which is unlikely but still
    return -2;
  
  var size = exe.fetchDWord(offset + 0x8*index + 0x4);
  offset = exe.Rva2Raw(exe.fetchDWord(offset + 0x8*index) + exe.getImageBase());
  
  return {"offset":offset, "size":size};
}

//######################################################################
//# Purpose: Extracts the Resource Entry from rTree object - Currently #
//#          used in Custom Icon Function only.                        #
//######################################################################

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

//#######################################################################
//# Purpose: Extracts and returns a ResourceDir object containing other #
//#          ResourceDir and ResourceFile objects forming a tree        #
//#######################################################################

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

//#######################################################################
//# Purpose: Extracts and returns a ResourceFile object containing info #
//#          of that particular resource node                           #
//#######################################################################

function ResourceFile(rsrcAddr, addrOffset, id) {
  this.id = id;
  this.addr = rsrcAddr + addrOffset;
  this.dataAddr = exe.Rva2Raw(exe.fetchDWord(this.addr) + exe.getImageBase());
  this.dataSize = exe.fetchDWord(this.addr + 4);
}

//####################################################################################
//# Purpose: Find the endpoint of table initializations and extract all instructions #
//#          that are not part of the initializations but still mixed inside -       #
//#          Currently used for Custom Jobs and Custom Homunculus Patches            #
//####################################################################################

function FetchTillEnd(offset, refReg, refOff, tgtReg, langType, endFunc, assigner) {

  var done = false;
  var extract = "";
  var regAssigns = ["", "", "", "", "", "", "", ""];
  
  //var codes = "";//for debug
  
  if (typeof(langType) === "string") {
    langType = langType.unpackToInt();
  }
  
  if (typeof(assigner) === "undefined") {
    assigner = -1;
  }
  
  while (!done) {//only exits at the end of initializations
  
    //Step 1a - Get Opcode and possible Mod R/M byte
    var opcode = exe.fetchUByte(offset);
    var modrm  = exe.fetchUByte(offset + 1);
    
    //Step 1b - Get the instruction details
    var details = GetOpDetails(opcode, modrm, offset);//contains length of instruction, distance to next offset, optional destination operand, optional source operand. Usually index 0 and 1 are same
    
    //Step 1c - Now see if any of the end patterns match this opcode.
    done = endFunc(opcode, modrm, offset, details, assigner);
    if (done) 
      continue;
    
    //Step 1d - If not Parse opcode to see if the instruction is part of table assignments, langType checks or Jumps 
    var skip = false;
    
    switch (opcode) {
      case 0x8B: {
        if (tgtReg !== -1)
          break;
        
        skip = true;
     
        if (refOff !== 0 && details.tgtImm === refOff) //MOV reg32_A, DWORD PTR DS:[reg32_B + refOff]; reg32_B is set by refReg
          tgtReg = details.ro;
        else if (details.mode === 0 && details.rm === refReg) //MOV reg32_A, DWORD PTR DS:[reg32_B]
          tgtReg = details.ro;
        else
          skip = false;
        
        break;
      }
      
      case 0xC7:  //MOV DWORD PTR DS:[reg32_A + const], OFFSET addr
      case 0x89: {//MOV DWORD PTR DS:[reg32_A + const], reg32_C
        if (tgtReg !== -1 && details.rm === tgtReg && (details.mode !== 3)) {
          tgtReg = -1;
          skip = true;
        }
        
        if (skip && regAssigns[details.ro] !== "" && opcode === 0x89) {//Remove unnecessary assignments to registers
          extract = extract.replace(regAssigns[details.ro], "");
          regAssigns[details.ro] = "";
        }
          
        break;
      }
      
      case 0xB8:
      case 0xB9:
      case 0xBA:
      case 0xBB:
      case 0xBC:
      case 0xBD:
      case 0xBE:
      case 0xBF: {//MOV reg32, OFFSET addr; No need to skip but do save for comparison later
        regAssigns[opcode - 0xB8] = exe.fetchHex(offset, details.codesize);
        break;
      }
      
      case 0x0F: {//Conditional JMP
        skip = (modrm >= 0x80 && modrm <= 0x8F);
        if (skip)
          details.nextOff += details.tgtImm;

        break;
      }
      
      case 0xE9:
      case 0xEB:
      case 0x70:
      case 0x71:
      case 0x72:
      case 0x73:
      case 0x74:
      case 0x75:
      case 0x76:
      case 0x77:
      case 0x78:
      case 0x79:
      case 0x7A:
      case 0x7B:
      case 0x7C:
      case 0x7D:
      case 0x7E:
      case 0x7F: {//JMP & all SHORT jumps
        skip = true;
        details.nextOff += details.tgtImm;
        break;
      }
      
      case 0x83: {//CMP DWORD PTR DS:[g_serviceType], value
        skip = (modrm === 0x3D && details.tgtImm === langType);
        break;
      }
      
      case 0x39: {//CMP DWORD PTR DS:[g_serviceType], reg32
        skip = (details.mode === 0 && details.rm === 5 && details.tgtImm === langType);
        break;
      }
      
      case 0x6A:  //PUSH byte
      case 0x68: {//PUSH dword
        if (assigner === -1)
          break;
        
        //skip if its an argument to a CALL assigner
        //PUSH arg
        //MOV ECX, ESI
        //MOV DWORD PTR DS:[EAX], OFFSET; for previous (optional)
        //CALL assigner
        var offset2 = details.nextOff + 7;
        
        if (exe.fetchUByte(details.nextOff + 2) === 0xC7)
          offset2 += 6;
        
        skip = (exe.fetchUByte(offset2 - 5) === 0xE8 && exe.fetchDWord(offset2 - 4) === (assigner - offset2));
        if (skip) {
          details.nextOff = offset2;
          tgtReg = 0;//EAX
        }
        break;
      }
      
      case 0xE8: {//CALL 
        if (assigner === -1)
          break;
        
        if (details.tgtImm === (assigner - details.nextOff)) {//CALL assigner
          skip = true;
          extract += " 83 C4 04";//ADD ESP, 4; Restoring stack
          tgtReg = 0;//EAX
        }
      }
    }
    
    //Step 1e - Extract the code if skip is not enabled
    if (!skip)
      extract += exe.fetchHex(offset, details.codesize);
    
    //codes += exe.Raw2Rva(offset).toBE() + " :" + exe.fetchHex(offset, details.codesize) + "\n";//debug
    
    //Step 1f - Update offset
    offset = details.nextOff;
  }
  //return {"endOff":offset, "code":extract, "debug":codes};
  return {"endOff":offset, "code":extract};
}

//####################################################################################
//# Purpose: Support Function for 'FetchTillEnd' to get the Opcode details at offset #
//#          Also used in Increase Attack Display patch                              #
//####################################################################################

function GetOpDetails(opcode, modrm, offset) {
  
  var details = {};
  var opcode2 = -1;//will hold 2nd Opcode byte in case opcode is 0x0F
  
  //Step 1a - Look through OpcodeSizeMap to see if opcode match any of the opcodes
  for (var i = 0; i < OpcodeSizeMap.length; i += 2) {
    if (OpcodeSizeMap[i].indexOf(opcode) !== -1) {
      details.codesize = OpcodeSizeMap[i+1];
      break;
    }
  }
  
  //Step 1b - Update modrm for 2 byte opcode
  if (opcode === 0x0F) {
    opcode2 = modrm;
    modrm = exe.fetchUByte(offset + 2);
  }
  
  //Step 1c - If none matched in OpcodeSizeMap, then modrm is valid and we need to parse it
  // First 2 bits = Mode
  // Next 3 bits  = Target Reg / Operation Selector for special opcodes
  // Last 3 bits  = Source Reg / Memory Reference
  if (typeof(details.codesize) === "undefined") {
    
    //Step 2a - Split the required parts
    details.mode = (modrm & 0xC0) >> 6;
    details.ro   = (modrm & 0x38) >> 3;
	  details.rm   = (modrm & 0x07);
    
    //Step 2b - Start with 2 (Opcode + ModRM)
    details.codesize = 2;
    
    //Step 2c - Check for Scale Index Base addressing (SIB byte) => R/M = 4 and Mode != 3
    if (details.rm === 0x4 && details.mode !== 0x3) {
      details.codesize++;
    }
    
    //Step 2d - Check for Immediate 1 byte => Mode = 1
    if (details.mode === 0x1) {
      details.tgtImm = exe.fetchByte(offset + details.codesize);
      details.codesize++;
    }
    
    //Step 2e - Check for Immediate 4 byte => Mode = 0 and R/M = 5 or Mode = 2
    if (details.mode === 0x2 || (details.mode === 0x0 && (details.rm === 0x5 || details.rm === 0x4))) {
      details.tgtImm = exe.fetchDWord(offset + details.codesize);
      details.codesize += 4;
    }
    
    //Step 2f - Check for 2byte opcode
    if (opcode2 !== -1) {
      details.codesize++;
    }
  }
  
  //================================//
  // Now Some Opcode specific items //
  //================================//
  
  switch (opcode) {
    case 0xEB:
    case 0x70:
    case 0x71:
    case 0x72:
    case 0x73:
    case 0x74:
    case 0x75:
    case 0x76:
    case 0x77:
    case 0x78:
    case 0x79:
    case 0x7A:
    case 0x7B:
    case 0x7C:
    case 0x7D:
    case 0x7E:
    case 0x7F: {//All SHORT jumps
      details.tgtImm   = exe.fetchByte(offset + 1);
      //details.nextOff += details.tgtImm;
      //details.codesize++;
      break;
    }
    
    case 0xE8:
    case 0xE9: {//Long Jump
      details.tgtImm    = exe.fetchDWord(offset + 1);
      //details.nextOff  += details.tgtImm;
      //details.codesize += 4;
      break;
    }
    
    case 0x0F: {//Two Byte Opcode
      if (opcode2 >= 0x80 && opcode2 <= 0x8F) {
        details.tgtImm   = exe.fetchDWord(offset + 2);
        //details.nextOff  = 6 + details.tgtImm;
        details.codesize = 6;
      }
      break;
    }
    
    case 0x69:
    case 0x81:
    case 0xC7: {//Imm32 Source
      details.srcImm   = exe.fetchDWord(offset + details.codesize);
      details.codesize += 4;
      break;
    }
    
    case 0x6B:
    case 0xC0:
    case 0xC1:
    case 0xC6:
    case 0x80:
    case 0x82:
    case 0x83: {//Imm8 Source
      details.srcImm   = exe.fetchByte(offset + details.codesize);
      details.codesize++;
      break;
    }
  }
  
  details.nextOff = offset + details.codesize;
  
  return details;
}