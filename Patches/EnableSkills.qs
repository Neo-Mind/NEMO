///=====================================================///
/// Patch Functions wrapping over EnableSkills function ///
///=====================================================///

SKL = //Used for Enable*Skills patches
{
    "Offset"    : -1,
    "Prefix"    : "",
    "PatchID"   : false,
    "Error"     : false
}

function EnablePlayerSkills()
{
    return EnableSkills(
        " 3D 7D 02 00 00"    //CMP EAX, 27D
    +   " 0F 8F AB AB 00 00" //JG addr
    +   " 3D 7C 02 00 00"    //CMP EAX, 27C
    ,
        " 3D 06 01 00 00"    //CMP EAX, 106
    +   " 7F AB"             //JG SHORT addr
    +   " 0F 84 AB AB 00 00" //JE addr2
    ,
    233,
    "IsPlayerSkill\0",
    true
    );
}

function EnableHomunSkills() //Incomplete
{
    return EnableSkills(
        " 3D 40 1F 00 00" //CMP EAX, 1F40
    +   " 7C AB"          //JL SHORT addr
    +   " 3D 51 1F 00 00" //CMP EAX, 1F51
    ,
        " 05 C0 E0 FF FF" //ADD EAX, -1F40
    +   " B9 2C 00 00 00" //MOV ECX, 2C
    ,
    234,
    "IsHomunSkill\0",
    false
    );
}

function EnableMerceSkills() //Incomplete
{
    return EnableSkills(
        " 3D 08 20 00 00" //CMP EAX, 2008
    +   " 7C AB"          //JL SHORT addr
    +   " 3D 31 20 00 00" //CMP EAX, 2031
    ,
        " 8D AB F8 DF FF FF" //LEA reg32_B, [reg32_A - 2008]
    +   " 83 AB 29"          //CMP reg32_B, 29
    ,
    235,
    "IsMercenarySkill\0",
    false
    );
}

//###############################################################\\
//# Modify the respective Skill ID checker function (returns 1) #\\
//# to use Custom Lua functions instead of hardcoded tables     #\\
//###############################################################\\

function EnableSkills(oldPatn, newPatn, patchID, funcName, isPlayerFn)
{
    //Step 1.1 - Prep the code to find the Skill ID checker function
    if (exe.getClientDate() < 20100817)
        var code = oldPatn; //VC6
    else
        var code = newPatn; //VC9+
    
    //Step 1.2 - Find the code inside the function
    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    if (offset === -1)
        return "Failed in Step 1 - ID checker missing";
    
    //Step 1.3 - Get the Function Address (will be a few bytes before offset)
    if (HasFramePointer())
        var fnBegin = offset - 6;//Account for PUSH EBP; MOV EBP, ESP and MOV EAX, DWORD PTR SS:[EBP+8]
    else
        var fnBegin = offset - 3;//Account for MOV EAX, DWORD PTR SS:[ESP+4]

    //Step 2 - Inject Lua file Loaders
    if (isPlayerFn)//Player Function is big enough to put all the code there instead of DIFF section
        LoadSkillTypeLua(patchID, fnBegin + 0x100);
    else
        LoadSkillTypeLua(patchID);
    
    if (typeof(SKL.Error) === "string")
        return "Failed in Step 2 - " + SKL.Error;
    
    if (isPlayerFn)
    {
        //Step 3.1 - Prep Lua Function caller
        code =
            " 8B 44 24 04"  //MOV EAX, DWORD PTR SS:[ARG.1]
        +   GenLuaCaller(fnBegin + 4, funcName, exe.Raw2Rva(fnBegin + 0x80), "d>d", " 50")
        +   " C3"           //RETN ; AL is already set
        ;
        
        //Step 3.2 - Overwrite function with our code
        exe.replace(fnBegin, code, PTYPE_HEX);

        //Step 3.3 - Add the function Names after the codes
        exe.replace(fnBegin + 0x80, funcName, PTYPE_STRING);
    }
    else
    {
        //Step 4.1 - Find Free space for insertion considering max size
        var free = exe.findZeros(funcName.length + 0x3D + 1);//for RETN
        if (free === -1)
            return "Failed in Step 4 - Not enough free space";
        
        //Step 4.2 - Prep function which calls the Lua function
        code =
            funcName.toHex()
        +   GenLuaCaller(free, funcName, exe.Raw2Rva(fnBegin + 0x10), "d>d", " 52")
        +   " C3" //RETN
        ;
        
        //Step 4.3 - Insert at free space
        exe.insert(free, code.hexlength(), code, PTYPE_HEX);
        
        //Step 4.4 - Prep code which calls the above
        code = 
            " 52"                //PUSH EDX
        +   " 8B 54 24 08"       //MOV EDX, DWORD PTR SS:[ESP+8]
        +   " E8" + GenVarHex(1) //CALL ourFunc
        +   " 5A"                //POP EDX
        +   " C2 04 00"          //RETN 4
        ;
        code = ReplaceVarHex(code, 1, exe.Raw2Rva(free + funcName.length) - exe.Raw2Rva(fnBegin + 10));

        //Step 4.5 - Overwrite original function
        exe.replace(fnBegin, code, PTYPE_HEX);
    }
    return true;
}

///======================================================///
/// Patch Functions wrapping over _EnableSkills function ///
///======================================================///

function _EnablePlayerSkills()
{
    _EnableSkills(233);
}

function _EnableHomunSkills()
{
    _EnableSkills(234);
}

function _EnableMerceSkills()
{
    _EnableSkills(235);
}

//#########################################################\\
//# Make sure atleast one of the other active patches are #\\
//# loading the lua files                                 #\\
//#########################################################\\

function _EnableSkills(patchID)
{
    if (SKL.PatchID === patchID)
    {
        SKL.PatchID = false;
        for (var id = 229; id <= 231; id++)
        {
            if (id !== patchID && RefreshPatch(id))
                break;
        }
    }
}

//################################################################################\\
//# Helper function which injects skill lua file loading and also fills SKL hash #\\
//################################################################################\\

function LoadSkillTypeLua(id, offset)
{
    if (SKL.Prefix === "")
    {
        SKL.Prefix = "Lua Files\\SkillInfo";
        if (exe.getClientDate() >= 20100817)
            SKL.Prefix += "z";
    }
    
    if (!SKL.PatchID)
    {
        SKL.Offset = InjectLuaFiles(
            SKL.Prefix + "\\SkillInfo_F",
            [
                SKL.Prefix + "\\SkillType",
                SKL.Prefix + "\\SkillType_F"
            ],
            offset
        );
        if (typeof(SKL.Offset) === "string")//Error was returned
        {
            SKL.Error = SKL.Offset;
            SKL.Offset = -1;
        }
        else
        {
            SKL.Error = false;
            SKL.PatchID = id;
        }
    }
}