function EnableFlagEmotes() {
  //////////////////////////////////////////////////////////////
  // GOAL: Modify all the Flag Emote callers for all the      //
  //       buttons Ctrl+1-9 in UIWindowMgr::ProcessPushButton //
  //////////////////////////////////////////////////////////////
  
  //To Do - Procedure is a bit different in old clients.
  
  //Step 1 - Find a signature after which the Emote callers come
  
  var code = 
      " 05 2E FF FF FF" // ADD EAX,-D2
    + " 83 F8 08"       // CMP EAX, 08
    ;
    
  var offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2a - Get Input file containing the list of Flag Emotes per key
  var f = new TextFile();
  if (!getInputFile(f, "$inpFlag", "File Input - Enable Flag Emoticons", "Enter the Flags list file", APP_PATH + "/Input/flags.txt")) {
    return "Patch Cancelled";
  }
  
  //Step 2b - Read all the entries into an array
  var consts = [];
  while (!f.eof()) {
    var str = f.readline().trim();
    if (str.charAt(1) === "=") {
      var key = parseInt(str.charAt(0));
      if (!isNaN(key)) {
        var value = parseInt(str.substr(2));//full length is retrieved.
        if (!isNaN(value)) consts[key] = value;
      }
    }
  }
  f.close();
  
  //Step 3a - Prep code that constitutes the Emote caller
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 2 - LangType not found";
    
  code  =
      " A1" + LANGTYPE // MOV EAX, DS:[g_servicetype]
    + " 85 C0"      // TEST EAX, EAX
    ;

  var code2 =
      " 8B 01"     //MOV EAX,DWORD PTR DS:[ECX]
    + " 8B 50 18"  //MOV EDX,DWORD PTR DS:[EAX+18]
    + " 6A 00"     //PUSH 0
    + " 6A 00"     //PUSH 0
    + " 6A 00"     //PUSH 0
    + " 6A AB"     //PUSH emoteConstant
    + " 6A 1F"     //PUSH 1F
    + " FF D2"     //CALL EDX
    ;

  for (var i = 1; i < 10; i++) {
    //Step 3b - Find the first part
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset+1);
    if (offset === -1)
      return "Failed in Step 3 - First part missing : " + i;
    
    //Step 3c - Find the second part
    var jmpoffset = exe.find(code2, PTYPE_HEX, true, "\xAB", offset+7);
    if (jmpoffset === -1)
      return "Failed in Step 3 - Second part missing : " + i;
  
    //Step 3d - Replace the JNE after TEST EAX,EAX with JMP
    if (consts[i]) {//If Entry is present set the constant to it and JMP to code2.
      exe.replace(offset+7, " EB" + ( (jmpoffset) - (offset+9) ).packToHex(1), PTYPE_HEX);
      exe.replace(jmpoffset+12, consts[i].toString(16), PTYPE_HEX);
    }
    else {//if not then set JMP to after code2
      exe.replace(offset+7, " EB" + ( (jmpoffset + code2.hexlength()) - (offset+9) ).packToHex(1), PTYPE_HEX);
    }
    offset = jmpoffset+12;
  }
  
  return true;
}