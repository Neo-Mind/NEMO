//################################################################################
//# Purpose: Skip the Langtype checks inside UILoginWnd::OnCreate and always     #
//#          makes the registration page open inside UILoginWnd::SendMsg.        #
//#          Also modifies the CModeMgr::Quit CALL to actually close the client. #
//################################################################################

function ShowRegisterButton() {
  //Step 1a - Find the alternate URL string 
  var offset = exe.findString("http://ro.hangame.com/login/loginstep.asp?prevURL=/NHNCommon/NHN/Memberjoin.asp", RVA);
  if (offset === -1)
    return "Failed in Step 1 - String missing";
  
  //Step 1b - Find its reference inside UILoginWnd::SendMsg
  offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - String reference missing";
  
  //Step 2a - Get the LangType
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE.length === 1)
    return "Failed in Step 2 - " + LANGTYPE[0];

  //Step 2b - Look for the LangType comparison before the URL reference
  var code = 
    " 83 3D" + LANGTYPE + " 00" //CMP DWORD PTR DS:[g_serviceType], 0
  + " 75 AB"                    //JNE SHORT addr
  ;
  
  var codeSuffix =
    " 83 3D AB AB AB 00 01"     //CMP DWORD PTR DS:[g_isGravityID], 1
  + " 75"                       //JNE SHORT addr
  ;
  var type = 1;
  
  var offset2 = exe.find(code + codeSuffix, PTYPE_HEX, true, "\xAB", offset - 0x30, offset);
  if (offset2 === -1) {
    code =
      " A1" + LANGTYPE      //MOV EAX, DWORD PTR DS:[g_serviceType]
    + " 85 C0"              //TEST EAX, EAX
    + " 0F 85 AB 00 00 00"  //JNE addr
    ;
    type = 2;
    offset2 = exe.find(code + codeSuffix, PTYPE_HEX, true, "\xAB", offset - 0x30, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Step 2 - Langtype comparison missing";
  
  offset2 += code.hexlength();

  //Step 2c - Change the first JNE (LangType JNE) to JMP and goto the Jumped address
  if (type == 1) {
    exe.replace(offset2 - 2, "EB", PTYPE_HEX);
    offset2 += exe.fetchByte(offset2 - 1);
  }
  else {
    exe.replace(offset2 - 6, "90 E9", PTYPE_HEX);
    offset2 += exe.fetchDWord(offset2 - 4);
  }
  
  //Step 3a - Add 10 to Skip over MOV ECX, OFFSET g_modeMgr and CALL CModeMgr::Quit
  offset2 += 10;
  
  //Step 3b - Prep new code (original CModeMgr::Quit will get overwritten by RestoreLoginWindow so create a new function with the essentials)
  code = 
    " 8B 41 04"             //MOV EAX,DWORD PTR DS:[ECX+4]
  + " C7 40 14 00 00 00 00" //MOV DWORD PTR DS:[EAX+14], 0
  + " C7 01 00 00 00 00"    //MOV DWORD PTR DS:[ECX],0
  + " C3"                   //RETN
  
  //Step 3c - Allocate space for the code
  var free = exe.findZeros(code.hexlength());
  if (free === -1)
    return "Failed in Step 3 - Not enough free space";

  //Step 3d - Insert it
  exe.insert(free, code.hexlength(), code, PTYPE_HEX);

  //Step 3e - Change the CModeMgr::Quit CALL with a CALL to our function
  exe.replaceDWord(offset2 - 4, exe.Raw2Rva(free) - exe.Raw2Rva(offset2));
  
  //Step 4a - Find the prefix string for the button (pressed state)
  offset = exe.findString("btn_request_b", RVA);
  if (offset === -1)
    return "Failed in Step 4 - Button prefix missing";
  
  //Step 4b - Find its reference
  offset = exe.findCode(offset.packToHex(4) + " C7", PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 4 - Prefix reference missing";

  //Step 4c - Look for the LangType comparison after the reference
  code =
    " 83 AB 03"       //CMP reg32, 03 ; 03 is for register button
  + " 75 25"          //JNE SHORT addr
  + " A1" + LANGTYPE  //MOV EAX, DWORD PTR DS:[g_serviceType]
  ;
  
  offset2 = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 0xA0, offset + 0x100);
  if (offset2 === -1)
    return "Failed in Step 4 - Langtype comparison missing";

  //Step 4d - Change the JNE to JMP. This way no langtype check occurs for any buttons
  exe.replace(offset2 + 3, "EB", PTYPE_HEX);
  
  return true;
}