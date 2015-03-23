function EnableCustom3DBones() {
  ////////////////////////////////////////////////////////////////////
  // GOAL: Modify the comparisons in C3dGrannyBoneRes::GetAnimation //
  //       to always use gr2 from 3dmob_bone folder                 //
  ////////////////////////////////////////////////////////////////////
  
  //Step 1 - Find location of the sprintf control string for 3d mob bones
  var mob_bone = exe.findString("model\\3dmob_bone\\%d_%s.gr2", RVA);
  if (mob_bone === -1)
    return "Failed in Part 1";
  
  //Step 2 - Find its reference which is inside C3dGrannyBoneRes::GetAnimation
  var finish = exe.findCode("68" + mob_bone.packToHex(4), PTYPE_HEX, false);
  if (finish === -1)
    return "Failed in Part 2";

  finish -= 9;
  // MOV <R32>, [ARRAY] <= Find offset of this instruction
  // PUSH <R32>
  // PUSH <R32>
  // PUSH <$mob_bone>
  
  //Step 3 - Find Limiting CMP instruction within this function before the reference.
  //         we will assume it comes within 0x70h before finish
  
  // For VC9 images the value is 09h
  var offset = exe.find(" 83 FE 09", PTYPE_HEX, false, " ", finish - 0x70, finish);
  
  if (offset === -1) //For VC6 images the value is 0A
    offset = exe.find(" 83 FE 0A", PTYPE_HEX, false, " ", finish - 0x70, finish);
  
  if (offset === -1)
    return "Failed in Part 3";
  
  offset = offset + 3;
  
  //Step 4 - Modify JA/JGE address to the code for using 3dmob_bone. Do not care about which CMP we hit,
  //         the important thing is the conditional JGE/JA after it, be it SHORT or LONG.
  //         Also let"s trust the client here, that it never calls the function with nAniIdx outside of [0;4]
  var bite = exe.fetchByte(offset);
  
  if (bite === 0x77 || bite === 0x7D) // Short Jump
    exe.replace(offset+1, (finish-offset-2).packToHex(1), PTYPE_HEX);
  else if (bite === 0x0F) // Long Jump
    exe.replace(offset+2, (finish-offset-6).packToHex(4), PTYPE_HEX);
  else
    return "Failed in Part 4";
  
  //Step 5a - Find the annoying warning - "too many vertex granny model!"
  offset = exe.findString("too many vertex granny model!", RVA);
  
  //Step 5b - Find its reference + the function call after
  if (offset !== -1)
    offset = exe.findCode(" 68" + offset.packToHex(4) + " E8", PTYPE_HEX, false);

  //Step 5c - NOP out the call
  if (offset !== -1)
    exe.replace(offset+5, " 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}