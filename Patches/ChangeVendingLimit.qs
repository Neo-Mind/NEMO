//######################################################################
//# Purpose: Modify the constant used in Comparison inside the vending #
//#          related function (dont have name for it atm)              #
//######################################################################

function ChangeVendingLimit() {
  
  //Step 1a - Find the address of 1,000,000,000
  var offset = exe.findString("1,000,000,000", RVA);
  if (offset === -1)
    return "Failed in Step 1 - OneB string missing";
  
  var oneb = exe.Rva2Raw(offset);//Needed later to change the string
  
  //Step 1b - Find its reference
  var offset = exe.findCode("68" + offset.packToHex(4), PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 1 - OneB reference missing";
  
  //Step 1c - Find the comparison with 1B or 1B+1 before it
  var code = 
    " 00 CA 9A 3B" //CMP reg32_A, 3B9ACA00 (1B in hex)
  + " 7E"          //JLE SHORT addr
  ;
  var newstyle = true;
  var offset2 = exe.find(code, PTYPE_HEX, false, "", offset - 0x10, offset);
  if (offset2 === -1)
  {
    code =
      " 01 CA 9A 3B" //CMP reg32_A, 3B9ACA01 (1B+1 in hex)
    + " 7C"          //JL SHORT addr
    ;
    newstyle = false;
    offset2 = exe.find(code, PTYPE_HEX, false, "", offset - 0x10, offset);
  }
  
  if (offset2 === -1)
    return "Failed in Step 1 - Comparison missing";
  
  //Step 2a - Find the MsgString call to 0 zeny message
  code = 
    " 6A 01"          //PUSH 1
  + " 6A 02"          //PUSH 2
  + " 68 5C 02 00 00" //PUSH 25C ;Line no. 605
  ;
  offset = exe.findCode(code, PTYPE_HEX, false);
  if (offset === -1)
    return "Failed in Step 2 - MsgBox call missing";

  //Step 2b - Find the comparison before it
  if (newstyle)
  {
    code =
      " 00 CA 9A 3B" //CMP reg32_A, 3B9ACA00 (1B in hex)
    + " 7E"          //JLE SHORT addr
    ;
  }
  else
  {
    code =
      " 01 CA 9A 3B" //CMP reg32_A, 3B9ACA01 (1B+1 in hex)
    + " 7D"          //JGE SHORT addr
    ;
  }
  var offset1 = exe.find(code, PTYPE_HEX, false, "", offset - 0x80, offset);
  
  if (offset1 === -1 && newstyle) {
    code = code.replace("7E", "76");//Recent clients use JBE instead of JLE
    offset1 = exe.find(code, PTYPE_HEX, false, "", offset - 0x80, offset);
  }
  
  if (offset1 === -1)
    return "Failed in Step 2 - Comparison missing";
  
  //Step 2c - Find the Extra comparison for oldstyle clients
  if (!newstyle)
  {
    code = code.replace("7D", "75");//JNE instead of JGE
    offset = exe.find(code, PTYPE_HEX, false, offset - 0x60, offset);
    if (offset === -1)
      return "Failed in Step 2 - Extra Comparison missing";
    
    //Step 2d - Change the JNE to JMP
    exe.replace(offset + 4, "EB", PTYPE_HEX);
  }
  
  //Step 3a - Get the new value from user
  var newValue = exe.getUserInput("$vendingLimit", XTYPE_DWORD, "Number Input", "Enter new Vending Limit (0 - 2,147,483,647):", 1000000000);
  if (newValue === 1000000000)
    return "Patch Cancelled - Vending Limit not changed";

  //Step 3b - Replace the 1B string
  var str = newValue.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + '\0';
  exe.replace(oneb, str, PTYPE_STRING);

  //Step 3c - Replace the compared value
  if (!newstyle)
    newValue++;
  
  exe.replaceDWord(offset1, newValue);
  exe.replaceDWord(offset2, newValue);
  
  return true;
}

//===================================================================//
// Disable for Unneeded Clients - Only 2013+ Clients have this check //
//===================================================================//
function ChangeVendingLimit_() {
  return (exe.findString("1,000,000,000", RAW) !== -1);
}