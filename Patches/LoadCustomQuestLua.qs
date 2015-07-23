//###############################################################################
//# Purpose: Hijack Quest_function lua file loading to load lua files specified #
//#          in the input file first before loading Quest_function              #
//###############################################################################

function LoadCustomQuestLua() {
  
  //Step 1 - Check if Quest_function is being loaded (same check as below but adding again just for safety)
  var prefix = "lua files\\quest\\";
  if (exe.findString(prefix + "Quest_function", RAW) === -1)
    return "Failed in Step 1 - Quest_function not found";
  
  //Step 2a - Get the list file
  var f = new TextFile();
  if (!GetInputFile(f, "$inpQuest", 'File Input - Load Custom Quest Lua', 'Enter the Lua list file', APP_PATH))
    return "Patch Cancelled";
  
  //Step 2b - Get the filenames from the list file
  var files = [];
  var ssize = 0;
  while (!f.eof()) {
    var line = f.readline().trim();
    if (line.charAt(0) !== "/" && line.charAt(1) !== "/") {
      files.push(prefix + line);
      ssize += prefix.length + line.length + 1;
    }
  }
  f.close();

  if (files.length > 0) {
    //Step 3 - Inject the files
    var retVal = InjectLuaFiles(prefix + "Quest_function", files);
    if (typeof(retVal) === "string")
      return retVal;
  }
  
  return true;
}

//================================================================//
// Disable for Unsupported client - Quest_function not even there //
//================================================================//
function LoadCustomQuestLua_() {
  return (exe.findString("lua files\\quest\\Quest_function", RAW) !== -1);
}