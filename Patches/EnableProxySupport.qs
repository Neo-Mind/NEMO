//###############################################################################
//# Purpose: Divert connect() call in CConnection::Connect() function to save   #
//#          the first IP used and use it for any following connection attempts #
//###############################################################################

function EnableProxySupport() {

  //Step 1a - Find the String's address.
  var offset = exe.findString("Failed to setup select mode", RVA);
  if (offset === -1)
    return "Failed in Step 1 - setup string not found";

  //Step 1b - Find the string's referenced location (which is only inside CConnection::Connect)
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - setup string reference missing";
  
  //Step 2a - Find connect call (Indirect call pattern should be within 0x50 bytes before offset)  - VC9 onwards
  var code = 
    " FF 15 AB AB AB AB" //CALL DWORD PTR DS:[<&WS2_32.connect>]
  + " 83 F8 FF"          //CMP EAX,-1
  + " 75 AB"             //JNZ SHORT addr
  + " 8B AB AB AB AB AB" //MOV EDI,DWORD PTR DS:[<&WS2_32.WSAGetLastError>]
  + " FF AB"             //CALL EDI
  + " 3D 33 27 00 00"    //CMP EAX, 2733h
  ;
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x50, offset);
  
  if (offset2 === -1) {
    //Step 2b - Find connect call (Direct call pattern should be within 0x90 bytes before offset) - Older clients
    code =
      " E8 AB AB AB AB" //CALL <&WS2_32.connect>
    + " 83 F8 FF"       //CMP EAX,-1
    + " 75 AB"          //JNZ SHORT addr
    + " E8 AB AB AB AB" //CALL <&WS2_32.WSAGetLastError>
    + " 3D 33 27 00 00" //CMP EAX, 2733h
    ;
    
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x90, offset);    
    if (offset2 === -1)
      return "Failed in Step 2";//Both patterns failed
    
    var bIndirectCALL = false;
  }
  else {
    var bIndirectCALL = true;
    exe.replace(offset2, " 90 E8", PTYPE_HEX);//Replace with direct call opcode (address will be changed afterwards)
    offset2++;
  }
  
  //Step 2c - Get the address pointing to ws2_32.connect
  var connAddr = exe.fetchDWord(offset2 + 1); 
  if (!bIndirectCALL)
    connAddr += exe.Raw2Rva(offset2 + 5);
  
  //Step 3a - Create the IP Saving code (g_saveIP will be filled later. for now we use filler)
  code =
    " A1" + GenVarHex(1) //MOV EAX, DWORD PTR DS:[g_saveIP]
  + " 85 C0"             //TEST EAX, EAX
  + " 75 08"             //JNZ SHORT addr
  + " 8B 46 0C"          //MOV EAX, DWORD PTR DS:[ESI+C]
  + " A3" + GenVarHex(2) //MOV DWORD PTR DS:[g_saveIP], EAX
  + " 89 46 0C"          //MOV DWORD PTR DS:[ESI+C], EAX <- addr
  ;

  if (bIndirectCALL)
    code += " FF 25" + connAddr.packToHex(4); //JMP DWORD PTR DS:[<&WS2_32.connect>]
  else
    code += " E9" + GenVarHex(3); //JMP <&WS2_32.connect>; will be filled later
  
  var csize = code.hexlength();
  
  //Step 3b - Allocate space for Adding the code.
  offset = exe.findZeros(0x4 + csize); //First 4 bytes are for g_saveIP
  if (offset === -1)
    return "Failed in Step 3 - Not enough free space";
  
  var offsetRva = exe.Raw2Rva(offset);
  
  //Step 3c - Set g_saveIP
  code = ReplaceVarHex(code, [1, 2], [offsetRva, offsetRva]);
  
  //Step 3d - Set connect address for Direct call - need relative offset
  if (!bIndirectCALL)
    code = ReplaceVarHex(code, 3, connAddr - (offsetRva + csize)); //Get Offset relative to JMP 
  
  //Step 4a - Redirect connect call to our code.
  exe.replaceDWord(offset2 + 1, offsetRva + 4 - exe.Raw2Rva(offset2 + 5));
  
  //Step 4b - Add our code to the client
  exe.insert(offset, 4 + csize, " 00 00 00 00" + code, PTYPE_HEX); //4 NULLs for g_saveIP filler
  
  return true;
}