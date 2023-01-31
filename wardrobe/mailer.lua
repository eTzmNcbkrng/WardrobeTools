--[[ 

	Martin Karer / Sezz, 2016
	Wardrobe BoE mailer
	
--]]

if (IsTrialAccount() or IsRestrictedAccount()) then return; end -- Mail is disabled for Trial accounts.

local addonName, ns = ...;
local S, C;
if (SezzUI) then
	S, C = unpack(SezzUI);
else
	S, C = ns.S, ns.C;
end

if (addonName == "WardrobeTools" and SezzUI) then return; end

-----------------------------------------------------------------------------

local addon = S:CreateModule("AppearanceMailer"):AddDefaultHandlers();

-- Lua API
local select, strlen, tinsert, tremove, strlower, next = select, string.len, table.insert, table.remove, string.lower, next;

-- WoW API
local GetItemClassInfo, GetItemSubClassInfo, GameTooltip_Hide, ClearCursor, PickupContainerItem, ClickSendMailItemButton, SendMail, GetItemInfo = GetItemClassInfo, GetItemSubClassInfo, GameTooltip_Hide, ClearCursor, PickupContainerItem, ClickSendMailItemButton, SendMail, GetItemInfo;
local ATTACHMENTS_MAX_SEND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_CLOTH, LE_ITEM_ARMOR_LEATHER, LE_ITEM_ARMOR_MAIL, LE_ITEM_ARMOR_PLATE, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_WARGLAIVE, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_BOWS, LE_ITEM_WEAPON_CROSSBOW, LE_ITEM_WEAPON_GUNS, LE_ITEM_ARMOR_SHIELD, LE_ITEM_ARMOR_GENERIC, INVTYPE_RANGED, INVTYPE_HOLDABLE = ATTACHMENTS_MAX_SEND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_CLOTH, LE_ITEM_ARMOR_LEATHER, LE_ITEM_ARMOR_MAIL, LE_ITEM_ARMOR_PLATE, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_WARGLAIVE, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_BOWS, LE_ITEM_WEAPON_CROSSBOW, LE_ITEM_WEAPON_GUNS, LE_ITEM_ARMOR_SHIELD, LE_ITEM_ARMOR_GENERIC, INVTYPE_RANGED, INVTYPE_HOLDABLE;

-----------------------------------------------------------------------------
-- BoA armor tokens
-----------------------------------------------------------------------------

local BoAArmorTokens = {
	[127777] = LE_ITEM_ARMOR_CLOTH,
	[127778] = LE_ITEM_ARMOR_CLOTH,
	[127779] = LE_ITEM_ARMOR_CLOTH,
	[127780] = LE_ITEM_ARMOR_CLOTH,
	[127781] = LE_ITEM_ARMOR_CLOTH,
	[127782] = LE_ITEM_ARMOR_CLOTH,
	[127783] = LE_ITEM_ARMOR_CLOTH,
	[127784] = LE_ITEM_ARMOR_CLOTH,
	[128803] = LE_ITEM_ARMOR_CLOTH,
	[127790] = LE_ITEM_ARMOR_LEATHER,
	[127791] = LE_ITEM_ARMOR_LEATHER,
	[127792] = LE_ITEM_ARMOR_LEATHER,
	[127793] = LE_ITEM_ARMOR_LEATHER,
	[127794] = LE_ITEM_ARMOR_LEATHER,
	[127795] = LE_ITEM_ARMOR_LEATHER,
	[127796] = LE_ITEM_ARMOR_LEATHER,
	[127797] = LE_ITEM_ARMOR_LEATHER,
	[128803] = LE_ITEM_ARMOR_LEATHER,
	[127803] = LE_ITEM_ARMOR_MAIL,
	[127804] = LE_ITEM_ARMOR_MAIL,
	[127805] = LE_ITEM_ARMOR_MAIL,
	[127806] = LE_ITEM_ARMOR_MAIL,
	[127807] = LE_ITEM_ARMOR_MAIL,
	[127808] = LE_ITEM_ARMOR_MAIL,
	[127809] = LE_ITEM_ARMOR_MAIL,
	[127810] = LE_ITEM_ARMOR_MAIL,
	[128803] = LE_ITEM_ARMOR_MAIL,
	[127816] = LE_ITEM_ARMOR_PLATE,
	[127817] = LE_ITEM_ARMOR_PLATE,
	[127818] = LE_ITEM_ARMOR_PLATE,
	[127819] = LE_ITEM_ARMOR_PLATE,
	[127820] = LE_ITEM_ARMOR_PLATE,
	[127821] = LE_ITEM_ARMOR_PLATE,
	[127822] = LE_ITEM_ARMOR_PLATE,
	[127823] = LE_ITEM_ARMOR_PLATE,
	[128803] = LE_ITEM_ARMOR_PLATE,
	-- Timeless
	[102288] = LE_ITEM_ARMOR_CLOTH,
	[102284] = LE_ITEM_ARMOR_CLOTH,
	[102290] = LE_ITEM_ARMOR_CLOTH,
	[102287] = LE_ITEM_ARMOR_CLOTH,
	[102289] = LE_ITEM_ARMOR_CLOTH,
	[102321] = LE_ITEM_ARMOR_CLOTH,
	[102286] = LE_ITEM_ARMOR_CLOTH,
	[102285] = LE_ITEM_ARMOR_CLOTH,
	[102282] = LE_ITEM_ARMOR_LEATHER,
	[102277] = LE_ITEM_ARMOR_LEATHER,
	[102280] = LE_ITEM_ARMOR_LEATHER,
	[102278] = LE_ITEM_ARMOR_LEATHER,
	[102283] = LE_ITEM_ARMOR_LEATHER,
	[102279] = LE_ITEM_ARMOR_LEATHER,
	[102281] = LE_ITEM_ARMOR_LEATHER,
	[102322] = LE_ITEM_ARMOR_LEATHER,
	[102270] = LE_ITEM_ARMOR_MAIL,
	[102273] = LE_ITEM_ARMOR_MAIL,
	[102275] = LE_ITEM_ARMOR_MAIL,
	[102272] = LE_ITEM_ARMOR_MAIL,
	[102276] = LE_ITEM_ARMOR_MAIL,
	[102271] = LE_ITEM_ARMOR_MAIL,
	[102274] = LE_ITEM_ARMOR_MAIL,
	[102323] = LE_ITEM_ARMOR_MAIL,
	[102266] = LE_ITEM_ARMOR_PLATE,
	[102263] = LE_ITEM_ARMOR_PLATE,
	[102268] = LE_ITEM_ARMOR_PLATE,
	[102269] = LE_ITEM_ARMOR_PLATE,
	[102265] = LE_ITEM_ARMOR_PLATE,
	[102267] = LE_ITEM_ARMOR_PLATE,
	[102264] = LE_ITEM_ARMOR_PLATE,
	[102320] = LE_ITEM_ARMOR_PLATE,
		-- Unsullied
	[152734] = LE_ITEM_ARMOR_CLOTH,
	[152738] = LE_ITEM_ARMOR_CLOTH,
	[152742] = LE_ITEM_ARMOR_CLOTH,
	[153135] = LE_ITEM_ARMOR_CLOTH,
	[153141] = LE_ITEM_ARMOR_CLOTH,
	[153144] = LE_ITEM_ARMOR_CLOTH,
	[153154] = LE_ITEM_ARMOR_CLOTH,
	[153156] = LE_ITEM_ARMOR_CLOTH,
	[152737] = LE_ITEM_ARMOR_LEATHER,
	[153136] = LE_ITEM_ARMOR_LEATHER,
	[153139] = LE_ITEM_ARMOR_LEATHER,
	[153142] = LE_ITEM_ARMOR_LEATHER,
	[153145] = LE_ITEM_ARMOR_LEATHER,
	[153148] = LE_ITEM_ARMOR_LEATHER,
	[152739] = LE_ITEM_ARMOR_LEATHER,
	[153151] = LE_ITEM_ARMOR_LEATHER,
	[152741] = LE_ITEM_ARMOR_MAIL,
	[152744] = LE_ITEM_ARMOR_MAIL,
	[153137] = LE_ITEM_ARMOR_MAIL,
	[153138] = LE_ITEM_ARMOR_MAIL,
	[153147] = LE_ITEM_ARMOR_MAIL,
	[153149] = LE_ITEM_ARMOR_MAIL,
	[153152] = LE_ITEM_ARMOR_MAIL,
	[153158] = LE_ITEM_ARMOR_MAIL,
	[152743] = LE_ITEM_ARMOR_PLATE,
	[153140] = LE_ITEM_ARMOR_PLATE,
	[153143] = LE_ITEM_ARMOR_PLATE,
	[153146] = LE_ITEM_ARMOR_PLATE,
	[153150] = LE_ITEM_ARMOR_PLATE,
	[153153] = LE_ITEM_ARMOR_PLATE,
	[153155] = LE_ITEM_ARMOR_PLATE,
	[153157] = LE_ITEM_ARMOR_PLATE,
};

-----------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------

local settingsAnchor;

local CreateSettingsHeader = function(itemClassID)
	local frame = CreateFrame("Frame", nil, addon.configFrame);
	frame:SetHeight(18);

	if (settingsAnchor) then
		frame:SetPoint("TOP", settingsAnchor, "BOTTOM", 0, 0);
	else
		frame:SetPoint("TOP", addon.configFrame, "TOP", 0, -30);
	end

	frame:SetPoint("LEFT");
	frame:SetPoint("RIGHT");

	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
	label:SetPoint("TOP");
	label:SetPoint("BOTTOM");
	label:SetJustifyH("CENTER");
	label:SetText(GetItemClassInfo(itemClassID));

	local left = frame:CreateTexture(nil, "BACKGROUND");
	left:SetHeight(8);
	left:SetPoint("LEFT", 14, 0);
	left:SetPoint("RIGHT", label, "LEFT", -5, 0);
	left:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border");
	left:SetTexCoord(0.81, 0.94, 0.5, 1);
	left:SetPoint("RIGHT", label, "LEFT", -5, 0);

	local right = frame:CreateTexture(nil, "BACKGROUND");
	right:SetHeight(8);
	right:SetPoint("RIGHT", -10, 0);
	right:SetPoint("LEFT", label, "RIGHT", 5, 0);
	right:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border");
	right:SetTexCoord(0.81, 0.94, 0.5, 1);

	settingsAnchor = frame;
end

local CreateTSMsettingsHeader = function(variable)

	local frame = CreateFrame("Frame", nil, addon.configFrame);
	frame:SetHeight(18);

	if (settingsAnchor) then
		frame:SetPoint("TOP", settingsAnchor, "BOTTOM", 0, 0);
	else
		frame:SetPoint("TOP", addon.configFrame, "TOP", 0, -30);
	end

	frame:SetPoint("LEFT");
	frame:SetPoint("RIGHT");

	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
	label:SetPoint("TOP");
	label:SetPoint("BOTTOM");
	label:SetJustifyH("CENTER");	
	label:SetText("TradeSkillMaster");
		
	local left = frame:CreateTexture(nil, "BACKGROUND");
	left:SetHeight(8);
	left:SetPoint("LEFT", 14, 0);
	left:SetPoint("RIGHT", label, "LEFT", -5, 0);
	left:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border");
	left:SetTexCoord(0.81, 0.94, 0.5, 1);
	left:SetPoint("RIGHT", label, "LEFT", -5, 0);

	local right = frame:CreateTexture(nil, "BACKGROUND");
	right:SetHeight(8);
	right:SetPoint("RIGHT", -10, 0);
	right:SetPoint("LEFT", label, "RIGHT", 5, 0);
	right:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border");
	right:SetTexCoord(0.81, 0.94, 0.5, 1);

	settingsAnchor = frame;
end


local CreateSettingsEditBox = function(itemClassID, itemSubClassID, customText)
	local frame = CreateFrame("Frame", nil, addon.configFrame);
	frame:SetHeight(26);
	frame:SetPoint("TOP", settingsAnchor, "BOTTOM", 0, 0);
	frame:SetPoint("LEFT");
	frame:SetPoint("RIGHT");
	frame.itemClassID = itemClassID;
	frame.itemSubClassID = itemSubClassID;

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 14, 0);
	label:SetPoint("BOTTOMRIGHT", -230, 0);
	label:SetJustifyH("RIGHT");
	label:SetText(customText or GetItemSubClassInfo(itemClassID, itemSubClassID));

	local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetTextInsets(0, 0, 3, 3)
	editbox:SetMaxLetters(256)
	editbox:SetPoint("RIGHT", -10, 0);
	editbox:SetPoint("LEFT", label, "RIGHT", 10, 0);
	editbox:SetHeight(19)
	frame.editbox = editbox;

	settingsAnchor = frame;
end

local CreateTSMsettingsEditBox = function(TSMsetting, customText)

	local frame = CreateFrame("Frame", nil, addon.configFrame);
	frame:SetHeight(26);
	frame:SetPoint("TOP", settingsAnchor, "BOTTOM", 0, 0);
	frame:SetPoint("LEFT");
	frame:SetPoint("RIGHT");
	frame.TSMsetting = TSMsetting;

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 14, 0);
	label:SetPoint("BOTTOMRIGHT", -230, 0);
	label:SetJustifyH("RIGHT");
	label:SetText(customText);

	local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetTextInsets(0, 0, 3, 3)
	editbox:SetMaxLetters(256)
	editbox:SetPoint("RIGHT", -10, 0);
	editbox:SetPoint("LEFT", label, "RIGHT", 10, 0);
	editbox:SetHeight(19)
	frame.editbox = editbox;

	settingsAnchor = frame;
end

local CreateSettingsCheckBox = function(valueID, customText)
	local frame = CreateFrame("Frame", nil, addon.configFrame);
	frame:SetHeight(26);
	frame:SetPoint("TOP", settingsAnchor, "BOTTOM", 0, 0);
	frame:SetPoint("LEFT");
	frame:SetPoint("RIGHT");
	frame.valueID = valueID;

	local checkbox = CreateFrame("CheckButton", nil, frame)
	checkbox:SetSize(19, 19);
	checkbox:SetHitRectInsets(0, -180, 0, 0);
	checkbox:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]]);
	checkbox:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]]);
	checkbox:SetHighlightTexture([[Interface\Buttons\UI-CheckBox-Highlight]], "ADD");
	checkbox:SetCheckedTexture([[Interface\Buttons\UI-CheckBox-Check]]);
	checkbox:SetDisabledCheckedTexture([[Interface\Buttons\UI-CheckBox-Check-Disabled]]);
	checkbox:SetPoint("LEFT", 90, 0);
	frame.checkbox = checkbox;

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("RIGHT", -10, 0);
	label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
	label:SetJustifyH("LEFT");
	label:SetText(customText);

	settingsAnchor = frame;
end

local ToggleSettings = function()
	if (addon.configFrame:IsShown()) then
		addon.configFrame:Hide();
	else
		addon.configFrame:Show();
	end
end

local UpdateSettings = function()
	-- Fill edit box text with saved settings

	for _, frame in pairs({ addon.configFrame:GetChildren() }) do
		
		if (frame.itemClassID and frame.itemSubClassID) then
			frame.editbox:SetText(addon.ADB.recipients[S.myRealm][S.myFactionGroup][frame.itemClassID][frame.itemSubClassID] or "");
			
		elseif (frame.valueID) then
			-- Checkbox
			frame.checkbox:SetChecked(addon.ADB.recipients[S.myRealm][S.myFactionGroup][frame.valueID]);
			
		elseif (frame.TSMsetting) then
			frame.editbox:SetText(addon.ADB.TSM[frame.TSMsetting] or "");
		end
	end
end

local SaveSettings = function()
	-- Save
	for _, frame in pairs({ addon.configFrame:GetChildren() }) do
		if (frame.itemClassID and frame.itemSubClassID) then
			-- Editbox
			local recipient = frame.editbox:GetText();
			addon.ADB.recipients[S.myRealm][S.myFactionGroup][frame.itemClassID][frame.itemSubClassID] = (strlen(recipient) >= 2 and recipient or nil);
		elseif (frame.valueID) then
			-- Checkbox
			addon.ADB.recipients[S.myRealm][S.myFactionGroup][frame.valueID] = frame.checkbox:GetChecked();
		elseif (frame.TSMsetting) then
			--TSM
			addon.ADB.TSM[frame.TSMsetting] = frame.editbox:GetText();
		end
	end

	-- Whoever is able to use LE_ITEM_WEAPON_BOWS can also use LE_ITEM_WEAPON_CROSSBOW + LE_ITEM_WEAPON_GUNS
	addon.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_WEAPON][LE_ITEM_WEAPON_CROSSBOW] = addon.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_WEAPON][LE_ITEM_WEAPON_BOWS];
	addon.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_WEAPON][LE_ITEM_WEAPON_GUNS] = addon.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_WEAPON][LE_ITEM_WEAPON_BOWS];
end

local SettingsFrame_OnShow = function(self)
	addon.configButton:SetText("<");
	UpdateSettings();
end

local SettingsFrame_OnHide = function(self)
	addon.configButton:SetText(">");
	SaveSettings();
end

local CreateSettingsFrame = function()
	if (addon.configFrame) then return; end

	local frame = CreateFrame("Frame", "SezzUIAppearanceMailerRecipients", InboxFrame, "UIPanelDialogTemplate");
	frame:Hide();
	frame:SetPoint("TOPLEFT", 335, 4);
	frame:SetSize(400, 725);
	frame:EnableMouse(true);
	frame:SetScript("OnShow", SettingsFrame_OnShow);
	frame:SetScript("OnHide", SettingsFrame_OnHide);

	addon.configFrame = frame;

	-- Title
	local title = frame:CreateFontString();
	title:SetFontObject(GameFontNormalCenter);
	title:SetPoint("TOPLEFT", "$parentTitleBG");
	title:SetPoint("BOTTOMRIGHT", "$parentTitleBG");
	title:SetText("WardrobeTools Settings");

	-- Armor
	CreateSettingsHeader(LE_ITEM_CLASS_ARMOR);
	CreateSettingsEditBox(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_CLOTH);
	CreateSettingsEditBox(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_LEATHER);
	CreateSettingsEditBox(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_MAIL);
	CreateSettingsEditBox(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_PLATE);
	CreateSettingsCheckBox("sendAllBoEs", "Also mail acquired appearances");
	CreateSettingsCheckBox("includeBoAArmorTokens", "Include BoA Armor Tokens");

	-- Weapons
	CreateSettingsHeader(LE_ITEM_CLASS_WEAPON);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_AXE1H);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_AXE2H);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_MACE1H);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_MACE2H);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_SWORD1H);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_SWORD2H);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_WARGLAIVE);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_DAGGER);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_UNARMED);

	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_POLEARM);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_STAFF);

	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_WAND);
	CreateSettingsEditBox(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_BOWS, INVTYPE_RANGED);

	CreateSettingsEditBox(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD);
	CreateSettingsEditBox(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_GENERIC, INVTYPE_HOLDABLE);

	--TSM 

	CreateTSMsettingsHeader();
	CreateSettingsCheckBox("TSMenabled", "Enable TSM filtering");
	CreateTSMsettingsEditBox("pricesource", "TSM Price Source");
	CreateTSMsettingsEditBox("threshold", "Mail only if price source is less than");

end

-----------------------------------------------------------------------------
-- Buttons
-----------------------------------------------------------------------------

local ShowTooltip = function(self)
	if (self.tooltipText) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:AddLine(self.tooltipText, 1, 1, 1);
		GameTooltip:SetClampedToScreen(true);
		GameTooltip:Show();
	end
end

local SendButton_OnClick = function(self)
	if (addon.configFrame:IsVisible()) then
		SaveSettings();
	end
	addon:QueueMails();
end

local SendButton_ShowTooltip = function(self)
	if (addon.configFrame:IsVisible()) then
		SaveSettings();
	end
	
	local queue = addon:QueueMails(true);	
	
	local queue_size = 0
	for _ in pairs(queue) do queue_size = queue_size + 1 end	
	
	local TSMenabled = addon.ADB.recipients[S.myRealm][S.myFactionGroup].TSMenabled;
	local TSMpricesource = addon.ADB.TSM.pricesource;
	local TSMthreshold = tonumber(addon.ADB.TSM.threshold);
	local TSMcheck = false;
	local TSMerror = false;
	
	--Check if TSM options are set up properly
	if TSMenabled then
		if TSM_API then 					
			-- Check if the set price source and threshold are valid. Only continue using TSM options if these options valid.
			if TSMpricesource and TSM_API.IsCustomPriceValid(TSMpricesource) and (type(TSMthreshold) == 'number') and TSMthreshold > 0 then			
				TSMcheck = true;
				
				if (next(queue)) then
					-- show tooltip
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

					for recipient, items in pairs(queue) do
						GameTooltip:AddLine(strupper(recipient), 1, 1, 1);

						for _, t in pairs(items) do
							GameTooltip:AddLine(GetContainerItemLink(t[1], t[2]));
						end
					end

					GameTooltip:SetClampedToScreen(true);
					GameTooltip:Show();
				
				elseif queue_size == 0 then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:AddLine("No items to be mailed.");
					GameTooltip:SetClampedToScreen(true);
					GameTooltip:Show();
				else 
					GameTooltip:Hide();
				end	
					
			else
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:AddLine("ERROR: Invalid TSM price source and/or threshold.\nNo mail will be sent.");
				GameTooltip:SetClampedToScreen(true);
				GameTooltip:Show();
				TSMerror = true;
				TSMcheck = false;
			end
		else
			-- TSM addon not detected
			TSMerror = true;
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine("ERROR: TradeSkillMaster addon not detected. No mail will be sent.\nTo fix this, either disable TSM filtering in WardrobeTools settings, or enable TSM.");
			GameTooltip:SetClampedToScreen(true);
			GameTooltip:Show();
		end		
	
	else	
		if (next(queue)) then
			-- show tooltip
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

			for recipient, items in pairs(queue) do
				GameTooltip:AddLine(strupper(recipient), 1, 1, 1);

				for _, t in pairs(items) do
					GameTooltip:AddLine(GetContainerItemLink(t[1], t[2]));
				end
			end

			GameTooltip:SetClampedToScreen(true);
			GameTooltip:Show();
			
		elseif queue_size == 0 then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine("No items to be mailed.");
			GameTooltip:SetClampedToScreen(true);
			GameTooltip:Show();
		else 
			GameTooltip:Hide();
		end		
	end	
end

local ResizePostalButtons = function()
	if (not PostalSelectOpenButton or not PostalSelectReturnButton or PostalSelectOpenButton:GetWidth() == 76) then return; end

	PostalSelectOpenButton:ClearAllPoints();
	PostalSelectOpenButton:SetPoint("TOPLEFT", "MailFrame", "TOPLEFT", 64, -30);
	PostalSelectOpenButton:SetWidth(76);

	PostalSelectReturnButton:SetWidth(76);
	PostalSelectReturnButton:ClearAllPoints();
	PostalSelectReturnButton:SetPoint("LEFT", "PostalSelectOpenButton", "RIGHT", 4, 0);

	addon.sendButton:SetWidth(76);
	addon.sendButton:SetHeight(25);
	addon.sendButton:SetText("Send Tmog");
	addon.sendButton:ClearAllPoints();
	addon.sendButton:SetPoint("LEFT", "PostalSelectReturnButton", "RIGHT", 4, 0);
	addon.configButton:SetHeight(25);
end

local CreateButtons = function()
	local buttonHeight = OpenMailReplyButton:GetHeight();

	if (not addon.sendButton) then
		local sendButton = CreateFrame("Button", nil, InboxFrame, "UIPanelButtonTemplate");
		sendButton:SetHeight(buttonHeight);
		sendButton:SetWidth(OpenMailReplyButton:GetWidth() * 1.5 );
		sendButton:SetPoint("TOPLEFT", "MailFramePortrait", "RIGHT", OpenMailReplyButton:GetWidth() * 1.5, -10);
		--sendButton:SetPoint("TOPLEFT", "MailFrame", "RIGHT", OpenMailReplyButton:GetWidth() * 1.5 + 4, -2);
		sendButton:SetText("Send Transmogs");
		sendButton:RegisterEvent("MAIL_INBOX_UPDATE");
		sendButton:RegisterEvent("UI_ERROR_MESSAGE");
		sendButton:RegisterEvent("MAIL_CLOSED");
		sendButton:SetScript("OnClick", SendButton_OnClick);
		sendButton:SetScript("OnEnter", SendButton_ShowTooltip);
		sendButton:SetScript("OnLeave", GameTooltip_Hide);

		addon.sendButton = sendButton;
	end

	if (not addon.configButton) then
		local configButton = CreateFrame("Button", nil, InboxFrame, "UIPanelButtonTemplate");
		configButton.tooltipText = "WardrobeTools Settings";
		configButton:SetSize(buttonHeight, buttonHeight);
		configButton:SetPoint("LEFT", addon.sendButton, "RIGHT", 4, 0);
		configButton:SetText(">");
		configButton:SetScript("OnEnter", ShowTooltip);
		configButton:SetScript("OnLeave", GameTooltip_Hide);
		configButton:SetScript("OnClick", ToggleSettings);

		addon.configButton = configButton;
	end

	if (IsAddOnLoaded("Postal") and Postal and Postal.IsEnabled and Postal:IsEnabled()) then
		local Postal_Select = Postal:GetModule("Select", true);
		if (Postal_Select and Postal_Select:IsEnabled()) then
			if (PostalSelectOpenButton and PostalSelectReturnButton) then
				ResizePostalButtons();
			else
				hooksecurefunc(Postal_Select, "OnEnable", ResizePostalButtons);
			end
		end
	end
end

-----------------------------------------------------------------------------
-- TSM
-----------------------------------------------------------------------------

function GetItemPrice(itemID, customPriceStr)

   local _, link = GetItemInfo(itemID)
   local itemString = TSM_API.ToItemString(link)
       
   if not TSM_API.IsCustomPriceValid(customPriceStr) then
      source = nil
   end
   
   return TSM_API.GetCustomPriceValue(customPriceStr, itemString)
end

-----------------------------------------------------------------------------
-- Module Loader
-----------------------------------------------------------------------------

addon.OnInitialize = function(self)
	self:LoadSettings(true);
	self:SetEnabledState(self.DB.enabled);
end

addon.InitializeProfile = function(self)
	if (not self.ADB.recipients or type(self.ADB.recipients) ~= "table") then
		self.ADB.recipients = {};
	end

	if (not self.ADB.recipients[S.myRealm]) then
		self.ADB.recipients[S.myRealm] = {};
	end

	if (not self.ADB.recipients[S.myRealm][S.myFactionGroup]) then
		self.ADB.recipients[S.myRealm][S.myFactionGroup] = {};
	end

	if (not self.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_ARMOR]) then
		self.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_ARMOR] = {};
	end

	if (not self.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_WEAPON]) then
		self.ADB.recipients[S.myRealm][S.myFactionGroup][LE_ITEM_CLASS_WEAPON] = {};
	end

	if (not self.ADB.TSM) then
		self.ADB.TSM = {};
	end

end

addon.OnEnable = function(self)
	self:InitializeProfile();

	self:RegisterEvent("MAIL_CLOSED");

	if (not self.configFrame) then
		if (InboxFrame:IsShown()) then
			-- already at a mailbox, create frames
			self:MAIL_SHOW();
		else
			-- create frames when visiting the mailbox
			self:RegisterEvent("MAIL_SHOW");
		end
	end

	-- show buttons
	if (self.configFrame) then
		self.sendButton:Show();
		self.configButton:Show();
	end
end

addon.OnDisable = function(self)
	-- hide buttons
	if (self.configFrame) then
		self.sendButton:Hide();
		self.configButton:Hide();
		self.configFrame:Hide();
	end

	-- disable events
	self:UnregisterAllEvents();
end

-----------------------------------------------------------------------------
-- UI Events
-----------------------------------------------------------------------------

addon.BAG_UPDATE_DELAYED = function(self)
	if (self.sendButton:IsEnabled() and self.sendButton:IsMouseOver()) then
		SendButton_ShowTooltip(self.sendButton);
	end
end

addon.MAIL_SHOW = function(self)
	CreateButtons();
	CreateSettingsFrame();
	self:RegisterEvent("BAG_UPDATE_DELAYED");
end

addon.MAIL_CLOSED = function(self)
	if (self.configFrame) then
		self.configFrame:Hide();
		self.configButton:Enable();
		self.sendButton:Enable();
	end
	self.active = false;
	wipe(self.queue);
	self:UnregisterEvent("BAG_UPDATE_DELAYED");
end

-----------------------------------------------------------------------------
-- Mailing
-----------------------------------------------------------------------------

local myName = strlower(S.myName);
local myNameFull = myName.."-"..strlower(gsub(S.myRealm, "%s", ""));

--message(TSM_API.GetPriceSourceKeys())

-- if TSM_API then
	
	-- --local _, link = GetItemInfo(4306)
	-- --TSMvalue = GetItemPrice(link,"dbmarket");
    
   -- --local itemString = TSM_API.ToItemString(link)

	-- --itemString = TSM_API.ToItemString(itemLink)	
	
	-- --TSMvalue = TSM_API.GetCustomPriceValue("DBMarket", itemString)
	
	-- --print(TSMvalue)
	
	-- --local pricef = ("% .2f"): format (value)
	
	-- --message(value)

	-- -- if (value > 1) then
		-- -- message("test")
	-- -- end
	
	-- --print("WardrobeTools: TSM detected.")
-- else
	-- --print("WardrobeTools: TSM NOT DETECTED.")
-- end

-- 

addon.queue = {};

addon.QueueMails = function(self, displayOnly)
	local queue = (displayOnly and {} or self.queue);
	local sendAllBoEs = addon.ADB.recipients[S.myRealm][S.myFactionGroup].sendAllBoEs;
	local includeBoAArmorTokens = addon.ADB.recipients[S.myRealm][S.myFactionGroup].includeBoAArmorTokens;
	local TSMenabled = addon.ADB.recipients[S.myRealm][S.myFactionGroup].TSMenabled;
	local TSMpricesource = addon.ADB.TSM.pricesource;
	local TSMthreshold = tonumber(addon.ADB.TSM.threshold);
	local TSMcheck = false;
	local TSMerror = false;

	-- Check if TSM options are set up properly
	if TSMenabled then
		--print("TSM enabled")
		
		-- Check if TSM addon is active
		if TSM_API then 
					
			-- Check if the set price source and threshold are valid. Only continue using TSM options if these options valid.
			if TSMpricesource and TSM_API.IsCustomPriceValid(TSMpricesource) and (type(TSMthreshold) == 'number') and TSMthreshold > 0 then			
				TSMcheck = true;
			else
				--print("WardrobeTools: Invalid TSM price source and/or threshold. No items will be sent.");
				TSMerror = true;
				TSMcheck = false;
			end;
		else
			-- TSM addon not detected
			TSMerror = true;
			--print("WardrobeTools: TSM addon not detected. No items will be sent. Disable the TSM option in WardrobeTools settings, or enable the TSM addon.");
		end		
	end
	
	-- iterate through bags and build mailing queue

		local bag, slot;
		for bag = 0, 4 do
			for slot = 1, GetContainerNumSlots(bag) do
				local itemID = GetContainerItemID(bag, slot);
				local itemLink = GetContainerItemLink(bag, slot);
				local TSMgreenlight = false;
				
				if (itemID and itemLink) then
					local name, _, quality, _, _, _, _, _, equipSlot, _, _, itemClassID, itemSubClassID = GetItemInfo(itemID);
					
					if (name) then
						if (includeBoAArmorTokens and string.find(name, "Unsullied")) then
							itemSubClassID = BoAArmorTokens[itemID]
							itemClassID = LE_ITEM_CLASS_ARMOR
						end

						if (includeBoAArmorTokens and itemClassID == LE_ITEM_CLASS_ARMOR and itemSubClassID == LE_ITEM_ARMOR_GENERIC and BoAArmorTokens[itemID]) then
							itemSubClassID = BoAArmorTokens[itemID];
						end
						
						--Run TSM checks for the item
						if TSMenabled then		
						
							if TSMcheck then
							
								TSMvalue = (GetItemPrice(itemID,TSMpricesource) or nil);
								
								--Only greenlight the item to be mailed if TSMvalue is less than the set threshold.
								if(TSMvalue and TSMthreshold and TSMvalue < TSMthreshold) then
									TSMgreenlight = true;										
								else	
									TSMgreenlight = false;
								end	
							
							else
								TSMvalue = nil;
								TSMgreenlight = false;
							end		
							
						else
							--If TSM options are disabled, greenlight ALL items to be mailed
							TSMgreenlight = true;
						end	

						local recipient = (itemClassID and itemSubClassID and self.ADB.recipients[S.myRealm][S.myFactionGroup][itemClassID] and self.ADB.recipients[S.myRealm][S.myFactionGroup][itemClassID][itemSubClassID] and strlower(self.ADB.recipients[S.myRealm][S.myFactionGroup][itemClassID][itemSubClassID]) or nil);
						
						if (TSMgreenlight and (not TSMerror) and quality >= 2 and quality ~= 7 and recipient and recipient ~= myName and recipient ~= myNameFull
							and (not (itemClassID == LE_ITEM_CLASS_ARMOR and itemSubClassID == LE_ITEM_ARMOR_GENERIC) or (itemClassID == LE_ITEM_CLASS_ARMOR and itemSubClassID == LE_ITEM_ARMOR_GENERIC and equipSlot == "INVTYPE_HOLDABLE"))
							and (not S.PlayerHasTransmog(itemLink) or sendAllBoEs) and S.IsBagItemTradable(bag, slot, includeBoAArmorTokens)) then
							-- LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_GENERIC is used for offhands and jewelery and propably more, filtering it by using INVTYPE_HOLDABLE

							if (not queue[recipient]) then
								queue[recipient] = {};
							end

							tinsert(queue[recipient], { bag, slot });
						end
					end
				end
			end
		end

		-- start sending mails if at least one item is found
		if (next(queue) and not displayOnly) then
			self.active = true;
			self.configButton:Disable();
			self.sendButton:Disable();

			-- enable events
			self:RegisterEvent("MAIL_FAILED");
			self:RegisterEvent("MAIL_SUCCESS");

			-- process queue
			self:ProcessQueue();
		elseif (displayOnly) then
			return queue;
		end
	end
	

addon.ProcessQueue = function(self)
	local recipient, items = next(self.queue);
	
	if (recipient) then
		-- clear message
		ClearSendMail();

		-- attach items
		local index = 1;
		while (index <= ATTACHMENTS_MAX_SEND and #items > 0) do
			local item = tremove(items);

			ClearCursor();
			PickupContainerItem(item[1], item[2]);
			ClickSendMailItemButton(index);
			index = index + 1;
		end

		-- remove recipient when no more items left
		if (#items == 0) then
			self.queue[recipient] = nil;
		end

		-- send message
		SendMail(recipient, "Appearance Collector Items", "");
	else
		-- done
		self:Print("All items sent!");
		self:UnregisterEvent("MAIL_FAILED");
		self:UnregisterEvent("MAIL_SUCCESS");
		self.configButton:Enable();
		self.sendButton:Enable();

		if (self.sendButton:IsMouseOver()) then
			GameTooltip_Hide();
		end
	end
end

addon.MAIL_FAILED = function(self, event)
	-- TOOD: Notify user, that something went wrong...
	self:ProcessQueue();
end

addon.MAIL_SUCCESS = function(self, event)
	-- Mail sent - proceed with the next one
	self:ProcessQueue();
end

-- Move "Inbox Full" Warning
InboxTooMuchMail:ClearAllPoints();
InboxTooMuchMail:SetPoint("TOPLEFT", 48, 5);

local iconWarning = select(2, InboxTooMuchMail:GetRegions());
iconWarning:SetSize(16, 16);
iconWarning:ClearAllPoints();
iconWarning:SetPoint("RIGHT", "$parentText", "LEFT", 0, -1);
