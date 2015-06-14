//###############################################################################
//# Purpose: Change the JZ/JNE to JMP/NOP after LangType Comparison for sending #
//#          Login Packet inside CLoginMode::OnChangeState function.            #
//###############################################################################
  
function UseSSOLoginPacket() {

  //Step 1a - Find the LangType comparison
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE.length === 1)
    return "Failed in Step 1 - " + LANGTYPE[0];
  
  var code =
    " 80 3D AB AB AB 00 00" //CMP BYTE PTR DS:[g_passwordencrypt], 0
  + " 0F 85 AB AB 00 00"    //JNE addr1
  + " A1" + LANGTYPE        //MOV EAX, DWORD PTR DS:[g_serviceType]
  + " AB AB"                //TEST EAX, EAX - (some clients use CMP EAX, EBP instead)
  + " 0F 84 AB AB 00 00"    //JZ addr2 -> Send SSO Packet (ID = 0x825. was 0x2B0 in Old clients)
  + " 83 AB 12"             //CMP EAX, 12
  + " 0F 84 AB AB 00 00"    //JZ addr2 -> Send SSO Packet (ID = 0x825. was 0x2B0 in Old clients)
  ;
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
 
  if (offset === -1) {
    code = code.replace(" A1", " 8B AB");//Change MOV EAX to MOV reg32_A, DWORD PTR DS:[g_serviceType]
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  }

  if (offset !== -1) {
    //Step 1b - Change first JZ to JMP
    exe.replace(offset + code.hexlength() - 15, " 90 E9", PTYPE_HEX);
    return true;
  }
  
  //Step 2a - Since it failed it is an old client before VC9. Find the alternate comparison pattern
  code = 
    " A0 AB AB AB 00"       //MOV AL, DWORD PTR DS:[g_passwordencrypt]
  + " AB AB"                //TEST AL, AL - (could be checked with CMP also. so using wildcard)
  + " 0F 85 AB AB 00 00"    //JNE addr1
  + " A1" + LANGTYPE        //MOV EAX, DWORD PTR DS:[g_serviceType]
  + " AB AB"                //TEST EAX, EAX - (some clients use CMP EAX, EBP instead)
  + " 0F 85 AB AB 00 00"    //JNE addr2 -> Send Login Packet (ID = 0x64)
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2b - Convert the JNE addr2 to NOP
  exe.replace(offset + code.hexlength() - 6, " 90 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}