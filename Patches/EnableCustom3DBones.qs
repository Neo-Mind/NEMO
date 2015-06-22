//#####################################################################
//# Purpose: Modify the comparisons in C3dGrannyBoneRes::GetAnimation #
//#       to always use gr2 from 3dmob_bone folder                    #
//#####################################################################

function EnableCustom3DBones() {
  
  //Step 1a - Find location of the sprintf control string for 3d mob bones
  var offset = exe.findString("model\\3dmob_bone\\%d_%s.gr2", RVA);
  if (offset === -1)
    return "Failed in Step 1 - String not found";
  
  //Step 1b - Find its reference which is inside C3dGrannyBoneRes::GetAnimation
  var finish = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (finish === -1)
    return "Failed in Step 1 - String reference missing";

  finish -= 9;
  // MOV <R32>, [ARRAY] <= Find offset of this instruction
  // PUSH <R32>
  // PUSH <R32>
  // PUSH <offset>
  
  //Step 2 - Find Limiting CMP instruction within this function before the reference.
  //         we will assume it comes within 0x70h before finish
  
  // For VC9 images the value is 09h
  var offset = exe.find(" 83 FE 09", PTYPE_HEX, false, " ", finish - 0x70, finish);
  
  if (offset === -1) //For VC6 images the value is 0A
    offset = exe.find(" 83 FE 0A", PTYPE_HEX, false, " ", finish - 0x70, finish);
  
  if (offset === -1)
    return "Failed in Step 2";
  
  offset += 3;
  
  //Step 3 - Modify JA/JGE address to the code for using 3dmob_bone. Do not care about which CMP we hit,
  //         the important thing is the conditional JGE/JA after it, be it SHORT or LONG.
  //         Also let"s trust the client here, that it never calls the function with nAniIdx outside of [0;4]
  switch(exe.fetchUByte(offset)) {
    case 0x77:
    case 0x7D: {// Short Jump
      exe.replace(offset + 1, (finish - offset - 2).packToHex(1), PTYPE_HEX);
      break;      
    }
    case 0x0F: {// Long Jump
      exe.replace(offset + 2, (finish - offset - 6).packToHex(4), PTYPE_HEX);
      break;
    }
    default: {
      return "Failed in Step 3";  
    }
  }
  
  //Step 4a - Find the annoying warning - 'too many vertex granny model!'
  offset = exe.findString("too many vertex granny model!", RVA);
  
  //Step 4b - Find its reference + the function call after
  if (offset !== -1)
    offset = exe.findCode(" 68" + offset.packToHex(4) + " E8", PTYPE_HEX, false);

  //Step 4c - NOP out the call
  if (offset !== -1)
    exe.replace(offset + 5, " 90 90 90 90 90", PTYPE_HEX);
  
  return true;
}