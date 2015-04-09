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
  
  //Step 1a - Prep code to find Corresponding Text Size comparison.
  var count = 2;//Char Create & Rename checks
  var code = " 8B AB AB"; // MOV ECX, DWORD PTR DS:[reg32_B + const]
  
  if (index !== 0) {
    count = 1;//Same Area for ID & Password
    code += " 83 C4 AB"; // ADD ESP, const2
  }
  
  var fourloc = code.hexlength() + 7;
  
  code +=
      " E8 AB AB AB FF"  // CALL UIEditCtrl::GetTextSize
    + " 83 F8 04"        // CMP EAX, 4
    + " 0F AB AB AB 00 00"  // JL addr2
    ;
  
  //Step 1b - Find the Text Size comparison  
  var offset = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (offset.length !== count)
    return "Failed in part 1";
  
  //Step 2 - For options 0 & 1 (Char & Password), replace the compared value (4) to 0
  if (index < 2) {
    for (var i = 0; i < count; i++) {
      exe.replace(offset[i] + fourloc, "00", PTYPE_HEX);
    }
    return true;
  }
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  // To Do - Can't seem to find the ID Check in the old client
  //         Need to find which client onwards it changed.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 3a - For option 2 (ID), Find the ID Comparison which is right after the Password comparison
  code =
      " E8 AB AB AB FF"  // CALL UIEditCtrl::GetTextSize
    + " 83 F8 04"        // CMP EAX, 4
    ;
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset + fourloc);
  if (offset === -1)
    return "Failed in part 3";

  //Step 3b - Now replace the compared value (4) to 0
  exe.replace(offset+7, "00", PTYPE_HEX);
  
  return true;
}