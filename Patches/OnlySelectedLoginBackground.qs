//===============================================================//
// Patch Functions wrapping over OnlySelectedBackground function //
//===============================================================//

function OnlyFirstLoginBackground() {//Change 2 to 1
  return OnlySelectedBackground("2", "");
}

function OnlySecondLoginBackground() {//Change 1 to 2
  return OnlySelectedBackground("", "2");
}

//###################################################################
//# Purpose: Change one of the Login Background format strings (s1) #
//#          to the other (s2)                                      #        
//###################################################################
  
function OnlySelectedBackground(s1, s2) {
  
  //Step 1a - Prep Strings to Find and Replace using s1 and s2 respectively. ( 유저인터페이스\T_배경%d-%d.bmp & 유저인터페이스\T2_배경%d-%d.bmp )
  var fnd = "\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\T" + s1 + "_\xB9\xE8\xB0\xE6" + "%d-%d.bmp";
  if (s1 === "")
    fnd  += "\x00";

  var rep = s2 + "_\xB9\xE8\xB0\xE6" + "%d-%d.bmp" + "\x00";
  
  //Step 1b - Find the source format string => s1
  var offset = exe.findString(fnd, RAW, false);
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace with the other => s2
  exe.replace(offset + 16, rep, PTYPE_STRING);
  
  return true;
}