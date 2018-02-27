// When an in-game setting that requires a restart to take effect is changed,
// the client tries to launch ro.gnjoy.com. This patch disables the behavior.
// Author: mrjnumber1
function DisableKroSiteLaunch() {

  //Step 1 - Find offset of ro.gnjoy.com
  var offset = exe.findString("ro.gnjoy.com", RAW);
  if (offset === -1)
    return "Failed in Step 1";
  
  //Step 2 - Replace with Zero
  exe.replace(offset, "00", PTYPE_HEX);
  
  return true;
}
