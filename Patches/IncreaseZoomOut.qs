//All three patches have same approach only differs in replaced value

function IncreaseZoomOut50Per() {
  return IncreaseZoomOut("FF 43");//510.0
}

function IncreaseZoomOut75Per() {
  return IncreaseZoomOut("4C 44");//816.0
}

function IncreaseZoomOutMax() {
  return IncreaseZoomOut("99 44");//1224.0
}

function IncreaseZoomOut(newvalue) {
  ////////////////////////////////////////////////////////
  // GOAL: Modify the Max Height from Ground = FAR_DIST //
  //       to  accomodate for larger zoom                //
  ////////////////////////////////////////////////////////
  
  //Step 1 - Find the FAR_DIST location
  var code = " 00 00 66 43 00 00 C8 43 00 00 96 43";
  var offset = exe.find(code, PTYPE_HEX, false);//Its not there in code section - so we use the generic find
  if (offset === -1)
    return "Failed in part 1";
  
  //Step 2 - Modify with the value supplied - Current value is 400.0
  exe.replace(offset+6, newvalue, PTYPE_HEX);
  
  return true;
}