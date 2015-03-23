//All Patches have the same procedure for finding code locations,
//hence we will be using a common function to achieve the results

function Disable4LetterCharnameLimit() {
  return Disable4LetterLimit(0);
}

function Disable4LetterPasswordLimit() {
  return Disable4LetterLimit(1);
}

function Disable4LetterUsernameLimit() {
  return Disable4LetterLimit(2);
}

function Disable4LetterLimit(index) {
  //////////////////////////////////////////////////////////////////////////
  // GOAL: Find the Comparisons of UserName/Password/CharName size with 4 //
  //       and replace it with 0 so any non-empty string is valid         //
  //////////////////////////////////////////////////////////////////////////
  
  //Step 1a - Find the Text Size comparisons
  var code =
      " E8 AB AB AB FF"  // CALL UIEditCtrl::GetTextSize
    + " 83 F8 04"        // CMP EAX, 4
    + " 0F AB AB AB 00"  // JL addr2
    ;
  
  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (!offsets[0])
    return "Failed in part 1 - No Results";
  
  //Step 1b - Check if at-least 2 results are there:
  // 1st = CharacterLimit
  // 2nd = Password
  
  if (!offsets[1])
    return "Failed in part 1 - Only 1 result found";
  
  //Step 2 - For options 0 & 1 (Char & Password), replace the compared value to 0
  if (index < 2) {
    exe.replace(offsets[index]+7, "00", PTYPE_HEX);
    return true;
  }
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - Can't seem to find the ID Check in the old client
  //         Need to find which client onwards it changed.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 3a - For option 2 (ID), Find the ID Comparison which is right after the Password comparison
  var code2 =
      " E8 AB AB AB FF"  // CALL UIEditCtrl::GetTextSize
    + " 83 F8 04"        // CMP EAX, 4
    ;
  var offset = exe.find(code2, PTYPE_HEX, true, "\xAB", offsets[1] + code.hexlength());
  if (offset === -1)
    return "Failed in part 3";

  //Step 3b - Now replace the compared value to 0
  exe.replace(offset+7, "00", PTYPE_HEX);
  
  return true;
}