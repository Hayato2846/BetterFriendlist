--------------------------------------------------------------------------
-- AnimationHelpers.lua
-- Utility functions for creating animations
--------------------------------------------------------------------------

local ADDON_NAME, BFL = ...

-- Animation Helpers (exposed globally for use in main addon)
_G.BFL_CreatePulseAnimation = function(frame)
	if not frame.pulseAnim then
		local animGroup = frame:CreateAnimationGroup()
		
		local scale1 = animGroup:CreateAnimation("Scale")
		scale1:SetScale(1.1, 1.1)
		scale1:SetDuration(0.15)
		scale1:SetOrder(1)
		
		local scale2 = animGroup:CreateAnimation("Scale")
		scale2:SetScale(0.909, 0.909) -- Back to 1.0 (1/1.1)
		scale2:SetDuration(0.15)
		scale2:SetOrder(2)
		
		frame.pulseAnim = animGroup
	end
	return frame.pulseAnim
end

_G.BFL_CreateFadeOutAnimation = function(frame, onFinished)
	if not frame.fadeOutAnim then
		local animGroup = frame:CreateAnimationGroup()
		
		local alpha = animGroup:CreateAnimation("Alpha")
		alpha:SetFromAlpha(1.0)
		alpha:SetToAlpha(0.0)
		alpha:SetDuration(0.3)
		alpha:SetSmoothing("OUT")
		
		animGroup:SetScript("OnFinished", onFinished)
		
		frame.fadeOutAnim = animGroup
	end
	return frame.fadeOutAnim
end
