//###############################################################
//# Purpose: Change JNE to JMP after the Langtype comparison in #
//#          the Monster talk loader function                   #
//###############################################################
  
function EnableMonsterTables() {//Comparison is different for pre-2010 clients.
  
  //Step 1 - Find the Comparison - Hint: Case 2723 of switch and it appears before PUSH "uae\"
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE.length === 1)
    return "Failed in Step 1 - " + LANGTYPE[0];
 
  var code = 
    LANGTYPE             //MOV reg32_A, DWORD PTR DS:[g_serviceType]
  + " 83 C4 04"          //ADD ESP, 4
  + " 83 AB 13"          //CMP reg32_A, 13
  + " 0F 85 AB AB 00 00" //JNE addr
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1 -  Comparison not found";
    
  //Step 2 - Swap JNE with NOP + JMP
  exe.replace(offset + code.hexlength() - 6, " 90 E9", PTYPE_HEX);
  
  return true;
}