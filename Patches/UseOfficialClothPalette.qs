function UseOfficialClothPalette() {
  /////////////////////////////////////////////////////
  // GOAL: Skip the LangType comparison when loading //
  //       Palette names into Palette Table          //
  /////////////////////////////////////////////////////
  
  // Step 1 - Find the comparison code in CSession::InitTable
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";
  
  var code =
      " 83 3D" + LANGTYPE + " 00" // CMP DWORD PTR DS:[g_servicetype], 0
    + " 0F 85 AB AB 00 00"        // JNE addr
    + " 8B"                       // MOV reg32_A , DWORD PTR DS:[reg32_b+const]
    ;
    
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 4";
  
  //Step 2 - NOP out the JNE
  exe.replace(offset+7, " 90 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}