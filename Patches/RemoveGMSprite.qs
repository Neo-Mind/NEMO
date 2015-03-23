function RemoveGMSprite() {
  ///////////////////////////////////////////////////////
  // GOAL: Disable switching to GM Spr & Act files for //
  //       Admin ids inside CPc::SetSprNameList        //
  ///////////////////////////////////////////////////////
  
  //Step 1a - Find offset of GM spr file
  var code = "인간족\\운영자\\운영자2_남_검.Spr";
  var offset =  exe.findString(code, RVA) .packToHex(4);
  
  //Step 2 - Do the modification for sprite
  var ret = helper_RGMS(offset);
  if (ret !== "Completed")
    return ret + "for spr";
  
  //Step 1b - Find offset of GM act file
  code = "인간족\\운영자\\운영자2_남_검.Act";
  offset =  exe.findString(code, RVA) .packToHex(4);
  
  //Step 2 - Do the modification for act
  ret = helper_RGMS(offset);
  if (ret !== "Completed")
    return ret + "for act";
  
  return true;
}

function helper_RGMS(offset) {
  //Step 2a - Find the string PUSH
  var finish = exe.findCode(" 68" + offset, PTYPE_HEX, false);
  if (finish === -1)
    return "Failed in Step 2 - Reference not found";
  
  //Step 2b - Find Pattern within boundary from finish (lets say within 0x200 bytes)
  var code =    
      " 83 C4 04"          // ADD ESP, 4
    + " 84 C0"             // TEST AL, AL
    + " 0F 84 AB AB 00 00" // JZ addr -> skipping GM sprite override
    ;

  var location = exe.find(code, PTYPE_HEX, true, "\xAB", finish - 0x200, finish);
  if (location === -1) 
    return "Failed in Step 2 - Pattern not found";
  
  //Step 2c - Change JZ to JMP
  exe.replace(location+5, " 90 E9", PTYPE_HEX);
  
  return "Completed";
}