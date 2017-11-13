//##########################################################################################
//# Purpose: Generate Packet Length Extractor DLL for loaded client using the template DLL #
//#          (ws2_pe.dll). Along with the Packet Keys for new clients                      #
//##########################################################################################

function GenPktExtractDLL() {//Planning to shift this into PEEK instead of here
  
  //To Do - Really Old clients have some variations in some of the patterns

  //Step 1a - Find the GetPacketSize function call
  var code =
      " E8 AB AB AB AB" //CALL CRagConnection::GetPacketSize
    + " 50"             //PUSH EAX
    + " E8 AB AB AB AB" //CALL CRagConnection::instanceR
    + " 8B C8"          //MOV ECX, EAX
    + " E8 AB AB AB AB" //CALL CRagConnection::SendPacket
    + " 6A 01"          //PUSH 1
    + " E8"             //CALL CConnection::SetBlock
    ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    throw "SendPacket not found";

  //Step 1b - Look for packet key pushes before it. if not present look for the combo function that both encrypts and retrieves the packet keys
  code = 
      " 8B 0D AB AB AB 00" //MOV ECX, DWORD PTR DS:[addr1]
    + " 68 AB AB AB AB"    //PUSH key3
    + " 68 AB AB AB AB"    //PUSH key2
    + " 68 AB AB AB AB"    //PUSH key1
    + " E8"                //CALL encryptor
    ;
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x100, offset);
  var KeyFetcher = 0;
  
  if (offset2 === -1) {
    code = 
        " 8B 0D AB AB AB 00" //MOV ecx, DS:[ADDR1] dont care what
      + " 6A 01"             //PUSH 1
      + " E8"                //CALL combofunction - encryptor and key fetcher combined.
      ;
    offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset-0x100, offset);
    KeyFetcher = -1;
  }
  
  if (offset2 !== -1 && KeyFetcher === -1) {
    offset2 += code.hexlength();
    KeyFetcher = exe.Raw2Rva(offset2+4) + exe.fetchDWord(offset2);
  }
  
  //Step 1c - Go Inside the function  
  offset += exe.fetchDWord(offset+1) + 5;
  
  //Step 1d - Look for g_PacketLenMap reference and the pktLen function call following it
  code =
      " B9 AB AB AB AB" //MOV ECX, g_PacketLenMap
    + " E8 AB AB AB AB" //CALL addr; gets the address pointing to the packet followed by len
    + " 8B AB 04"       //MOV reg32_A, [EAX+4]
    ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x60);
  if (offset === -1)
    throw "g_PacketLenMap not found";
  
  //Step 1e - Extract the g_PacketLenMap assignment
  var gPacketLenMap = exe.fetchHex(offset, 5);
  
  //Step 2a - Go inside the pktLen function following the assignment
  offset += exe.fetchDWord(offset+6) + 10;
  
  //Step 2b - Look for the pattern that checks the length with -1 
  code = 
      " 8B AB AB" //MOV reg32_A, DWORD DS:[reg32_B+lenOff]; lenOff = pktOff+4
    + " 83 AB FF" //CMP reg32_A, -1
    + " 75 AB"    //JNE addr
    + " 8B"       //MOV reg32_A, DWORD DS:[reg32_B+lenOff+4]
    ;
  
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x60);
  if (offset2 === -1)
    throw "PktOff not found";
  
  //Step 2c - Extract the displacement - 4 which will be PktOff
  var PktOff = exe.fetchByte(offset2+2)-4;
  
  //Step 3a - Find the InitPacketMap function using g_PacketLenMap extracted
  code =
      gPacketLenMap
    + " E8 AB AB AB AB" //CALL CRagConnection::InitPacketMap
    + " 68 AB AB AB 00" //PUSH addr1
    + " E8 AB AB AB AB" //CALL addr2
    + " 59"             //POP ECX
    + " C3"             //RETN
    ;

  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    throw "InitPacketMap not found";
  
  //Step 3b - Save the address after the call which will serve as the ExitAddr
  var ExitAddr = exe.Raw2Rva(offset+15);
  
  //Step 3c - Go Inside InitPacketMap
  offset += exe.fetchDWord(offset+6) + 10;
  
  //Step 3d - Look for InitPacketLenWithClient call
  code = 
      " 8B CE"          //MOV ECX, ESI
    + " E8 AB AB AB AB" //CALL InitPacketLenWithClient
    + " C7"             //MOV DWORD PTR SS:[LOCAL.x], -1
    ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset+0x140);
  if (offset === -1)
    throw "InitPacketLenWithClient not found";

  //Step 3e - Go Inside InitPacketLenWithClient
  offset += exe.fetchDWord(offset+3) + 7;
  
  //Step 4a - Now comes the tricky part. We need to get all the functions called till a repeat is found.
  //          Last unrepeated call is the std::map function we need
  var funcs = [];
  while(1) {
    offset = exe.find(" E8 AB AB FF FF", PTYPE_HEX, true, "\xAB", offset+1);//CALL std::map
    if (offset === -1) break;
    var func = offset + exe.fetchDWord(offset+1) + 5;
    if (funcs.indexOf(func) !== -1) break;
    funcs.push(func);
  }
  
  if (offset === -1 || funcs.length === 0)
    throw "std::map not found";
  
  //Step 4b - Go Inside std::map
  offset = funcs[funcs.length-1];

  //Step 4c - Look for all calls to std::_tree (should be either 1 or 2 calls)
  //          The called Locations serve as our Hook Addresses
  code = 
      " E8 AB AB FF FF" //CALL std::_tree
    + " 8B AB"          //MOV reg32_A, [EAX]
    + " 8B"             //MOV EAX, DWORD PTR SS:[ARG.1]
    ;
  
  var HookAddrs = exe.findAll(code, PTYPE_HEX, true, "\xAB", offset, offset+0x100);
  if (HookAddrs.length < 1 || HookAddrs.length > 2)
    throw "std::_tree call count is different";
  
  //Step 5a - Get the DLL file
  var fp = new BinFile();
  if (!fp.open(APP_PATH + "/Input/ws2_pe.dll"))
    throw "Base File - ws2_pe.dll is missing from Input folder";
  
  //Step 5b - Read the contents
  var dllHex = fp.readHex(0, 0x1800);
  fp.close();
  
  //Step 5c - Replace the Filename template
  dllHex = dllHex.replace(" 64".repeat(8), ("" + exe.getClientDate()).toHex());//FileName
  
  //Step 5d - Replace all the addresses and PktOff
  code = 
      PktOff.packToHex(4)
    + ExitAddr.packToHex(4)
    + exe.Raw2Rva(HookAddrs[0]).packToHex(4)
    ;
  
  if (HookAddrs.length === 1)
    code += " 00 00 00 00";
  else
    code += exe.Raw2Rva(HookAddrs[1]).packToHex(4);
  
  code += KeyFetcher.packToHex(4);
  
  dllHex = dllHex.replace(/ 01 FF 00 FF 02 FF 00 FF 03 FF 00 FF 04 FF 00 FF 05 FF 00 FF/i, code);
  
  //Step 5e - Write out the filled up contents
  if (!fp.open(APP_PATH + "/Output/ws2_pe_" + exe.getClientDate() + ".dll", "w"))
    throw "Unable to create output file";
  
  fp.writeHex(0, dllHex);
  fp.close();
  
  return "DLL has been generated - Dont forget to rename it.";
}

//==================================================================================//
// How to use - client in hex editor and replace all occurances of ws2_32 to ws2_pe //
//              copy the generated dll to Client area and rename it to ws2_pe.dll   //
//              Run the client. It will Extract the packets and auto-close.         //
//==================================================================================//