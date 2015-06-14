//=======================================================//
// Patch Functions wrapping over SharedPalettes function //
//=======================================================//

function SharedBodyPalettesV1() {
  // "个\%s_%s_%d.pal" => "个\body%.s_%s_%d.pal"
  
  return SharedPalettes("\xB8\xF6\\", "\xB8\xF6\\body%.s_%s_%d.pal\x00"); //%.s is required. Skips jobname
}

function SharedBodyPalettesV2() {
  // "个\%s_%s_%d.pal" => "个\body%.s%.s_%d.pal"
  
  return SharedPalettes("\xB8\xF6\\", "\xB8\xF6\\body%.s%.s_%d.pal\x00"); //%.s is required. Skips jobname & gender
}

function SharedHeadPalettesV1() {
  // "赣府\赣府%s_%s_%d.pal" => "赣府\head%.s_%s_%d.pal"
  
  return SharedPalettes("\xB8\xD3\xB8\xAE\\\xB8\xD3\xB8\xAE", "\xB8\xD3\xB8\xAE\\head%.s_%s_%d.pal\x00");// %.s is required. Skips jobname
}

function SharedHeadPalettesV2() {
  // "赣府\赣府%s_%s_%d.pal" => "赣府\head%.s%.s_%d.pal"
  
  return SharedPalettes("\xB8\xD3\xB8\xAE\\\xB8\xD3\xB8\xAE", "\xB8\xD3\xB8\xAE\\head%.s%.s_%d.pal\x00");// %.s is required. Skips jobname & gender
}

//#####################################################################################
//# Purpose: Change the format string used in CSession::GetBodyPaletteName (for Body) #
//#          or CSession::GetHeadPaletteName (for Head) to skip some arguments        #
//#####################################################################################

function SharedPalettes(prefix, newString) {
  
  //Step 1a - Find address of original Format String
  var offset = exe.findString(prefix + "%s%s_%d.pal", RVA);//<prefix>%s%s_%d.pal - Old Format
  
  if (offset === -1)
    offset = exe.findString(prefix + "%s_%s_%d.pal", RVA);//<prefix>%s_%s_%d.pal - New Format
  
  if (offset === -1)
    return "Failed in Step 1 - Format String missing";

  //Step 1b - Find its reference
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - Format String reference missing";
    
  //Step 2a - Allocate space for New Format String - Original address don't have enough space for some scenarios.
  var free = exe.findZeros(newString.length);
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";
  
  //Step 2b - Insert the new format string
  exe.insert(free, newString.length, newString, PTYPE_STRING);
  
  //Step 3 - Replace with new one's address
  exe.replace(offset + 1, exe.Raw2Rva(free).packToHex(4), PTYPE_HEX);
  
  return true;
}