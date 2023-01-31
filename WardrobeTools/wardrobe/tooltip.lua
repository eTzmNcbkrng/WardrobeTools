--[[

	Martin Karer / Sezz, 2016
	Adds known/unknown information to all item tooltips

--]]

local addonName, ns = ...;
local S, C;
if (SezzUI) then
	S, C = unpack(SezzUI);
else
	S, C = ns.S, ns.C;
end

if (addonName == "WardrobeTools" and SezzUI) then return; end
if (addonName == "WardrobeTools") then return; end -- Disabled in standalone version

-----------------------------------------------------------------------------

-- WoW API/Constants
local TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN, TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN, TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN;

-- Text
local tooltipAppearanceUnusable = "You can't collect this appearance";
local tooltipSuffix = "!"; -- Makes it easier to tell if Blizzard added the text or we did...

-- Colors
local colorKnownR, colorKnownG, colorKnownB = 170/255, 255/255, 126/255;
local colorMissingR, colorMissingG, colorMissingB = 136/255, 170/255, 255/255;
local colorInvalidR, colorInvalidG, colorInvalidB = 255/255, 170/255, 126/255;

-----------------------------------------------------------------------------
-- Tooltip hooks
-----------------------------------------------------------------------------

local OnTooltipSetItemHook = function(self)
	local _, itemLink = self:GetItem();
	if (not itemLink) then return; end

	local canTransmog, noSourceReason = S.ItemIsValidTransmogrifySource(itemLink);
	if (not canTransmog) then
		if (noSourceReason and noSourceReason == "INVALID_SOURCE") then
			self:AddLine(tooltipAppearanceUnusable..tooltipSuffix, colorInvalidR, colorInvalidG, colorInvalidB);
		end
		return;
	end

	-- Check if Blizzard already added the text to the tooltip,
	-- they only add it to items equippable by the current class.
	local found = false;
	local tooltipName = self:GetName();
	local numLines = self:NumLines();

	for i = numLines, 1, -1 do
		local frame = _G[tooltipName.."TextLeft"..i];
		if (frame) then
			local text = frame:GetText();
			if (text and text == TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN) then
				found = true;
				break;
			elseif (text and text == TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN) then
				frame:SetTextColor(colorKnownR, colorKnownG, colorKnownB);
				frame:SetText(TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN..tooltipSuffix);
				found = true;
				break;
			end
		end
	end

	if (not found) then
		if (S.PlayerHasTransmog(itemLink)) then
			self:AddLine(TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN..tooltipSuffix, colorKnownR, colorKnownG, colorKnownB);
		else
			self:AddLine(TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN..tooltipSuffix, colorMissingR, colorMissingG, colorMissingB);
		end
	end
end


TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
	if not tooltip then return end
	for _, tt in pairs({ GameTooltip, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ShoppingTooltip1, ShoppingTooltip2, AtlasLootTooltip }) do
		if tooltip == tt then
			OnTooltipSetItemHook(tooltip)
		end
	end
end)

-- Enable additional Blizzard text
--C_TransmogCollection.SetShowMissingSourceInItemTooltips(true);
SetCVar("missingTransmogSourceInItemTooltips", 1)