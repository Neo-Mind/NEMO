function EnableProxySupport() {
  ////////////////////////////////////////////////////////////
  // GOAL: Divert connect() call in CConnection::Connect()  //
  //       function to save the first IP that gets used and //
  //       use it for any following connection attempts.    //
  ////////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // Note
  // ------
  // Clients after certain date have the ws2_32::connect() function
  // linked by ordinal rather than by name, So we cannot directly 
  // get its address. 
  // Instead we will look for a certain string reference inside 
  // CConnection::Connect() function.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
  //Step 1 - Find the String's virtual address.
  var offset = exe.findString("Failed to setup select mode", RVA);
  if (offset === -1)
    return "Failed in Part 1";

  //Step 2 - Find the string's referenced location (which is only inside CConnection::Connect)
  strOffset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (strOffset === -1)
    return "Failed in Part 2";
  
  //Step 3a - Find connect call (Indirect call pattern should be within 0x50 bytes before strOffset)  - VC9 onwards
  var code = 
      " FF 15 AB AB AB AB" // CALL NEAR DWORD PTR DS:[<&WS2_32.connect>]
    + " 83 F8 FF"          // CMP  EAX,-1
    + " 75 AB"             // JNZ  SHORT OFFSET v
    + " 8B 3D AB AB AB AB" // MOV  EDI,DWORD PTR DS:[<&WS2_32.WSAGetLastError>]
    + " FF D7"             // CALL NEAR EDI
    + " 3D 33 27 00 00"    // CMP  EAX, 2733h
    ;
        
  var connOffset = exe.find(code, PTYPE_HEX, true, "\xAB", strOffset-0x50, strOffset);
  
  if (connOffset === -1) {  
    //Step 3b - Find connect call (Direct call pattern should be within 0x90 bytes before strOffset) - VC6 for older clients
    code =
      " E8 AB AB AB AB"    // CALL <&WS2_32.connect>
    + " 83 F8 FF"          // CMP  EAX,-1
    + " 75 AB"             // JNZ  SHORT OFFSET v
    + " E8 AB AB AB AB"     // CALL <&WS2_32.WSAGetLastError>
    + " 3D 33 27 00 00"    // CMP  EAX, 2733h
    ;
    
    connOffset = exe.find(code, PTYPE_HEX, true, "\xAB", strOffset-0x90, strOffset);    
    if (connOffset === -1)
      return "Failed in Part 3";//Both patterns failed    
    
    var bIndirectCALL = false;
  }
  else {
    var bIndirectCALL = true;
    exe.replace(connOffset, " 90 E8", PTYPE_HEX);//Replace with direct call opcode (address will be changed afterwards)
    connOffset++;
  }
  
  //Step 3c - Get ws2_32::connect address.
  var connAddr = exe.fetchDWord(connOffset+1);
  
  //Step 4a - Create the IP Saving code (g_SaveIP will be filled later. for now we use filler)
  var jmpCode =  
      " A1" + genVarHex(1)  // MOV  EAX,DWORD PTR DS:[<g_SaveIP>]
    + " 85 C0"           // TEST EAX,EAX
    + " 75 08"           // JNZ  SHORT to 'MOV [ESI+C], EAX'
    + " 8B 46 0C"        // MOV  EAX,DWORD PTR DS:[ESI+C]
    + " A3" + genVarHex(2)  // MOV  DWORD PTR DS:[<g_SaveIP>],EAX
    + " 89 46 0C"        // MOV  DWORD PTR DS:[ESI+C],EAX
    ;

  if (bIndirectCALL)
    jmpCode += " FF 25" + connAddr.packToHex(4) // JMP DWORD PTR DS:[<&WS2_32.connect>]
  else
    jmpCode += " E9" + genVarHex(3)  // JMP <&WS2_32.connect> - will be filled later
  
  //Step 4b - Allocate space for Adding the code.
  var jcSize = jmpCode.hexlength();
  
  offset = exe.findZeros(0x4+jcSize);//First 4 bytes are for g_SaveIP
  if (offset === -1)
    return "Failed in Part 4";
  
  //Step 4c - Set g_SaveIP
  jmpCode = remVarHex(jmpCode, 1, offset);
  jmpCode = remVarHex(jmpCode, 2, offset);
  
  //Step 4d - Set connect address for Direct call - need relative offset
  if (!bIndirectCALL) {
    connAddr += exe.Raw2Rva(offset+5) - exe.Raw2Rva(offset+jcSize);//Get Offset relative to JMP 
    jmpCode = remVarHex(jmpCode, 3, connAddr);
  }
  
  //Step 5a - Redirect connect call to our code.
  var jmpdiff = exe.Raw2Rva(offset+4) - exe.Raw2Rva(connOffset+5);
  exe.replace(connOffset, " E8" + jmpdiff.packToHex(4), PTYPE_HEX);
  
  //Step 5b - Add our code to the client
  jmpCode = " 00 00 00 00" + jmpCode;//4 NULLs for g_SaveIP filler
  exe.insert(offset, 0x4+jcSize, PTYPE_HEX);
  
  return true;
}