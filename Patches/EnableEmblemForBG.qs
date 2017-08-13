//###################################################################################\\
//# Modify the Siege mode & BG mode check Jumps to Display Emblem when either is ON #\\
//###################################################################################\\

function EnableEmblemForBG()
{
    //Step 1.1 - Look for the Mode checking pattern
    var code =
        " B9 AB AB AB 00" //MOV ECX, OFFSET g_session
    +   " E8 AB AB AB 00" //CALL CSession::IsSiegeMode
    +   " 85 C0"          //TEST EAX, EAX
    +   " 74 AB"          //JZ SHORT addr
    +   " B9 AB AB AB 00" //MOV ECX, OFFSET g_session
    +   " E8 AB AB AB 00" //CALL CSession::IsBgMode
    +   " 85 C0"          //TEST EAX, EAX
    +   " 75 AB"          //JNZ SHORT addr ;AB at the end is needed
    ;
    
    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset === -1)
        return "Failed in Step 1";
 
    //Step 1.2 - Calculate the code size & its half (will point to the second MOV ECX when added to offset)
    var csize = code.hexlength();
    var hsize = csize/2;
    
    //Step 2.1 - Change the first JZ to JNZ and addr to location after the code
    exe.replace(offset + hsize - 2, "75" + hsize.packToHex(1), PTYPE_HEX);
    
    //Step 2.2 - Change the second JNZ to JZ
	exe.replace(offset + csize - 2, "74", PTYPE_HEX);
    return true;
}
