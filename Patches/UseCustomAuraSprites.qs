 //###########################################################################
 //# Purpose: Change the filename references used for Level99 Aura effect    #
 //#          ring_blue.tga -> aurafloat.tga , pikapika2.bmp -> auraring.bmp #
 //###########################################################################
 
function UseCustomAuraSprites() {
 
  //Step 1a - Find address of ring_blue.tga
  var offset = exe.findString("effect\\ring_blue.tga", RVA, false);//false for not prefixing zero.
  if (offset === -1)
    return "Failed in Step 1 - ring_blue.tga not found";
  
  var rblue = " 68" + offset.packToHex(4);//PUSH OFFSET addr; ASCII "effect\ring_blue.tga"
  
  //Step 1b - Find address of pikapika2.bmp
  offset = exe.findString("effect\\pikapika2.bmp", RVA, false);//false for not prefixing zero.
  if (offset === -1)
    return "Failed in Step 1 - pikapika2.bmp not found";
  
  var ppika2 = " 68" + offset.packToHex(4);//PUSH OFFSET addr; ASCII "effect\pikapika2.bmp"

  //Step 1c - Allocate space for the replace strings
  var strings = ["effect\\aurafloat.tga", "effect\\auraring.bmp"];
  var code = strings.join("\x00") + "\x00";
  
  var free = exe.findZeros(code.length);
  if (free === -1)
    return "Failed in Step 1 - Not enough free space";

  //Step 1d - Insert the strings into the allocated area
  exe.insert(free, code.length, code.toHex(), PTYPE_HEX);

  var afloat = exe.Raw2Rva(free).packToHex(4);
  var aring = exe.Raw2Rva(free + strings[0].length + 1).packToHex(4);
  
  //Step 2a - Find the reference of both where they are used to display the aura
  var code1 =
    rblue             //PUSH OFFSET addr; ASCII "effect\ring_blue.tga"
  + " 8B AB"          //MOV ECX, reg32_A
  + " E8 AB AB AB AB" //CALL addr2
  + " E9 AB AB AB AB" //JMP addr3
  ;
  var code2 = code1.replace(rblue, ppika2);
  var roff = code1.hexlength() + 2;
  
  offset = exe.findCode(code1 + " AB" + code2, PTYPE_HEX, true, "\xAB");//PUSH reg32_B in between
  if (offset === -1) {
    offset = exe.findCode(code1 + " 6A 00" + code2, PTYPE_HEX, true, "\xAB");//PUSH 0 in between
    roff++;
  }
  
  if (offset === -1)
    return "Failed in Step 2";
  
  //Step 2b - Replace the two string addresses.
  exe.replace(offset + 1, afloat, PTYPE_HEX);
  exe.replace(offset + roff, aring, PTYPE_HEX);
  
  //===========================================//
  // For new clients above is left unused but  //
  // we are still going to keep it as failsafe //
  //===========================================//

  //Step 3a - Look for the second pattern in the new clients.
  code = 
    " 56"             //PUSH ESI
  + " 8B F1"          //MOV ESI, ECX
  + " E8 AB AB FF FF" //CALL addr1
  + " 8B CE"          //MOV ECX, ESI
  + " 5E"             //POP ESI
  + " E9 AB AB FF FF" //JMP addr2
  ;

  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  var offsetR = -1;
  var offsetP = -1;
  
  //Step 3b - Find the pattern that calls pikapika2 effect followed by ring_blue. 
  //          (addr1 should pikapika2 reference & addr2 should contain ring_blue reference)
  for (var i = 0; i < offsets.length; i++) {
    offset = offsets[i] + 8 +  exe.fetchDWord(offsets[i] + 4);
    offsetP = exe.find(ppika2, PTYPE_HEX, false, "", offset, offset + 0x100);
    
    offset = offsets[i] + 16 + exe.fetchDWord(offsets[i] + 12);
    offsetR = exe.find(rblue,  PTYPE_HEX, false, "", offset, offset + 0x120);
    
    if (offsetP !== -1 && offsetR !== -1) break;
  }
  
  //Step 3c - Replace the two string addresses.
  if (offsetP !== -1 && offsetR !== -1) {
    exe.replace(offsetP + 1, aring, PTYPE_HEX);
    exe.replace(offsetR + 1, afloat, PTYPE_HEX);
  }
  
  return true;
}