  /////////////////////////////////////////////////////
  // GOAL: Skip the LangType comparison when loading //
  //       Palette names into Palette Table          //
  /////////////////////////////////////////////////////
  
function UseOfficialClothPalette() {//To be completed
  
  // Step 1 - Find the comparison code in CSession::InitTable
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE.length === 1)
    return "Failed in Step 1 - " + LANGTYPE[0];
  
  var code1 = " 83 3D" + LANGTYPE + " 00"; // CMP DWORD PTR DS:[g_servicetype], 0
  var code2 = " 0F 85 AB AB 00 00";        // JNE addr
  
  var repLoc = code1.hexlength();
  offset = exe.findCode(code1 + code2 + " 8B", PTYPE_HEX, true, "\xAB"); //8B -> MOV reg32_A , DWORD PTR DS:[reg32_B+const]
  
  if (offset === -1) {
    repLoc += 2;
    offset = exe.findCode(code1 + " 8B AB" + code2, PTYPE_HEX, true, "\xAB"); //8B -> MOV reg32_A , DWORD PTR DS:[reg32_B]
  }
  
  if (offset === -1) {
    repLoc += 4;
    offset = exe.findCode(code1 + " 8B AB AB AB 00 00" + code2, PTYPE_HEX, true, "\xAB"); //8B -> MOV reg32_A , DWORD PTR DS:[reg32_B+const]
  }
 
  if (offset === -1) 
    return "Failed in Step 1 - comparison not found";
  
  //Step 2 - NOP out the JNE
  exe.replace(offset + repLoc, " 90 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}