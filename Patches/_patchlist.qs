/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//Register all your Patches and Patch groups in this file. Always register group before using its id in a patch.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//FORMAT for registering group : registerGroup(group id, group Name, mutualexclude [true/false]);
//
//  If you wish that only 1 patch can be active at a time (default) put mutualexclude as true
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//FORMAT for registering patch : registerPatch(patch id, functionName, patch Name, category, group id, author, description, recommended [true/false] );
//
//  functionName is the function called when a patch is enabled. All your logic goes inside it.
//  You can define your function in any .qs file in the patches folder.
//  Remember the functionName needs to be in quotes (single or double) here but no quotes should be used while defining it.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//Currently some of the ids are not used in between - i believe because some patches were removed due to errors. Anyways dont use those ids for new ones.
//Also please keep the patches in the order of ids.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

registerGroup(  1, "ChatLimit", true);

registerPatch(  2, "AllowChatFlood", 'Chat Flood Allow', 'UI', 1, "Shinryo", 'Disable the clientside repeat limit of 3, and sets it to the specified value.', false);

registerPatch(  3, "RemoveChatLimit", 'Chat Flood Remove Limit', 'UI', 1, "Neo", 'Remove the clientside limitation which checks for maximum repeated lines.', false);

//registerPatch(  4, "EnableAuraOver", 'Enable Aura Over Level 99 And Level 150', 'UI', 0, "Shinryo", 'Allows the client to display standard auras over level 99 and 3rd class auras over level 150.', false);

registerPatch(  5, "EnableProxySupport", 'Enable Proxy Support (Experimental)', 'Fix', 0, "Ai4rei/AN", 'Ignores server-provided IP addresses when changing servers.', false);

registerPatch(  6, "ForceSendClientHash", 'Force Send Client Hash Packet (Experimental)', 'Packet', 0, "GreenBox, Neo", 'Forces the client to send a packet with it\'s MD5 hash for all langtypes. Only use if you have enabled it in your server', false);

//registerPatch(  7, "ChangeGravityErrorHandler", 'Change Gravity Error Handler', 'Fix', 0, " ", 'It changes the Gravity Error Handler Mesage for a Custom One Pre-Defined by Diff Team.', false);

registerPatch(  8, "CustomWindowTitle", 'Custom Window Title', 'UI', 0, "Shinryo", 'Changes window title. Normally, the window title is "Ragnarok".', false);

registerPatch(  9, "Disable1rag1Params", 'Disable 1rag1 type parameters', 'Fix', 0, "Shinryo", 'Enable this to launch the client directly without patching or any 1rag1, 1sak1 etc parameters.', true);

registerPatch( 10, "Disable4LetterCharnameLimit", 'Disable 4 Letter Character Name Limit', 'Fix', 0, "Shinryo", 'Will allow people to use character names shorter than 4 characters.', false);

registerPatch( 11, "Disable4LetterUsernameLimit", 'Disable 4 Letter User Name Limit', 'Fix', 0, "Shinryo", 'Will allow people to use account names shorter than 4 characters.', false);

registerPatch( 12, "Disable4LetterPasswordLimit", 'Disable 4 Letter Password Limit', 'Fix', 0, "Shinryo", 'Will allow people to use passwords shorter than 4 characters.', false);

registerPatch( 13, "DisableFilenameCheck", 'Disable Ragexe Filename Check', 'Fix', 0, "Shinryo", 'Disables the check that forces the rakexe to quit if not called "sakexe.exe" in langtype 0', true);

registerPatch( 14, "DisableHallucinationWavyScreen", 'Disable Hallucination Wavy Screen', 'Fix', 0, "Shinryo", 'Disables the Hallucination effect (screen becomes wavy and lags the client), used by baphomet, horongs, and such.', true);

registerPatch( 15, "DisableHShield", 'Disable HShield', 'Fix', 0, "Ai4rei/AN, Neo", 'Disables HackShield', true);

registerPatch( 16, "DisableSwearFilter", 'Disable Swear Filter', 'UI', 0, "Shinryo", 'The content of manner.txt has no impact on ability to send text.', false);

registerPatch( 17, "EnableOfficialCustomFonts", 'Enable Official Custom Fonts', 'UI', 0, "Shinryo", 'This option forces Official Custom Fonts (eot files int data folder) on all langtype.', false);

registerPatch( 18, "SkipServiceSelect", 'Skip Service Selection Screen', 'UI', 0, "Shinryo", 'Jumps directly to the login interface without asking to select a service.', false);

registerPatch( 19, "EnableTitleBarMenu", 'Enable Title Bar Menu', 'UI', 0, "Shinryo", 'Enable Title Bar Menu (Reduce, Maximize, Close button) and the window icon.', false);

registerPatch( 20, "ExtendChatBox", 'Extend Chat Box', 'UI', 0, "Shinryo", 'Extend the Main/Battle chat box max input chars from 70 to 234.', false);

registerPatch( 21, "ExtendChatRoomBox", 'Extend Chat Room Box', 'UI', 0, "Shinryo", 'Extend the chat room box max input chars from 70 to 234.', false);

registerPatch( 22, "ExtendPMBox", 'Extend PM Box', 'UI', 0, "Shinryo", 'Extend the PM chat box max input chars from 70 to 221.', false);

registerGroup( 23, "FixCameraAngles", true);

registerPatch( 24, "FixCameraAnglesRecomm", 'Fix Camera Angles', 'UI', 23, "Shinryo", 'Unlocks the possible camera angles to give more freedom of placement. Gives a medium range of around 60 degress', true);

registerPatch( 25, "FixCameraAnglesLess", 'Fix Camera Angles (LESS)', 'UI', 23, "Shinryo", 'Unlocks the possible camera angles to give more freedom of placement. This enables an 30deg angle ', false);

registerPatch( 26, "FixCameraAnglesFull", 'Fix Camera Angles (FULL)', 'UI', 23, "Shinryo", 'Unlocks the possible camera angles to give more freedom of placement. This enables an almost ground-level camera.', false);

registerPatch( 27, "HKLMtoHKCU", 'HKLM To HKCU', 'Fix', 0, "Shinryo", 'This makes the client use HK_CURRENT_USER registry entries instead of HK_LOCAL_MACHINE. Neccessary for users who have no admin privileges on their computer.', false);

registerPatch( 28, "IncreaseViewID", 'Increase Headgear ViewID', 'Data', 0, "Shinryo", 'Increases the limit for the headgear ViewIDs from 2000 to User Defined value (max 32000)', false);

registerGroup( 29, "IncreaseZoomOut", true);

registerPatch( 30, "IncreaseZoomOut50Per", 'Increase Zoom Out 50%', 'UI', 29, "Shinryo", 'Increases the zoom-out range by 50 percent', false);

registerPatch( 31, "IncreaseZoomOut75Per", 'Increase Zoom Out 75%', 'UI', 29, "Shinryo", 'Increases the zoom-out range by 75 percent', false);

registerPatch( 32, "IncreaseZoomOutMax", 'Increase Zoom Out Max', 'UI', 29, "Shinryo", 'Maximizes the zoom-out range', false);

registerPatch( 33, "KoreaServiceTypeXMLFix", 'Always Call SelectKoreaClientInfo()', 'Fix', 0, "Shinryo", 'Calls SelectKoreaClientInfo() always before SelectClientInfo() allowing you to use features that would be only visible on korean service type.', true);

registerPatch( 34, "EnableShowName", 'Enable /showname', 'Fix', 0, "Neo", 'Enables use of /showname command on all langtypes', true);

registerPatch( 35, "ReadDataFolderFirst", 'Read Data Folder First', 'Data', 0, "Shinryo", 'Gives the data directory contents priority over the data/sdata.grf contents.', false);

registerPatch( 36, "ReadMsgstringtabledottxt", 'Read msgstringtable.txt', 'Data', 0, "Shinryo", 'This option will force the client to read all the user interface messages from  msgstringtable.txt instead of displaying the korean messages.  (This does not fix the korean images, like buttons.)', true);

registerPatch( 37, "ReadQuestid2displaydottxt", 'Read questid2display.txt', 'Data', 0, "Shinryo", 'Makes the client to load questid2display.txt on every langtype (instead of only 0).', true);

registerPatch( 38, "RemoveGravityAds", 'Remove Gravity Ads', 'UI', 0, "Shinryo", 'Removes Gravity ads on the login background.', true);

registerPatch( 39, "RemoveGravityLogo", 'Remove Gravity Logo', 'UI', 0, "Shinryo", 'Removes Gravity Logo on the login background.', true);

registerPatch( 40, "RestoreLoginWindow", 'Restore Login Window', 'Fix', 0, "Shinryo, Neo", 'Circumvents Gravity\'s new token-based login system and restores the normal login window', true);

registerPatch( 41, "DisableNagleAlgorithm", 'Disable Nagle Algorithm', 'Packet', 0, "Shinryo", 'Disables the Nagle Algorithm.The Nagle Algorithm queues packets before they are sent in order to minimize protocol overhead. Disabling the algorithm will slightly increase network traffic, but it will decrease latency as well.', true);

registerPatch( 42, "SkipResurrectionButtons", 'Skip Resurrection Buttons', 'UI', 0, "Shinryo", 'Skip resurrection button when you die or use Token of Ziegfried.', false);

registerGroup( 43, "UseIcon", true);

registerPatch( 44, "TranslateClient", 'Translate Client', 'UI', 0, "Ai4rei/AN, Neo", 'This will translate some of the hardcoded Korean phrases with strings stored in TranslateClient.txt. It also fixes the Korean Job name issue with langtype', true);

registerPatch( 45, "UseCustomAuraSprites", 'Use Custom Aura Sprites', 'Data', 0, "Shinryo", 'This option will make it so your warp portals will not be affected by your aura sprites. For this you will have to make aurafloat.tga and auraring.bmp and place them in your "data\\texture\\effect" folder');

registerPatch( 46, "UseNormalGuildBrackets", 'Use Normal Guild Brackets', 'UI', 0, "Shinryo", 'On langtype 0, instead of square-brackets, japanese style brackets are used, this option reverts that behaviour to the normal square brackets ("[" and"]").', false);

registerPatch( 47, "UseRagnarokIcon", 'Use Ragnarok Icon', 'UI', 43, "Shinryo, Neo", 'Makes the hexed client use the RO program icon instead of the generic Win32 app icon.', false);

registerPatch( 48, "UsePlainTextDescriptions", 'Use Plain Text Descriptions', 'Data', 0, "Shinryo", 'Signals that the contents of text files are text files, not encoded.', true);

//DO NOT USE 49 - it is used by Enable Multiple GRFs 

registerPatch( 50, "SkipLicenseScreen", 'Skip License Screen', 'UI', 0, "Shinryo, MS", 'Skip the warning screen and goes directly to the main window with the Service Select.', false);

//registerPatch( 51, "UseArialOnAllLangtypes", 'Use Arial on All Langtypes', 'UI', 0, "Ai4rei/AN, Shakto", 'Makes Arial the default font on all Langtypes (it s enable ascii by default)', true);

registerPatch( 52, "UseCustomFont", 'Use Custom Font', 'UI', 0, "Ai4rei/AN", 'Allows the use of user-defined font for all langtypes. The langtype-specific charset is still being enforced, so if the selected font does not support it, the system falls back to a font that does.', false);

registerPatch( 53, "UseAsciiOnAllLangtypes", 'Use Ascii on All Langtypes', 'UI', 0, "Ai4rei/AN", 'Makes the Client Enable ASCII irrespective of font or Langtypes', true);

registerPatch( 54, "ChatColorGM", 'Chat Color - GM', 'Color', 0, "Ai4rei/AN, Shakto", 'Changes the GM Chat color and sets it to the specified value. Default value is ffff00 (a yellow color)', false);

registerPatch( 55, "ChatColorPlayerOther", 'Chat Color - Other Player', 'Color', 0, "Ai4rei/AN, Shakto", 'Changes other players Chat color and sets it to the specified value. Default value is ffffff (a white color)' );

//There is some mixup with PlayerOther patch
//registerPatch( 56, "ChatColorMain", 'Chat Color - Main', 'Color', 0, "Ai4rei/AN, Shakto", 'Changes the Main Chat color and sets it to the specified value.', false);

registerPatch( 57, "ChatColorGuild", 'Chat Color - Guild', 'Color', 0, "Ai4rei/AN, Shakto", 'Changes the Guild Chat color and sets it to the specified value. Default Value is b4ffb4 (a light green color)' );

registerPatch( 58, "ChatColorPartyOther", 'Chat Color - Other Party ', 'Color', 0, "Ai4rei/AN, Shakto", 'Changes the Other Party members Chat color and sets it to the specified value. Default value is ffc8c8 (a pinkish color)' );

registerPatch( 59, "ChatColorPartySelf", 'Chat Color - Your Party', 'Color', 0, "Ai4rei/AN, Shakto", 'Changes Your Party Chat color and sets it to the specified value. Default value is ffc800 (An orange color)' );

registerPatch( 60, "ChatColorPlayerSelf", 'Chat Color - Self', 'Color', 0, "Ai4rei/AN, Shakto", 'Changes your character\'s Chat color and sets it to the specified value. Default value is 00ff00 (a green color)', false);

registerPatch( 61, "DisablePacketEncryption", 'Disable Packet Encryption', 'UI', 0, "Ai4rei/AN", 'Disable kRO Packet_ID Encryption. Also known as Skip Packet Obfuscation', true);

registerPatch( 63, "UseOfficialClothPalette", 'Use Official Cloth Palettes', 'UI', 0, "Neo", 'Use Official Cloth Palette on all Langtypes. Do not use this if you are using the "Enable Custom Jobs" patch', false);

registerPatch( 64, "FixChatAt", '@ Bug Fix', 'UI', 0, "Shinryo", 'Correct the bug to write @ in chat', true);

registerPatch( 65, "ItemInfo", 'Load Custom lua file instead of iteminfo.lub', 'UI', 0, "Neo", 'Makes the client load your own lua file instead of iteminfo.lub . If you directly use ItemInfo.lub for your translated items, it may become lost during the next kRO update', false);

registerPatch( 67, "DisableQuakeEffect", 'Remove Quake skill effect', 'UI', 0, "Ai4rei/AN", ' ', false);

registerPatch( 68, "Enable64kHairstyle", 'Enable 64k Hairstyle', 'UI', 0, "Ai4rei/AN", 'Enable 64k hairstyle instead 27 by default', false);

registerPatch( 69, "ExtendNpcBox", 'Extend Npc Dialog Box', 'UI', 0, "Ai4rei/AN", 'Increases max input chars of NPC dialog boxes from 2052 to 4096', false);

registerPatch( 71, "IgnoreMissingFileError", 'Ignore Missing File Error', 'Fix', 0, "Shinryo", 'Prevents the client from displaying error messages about missing files. - it does not guarantee client will not crash if files are missing', false);

registerPatch( 72, "IgnoreMissingPaletteError", 'Ignore Missing Palette Error', 'Fix', 0, "Shinryo", 'Prevents the client from displaying error messages about missing palettes. - it does not guarantee client will not crash if files are missing', false);

registerPatch( 73, "RemoveHourlyAnnounce", 'Remove Hourly Announce', 'UI', 0, "Ai4rei/AN", 'Remove hourly game grade and hourly play time minder announcements', true);

registerPatch( 74, "IncreaseScreenshotQuality", 'Increase Screenshot Quality', 'UI', 0, "Ai4rei/AN", 'Allows changing the JPEG quality parameter for screenshots.', false);

registerPatch( 75, "EnableFlagEmotes", 'Enable Flag Emoticons', 'UI', 0, "Neo", 'Enable Selected Flag Emoticons for all langtypes. You need to specify a txt file as input with the flag constants assigned to 1-9', false);

registerPatch( 76, "EnforceOfficialLoginBackground", 'Enforce Official Login Background', 'UI', 0, "Shinryo", 'Enforce Official Login Background for all langtype', false);

registerPatch( 77, "EnableCustom3DBones", 'Enable Custom 3D Bones', 'Data', 0, "Ai4rei/AN", 'Enables the use of custom 3D monsters (Granny) by lifting hardcoded ID limit.', false);

registerGroup( 78, "SharedBodyPalettes", true)

registerPatch( 79, "SharedBodyPalettesV2", 'Shared Body Palettes Type2', 'UI', 78, "Ai4rei/AN, Neo", 'Makes the client use a single cloth palette set (body_%d.pal) for all job classes both genders', false);

registerPatch( 80, "SharedBodyPalettesV1", 'Shared Body Palettes Type1', 'UI', 78, "Ai4rei/AN, Neo", 'Makes the client use a single cloth palette set (body_%s_%d.pal) for all job classes but seperate for both genders', false);

registerGroup( 81, "SharedHeadPalettes", true);

registerPatch( 82, "SharedHeadPalettesV1", 'Shared Head Palettes Type1', 'UI', 81, "Ai4rei/AN, Neo", 'Makes the client use a single hair palette set (head_%s_%d.pal) for all job classes but seperate for both genders', false);

registerPatch( 83, "SharedHeadPalettesV2", 'Shared Head Palettes Type2', 'UI', 81, "Ai4rei/AN, Neo", 'Makes the client use a single hair palette set (head_%d.pal) for all job classes both genders', false);

registerPatch( 84, "RemoveSerialDisplay", 'Remove Serial Display', 'UI', 0, "Shinryo", 'Removes the display of the client serial number in the login window (bottom right corner).', true);

registerGroup( 85, "OnlySelectedLoginBackground", true);

registerPatch( 86, "OnlyFirstLoginBackground", 'Only First Login Background', 'UI', 85, "Shinryo", 'Displays always the first login background.', false);

registerPatch( 87, "OnlySecondLoginBackground", 'Only Second Login Background', 'UI', 85, "Shinryo", 'Displays always the second login background.', false);

registerPatch( 88, "AllowSpaceInGuildName", 'Allow space in guild name', 'UI', 0, "Shakto", 'Allow player to create a guild with space in the name (/guild "Space Name").', false);

registerPatch( 90, "EnableDNSSupport", 'Enable DNS Support', 'UI', 0, "Shinryo", 'Enable DNS support for clientinfo.xml', true);

registerGroup( 91, "PacketEncryptionKeys", false);

registerPatch( 92, "PacketFirstKeyEncryption", 'Packet First Key Encryption', 'Packet', 91, "Shakto, Neo", 'Change the 1st key for packet encryption. Dont select the patch Disable Packet Header Encryption if you are using this. Don\'t use it if you don\'t know what you are doing. (Not available yet on rathena)', false);

registerPatch( 93, "PacketSecondKeyEncryption", 'Packet Second Key Encryption', 'Packet', 91, "Shakto, Neo", 'Change the 2nd key for packet encryption. Dont select the patch Disable Packet Header Encryption if you are using this. Don\'t use it if you don\'t know what you are doing. (Not available yet on rathena)', false);

registerPatch( 94, "PacketThirdKeyEncryption", 'Packet Third Key Encryption', 'Packet', 91, "Shakto, Neo", 'Change the 3rd key for packet encryption. Dont select the patch Disable Packet Header Encryption if you are using this. Don\'t use it if you don\'t know what you are doing. (Not available yet on rathena)', false);

registerPatch( 95, "UseSSOLogin", 'Use SSO Login Packet', 'Packet', 0, "Ai4rei/AN", 'Enable using SSO packet on all langtype (to use login and pass with a launcher)', false);

registerPatch( 96, "RemoveGMSprite", 'Remove GM Sprites', 'UI', 0, "Neo", 'Remove the GM sprites and keeping all the functionality like yellow name and admin right click.', false);

registerPatch( 97, "CancelToLoginWindow", 'Cancel to Login Window', 'Fix', 0, "Neo", 'Makes clicking the Cancel button in Character selection window return to login window instead of Quitting', true);

registerPatch( 98, "DisableDCScream", 'Disable dc_scream.txt', 'UI', 0, "Neo", 'Disable chat on file dc_scream', false);

registerPatch( 99, "DisableBAFrostJoke", 'Disable ba_frostjoke.txt', 'UI', 0, "Neo", 'Disable chat on file ba_frostjoke', false);

registerPatch(100, "DisableMultipleWindows", 'Disable Multiple Windows', 'UI', 0, "Shinryo, Ai4rei/AN", 'Prevents the client from creating more than one instance on all lang types. Currently has small bug - when closing client stale process remains', false);

registerGroup(101, "MultiGRFs", true);

registerPatch(102, "FixTetraVortex", 'Fix Tetra Vortex', 'UI', 0, "sanosan33, Neo", 'Fixes the black screen animation issue of tetra vortex', false);

registerPatch(103, "DisableAutofollow", 'Disable Auto follow', 'UI', 0, "Functor, Neo", 'Disables player autofollow on Shift+Right click', false);

registerPatch( 49, "EnableMultipleGRFs", 'Enable Multiple GRFs', 'UI', 101, "Shinryo", 'Enables the use of multiple grf files by putting them in a data.ini file in your client folder.You can only load up to 10 total grf files with this option (0-9).', true);

// Starting special customs from 200
registerPatch(200, "EnableMultipleGRFsV2", 'Enable Multiple GRFs - Embedded', 'UI', 101, "Neo", 'Enables the use of multiple grf files without needing INI file in client folder. Instead you specify the INI file as input to the patch.', false);

registerPatch(201, "EnableCustomHomunculus", 'Enable Custom Homunculus', 'Custom', 0, "Neo", 'Enables the addition of Custom Homunculus using Lua Files.', false);

registerPatch(202, "EnableCustomJobs", 'Enable Custom Jobs', 'Custom', 0, "Neo", 'Enables the use of Custom Jobs (using Lua Files similar to Xray)', false);

registerPatch(203, "EnableCustomShields", 'Enable Custom Shields', 'Custom', 0, "Neo", 'Enables the use of Custom Shield Types using Lua Files', false);

registerPatch(204, "IncreaseAtkDisplay", 'Increase Attack Display', 'Custom', 0, "Neo", 'Increases the limit of digits displayed while attacking from 6 to 10', false);

registerPatch(205, "EnableMonsterInfo", 'Enable Monster tables', 'Custom', 0, "Ind, Neo", 'Enables Loading of MonsterTalkTable.xml, PetTalkTable.xml & MonsterSkillInfo.xml for all langtypes.', false);

registerPatch(206, "LoadCustomQuestLua", 'Load Custom Quest Lua/Lub files', 'Custom', 0, "Neo", 'Enables loading of custom lua files used for quests. You need to specify a txt file containing list of files in the lua files\\quest folder to load (one file per line).', false);

registerPatch(207, "ResizeFont", "Resize Font", 'Custom', 0, "Yommy, Neo", 'Resizes the height of the font used to the value specified.', false);

//registerPatch(208, "ExtractStrings", "Extract it bitch", 'Custom', 0, "Neo", 'No Description meh', false);

registerPatch(209, "EnableMailBox", "Enable Mail Box for All Langtypes", 'Custom', 0, "Neo", 'Enables the full use of Mail Boxes and @mail commands (write is disabled for few langtypes by default in 2013 Clients)', false);

registerPatch(210, "UseCustomIcon", "Use Custom Icon", "Custom", 43, "Neo", 'Makes the hexed client use the User specified icon. Icon file should have an 8bpp (256 color) 32x32 image', false);

registerPatch(211, "UseCustomDLL", "Use Custom DLL", "Custom", 0, "Neo", 'Makes the hexed client load the specified DLL and functions');