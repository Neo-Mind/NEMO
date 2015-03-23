// Both have same procedure - only format string is different
function SharedBodyPalettesV1() {
  return SharedBodyPalettes("body%.s_%s_%d.pal\x00"); //%.s is required. Skips jobname
}

function SharedBodyPalettesV2() {
  return SharedBodyPalettes("body%.s%.s_%d.pal\x00"); //%.s is required. Skips jobname & gender
}

function SharedBodyPalettes(fmt) {
  ////////////////////////////////////////////////////////////////////
  // GOAL: Modify the format string in CSession::GetBodyPaletteName //
  //       used for constructing Body palette filename to skip parts//
  ////////////////////////////////////////////////////////////////////
  
  //Step 1 - Find offset of String 个\%s%s_%d.pal - Old Format
  var offset = exe.findString("个\\%s%s_%d.pal", RVA);
  
  if (offset === -1)// Otherwise look for 个\%s_%s_%d.pal - New Format    
    offset = exe.findString("个\\%s_%s_%d.pal", RVA);
  
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2a - Now allocate space for new string. original may not have enough space  
  var offset2 = exe.findZeros( fmt.length );
  if (offset2 === -1)
    return "Failed in Step 2";
  
  //Step 2b - Insert the new format string
  exe.insert(offset2, fmt.length, fmt, PTYPE_STRING);
  
  //Step 3a - Find the reference to current string
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 3";
  
  //Step 3b - Replace with ours
  exe.replace(offset+1, exe.Raw2Rva(offset2).packToHex(4), PTYPE_HEX);
  
  return true;
}