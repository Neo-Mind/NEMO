function SkipLicenseScreen() {
  ////////////////////////////////////////////////////////////////////////
  // GOAL: Modify the switch statement inside CLoginMode::OnChangeState //
  //       which handles control to License Screen code to skip it      //
  ////////////////////////////////////////////////////////////////////////
  
  //Step 1a - Find offset of "btn_disagree"
  var offset = exe.findString("btn_disagree", RVA);
  if (offset === -1)
    return "Failed in Part 1 - Unable to find btn_disagree";
    
  //Step 1b - Find it's reference . Interestingly it is only PUSHed once
  offset = exe.findCode(" 68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Part 1 - Unable to find reference to btn_disagree";
    
  //Step 2a - Find the Switch Case JMPer within 0x200 bytes before the PUSH
  offset = exe.find(" FF 24 85 AB AB AB 00", PTYPE_HEX, true, "\xAB", offset - 0x200, offset);//JMP DWORD PTR DS:[EAX*4 + refaddr]
  if (offset === -1)
    return "Failed in Part 2 - Unable to find the switch";
    
  //Step 2b - Extract the refaddr
  var refaddr = exe.Rva2Raw(exe.fetchDWord(offset + 3));//We need the raw address
  
  //Step 2c - Extract the 3rd Entry in the jumptable => Case 2. Case 0 and Case 1 are related to License Screen
  var third = exe.fetchHex(refaddr+8, 4);
  
  //Step 3 - Replace the 1st and 2nd entries with the third. i.e. Case 0 and 1 will now use Case 2
  exe.replace(refaddr, third, PTYPE_HEX);
  exe.replace(refaddr+4, third, PTYPE_HEX);
  
  return true;
}