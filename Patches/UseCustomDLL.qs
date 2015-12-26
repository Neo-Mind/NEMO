//##############################################################
//# Purpose: Create a new import table containing the existing #
//#          table and the specified DLL + functions.          #
//##############################################################

delete Import_Info;//Removing any stray values before Patches are selected
var dllFile = false;

function UseCustomDLL() {
  
  //Step 1a - Flag for "Disable HShield" patch is ON
  var hasHShield = (getActivePatches().indexOf(15) !== -1);
  
  //Step 1b - Get the current import table
  var dir = GetDataDirectory(1);
  
  //Step 1d - Loop through the table and extract to dirData. 
  //          if HShield patch is enabled then skip aossdk entry will be skipped then extracting
  var finalValue = " 00".repeat(20);
  var curValue;
  var lastDLL = "";
  var dirData = "";
  var offset = dir.offset;
  
  for ( ; (curValue = exe.fetchHex(offset, 20)) !== finalValue; offset += 20) {
    
    //Step 1e - Get the DLL Name for the import entry
    var offset2 = exe.Rva2Raw(exe.fetchDWord(offset + 12) + exe.getImageBase());
    var offset3 = exe.find("00", PTYPE_HEX, false, "", offset2);
    var curDLL = exe.fetch(offset2, offset3 - offset2);
    
    //Step 1f - Make sure there is no duplicate
    //if (curDLL === lastDLL) continue;
    
    //Step 1g - Skip aossdk if HShield is Disabled
    if (hasHShield && curDLL === "aossdk.dll") continue;
    
    dirData += curValue;
    lastDLL = curDLL;
  }
    
  //Step 2a - Get the list file containing the dlls and functions to add
  var fp = new TextFile();
  if (!dllFile)
      dllFile = GetInputFile(fp, "$customDLL", "File Input - Use Custom DLL", "Enter the DLL info file", APP_PATH + "/Input/dlls.txt");
 
  if (!dllFile)
    return "Patch Cancelled";
  
  //Step 2b - Read the file and store the dll names and function names into arrays
  var dllNames = [];
  var fnNames = [];
  var dptr = -1;
  
  while (!fp.eof()) {
    var line = fp.readline().trim();
    if (line === "" || line.indexOf("//") == 0) continue;
    if (line.length > 4 && (line.indexOf(".dll") - line.length) == -4) {
      dptr++;
      dllNames.push({"offset":0, "value":line});
      fnNames[dptr] = [];
    }
    else
      fnNames[dptr].push({"offset":0, "value":line});
  }
  fp.close();
  
  //Step 3a - Construct the String set (all the names) with the stored data
  var dirSize = dirData.hexlength();//Holds the size of Import Directory Table and IAT values
  var strData = "";
  var strSize = 0;//Holds the size of dll names and function names
  
  for (var i = 0; i < dllNames.length; i++) {
    var name = dllNames[i].value;
    dllNames[i].offset = strSize;
    strData = strData + name.toHex() + " 00";    
    strSize = strSize + name.length + 1;//Space for name
    dirSize = dirSize + 20 ;//IDIR Entry Size

    for (var j = 0; j < fnNames[i].length; j++) {
      var name = fnNames[i][j].value;

      if (name.charAt(0) === ':') {//By Ordinal
        fnNames[i][j].offset = 0x80000000 | parseInt(name.substr(1));
      }
      else {//By Name
        fnNames[i][j].offset = strSize;
        strData = strData + j.packToHex(2) + name.toHex() + " 00";
        strSize = strSize + 2 + name.length + 1;//Space for name
      
        if (name.length % 2 != 0) {//Even the Odds xD
          strData = strData + " 00";
          strSize++;
        }
      }
      
      dirSize += 4; //Thunk Value RVAs & Ordinals
    }
    dirSize += 4;//Last Value is 00 00 00 00 after Thunks
  }  
  dirSize += 20;//Accomodate for IAT End Entry

  //Step 3b - Allocate space for the above and below
  var free = exe.findZeros(strSize + dirSize);
  if (free === -1)
    return "Failed in Step 3 - Not enough free space";

  //Step 3c - Construct the new Import table
  var baseAddr = exe.Raw2Rva(free) - exe.getImageBase();
  var prefix = " 00".repeat(12);  
  var dirEntryData = "";
  var dirTableData = "";
  
  var dptr = 0;
  for (var i = 0; i < dllNames.length; i++) {
    if (fnNames[i].length == 0) continue;
    dirTableData = dirTableData + prefix + (baseAddr + dllNames[i].offset).packToHex(4) + (baseAddr + strSize + dptr).packToHex(4);
    
    for (var j = 0; j < fnNames[i].length; j++) {
      if ((fnNames[i][j].offset & 0x80000000) === 0)        
        dirEntryData = dirEntryData + (baseAddr + fnNames[i][j].offset).packToHex(4);
      else
        dirEntryData = dirEntryData + fnNames[i][j].offset.packToHex(4);
      
      dptr += 4;
    }
    dirEntryData = dirEntryData + " 00 00 00 00";
    dptr += 4;  
  }
  dirTableData = dirData + dirTableData + finalValue;
  
  //Step 4a - Insert the new table and strings
  exe.insert(free, strSize + dirSize, strData + dirEntryData + dirTableData, PTYPE_HEX);
  
  //Step 4b - Change the PE Table Import Data Directory Address
  var PEoffset = exe.find("50 45 00 00", PTYPE_HEX, false);  
  exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0x8, baseAddr + strSize + dirEntryData.hexlength() );
  exe.replaceDWord(PEoffset + 0x18 + 0x60 + 0xC, dirTableData.hexlength() - 20);

  //Step 4 - Hint for HShield Patch to not conflict with this one.
  Import_Info = {
    "offset":free, 
    "valuePre":strData + dirEntryData,
    "valueSuf":dirTableData,
    "tblAddr":baseAddr + strSize + dirEntryData.hexlength(),
    "tblSize":dirTableData.hexlength() - 20
  };

  return true;
}

//######################################################################
//# Purpose: Rerun the DisableHShield function if the HShield patch is #
//#          selected so that it doesnt accomodate for Custom DLL      #
//######################################################################
function _UseCustomDLL() {
  if (getActivePatches().indexOf(15) !== -1) {
    exe.setCurrentPatch(15);
    exe.emptyPatch(15);
    DisableHShield();
  }
  dllFile = false;
}