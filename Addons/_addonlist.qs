/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//Register all your Addons in this file. All addons need to be registered to appear in NEMO
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//FORMAT for registering Addon : registerAddon(functionName, description, Tooltip text);
//
//	functionName is the function called when an addon is clicked. All your logic goes inside it.
//	You can define your function in any .qs file in the Addons folder.
//	Remember the functionName needs to be in quotes (single or double) here but no quotes should be used while defining it.
//  
//  description is what shows up in the Addon menu of NEMO.
//  tooltip - text which shows detail about what a particualar tool/addon does - need to check if its actually visible.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

registerAddon("ExtractMsgTable", "Extract msgstringtable", "Extracts embedded msgstringtable from the loaded client");

registerAddon("ExtractTxtNames", "Extract txt file names", "Extracts embedded txt file names in the loaded client");

registerAddon("GetPacketKeys", "Get Packet Keys", "Retrieves the packet keys used in the loaded client for Obfuscation");

//registerAddon("GenMapEffectPlugin", "Generate Mapeffect plugin by Curiosity", "Generates Curiosity's mapeffect plugin for loaded client");
//Disabled since it needs to be fixed.