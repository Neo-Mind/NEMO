//###############################################################
//# Purpose: Change JNZ to JMP after LangType comparison inside #
//#          DataTxtDecode function                             #
//###############################################################

function UsePlainTextDescriptions() {
  
  //Step 1a - Get the Langtype
  var LANGTYPE = GetLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE.length === 1)
    return "Failed in Step 1 - " + LANGTYPE[0];
 
 //Step 1b - Find the LangType comparison in the DataTxtDecode function
  var code =
    " 83 3D" + LANGTYPE + " 00" //CMP DWORD PTR DS:[g_serviceType], 0
  + " 75 AB" //JNZ SHORT addr
  + " 56"    //PUSH ESI
  + " 57"    //PUSH EDI
  ;
  var repLoc = 7;//Position of JNZ relative to offset
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");//VC9+ Clients
  
  if (offset === -1) {
    code = code.replace(" 75 AB 56 57", " 75 AB 57");//remove PUSH ESI
    offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");//Latest Clients
  }
  
  if (offset === -1) {
    code =
      " A1" + LANGTYPE //MOV EAX, DWORD PTR DS:[g_serviceType]
    + " 56"            //PUSH ESI
    + " 85 C0"         //TEST EAX, EAX
    + " 57"            //PUSH EDI
    + " 75"            //JNZ SHORT addr
    ;
    repLoc = code.hexlength() - 1;
    offset = exe.findCode(code, PTYPE_HEX, false);//Older Clients
  }
  
  if (offset === -1)
    return "Failed in Step 1 - LangType Comparison missing";
  
  //Step 2 - Change JNE/JNZ to JMP
  exe.replace(offset + repLoc, "EB", PTYPE_HEX);
  
  return true;
}