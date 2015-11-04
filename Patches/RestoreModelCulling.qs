//#####################################################################
//# Purpose: Make models in front of player turn transparent          #
//#####################################################################

/**
 * This seems to be yet another features that never got completed.
 * 
 * Source:
 * 
 * void C3dActor::CullByOBB(lineSegment3d *ray)
 * {
 *   if (this->m_isHideCheck)
 *   {
 *     if (CheckLineSegmentOBBIntersect(ray, &this->m_oBoundingBox))
 *       this->m_node->SetAlpha();
 *   }
 * }
 * 
 * C3dActor instances are always initialized with m_isHideCheck = false. 
 * C3dNode::SetAlpha sets C3dNode::m_isAlphaForPlayer, but this variable 
 * only affects lighting and not opacity. We can instead use 
 * C3dActor::m_isHalfAlpha, which affects C3dActor::m_fadeAlphaCnt.
 * 
 * Our desired result:
 * 
 * void C3dActor::CullByOBB(lineSegment3d *ray)
 * {
 *   if (1)
 *   {
 *     if (CheckLineSegmentOBBIntersect(ray, &this->m_oBoundingBox))
 *       this->m_isHalfAlpha = 1;
 *   }
 * }
 * 
 */

function RestoreModelCulling()
{
	// 1. Locate C3dActor::CullByOBB (should be first instance in exe)

	var pBase = exe.findCode(
		" 8D 86 30 01 00 00" // lea eax, [esi+130h] (eax = &m_oBoundingBox)
	);

	if(pBase === -1)
		return "No candidates for C3dActor::CullByOBB!";

	// 2. Locate the jump on m_isHideCheck

	var jmpCodes = [" 74 1E", " 74 1F"]; // jz LOC_END
	var pJmpHideCheck = -1;

	for(var i = 0; i < jmpCodes.length; i++)
	{
		pJmpHideCheck = exe.find(
			jmpCodes[i], 
			PTYPE_HEX, 
			false, 
			"\xAB", 
			pBase - 10, 
			pBase
		);
		
		if(pJmpHideCheck !== -1)
			break;
	}

	if(pJmpHideCheck === -1)
	{
		return "Unable to locate jump condition for m_isHideCheck";
	}

	// 3. Locate call to m_node->SetAlpha()

	var pSetAlpha = exe.find(
		" 8B 0E E8",  // mov ecx, [esi]
									// call ...
		PTYPE_HEX,
		false,
		"\xAB",
		pBase + 5,
		pBase + 30
	);

	if(pSetAlpha === -1)
	{
		return "Unable to locate m_node->SetAlpha()";
	}

	// 4. Replace 

	// nop, nop
	exe.replace(pJmpHideCheck, " 90 90", PTYPE_HEX); 

	// mov byte ptr [esi+1ECh], 1h (m_isHalfAlpha = 1)
	exe.replace(pSetAlpha, " C6 86 EC 01 00 00 01", PTYPE_HEX);

	return true;
}
