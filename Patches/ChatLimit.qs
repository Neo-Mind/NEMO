//Both Patches have the same procedure for finding code location,
//hence we will be using a common function to achieve the results

function RemoveChatLimit() {
  return ChatLimit(0);
}

function AllowChatFlood() {
  return ChatLimit(1);
}

function ChatLimit(option) {
  ///////////////////////////////////////////////////////////////
  //GOAL: Find the Comparison in the ::IsSameSentence function //
  //      and change the reference value of 2 or to remove the //
  //      limit, change the conditional jump to regular jmp    //
  //      after the comparison.                                //
  ///////////////////////////////////////////////////////////////
  
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  //To Do - Old clients don"t have either patterns. Need to Find 
  //        which client date onwards the first pattern starts.
  //;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  //Step 1a - Get the comparison pattern (changes for different client dates because of ebp/esp shift)
  
  var LANGTYPE = getLangType();//Langtype value overrides Service settings hence they use the same variable - g_serviceType
  if (LANGTYPE === -1)
    return "Failed in Part 1 - LangType not found";
    
  if (exe.getClientDate() <= 20130605) {
    var code = 
      " 83 3D" + LANGTYPE + " 0A" //CMP DWORD PTR DS:[g_serviceType], 0A
    + " 74 AB"                    //JE SHORT addr
    + " 83 7C 24 04 02"           //CMP DWORD PTR SS:[ARG.1], 02
    + " 7C AB"                    //JL SHORT addr
    + " 6A 00"                    //PUSH 0
    ;

    var hexoff = 13;//position of 02 in the above code
  }
  else {
  
    var code = 
      " 83 3D" + LANGTYPE + " 0A" //CMP DWORD PTR DS:[g_serviceType], 0A
    + " 74 AB"                    //JE SHORT addr
    + " 83 7D 08 02"              //CMP DWORD PTR SS:[ARG.1], 02
    + " 7C AB"                    //JL SHORT addr
    + " 6A 00"                    //PUSH 0
    ;

    var hexoff = 12;//position of 02 in the above code
  }
  
  //Step 1b - Now Search for the pattern chosen
  var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
  if (offset === -1)
    return "Failed in Step 1";
  
  if (option === 1) {
    //Step 2a - Get new value from user
    exe.getUserInput("$allowChatFlood", XTYPE_BYTE, "Number Input", "Enter new chat limit (0-127, default is 3):", 3, 0, 127);  
    
    //Step 2b - Replace 02 with new value
    exe.replace(offset+hexoff, "$allowChatFlood", PTYPE_STRING);
  }
  else {  
    //Step 2 - Replace JL with JMP
    exe.replace(offset+hexoff+1, "EB", PTYPE_HEX);
  }
  return true;
}