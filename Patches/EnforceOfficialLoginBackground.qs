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
  + " 83 F8 AB" //CMP EAX, const
  + " 74 AB"    //JZ SHORT addr -> prep for UIWindowMgr::RenderTitleGraphic
  + " 83 F8 03" //CMP EAX, 03
  ;

  var offsets = exe.findCodes(code, PTYPE_HEX, true, "\xAB");
  if (offsets.length !== 2)
    return "Failed in Step 1";
  
  //Step 2 - Replace first JZ to JMP for the first match
  exe.replace(offsets[0], "EB", PTYPE_HEX);
  
  return true;
}