//#############################################################
//# Purpose: Change the pf argument to CTexMgr::CreateTexture #
//#          to increase the color depth used to 32 bit       #
//#############################################################

function IncreaseMapQuality() {
  //Step 1a - Find the CreateTexture call
  var code =
    " 51"             //PUSH ECX ; imgData
  + " 68 00 01 00 00" //PUSH 100 ; h = 256
  + " 68 00 01 00 00" //PUSH 100 ; w = 256
  + " B9 AB AB AB 00" //MOV ECX, OFFSET g_texMgr
  + " E8"             //CALL CTexMgr::CreateTexture
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  
  if (offset === -1) {
    code = code.replace(" 51", " 50");//PUSH EAX ; imgData
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }
  
  if (offset === -1)
    return "Failed in Step 1 - CreateTexture call missing";
  
  //Step 1b - Find the pf argument push before it.
  if (exe.fetchByte(offset - 1) === 0x01) {//PUSH 1 is right before PUSH E*X
    offset--;
  }
  else {
    offset = exe.find(" 6A 01", PTYPE_HEX, false, "", offset - 10, offset);//PUSH 1
    if (offset === -1)
      return "Failed in Step 1 - pf push missing";
    
    offset++;
  }
  
  //Step 2 - Change PUSH 1 to PUSH 4
  exe.replace(offset, " 04", PTYPE_HEX);
  
  return true;
}