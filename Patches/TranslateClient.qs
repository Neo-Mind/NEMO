function TranslateClient() {
  ////////////////////////////////////////////////////////
 // GOAL: Translate Korean Strings to User Specified   //
 //       Strings both loaded from TranslateClient.txt //
  ////////////////////////////////////////////////////////

 // Step 1 - Open the text file for reading
 var f = new TextFile();
 if (!f.open(APP_PATH + "/patches/TranslateClient.txt") )
  return "Failed in Part 1 - Unable to open file";
 
 var offset = -1;
 var msg = ""; 
 var failmsgs = [];//Array to store all Failure messages
 
 // Step 2 - Loop through the text file, get the respective strings & do findString + replace
 // M: = Failure message string
 // F: = Find string
 // R: = Replace string
 
 while (!f.eof()) {
  var str = f.readline().trim();
  
  if (str.charAt(0) === "M") {
   msg = str.substring(2).trim();
  }
  else if (str.charAt(0) === "F") {
   str = str.substring(2).trim();
   
   if (str.charAt(0) === "'")
    str = str.substring(1,str.length-1);
   else
    str = str.toAscii();

   offset = exe.findString(str, RAW);
   if (offset === -1)
    failmsgs.push(msg);//No Match = Collect Failure message
  }
  else if (str.charAt(0) === "R" && offset !== -1) {
   str = str.substring(2).trim();
   
   if (str.charAt(0) === "'")
    exe.replace(offset, str.substring(1, str.length-1) + "\x00", PTYPE_STRING);
   else
    exe.replace(offset, str + " 00", PTYPE_HEX);

   offset = -1;
  }
 }
 f.close();
 
 //Step 3 - Dump all the Failure messages collected to FailedTranslations.txt
 if (failmsgs.length != 0) {
  var outfile = new TextFile();
  if (outfile.open(APP_PATH + "/FailedTranslations.txt", "w")) {
   for (var i=0; i< failmsgs.length; i++) {
    outfile.writeline(failmsgs[i]);
   }
  }
  outfile.close();
 }
 
 //Step 4a - Translate Taekwon Job names. Find the Langtype Check
 var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
 if (LANGTYPE === -1)
   return "Failed in Part 4 - LangType not found";
  
 var code = 
      " 83 3D" + LANGTYPE + " 00" // CMP DWORD PTR DS:[g_serviceType], 0
    + " B9 AB AB AB AB"           // MOV ECX, addr1
    + " 75 59"                    // JNZ addr2
  ;
 
 offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
 if (offset === -1)
  return "Failed in Part 4 - Translate Taekwon Job";
 
 //Step 4b - Change the JNZ to JMP so that Korean names never get assigned.
 exe.replace(offset+12, "EB", PTYPE_HEX);
 
 return true;
}