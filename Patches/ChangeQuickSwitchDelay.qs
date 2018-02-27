// Change hardcoded quick item switch delay
// Author: mrjnumber1
function ChangeQuickSwitchDelay() {
  var tick = 10;
  var tick_ms = tick*1000;
  var code = 
    " 3D " + tick_ms.packToHex(4) // CMP eax, 10000
  + " 0F 83 AB AB 00 00"          // JNB addr
  + " 8B AB AB AB AB 00"          // MOV r32, g_qsTick
  ;
  
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  
  if (offsets.length === 0) {
    code = code.replace(" 8B AB AB AB AB 00", " 8B AB AB AB AB 01");
	offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  }
  
  var size = offsets.length;
  
  if (size === 0) 
    return "Failed in Step 1 - Find Quickswitch Tick";
  
  var g_qsTick = exe.fetchDWord(offsets[0]+13);

  var new_tick = exe.getUserInput("$my_new_tick", XTYPE_BYTE, "Number - (0-255)", "Enter the new Quickswitch delay", tick, 0, 255);
  if (tick == new_tick)
    return "Patch Cancelled - New value is same as old";

  var new_tick_ms = new_tick * 1000;
	
  for (i=0; i < size; ++i)
  {
    // replace the first found values
	exe.replace(offsets[i]+1, new_tick_ms.packToHex(4), PTYPE_HEX);
	
	// replace the later values that are shown in the chat window
	// "n seconds to next quick switch ..."
    var start = offsets[i]+17;
	var end = start + 50;
	code = " B8" + tick.packToHex(4); // MOV eax, 10 
    var offset = exe.find(code, PTYPE_HEX, true, "\xAB", start, end);
	if (offset === -1) 
      return "Failed in Step 2 - Find delay subtraction for spot " + i;
    exe.replace(offset+1, new_tick.packToHex(4), PTYPE_HEX);
  
  }
  
  // for when opening the full equip window - although the
  // status of the quickswitch button doesn't reload
  // when the time is expired anyways.. oh well.
  
  // find the first use of g_qsTick
  code = " 8B AB " + g_qsTick.packToHex(4); // MOV r32, g_qsTick
  var ui_offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (ui_offset === -1)
    return "Failed in Step 3a - Find UI quickswitch offset";
  
  // find the comparison to the default tick_ms value
  code = " 3D " + tick_ms.packToHex(4); // CMP eax, tick_ms (default)
  offset = exe.find(code, PTYPE_HEX, true, ui_offset+6, ui_offset+30);
  if (offset === -1)
    return "Failed in Step 3b - Find Compare to " + tick_ms;
  
  exe.replace(offset + 1, new_tick_ms.packToHex(4), PTYPE_HEX);
}

//==============================//
// Disable for Unsupported date //
//==============================//
function ChangeQuickSwitchDelay_() {
  return (exe.getClientDate() >= 20170517);
}
