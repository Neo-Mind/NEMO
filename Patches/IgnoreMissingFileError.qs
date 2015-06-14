//###############################################
//# Purpose: Modify ErrorMsg function to return #
//#          without showing the MessageBox     #
//###############################################

function IgnoreMissingFileError() {//The patch skips showing error for a lot of things. Either rename or make it specific to missing files
  
  //Step 1a - Prep code for finding the ErrorMsg(msg) function
  
  var code = 
    " E8 AB AB AB FF"    // CALL GDIFlip
  + " MovEax"            // FramePointer Specific MOV
  + " 8B 0D AB AB AB AB" // MOV ECX, DWORD PTR DS:[g_hMainWnd]
  + " 6A 00"             // PUSH 0
  ;
  
  var fpEnb = HasFramePointer();
  if (fpEnb)      
    code = code.replace(" MovEax", " 8B 45 08");    // MOV EAX, DWORD PTR SS:[EBP-8]
  else
    code = code.replace(" MovEax", " 8B 44 24 04"); // MOV EAX, DWORD PTR SS:[ESP+4]
      
  //Step 1b - Find the function
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace with XOR EAX, EAX followed by RETN . If Frame Pointer is present then a POP EBP comes before RETN
  if (fpEnb)
    exe.replace(offset + 5, " 31 C0 5D C3", PTYPE_HEX);
  else
    exe.replace(offset + 5, " 31 C0 C3 90", PTYPE_HEX);

  return true;
}