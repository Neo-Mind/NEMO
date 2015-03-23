function UseCustomAuraSprites(){//-Incomplete. Old patch seems to be changing different areas
  
  //To Do - Patterns differ in old clients. Find when it changed.
  
  //Step 1a - Find offset of ring_blue.tga
  var offset = exe.findString("effect\\ring_blue.tga", RVA);
  if (offset === -1)
    return "Failed in Part 1 - ring_blue.tga not found";
    
  var erb = offset.packToHex(4);
  
  //Step 1b - Find offset of pikapika2.bmp  
  offset = exe.findString("effect\\pikapika2.bmp", RVA);
  if (offset === -1)
    return "Failed in Part 1 - pikapika2.bmp not found";
    
  var epp = offset.packToHex(4);
  
  if (exe.getClientDate() <= 20130605) {
    var code00 =  
        " 68" + erb                // PUSH erb; ASCII "effect\ring_blue.tga"
      + " FF 15 AB AB AB AB"       // CALL NEAR DWORD PTR DS:[&MSVCP90.std::basic_string<char>::basic_string<char>]
      + " 89 AB AB AB"             // MOV DWORD PTR SS:[ESP+const1], EBP
      + " C7 44 AB AB AB AB AB AB" // MOV DWORD PTR SS:[ESP+const2], const3
      + " 8B CE"                   // MOV  ECX,ESI
      + " E8 AB AB AB AB"          // CALL func1
      + " 8B 57 AB"                // MOV EAX, DWORD PTR DS:[EDI+const4]
      + " 56"                      // PUSH ESI
      + " 8B CF"                   // MOV ECX, EDI
      + " 89 AB AB"                // MOV DWORD PTR DS:[ESI+4], EDX
      + " 89 AB AB"                // MOV DWORD PTR DS:[ESI+0C], EBX
      + " 89 AB AB"                // MOV DWORD PTR DS:[ESI+10], EBP
      + " C7 46 AB AB AB AB AB"    // MOV DWORD PTR DS:[ESI+8], 1
      + " E8 AB AB AB AB"          // CALL func2
      ;
          
    var code01 =
        " 68" + epp // PUSH epp; ASCII "effect\pikapika2.bmp"
      + " FF 15"    // CALL DWORD PTR DS:[&MSVCP90.std::basic_string<char>::basic_string<char>]
      ;
  }
  else {
    var code00 =
        " 68" + erb             // PUSH erb; ASCII "effect\ring_blue.tga"
      + " C6 01 00"             // MOV BYTE PTR DS:[ECX], 0
      + " E8 AB AB AB AB"       // CALL addr1
      + " C7 45 AB AB AB AB AB" // MOV DWORD PTR SS:[LOCAL.x], const1
      + " C7 45 AB AB AB AB AB" // MOV DWORD PTR SS:[LOCAL.y], const2
      + " 8B CE"                // MOV ECX, ESI
      + " E8 AB AB AB AB"       // CALL addr2
      + " 8B 57 04"             // MOV EDX, [EDI+4]
      + " 56"                   // PUSH ESI
      + " 8B CF"                // MOV ECX, EDI
      + " 89 AB AB"             // MOV DWORD PTR DS:[ESI+4], EDX
      + " 89 AB AB"             // MOV DWORD PTR DS:[ESI+0C], EBX
      + " C7 46 AB AB AB AB AB" // MOV DWORD PTR DS:[ESI+10], 0
      + " C7 46 AB AB AB AB AB" // MOV DWORD PTR DS:[ESI+8], 1
      + " E8 AB AB AB AB"       // CALL addr3
      ;

    var code01 =
        " 68" + epp       // PUSH epp; ASCII "effect\pikapika2.bmp"
      + " C6 AB AB"       // MOV BYTE PTR DS:[ECX], 0
      + " E8 AB AB AB AB" // CALL func
      ;
  }

  var offset00 = exe.findCode(code00, PTYPE_HEX, true, "\xAB");
  if (offset00 === -1)
    return "Failed in part 1";
  
  var offset01 = exe.findCode(code01, PTYPE_HEX, true, "\xAB");
  if (offset01 === -1)
    return "Failed in part 2";
     
  var code =  "effect\\aurafloat.tga\x00effect\\auraring.bmp\x00\x90";
  var size =  code.length;
  
  var free = exe.findZeros(size);
  if (free === -1)
    return "Failed to find enough free space";
  
  exe.replace(offset00+1,  exe.Raw2Rva(free+0 ).packToHex(4), PTYPE_HEX);
  exe.replace(offset01+1,  exe.Raw2Rva(free+21).packToHex(4), PTYPE_HEX);
  exe.insert(free, size, code.toHex(), PTYPE_HEX);
  
  return true;
}