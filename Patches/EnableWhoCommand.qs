//###############################################################
//# Purpose: Change the JE/JNE after LangType comparison inside #
//#          CGameMode::SendMsg function for /who command       #
//#          and inside CGameMode::Zc_User_Count                #
//###############################################################

function EnableWhoCommand() {
  
  //Step 1a - Find LangType comparison
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE.length === 1)
    return "Failed in Step 1 - " + LANGTYPE[0];
  
  var code = 
    " A1" + LANGTYPE     //MOV EAX,DWORD PTR DS:[g_serviceType]
  + " 83 F8 03"          //CMP EAX,3
  + " 0F 84 AB AB 00 00" //JE addr
  + " 83 F8 08"          //CMP EAX,8
  + " 0F 84 AB AB 00 00" //JE addr
  + " 83 F8 09"          //CMP EAX,9
  + " 0F 84 AB AB 00 00" //JE addr
  + " 8D"                //LEA ECX,[ESP+x]
  ;
  
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1 - LangType comparison missing";
  
  //Step 1b - Replace the First JE with JMP to LEA
  exe.replace(offset + 5, "90 EB 18", PTYPE_HEX);
  
  //Step 2a - Find PUSH 0B2 followed by CALL MsgStr - Common pattern inside Zc_User_Count
  code =
    " 68 B2 00 00 00" //PUSH 0B2
  + " E8"             //CALL MsgStr
  ;
  
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 2 - MsgStr call missing";
  
  //Step 2b - Find the JNE after LangType comparison before it (closer to start of Zc_User_Count)
  code =
    " 75 AB"          //JNE SHORT addr
  + " A1 AB AB AB 00" //MOV EAX, DWORD PTR DS:[refAddr]
  + " 50"             //PUSH EAX
  + " E8 AB AB AB FF" //CALL IsGravityAid
  + " 83 C4 04"       //ADD ESP, 4
  + " 84 C0"          //TEST AL, AL
  + " 75"             //JNE SHORT addr
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset - 0x60, offset);
  if (offset === -1)
    return "Failed in Step 2 - LangType comparison missing";
  
  //Step 2c - Replace First JNE with JMP
  exe.replace(offset, "EB", PTYPE_HEX);
 
  return true;
}