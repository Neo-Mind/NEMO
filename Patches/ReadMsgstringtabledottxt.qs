//##################################################################
//# Purpose: Change the JNZ after LangType check in InitMsgStrings #
//#          function to JMP.                                      #
//##################################################################

function ReadMsgstringtabledottxt() {
  
  //Step 1 - Find the comparison which is at the start of the function
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceTypes
  if (LANGTYPE.length === 1)
    return "Failed in Step 1 - " + LANGTYPE[0];

  var code = 
    " 83 3D" + LANGTYPE + " 00" //CMP DWORD PTR DS:[g_serviceType], 0
  + " 56"                       //PUSH ESI
  + " 75"                       //JNZ SHORT addr -> continue with msgStringTable.txt loading
  ;
  var offset = exe.findCode(code, PTYPE_HEX, false);//VC9+ Clients
  
  if (offset === -1) {
    code =
      " A1" + LANGTYPE //MOV EAX, DWORD PTR DS:[g_serviceType]
    + " 56"            //PUSH ESI
    + " 85 C0"         //TEST EAX, EAX
    + " 75"            //JNZ SHORT addr -> continue with msgStringTable.txt loading
    ;
    offset = exe.findCode(code, PTYPE_HEX, false);//Older Clients
  }
  
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Change JNZ to JMP
  exe.replace(offset + code.hexlength() - 1, "EB", PTYPE_HEX);
  
  return true;
}