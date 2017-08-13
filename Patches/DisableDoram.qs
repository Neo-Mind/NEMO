//#########################################################################################
//# Purpose: Remove Doram race from character creation UI                                 #
//#          special thanks to @Ai4Rei for the original hex sequences.                    #
//#########################################################################################

function DisableDoram() {

  // Step 1
  var code =
    " FF 77 AB"       // PUSH DWORD PTR ??
  + " 8B CF"          // MOV ECX, EDI
  + " FF 77 AB"       // PUSH DWORD PTR ??
  + " E8"             // CALL ??
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1)
    return "Failed in step 1";
	
  exe.replace(offset, "90 6A 00", PTYPE_HEX);

  // Step 2a - MOV pattern
  code =
    " C7 AB AB FF FF FF 00 00 00 00"  // MOV [EBP + var_DC], 0
  + " C7 AB AB FF FF FF 00 00 00 00"  // MOV [EBP + var_D8], 0
  + " C7 AB AB FF FF FF 00 00 00 00"  // MOV [EBP + var_D4], 0
  + " 6A 01"                          // PUSH 1
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1)
    return "Failed in step 2 - Cannot find 3 MOV [EXP + var_Dx], 0 pattern.";

  offset += 30; // 10*3 from each MOV

  // Step 2b - XOR jump
  code =
    " 33 F6"             // XOR ESI, ESI
  + " 8D 87 AB AB 00 00" // LEA EAX, [EDI + const]
  + " 8D 49 00"          // LEA ECX, [ECX + 0]
  ;
  
  var offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset, offset + 0x300);
  
  if (offset2 === -1)
    return "Failed in step 2b - XOR after MOV pattern not found";

  offset2 = offset2 - offset - 5;
  
  exe.replace(offset, "E9" + offset2.packToHex(4) + " 90 90", PTYPE_HEX);
  
  // Step 3
  code =
    " 8B 8D 38 FF FF FF" // MOV ECX, [EBP+var_C8]
  + " 41"                // INC ECX
  + " 89 8D 38 FF FF FF" // MOV [EBP+var_C8], ECX
  + " B8 AB AB 00 00"    // MOV EAX, const
  + " 83 F9 02"          // CMP EAX, 2
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in step 3";
	
  exe.replace(offset + code.hexlength(), "90 90 90 90 90 90", PTYPE_HEX);
  return true;
}