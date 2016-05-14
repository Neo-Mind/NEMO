//##################################################################################
//# Purpose: NOP out the JNE after LangType Comparison (but before PUSH 0 and      #
//#          PUSH 'questID2display.txt') in ITEM_INFO::InitItemInfoTables function #
//##################################################################################
  
function ReadQuestid2displaydottxt() {
  
  //Step 1a - Find address of questID2display.txt
  var offset = exe.findString("questID2display.txt", RVA);
  if (offset === -1)
    return "Failed in Step 1 - questID2display not found";
  
  //Step 1b - Find its reference 
  var code = 
    " 6A 00"                    //PUSH 0
  + " 68" + offset.packToHex(4) //PUSH addr2 ; "questID2display.txt"
  ;
  offset = exe.findCode(code, PTYPE_HEX, false);//VC9+ Clients
  
  if (offset === -1) {
    code = code.replace(" 00", " 00 8D AB AB");//Insert LEA reg32, [LOCAL.x] after PUSH 0
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");//Older Clients
  }
  
  if (offset === -1)
    return "Failed in Step 1";

  //Step 2 - Replace JNE before PUSH 0 with NOP (for long JNE, byte at offset - 1 will be 0)
  if (exe.fetchByte(offset - 1) === 0)
    exe.replace(offset - 6, " 90 90 90 90 90 90", PTYPE_HEX);
  else
    exe.replace(offset - 2, " 90 90", PTYPE_HEX);
    
  return true;
}