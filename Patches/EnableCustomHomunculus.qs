//###################################################################
//# Purpose: Change the Hardcoded table loading of Homunculus names #
//#          to Lua based loading using 'ReqJobName' function.      #
//###################################################################

MaxHomun = 7000;
function EnableCustomHomunculus() {//Work In Progress
    
  //Step 1a - Find offset of LIF
  var offset = exe.findString("LIF", RVA);
  if (offset === -1)
    return "Failed in Step 1 - LIF not found";
  
  //Step 1b - Find its reference - This is where all the homunculus names are loaded into the table.
  var code = " C7 AB C4 5D 00 00" + offset.packToHex(4); //MOV DWORD PTR DS:[reg32_A+5DC4], OFFSET addr; ASCII "LIF" 
  
  var hookLoc = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (hookLoc === -1)
    return "Failed in Step 1 - homun code not found";
  
  //Step 1c - Get the LangType address
  var LANGTYPE = GetLangType();
  if (LANGTYPE.length === 1)
    return "Failed in Step 1 - " + LANGTYPE[0];
  
  //Step 2a - Extract reference Register, reference Offset and current Register from the instruction before hookLoc
  //          MOV curReg, DWORD PTR DS:[refReg + refOff]
  
  if (exe.fetchByte(hookLoc - 2) === 0) {//refOff != 0
    var modrm = exe.fetchByte(hookLoc - 5);
    var refOff = exe.fetchDWord(hookLoc - 4);
  }
  else {//refOff = 0
    var modrm = exe.fetchByte(hookLoc - 1);
    var refOff = 0;
  }
  var refReg = modrm & 0x7;
  var curReg = (modrm & 0x38) >> 3;
  
  //Step 2b - Find Location after the Table assignments which is the location to jump to after lua based loading
  //          Also extract all non-table related instuctions in between
  var details = FetchTillEnd(hookLoc + code.hexlength(), refReg, refOff, curReg, LANGTYPE, CheckHomunEoT);
  
  //Step 2c - Find offset of ReqJobName
  //Get the current lua caller code for Job Name i.e. ReqJobName calls
  offset = exe.findString("ReqJobName", RVA);
  if (offset === -1)
    return "Failed in Step 2 - ReqJobName not found";
  
  //Step 3a - Construct the code to replace with
  code =
    (0x50 + curReg).packToHex(1)  //PUSH curReg
  + " 60"                         //PUSHAD
  + " BF 71 17 00 00"             //MOV EDI, 1771
  + " BB" + MaxHomun.packToHex(4) //MOV EBX, MaxHomun
  ;
  var csize = code.hexlength();
  
  code += GenLuaCaller(hookLoc + csize, "RegJobName", offset, "d>s", " 57");
  
  code += 
    " 8A 08"          //MOV CL, BYTE PTR DS:[EAX]
  + " 84 C9"          //TEST CL, CL
  + " 74 07"          //JE SHORT addr
  + " 8B 4C 24 20"    //MOV ECX, DWORD PTR SS:[ESP+20]
  + " 89 04 B9"       //MOV DWORD PTR DS:[EDI*4+ECX], EAX
  + " 47"             //INC EDI; addr
  + " 39 DF"          //CMP EDI,EBX
  + " 7E"             //JLE SHORT addr2; to start of GenLuaCaller code
  ;
  
  code += (csize - (code.hexlength() + 1)).packToHex(1);
  
  code += 
    " 61"       //POPAD
  + " 83 C4 04" //ADD ESP, 4
  + details.code
  ;
  
  code += " E9" + (details.endOff - (hookLoc + code.hexlength() + 5)).packToHex(4);
  
  //Step 3b - Replace at hookLoc
  exe.replace(hookLoc, code, PTYPE_HEX);
  
  //Step 4a - Find the homun limiter code for right click menu.
  code =
    " 05 8F E8 FF FF" //SUB EAX, 1771
  + " B9 33 00 00 00" //MOV ECX, 33
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset !== -1) {
    //Step 4b - Replace the 33 with MaxHomun - 6001
    exe.replace(offset + 6, (MaxHomun - 6001).packToHex(4), PTYPE_HEX);
    return true; 
  }
  
  //Step 4c - Find the limiter for Older clients
  code =
    " 3D 70 17 00 00" //CMP EAX, 1770
  + " 7E 10"          //JLE SHORT addr
  + " 3D A5 17 00 00" //CMP EAX, 17A5
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 4";
  
  //Step 4d - Replace 17A5 with MaxHomun
  exe.replace(offset + code.hexlength() - 4, MaxHomun.packToHex(4), PTYPE_HEX);
  
  return true;
}

//###############################################################################
//# Purpose: Check whether End of Homunculus Table assignments has been reached #
//#          at the supplied offset. Used as argument to FetchTillEnd           #
//###############################################################################

function CheckHomunEoT(opcode, modrm, offset) {
  //SUB reg32_A, reg32_B
  //SAR reg32_A, 2
  if (opcode === 0x2B && exe.fetchUByte(offset + 2) === 0xC1 && exe.fetchUByte(offset + 4) === 0x02 )
    return true;
  
  //TEST reg32_A, reg32_A
  //JZ SHORT addr
  if (opcode === 0x85 && exe.fetchUByte(offset + 2) === 0x74)
    return true;
  
  return false;
}
