--[[ 

	Martin Karer / Sezz, 2016
	
	PlayerHasTransmog(itemID|itemLink[, checkSource, forceRefresh])
		Returns if the player has collected the item apperance,
		Use ItemIsValidTransmogrifySource first to check if the item appearance can be used for transmogging or pass checkSource as 2nd optional argument.
		Set forceRefresh to true if you are also calling this on TRANSMOG_COLLECTION_UPDATED!
		
		Return values:
			hasTransmog (boolean)
			hasTransmogSource (boolean) - due to Blizzard's limitations this only works for items the player can equip it

	ItemIsValidTransmogrifySource(itemLink)
		Returns if the item appearance can be used for transmogging.
		If Blizzard returns noSourceReason it will be returned too.

		Return values:
			canBeSource (boolean)
			noSourceReason (string, optional) - error code if canBeSource (from C_Transmog.GetItemInfo) is false

	PlayerCanEquip(itemLink)
		Returns if the player can equip an item.
		NB: Fails for spec-requirements.

		Return values:
			canEquip (boolean)

	IsBagItemTradable(containerID, slotID, allowBindOnAccount)
		Returns if a item isn't soulbound
		If allowBindOnAccount is true it treats BoA items like unbound BoE items

		Returns values:
			isTradable (boolean)

	IsItemTradable(itemLink, allowBindOnAccount)
		Returns if a item isn't soulbound on pickup
		If allowBindOnAccount is true it treats BoA items like unbound BoE items

		Returns values:
			isTradable (boolean)

--]]

local addonName, ns = ...;
local S, C;
if (SezzUI) then
	S, C = unpack(SezzUI);
else
	S, C = ns.S, ns.C;
end

if (addonName == "WardrobeTools" and SezzUI) then return; end

-----------------------------------------------------------------------------

-- Lua API
local strmatch, tonumber, select = string.match, tonumber, select;

-- WoW API/Constants
local IsDressableItem, GetItemInfo = IsDressableItem, GetItemInfo;
local TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN, TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN, TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN;
local LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_CLOTH, LE_ITEM_ARMOR_LEATHER, LE_ITEM_ARMOR_MAIL, LE_ITEM_ARMOR_PLATE, LE_ITEM_CLASS_WEAPON, LE_ITEM_ARMOR_COSMETIC = LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_CLOTH, LE_ITEM_ARMOR_LEATHER, LE_ITEM_ARMOR_MAIL, LE_ITEM_ARMOR_PLATE, LE_ITEM_CLASS_WEAPON, LE_ITEM_ARMOR_COSMETIC;

-----------------------------------------------------------------------------

local tooltip = S.ScanningTooltip;
local tooltipName = S.ScanningTooltip:GetName();

-----------------------------------------------------------------------------
-- Hidden DressUpModel
-- TODO: Use C_TransmogCollection.PlayerHasTransmog(itemID[, itemAppearanceModID]) when Blizzard finally decides to give us access to itemAppearanceModID for all items.
-----------------------------------------------------------------------------

local model = CreateFrame("DressUpModel");
model:SetKeepModelOnHide(true);
model:Hide();

local lastItem, lastResult, lastResultSource;
local f = CreateFrame("Frame");
f:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");
f:SetScript("OnEvent", function(self)
	lastItem = nil;
end);

local equipSlotIDs = {
	["INVTYPE_HEAD"] = 1,
	["INVTYPE_NECK"] = 2,
	["INVTYPE_SHOULDER"] = 3,
	["INVTYPE_BODY"] = 4,
	["INVTYPE_CHEST"] = 5,
	["INVTYPE_ROBE"] = 5,
	["INVTYPE_WAIST"] = 6,
	["INVTYPE_LEGS"] = 7,
	["INVTYPE_FEET"] = 8,
	["INVTYPE_WRIST"] = 9,
	["INVTYPE_HAND"] = 10,
	["INVTYPE_CLOAK"] = 15,
	["INVTYPE_WEAPON"] = 16,
	["INVTYPE_SHIELD"] = 17,
	["INVTYPE_2HWEAPON"] = 16,
	["INVTYPE_WEAPONMAINHAND"] = 16,
	["INVTYPE_RANGED"] = 16,
	["INVTYPE_RANGEDRIGHT"] = 16,
	["INVTYPE_WEAPONOFFHAND"] = 17,
	["INVTYPE_HOLDABLE"] = 17,
	["INVTYPE_TABARD"] = -19,
};

local PlayerHasApperanceSource = function(item)
	-- Only works if C_TransmogCollection.GetShowMissingSourceInItemTooltips() is true!
	tooltip:SetHyperlink(item);
	
	for i = tooltip:NumLines(), 1, -1 do
		local text = tooltip.L[i];
		if (text) then
			if (text == TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN or text == TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN) then
				return true;
			elseif (text == TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN) then
				return false;
			end
		end
	end

	return false;
end

local PlayerHasTransmog = function(item, checkSource, forceRefresh)
	if (not item or (checkSource and not S.ItemIsValidTransmogrifySource(item))) then return; end
	model:SetUnit("player");
	model:Undress();

	if (not forceRefresh and lastItem and lastItem == item) then
		-- Tooltip update, reuse last results
		return lastResult, lastResultSource;
	end

	local isCollected, isCollectedSource = false, false;
	local equipSlot = select(9, GetItemInfo(item));

--	S:Debug("Item: "..item, "Core");
--	S:Debug("equipSlot: "..(equipSlot ~= nil and equipSlot or "Unknown"), "Core");
	if (equipSlot and equipSlot ~= "") then
		if (equipSlotIDs[equipSlot] < 0) then
			-- Workaround for tabards
			local itemID = type(item) == "string" and tonumber(strmatch(item, "item:(%d+)")) or item;
			isCollected = C_TransmogCollection.PlayerHasTransmog(itemID);
		else
			model:TryOn(item);

			local appearanceSourceID = model:GetSlotTransmogSources(equipSlotIDs[equipSlot]);
			if (appearanceSourceID == 0 and (equipSlotIDs[equipSlot] == 16 or equipSlotIDs[equipSlot] == 17)) then
				-- Even though the model is undressed it sometimes puts weapons into the offhand slot instead of the mainhand slot,
				-- especially when equipping 2 similar items (like two Baleful weapons with different attributes)
				appearanceSourceID = model:GetSlotTransmogSources(equipSlotIDs[equipSlot] == 16 and 17 or 16);
			end

--			S:Debug("Appearance Source ID: "..(appearanceSourceID ~= nil and appearanceSourceID or "Unknown"), "Core");
			if (appearanceSourceID and appearanceSourceID > 0) then
				-- TODO:
				-- C_TransmogCollection.GetAppearanceInfoBySource(appearanceSourceID)
				-- Returns .appearanceIsCollected/.sourceIsCollected but doesn't return anything if player
				-- cannot use the item...
--				S:Dump(C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID));
--				S:Dump(C_TransmogCollection.GetAppearanceInfoBySource(appearanceSourceID));

				local appearanceInfo = C_TransmogCollection.GetAppearanceInfoBySource(appearanceSourceID);
--				S:Debug("Appearance Info: "..(appearanceInfo ~= nil and "OK" or "nil"), "Core");
				if (appearanceInfo) then
					-- This is the data we want, but we can only use it if the player can equip the item.
					isCollected = appearanceInfo.appearanceIsCollected or appearanceInfo.sourceIsCollected; -- Buggy sometimes
					isCollectedSource = appearanceInfo.sourceIsCollected;
				else
					-- Failover #1
					isCollected = C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(appearanceSourceID);
					isCollectedSource = isCollected;
--					S:Debug("PlayerHasTransmogItemModifiedAppearance: "..(isCollected and "Yes" or "No"), "Core");

					if (not isCollected) then
					-- Failover #2
						local _, appearanceID = C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID);
--						S:Debug("Appearance ID: "..(appearanceID ~= nil and appearanceID or "Unknown"), "Core");
						if (appearanceID) then
							local appearanceSources = C_TransmogCollection.GetAppearanceSources(appearanceID)
--							S:Debug("Appearance Sources: "..(appearanceSources and #appearanceSources or 0), "Core");
							if (appearanceSources) then
								for _, appearanceSource in pairs(appearanceSources) do
--									S:Debug("Source.isCollected: "..(appearanceSource.isCollected and "Yes" or "No"), "Core");
									if (appearanceSource.isCollected) then
--										print("C_TransmogCollection.GetAppearanceSourceInfo");
										isCollected = true;
										break;
									end
								end
							end
						else
							-- Failover #3, doesn't show if already collected any other items with the same appearance.
							isCollected = select(5, C_TransmogCollection.GetAppearanceSourceInfo(appearanceSourceID)) or false;
							if (not isCollected and C_TransmogCollection.GetShowMissingSourceInItemTooltips()) then
								isCollected = PlayerHasApperanceSource(item);
--								if (isCollected) then
--									S:Debug("PlayerHasApperanceSourceTooltip!");
--								end
							end
						end
					end
				end
			end

			model:Undress();
		end
	end

	-- Cache results
	lastItem = item;
	lastResult = isCollected;
	lastResultSource = isCollectedSource;

	return isCollected, isCollectedSource;
end

S.PlayerHasTransmog = PlayerHasTransmog;

-----------------------------------------------------------------------------

local ItemIsValidTransmogrifySource = function(itemLink)
	local itemID = tonumber(strmatch(itemLink, "item:(%d+)"));
	if (not itemID) then return false; end

	local equipSlot, _, _, itemClassID, itemSubClassID = select(9, GetItemInfo(itemLink));
	if (itemClassID == LE_ITEM_CLASS_ARMOR and itemSubClassID == LE_ITEM_ARMOR_COSMETIC) then return true; end -- C_Transmog.GetItemInfo() doesn't like cosmetic armor

	local isDressable = IsDressableItem(itemID);
	local _, _, canBeSource, noSourceReason = C_Transmog.GetItemInfo(itemID);
	if (not isDressable or not canBeSource) then return false, noSourceReason; end

	if (equipSlot == "INVTYPE_NECK" or equipSlot == "INVTYPE_FINGER" or equipSlot == "INVTYPE_TRINKET") then return false; end
	return true;
end

S.ItemIsValidTransmogrifySource = ItemIsValidTransmogrifySource;

-----------------------------------------------------------------------------

local durabilityPattern = DURABILITY_TEMPLATE:gsub("%%d", "(%%d+)");
local reqLevelPattern = ITEM_MIN_LEVEL:gsub("%%d", "(%%d+)");

local classArmor;
if (S.myClass == "ROGUE" or S.myClass == "DRUID" or S.myClass == "MONK" or S.myClass == "DEMONHUNTER") then
	classArmor = LE_ITEM_ARMOR_LEATHER;
elseif (S.myClass == "WARRIOR" or S.myClass == "PALADIN" or S.myClass == "DEATHKNIGHT") then
	classArmor = LE_ITEM_ARMOR_PLATE;
elseif (S.myClass == "MAGE" or S.myClass == "PRIEST" or S.myClass == "WARLOCK") then
	classArmor = LE_ITEM_ARMOR_CLOTH;
elseif (S.myClass == "SHAMAN" or S.myClass == "HUNTER") then
	classArmor = LE_ITEM_ARMOR_MAIL;
end

local PlayerCanEquip = function(itemLink)
	if (not classArmor) then return false; end

	-- Level
	local _, _, _, _, reqLevel, _, _, _, equipSlot, _, _, itemClassID, itemSubClassID = GetItemInfo(itemLink);
	if (reqLevel > S.myLevel) then return false; end

	-- Armor type
	if (itemClassID == LE_ITEM_CLASS_ARMOR and (equipSlot ~= "INVTYPE_CLOAK") and (itemSubClassID == LE_ITEM_ARMOR_CLOTH or itemSubClassID == LE_ITEM_ARMOR_LEATHER or itemSubClassID == LE_ITEM_ARMOR_PLATE or itemSubClassID == LE_ITEM_ARMOR_MAIL) and itemSubClassID ~= classArmor) then return false; end

	-- Scan tooltip for other restrictions
	local textL, textR;

	tooltip:SetHyperlink(itemLink);
	for i = tooltip:NumLines(), 1, -1 do
		-- Left: Class/Race/...
		textL = tooltip.L[i];
		if (textL) then
			local r, g, b = _G[tooltipName.."TextLeft"..i]:GetTextColor();
			if (r > 0.99 and floor(g * 1000) == 125 and floor(b * 1000) == 125 and not strmatch(textL, durabilityPattern) and not strmatch(textL, reqLevelPattern)) then
				return false;
			end
		end

		-- Right: Weapon/Armor type
		if (itemClassID == LE_ITEM_CLASS_WEAPON or itemClassID == LE_ITEM_CLASS_ARMOR) then
			textR = tooltip.R[i];
			if (textR) then
				local r, g, b = _G[tooltipName.."TextRight"..i]:GetTextColor();
				if (r > 0.99 and floor(g * 1000) == 125 and floor(b * 1000) == 125 and not strmatch(textR, durabilityPattern)) then
					return false;
				end
			end
		end
	end

	return true;
end

S.PlayerCanEquip = PlayerCanEquip;

-----------------------------------------------------------------------------

local ITEM_SOULBOUND, ITEM_ACCOUNTBOUND, ITEM_BIND_TO_BNETACCOUNT, ITEM_BNETACCOUNTBOUND, ITEM_BIND_ON_PICKUP = ITEM_SOULBOUND, ITEM_ACCOUNTBOUND, ITEM_BIND_TO_BNETACCOUNT, ITEM_BNETACCOUNTBOUND, ITEM_BIND_ON_PICKUP;

local IsTooltipItemTradable = function(allowBoA)
	for i = 1, 8 do
		local text = tooltip.L[i];
		if (not allowBoA and (text == ITEM_SOULBOUND or text == ITEM_BIND_ON_PICKUP or text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_BNETACCOUNT or text == ITEM_BNETACCOUNTBOUND)) then
			return false;
		elseif (allowBoA) then
			if (text == ITEM_SOULBOUND or text == ITEM_BIND_ON_PICKUP) then
				return false;
			elseif (text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_BNETACCOUNT or text == ITEM_BNETACCOUNTBOUND) then
				return true;
			end
		end
	end

	return true;
end

local IsBagItemTradable = function(bag, slot, allowBoA)
	if (not bag or not slot) then
		return false;
	else
		tooltip:SetBagItem(bag, slot);
		return IsTooltipItemTradable(allowBoA);
	end
end

local IsItemTradable = function(itemLink, allowBoA)
	if (not itemLink) then
		return false;
	else
		tooltip:SetHyperlink(itemLink);
		return IsTooltipItemTradable(allowBoA);
	end
end

S.IsBagItemTradable = IsBagItemTradable;
S.IsItemTradable = IsItemTradable;
