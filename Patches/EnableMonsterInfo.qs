function EnableMonsterInfo() {
  ///////////////////////////////////////////////////////////////////
  // GOAL: Change the Langtype comparison jump in the Monster talk //
  //       loader function
  ///////////////////////////////////////////////////////////////////
  
  //Step 1 - Find the starting of the case
  var code = 
      " 89 BE AB AB 00 00" //MOV DWORD PTR DS:[ESI+const1], EDI ; Case 2723 of switch 
    + " 57"                //PUSH EDI 
    + " 89 3D AB AB AB 00" //MOV DWORD PTR DS:[addr1], EDI
    ;
    
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Part 1";
    
  
  //Step 2 - Swap JNE with NOP + JMP (the Comparison with 0x13 occurs at 26 bytes after offset and the JNE is at 29
  exe.replace(offset+29, " 90 E9", PTYPE_HEX);
  
  return true;
}