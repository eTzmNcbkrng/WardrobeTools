--[[

	Martin Karer / Sezz, 2016-2017
	Wardrobe appearance collector for BoE items

	Known issues:
	- The API sometimes doesn't seem to know whether an appearance is collected or not, nothing I can do about that.

--]]

local addonName, ns = ...;
local S, C;
if (SezzUI) then
	S, C = unpack(SezzUI);
else
	S, C = ns.S, ns.C;
end

if (addonName == "WardrobeTools" and SezzUI) then return; end
local addon = S:CreateModule("AppearanceCollector", "SezzUIAppearanceCollector", "Button", "SecureActionButtonTemplate,ActionButtonTemplate");

-----------------------------------------------------------------------------

-- Lua API
local strlower, select, tonumber, strfind = string.lower, select, tonumber, string.find;

-- WoW API/Constants
local GetContainerItemID = GetContainerItemID or (C_Container and C_Container.GetContainerItemID)
local GetContainerItemLink = GetContainerItemLink or (C_Container and C_Container.GetContainerItemLink)
local GetContainerNumSlots = GetContainerNumSlots or (C_Container and C_Container.GetContainerNumSlots)
local GetContainerItemInfo = GetContainerItemInfo or (C_Container and C_Container.GetContainerItemInfo)
local InCombatLockdown, SetOverrideBindingClick, ClearOverrideBindings, GetItemInfo = InCombatLockdown, SetOverrideBindingClick, ClearOverrideBindings, GetItemInfo;
local SaveEquipmentSet, DeleteEquipmentSet, CreateEquipmentSet, UseEquipmentSet = C_EquipmentSet.SaveEquipmentSet, C_EquipmentSet.DeleteEquipmentSet, C_EquipmentSet.CreateEquipmentSet, C_EquipmentSet.UseEquipmentSet;
local IsEquippableItem = IsEquippableItem
local LE_ITEM_CLASS_ARMOR = LE_ITEM_CLASS_ARMOR or Enum.ItemClass.Armor or 4
local LE_ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON or Enum.ItemClass.Weapon or 2
local GameTooltip_Hide = GameTooltip_Hide;

-----------------------------------------------------------------------------

local equipmentSet = "SezzAC";
local lootPattern = LOOT_ITEM_SELF:gsub("%.", "%%%."):gsub("%%s", "((.+)|h|r)");
local receivePattern = LOOT_ITEM_PUSHED_SELF:gsub("%.", "%%%."):gsub("%%s", "((.+)|h|r)");
local showAfterCombat = false;

-----------------------------------------------------------------------------

local GetNextItem = function()
	local bag, slot;
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot);

			if (link and S.ItemIsValidTransmogrifySource(link) and not select(2, S.PlayerHasTransmog(link)) and S.IsBagItemTradable(bag, slot) and IsEquippableItem(link)) then
				local _, _, _, _, reqLevel, _, _, _, equipSlot, _, _, itemClassID = GetItemInfo(link);
				if ((itemClassID == LE_ITEM_CLASS_ARMOR or itemClassID == LE_ITEM_CLASS_WEAPON) and (not reqLevel or (reqLevel == 0 and equipSlot == "INVTYPE_BODY") or (reqLevel > 0 and reqLevel <= S.myLevel))) then
					return bag, slot, equipSlot;
				end
			end
		end
	end
end

local ShowTooltip = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP");

	if (self.bag and self.slot) then
		GameTooltip:SetBagItem(self.bag, self.slot);
	else
		GameTooltip:AddLine("Close AppearanceCollector", 1, 1, 1);
		GameTooltip:AddLine("There are no more uncollected appearances in your inventory.");
		GameTooltip:AddLine("Click here to close the addon and re-equip your old gear.");
	end

	GameTooltip:SetClampedToScreen(true);
	GameTooltip:Show();
end

addon.BAG_UPDATE_DELAYED = function(self, event)
	if (not InCombatLockdown()) then
		self:Update();
	end
end

addon.PLAYER_REGEN_DISABLED = function(self, event)
	self.icon:SetVertexColor(0.5, 0.5, 0.5);
	self.icon:SetDesaturated(true);
	self:SetAttribute("type", nil);
	self:UnbindMouseWheel();
end

addon.PLAYER_REGEN_ENABLED = function(self, event)
	if (self:IsVisible()) then
		self.icon:SetVertexColor(1, 1, 1);
		self.icon:SetDesaturated(false);
		self:SetAttribute("type", "macro");
		self:BindMouseWheel();
	elseif (showAfterCombat) then
		self:Toggle();
	end
end

addon.Update = function(self, shutdown)
	local bag, slot, equipSlot = GetNextItem();

	if (not shutdown and bag and slot and equipSlot) then
		local texture = GetContainerItemInfo(bag, slot);

		self.bag = bag;
		self.slot = slot;
		self.equipSlot = equipSlot;

		self:SetAttribute("macrotext", "/use "..bag.." "..slot.."\n/click StaticPopup1Button1");
		self.icon:SetTexture(texture);
	else
		-- No more items left
		self.bag = nil;
		self.slot = nil;
		self.equipSlot = nil;
		self:SetAttribute("macrotext", nil);
		self.icon:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Undo");
	end
end

addon.OnInitialize = function(self)
	if (not C.modules.AppearanceCollector) then
		-- Standalone defaults
		C.modules.AppearanceCollector = {
			anchor = "CENTER",
			x = 300,
			y = 0,
			autoShow = false,
		};
	end

	self:LoadSettings();
	self:Hide();

	if (self.DB.autoShow) then
		self:RegisterEvent("CHAT_MSG_LOOT");
		self:RegisterEvent("PLAYER_REGEN_ENABLED");
		self:RegisterEvent("PLAYER_LEVEL_UP");
	end
end

addon.CHAT_MSG_LOOT = function(self, event, message)
	local link = select(3, strfind(message, lootPattern)) or select(3, strfind(message, receivePattern));
	if (link and not self.enabledState and S.ItemIsValidTransmogrifySource(link) and not select(2, S.PlayerHasTransmog(link)) and S.IsItemTradable(link) and IsEquippableItem(link)) then
		if (InCombatLockdown()) then
			showAfterCombat = true;
		else
			self:Toggle();
		end
	end
end

addon.PLAYER_LEVEL_UP = function(self, event, level)
	if (not self.enabledState and GetNextItem()) then
		if (InCombatLockdown()) then
			showAfterCombat = true;
		else
			addon:Toggle();
		end
	end
end

local GetAppearanceCollectorEquipmentSetID = function()
	for i = 1, C_EquipmentSet.GetNumEquipmentSets() do
		local name, _, id = C_EquipmentSet.GetEquipmentSetInfo(i);
		if (name == equipmentSet) then
			return id;
		end
	end
end

local DeleteAppearanceCollectorEquipmentSet = function()
	local equipmentSetID = GetAppearanceCollectorEquipmentSetID();
	if (equipmentSetID) then
		DeleteEquipmentSet(equipmentSetID);
	end
end

local UseAppearanceCollectorEquipmentSet = function()
	local equipmentSetID = GetAppearanceCollectorEquipmentSetID();
	if (equipmentSetID) then
		UseEquipmentSet(equipmentSetID);
	end
end

addon.OnEnable = function(self)
	self:Print(GREEN_FONT_COLOR_CODE.."ON"..FONT_COLOR_CODE_CLOSE);
	showAfterCombat = false;

	if (not CollectionsJournal) then
		CollectionsJournal_LoadUI();
	end

	if (not IsAddOnLoaded("Blizzard_Collections")) then
		self:PrintError("Couln't load Blizzard_Collections - this is required to check if an appearance is already collected.");
		self:SetEnabledState(false);
		return;
	end

	-- Create button
	if (not self:GetAttribute("type")) then
		self:SetPoint(self.DB.anchor, self.DB.x, self.DB.y);
		self:SetSize(48, 48);
		self:SetScript("OnEnter", ShowTooltip);
		self:SetScript("OnLeave", GameTooltip_Hide);
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown", "RightButtonDown");
		self:SetMovable(true);
		self:RegisterForDrag("LeftButton");
		self:EnableMouse(true);
		S.SkinActionButton(self);

		self:SetScript("OnDragStart", function(self)
			if (IsAltKeyDown()) then
				self:StartMoving();
			end
		end);

		self:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing();

			local anchor, _, _, x, y = self:GetPoint();
			self.DB.anchor = anchor;
			self.DB.x = x;
			self.DB.y = y;
		end);

		self:HookScript("PreClick", function(self, button)
			if (not InCombatLockdown() and button == "RightButton" and self.equipSlot) then
				-- Remove equip macro
				self:Update(true);
			end
		end);

		self:HookScript("OnClick", function(self, button)
			if (not InCombatLockdown()) then
				if (button == "RightButton" or not self.bag) then
					-- Disable
					self:Toggle();
				end
			end
		end);
	end

	-- Setup equipment set
	DeleteAppearanceCollectorEquipmentSet();
	PaperDollFrame_ClearIgnoredSlots();
	PaperDollEquipmentManagerPane_Update(true);
	CreateEquipmentSet(equipmentSet, 897143);

	-- Setup events
	self:RegisterEvent("BAG_UPDATE_DELAYED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	if (not self.DB.autoShow) then
		self:RegisterEvent("PLAYER_REGEN_ENABLED");
	end

	-- Update button
	self:Update();
	self:Show();
	self:PLAYER_REGEN_ENABLED();
end

addon.OnDisable = function(self)
	self:Print(GRAY_FONT_COLOR_CODE.."OFF"..FONT_COLOR_CODE_CLOSE);
	self:Hide();
	self:SetAttribute("macrotext", nil);
	self:UnbindMouseWheel();

	-- Events
	showAfterCombat = false;
	self:UnregisterEvent("BAG_UPDATE_DELAYED");
	self:UnregisterEvent("PLAYER_REGEN_DISABLED");
	if (not self.DB.autoShow) then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED");
	end

	-- Equip normal gear and remove equipment set
	UseAppearanceCollectorEquipmentSet();
	DeleteAppearanceCollectorEquipmentSet();
end

addon.BindMouseWheel = function(self)
	--SetOverrideBindingClick(self, true, "MOUSEWHEELUP", self:GetName());
	--SetOverrideBindingClick(self, true, "MOUSEWHEELDOWN", self:GetName());
	return;
end

addon.UnbindMouseWheel = function(self)
	ClearOverrideBindings(self);
end

addon.Toggle = function(self)
	if (not InCombatLockdown()) then
		self:SetEnabledState(not self.enabledState);
	else
		self:Print("Sorry, you can't toggle this addon while in combat!");
		if (not self:IsVisible()) then
			self:Print("It will be automatically shown after leaving combat.");
			showAfterCombat = true;
		end
	end
end

S:RegisterSlashCommand("AC", "/ac", function(args)
	if (args and args ~= "") then
		local args = strlower(args);

		if (args == "reset") then
			addon.DB.anchor = "CENTER";
			addon.DB.x = 300;
			addon.DB.y = 0;
			addon:ClearAllPoints();
			addon:SetPoint(addon.DB.anchor, addon.DB.x, addon.DB.y);
		elseif (args == "autoshow") then
			addon.DB.autoShow = not addon.DB.autoShow;
			addon:Print("AutoShow "..(addon.DB.autoShow and GREEN_FONT_COLOR_CODE.."ON" or GRAY_FONT_COLOR_CODE.."OFF")..FONT_COLOR_CODE_CLOSE);

			if (addon.DB.autoShow) then
				addon:RegisterEvent("CHAT_MSG_LOOT");
				addon:RegisterEvent("PLAYER_LEVEL_UP");
			else
				addon:UnregisterEvent("CHAT_MSG_LOOT");
				addon:UnregisterEvent("PLAYER_LEVEL_UP");
			end
		else
			addon:Print("Usage:")
			addon:Print("- Type "..ORANGE_FONT_COLOR_CODE.."/ac"..FONT_COLOR_CODE_CLOSE.." to toggle the button");
			addon:Print("- Left clicking the button equips the displayed item, right clicking closes the addon (you can also use the mousewheel while the button is displayed to quickly equip all items and close the addon when done)");
			addon:Print("- To move the button press and hold the ALT key and drag it to the desired position");
			addon:Print("Slash commands:");
			addon:Print(" - "..ORANGE_FONT_COLOR_CODE.."/ac reset"..FONT_COLOR_CODE_CLOSE.." reset button position");
			addon:Print(" - "..ORANGE_FONT_COLOR_CODE.."/ac autoshow"..FONT_COLOR_CODE_CLOSE.." automatically show button upon looting");
		end
	else
		addon:Toggle();
	end
end);