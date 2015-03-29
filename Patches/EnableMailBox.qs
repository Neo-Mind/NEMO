function EnableMailBox() {
  ///////////////////////////////////////////////////////////////////////
  // GOAL: Fixup all the Langtype comparison Jumps in Mailbox function //
  ///////////////////////////////////////////////////////////////////////
  
  //Step 1 - Check Date . Patch is only required for new clients
  if (exe.getClientDate() < 20130320)
    return "Only meant for Later 2013 and newer Clients";

  //Step 2a - Prep codes for finding short jumps
  var code  =
      " 74 AB"    // JE SHORT addr1 (prev statement is either TEST EAX, EAX or CMP EAX, r32 => both instructions use 2 bytes)
    + " 83 F8 08" // CMP EAX,08
    + " 74 AB"    // JE SHORT addr1
    + " 83 F8 09" // CMP EAX,09
    + " 74 AB"    // JE SHORT addr1
    ;

  var pat1 = " 8B 8E AB 00 00 00"  //MOV ECX, DWORD PTR DS:[ESI+const]
  var pat2 = " BB 01 00 00 00"  //MOV EBX,1
  
  //Step 2b - Find all occurences of 1st LangType comparisons in the mailbox function
  var offsets = exe.findCodes(code+pat1, PTYPE_HEX, true, "\xAB");
  if (offsets.length !== 3)
    return "Failed in Part 2 - First pattern not found";
  
  //Step 2c - Change the first JE to JMP
  for (i=0; i < 3; i++) {
    exe.replace(offsets[i]-2, " EB 0C", PTYPE_HEX);
  }
  
  //Step 2d - Find occurence of 2nd LangType comparison in the mailbox function
  var offset = exe.findCode(code+pat2, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 2 - Second pattern not found";
  
  //Step 2e - Change the first JE to JMP
  exe.replace(offset-2, " EB 0C", PTYPE_HEX);
  
  //Step 3a - Prep codes for finding Long jumps
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 3 - LangType not found";
  
  code =
      " 0F 84 AB AB 00 00" //JE addr1 (prev statement is either TEST EAX, EAX or CMP EAX, r32 => both instructions use 2 bytes)
    + " 83 F8 08"          //CMP EAX,08
    + " 0F 84 AB AB 00 00" //JE addr1
    + " 83 F8 09"          //CMP EAX,09
    + " 0F 84 AB AB 00 00" //JE addr1
    ;
  
  pat1 = " A1" + LANGTYPE + " AB AB" ; //MOV EAX, DS:[g_Servicetype]; (g_servicetype is overriden by langtype meh )
  
  //Step 3b - Find all occurences of the pattern - 3 or 4 would be there
  offsets = exe.findCodes(pat1+code, PTYPE_HEX, true, "\xAB");
  if (offsets.length < 3 || offsets.length > 4)
    return "Failed in Part 3";
  
  for (i=0; i<offsets.length; i++) {
    exe.replace(offsets[i]+5, " EB 18", PTYPE_HEX);
  }
  
  //Step 4 - If the count is 3 then there is an additional JE we missed
  if (offsets.length == 3) {
    var pat2 = " 6A 23"  //PUSH 23
    
    var offset = exe.findCode(code+pat2, PTYPE_HEX, true, "\xAB");
    if (offset === -1)
      return "Failed in Part 4";
    
    exe.replace(offset-2, " EB 18", PTYPE_HEX);
  }
  return true;
}