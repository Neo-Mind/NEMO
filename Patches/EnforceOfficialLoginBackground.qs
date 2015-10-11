//##################################################################
//# Purpose: Change the JZ to JMP after the LangType comparison in #
//#          CLoginMode::OnUpdate function.                        #
//##################################################################

function EnforceOfficialLoginBackground() {

  //Step 1 - Find the comparisons
  var code =
    " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 04" //CMP EAX, 04
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 08" //CMP EAX, 08
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 09" //CMP EAX, 09
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 0E" //CMP EAX, 0E
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 03" //CMP EAX, 03
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 0A" //CMP EAX, 0A
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 01" //CMP EAX, 01
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 0B" //CMP EAX, 0B
  ;

  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (offsets.length === 0)
    return "Failed in Step 1";
  
  //Step 2 - Replace first JZ to JMP for all the matches
  for (var i = 0; i < offsets.length; i++) {
    exe.replace(offsets[i], "EB", PTYPE_HEX); 
  }
  
  return true;
}