//Both Patches use same procedure only the file name varies

function DisableBAFrostJoke() {
  return DisableChatInSkill("BA_frostjoke.txt");
}

function DisableDCScream() {
  return DisableChatInSkill("DC_scream.txt");
}

function DisableChatInSkill(txtname) {
  //////////////////////////////////////////////////
  // GOAL: Zero out the txt file strings used in  //
  //       random Chat skills - Frost Joke/Scream //
  //////////////////////////////////////////////////
  
  //Step 1a - Find the 1st text file offset 
  var offset = exe.findString("english\\" + txtname, RAW);
  if (offset === -1)
    return "Failed in Part 1";
  
  //Step 1b - Zero it out
  exe.replace(offset, "00", PTYPE_HEX);
  
  //Step 2a - Find the 2nd one
  offset = exe.findString(txtname, RAW);
  if (offset === -1)
    return "Failed in Part 2";
  
  //Step 2b - Zero it out
  exe.replace(offset, "00", PTYPE_HEX);
  
  return true;
}