//#########################################################################
//# Purpose: Add an extra loop for loading NPC names using ReqJobName Lua #
//#          function between user specified limits                       #
//#########################################################################

function IncreaseNpcIDs() {
  
  //Step 1a - Find offset of ReqJobName
  var offset = exe.findString("ReqJobName", RVA);
  if (offset === -1)
    return "Failed in Step 1 - ReqJobName not found";
  
  //Step 1b - Find its references
  var offsets = exe.findCodes("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offsets.length < 3)
    return "PaFailed in Step 1 - Some ReqJobName references missing";
  
  //Step 2a - Look for 0x190 assignment - we will jump from here
  var code = " BE 90 01 00 00";
  offset = exe.find(code, PTYPE_HEX, false, "", offsets[0], offsets[1]);
  
  if (offset === -1) {
    code = code.replace(" BE", " BF")
    offset = exe.find(code, PTYPE_HEX, false, "", offsets[0], offsets[1]);
  }
    
  if (offset === -1)
    return "Failed in Step 2 - 0x190 assignment missing";
  
  //Step 2b - Look for 0x3E9 assignment - needed to extract the loop code
  var offset2 = exe.find(code.replace(" 90 01", " E9 03"), PTYPE_HEX, false, "", offsets[1], offsets[2]);
  if (offset2 === -1)
    return "Failed in Step 2 - 0x3E9 assignment missing";
  
  //Step 3a - Prep code to insert
  code = 
    exe.fetchHex(offset, offset2 - offset) //The Loop code
  + code                                   //MOV reg32, 190
  + " E9" + GenVarHex(1)                   //JMP retAddr ; retAddr = offset + 5
  ;
  var size = code.hexlength();
  
  //Step 3b - Allocate space for it
  var free = exe.findZeros(size);
  if (free === -1)
    return "Failed in Step 3 - Not enough free space";

  //Step 3c - Get the starting and ending IDs for the Loop from user
  var lowerLimit = exe.getUserInput("$npcLower", XTYPE_DWORD, "Number input - Increase Npc IDs", "Enter Lower Limit of Npc IDs", 10000, 10000, 20000);
  var upperLimit = exe.getUserInput("$npcUpper", XTYPE_DWORD, "Number input - Increase Npc IDs", "Enter Upper Limit of Npc IDs", 11000, 10000, 20000);
  
  if (upperLimit === lowerLimit)
    return "Patch Cancelled - Lower and Upper Limits are same";

  //Step 4a - Update the limits & Direct Function CALL offsets 
  code = code.replace(" 90 01 00 00", lowerLimit.packToHex(4));
  code = code.replace(" E8 03 00 00 7C", upperLimit.packToHex(4) + " 7C");
  
  var diff = exe.Raw2Rva(free) - exe.Raw2Rva(offset + 5);
  var index = 0;
  while (index >= 0) {
    index = code.search(/ E8 .. .. .. FF/i);
    if (index !== -1) {
      code = code.replace(/ E8 .. .. .. FF/i, " E8" + (code.substr(index + 3, 12).unpackToInt() - (diff + 5)).packToHex(4));
    }
  }
  
  //Step 4b - Fill in the blanks
  code = ReplaceVarHex(code, 1, -(diff + size));
  
  //Step 4c - Insert the code in Allocated space.
  exe.insert(free, size, code, PTYPE_HEX);
  
  //Step 4d - Change the original MOV to a JMP to our code.
  exe.replace(offset, "E9" + diff.packToHex(4), PTYPE_HEX);
  
  return true;
}