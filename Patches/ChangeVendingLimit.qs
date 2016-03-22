//######################################################################
//# Purpose: Modify the constant used in Comparison inside the vending #
//#          related function (dont have name for it atm)              #
//######################################################################

function ChangeVendingLimit() {
  
  //Step 1a - Find the call to ErrorMsg function which uses the 1Billion limit message
  var code = 
    " 6A 01"          //PUSH 1
  + " 6A 02"          //PUSH 2
  + " 68 A4 09 00 00" //PUSH 9A4 ;Line no. 2469
  ;
  var offsets = exe.findCodes(code, PTYPE_HEX, false);
  
  if (offsets.length === 0) {
    code = code.replace(" A4", " A3");//Newer clients have msgstring at line no. 9468
    offsets = exe.findCodes(code, PTYPE_HEX, false);
  }
  
  if (offsets.length === 0)
    return "Failed in Step 1 - Message Box call missing";
  
  //Step 1b - Among the multiple matches find the one where there is a comparison with 1 Billion (0x3B9ACA00) before the call 
  for (var i = 0; i < offsets.length ; i++) {
    var offset = exe.find("00 CA 9A 3B", PTYPE_HEX, false, "", offsets[i] - 24, offsets[i] - 12);
    if (offset !== -1)
      break;
  }
  
  if (offset === -1)
    return "Failed in Step 1 - Comparison missing";
  
  //Step 2a - Get the new value from user
  var newValue = exe.getUserInput("$vendingLimit", XTYPE_DWORD, "Number Input", "Enter new Vending Limit (0 - 2,147,483,647):", 1000000000);
  if (newValue === 1000000000)
    return "Patch Cancelled - Vending Limit not changed";

  //Step 2b - Replace the compared value
  exe.replace(offset, "$vendingLimit", PTYPE_STRING);

  //Step 2c - Find the second instance of 1 Billion after the ErrorMsg function call
  code = 
    " 6A 0A"          //PUSH 0A
  + " 8D AB AB"       //LEA reg32_A, SS:[EBP-x]
  + " AB"             //PUSH reg32_A
  + " AB 00 CA 9A 3B" //MOV reg32_B, 3B9ACA00 ; Hex of 1000000000
  ;
  
  offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset + 0x30, offset + 0x50);
  if (offset === -1)
    return "Failed in Step 2";
  
  //Step 2d - Modify that one too
  exe.replace(offset + code.hexlength() - 4, "$vendingLimit", PTYPE_STRING);
  
  return true;
}

//===================================================================//
// Disable for Unneeded Clients - Only 2013+ Clients have this check //
//===================================================================//
function ChangeVendingLimit_() {
  return (exe.getClientDate() > 20130618);
}