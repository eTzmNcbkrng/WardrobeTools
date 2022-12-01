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
local GetItemClassInfo, GetItemSubClassInfo, GameTooltip_Hide, ClearCursor, ClickSendMailItemButton, SendMail, GetItemInfo = GetItemClassInfo, GetItemSubClassInfo, GameTooltip_Hide, ClearCursor, ClickSendMailItemButton, SendMail, GetItemInfo;
local INVTYPE_RANGED, INVTYPE_HOLDABLE = ATTACHMENTS_MAX_SEND;


-- Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth, Enum.ItemArmorSubclass.Leather, Enum.ItemArmorSubclass.Mail, Enum.ItemArmorSubclass.Plate, Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe1H, Enum.ItemWeaponSubclass.Axe2H, Enum.ItemWeaponSubclass.Mace1H, Enum.ItemWeaponSubclass.Mace2H, Enum.ItemWeaponSubclass.Sword1H, Enum.ItemWeaponSubclass.Sword2H, Enum.ItemWeaponSubclass.Warglaive, Enum.ItemWeaponSubclass.Dagger, Enum.ItemWeaponSubclass.Unarmed, Enum.ItemWeaponSubclass.Polearm, Enum.ItemWeaponSubclass.Staff, Enum.ItemWeaponSubclass.Wand, Enum.ItemWeaponSubclass.Bows, Enum.ItemWeaponSubclass.Crossbow, Enum.ItemWeaponSubclass.Guns, Enum.ItemArmorSubclass.Shield, Enum.ItemArmorSubclass.Generic, INVTYPE_RANGED, INVTYPE_HOLDABLE = ATTACHMENTS_MAX_SEND, Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth, Enum.ItemArmorSubclass.Leather, Enum.ItemArmorSubclass.Mail, Enum.ItemArmorSubclass.Plate, Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe1H, Enum.ItemWeaponSubclass.Axe2H, Enum.ItemWeaponSubclass.Mace1H, Enum.ItemWeaponSubclass.Mace2H, Enum.ItemWeaponSubclass.Sword1H, Enum.ItemWeaponSubclass.Sword2H, Enum.ItemWeaponSubclass.Warglaive, Enum.ItemWeaponSubclass.Dagger, Enum.ItemWeaponSubclass.Unarmed, Enum.ItemWeaponSubclass.Polearm, Enum.ItemWeaponSubclass.Staff, Enum.ItemWeaponSubclass.Wand, Enum.ItemWeaponSubclass.Bows, Enum.ItemWeaponSubclass.Crossbow, Enum.ItemWeaponSubclass.Guns, Enum.ItemArmorSubclass.Shield, Enum.ItemArmorSubclass.Generic,
-----------------------------------------------------------------------------
-- BoA armor tokens
-----------------------------------------------------------------------------

local BoAArmorTokens = {
	[127777] = Enum.ItemArmorSubclass.Cloth,
	[127778] = Enum.ItemArmorSubclass.Cloth,
	[127779] = Enum.ItemArmorSubclass.Cloth,
	[127780] = Enum.ItemArmorSubclass.Cloth,
	[127781] = Enum.ItemArmorSubclass.Cloth,
	[127782] = Enum.ItemArmorSubclass.Cloth,
	[127783] = Enum.ItemArmorSubclass.Cloth,
	[127784] = Enum.ItemArmorSubclass.Cloth,
	[128803] = Enum.ItemArmorSubclass.Cloth,
	[127790] = Enum.ItemArmorSubclass.Leather,
	[127791] = Enum.ItemArmorSubclass.Leather,
	[127792] = Enum.ItemArmorSubclass.Leather,
	[127793] = Enum.ItemArmorSubclass.Leather,
	[127794] = Enum.ItemArmorSubclass.Leather,
	[127795] = Enum.ItemArmorSubclass.Leather,
	[127796] = Enum.ItemArmorSubclass.Leather,
	[127797] = Enum.ItemArmorSubclass.Leather,
	[128803] = Enum.ItemArmorSubclass.Leather,
	[127803] = Enum.ItemArmorSubclass.Mail,
	[127804] = Enum.ItemArmorSubclass.Mail,
	[127805] = Enum.ItemArmorSubclass.Mail,
	[127806] = Enum.ItemArmorSubclass.Mail,
	[127807] = Enum.ItemArmorSubclass.Mail,
	[127808] = Enum.ItemArmorSubclass.Mail,
	[127809] = Enum.ItemArmorSubclass.Mail,
	[127810] = Enum.ItemArmorSubclass.Mail,
	[128803] = Enum.ItemArmorSubclass.Mail,
	[127816] = Enum.ItemArmorSubclass.Plate,
	[127817] = Enum.ItemArmorSubclass.Plate,
	[127818] = Enum.ItemArmorSubclass.Plate,
	[127819] = Enum.ItemArmorSubclass.Plate,
	[127820] = Enum.ItemArmorSubclass.Plate,
	[127821] = Enum.ItemArmorSubclass.Plate,
	[127822] = Enum.ItemArmorSubclass.Plate,
	[127823] = Enum.ItemArmorSubclass.Plate,
	[128803] = Enum.ItemArmorSubclass.Plate,
	-- Timeless
	[102288] = Enum.ItemArmorSubclass.Cloth,
	[102284] = Enum.ItemArmorSubclass.Cloth,
	[102290] = Enum.ItemArmorSubclass.Cloth,
	[102287] = Enum.ItemArmorSubclass.Cloth,
	[102289] = Enum.ItemArmorSubclass.Cloth,
	[102321] = Enum.ItemArmorSubclass.Cloth,
	[102286] = Enum.ItemArmorSubclass.Cloth,
	[102285] = Enum.ItemArmorSubclass.Cloth,
	[102282] = Enum.ItemArmorSubclass.Leather,
	[102277] = Enum.ItemArmorSubclass.Leather,
	[102280] = Enum.ItemArmorSubclass.Leather,
	[102278] = Enum.ItemArmorSubclass.Leather,
	[102283] = Enum.ItemArmorSubclass.Leather,
	[102279] = Enum.ItemArmorSubclass.Leather,
	[102281] = Enum.ItemArmorSubclass.Leather,
	[102322] = Enum.ItemArmorSubclass.Leather,
	[102270] = Enum.ItemArmorSubclass.Mail,
	[102273] = Enum.ItemArmorSubclass.Mail,
	[102275] = Enum.ItemArmorSubclass.Mail,
	[102272] = Enum.ItemArmorSubclass.Mail,
	[102276] = Enum.ItemArmorSubclass.Mail,
	[102271] = Enum.ItemArmorSubclass.Mail,
	[102274] = Enum.ItemArmorSubclass.Mail,
	[102323] = Enum.ItemArmorSubclass.Mail,
	[102266] = Enum.ItemArmorSubclass.Plate,
	[102263] = Enum.ItemArmorSubclass.Plate,
	[102268] = Enum.ItemArmorSubclass.Plate,
	[102269] = Enum.ItemArmorSubclass.Plate,
	[102265] = Enum.ItemArmorSubclass.Plate,
	[102267] = Enum.ItemArmorSubclass.Plate,
	[102264] = Enum.ItemArmorSubclass.Plate,
	[102320] = Enum.ItemArmorSubclass.Plate,
		-- Unsullied
	[152734] = Enum.ItemArmorSubclass.Cloth,
	[152738] = Enum.ItemArmorSubclass.Cloth,
	[152742] = Enum.ItemArmorSubclass.Cloth,
	[153135] = Enum.ItemArmorSubclass.Cloth,
	[153141] = Enum.ItemArmorSubclass.Cloth,
	[153144] = Enum.ItemArmorSubclass.Cloth,
	[153154] = Enum.ItemArmorSubclass.Cloth,
	[153156] = Enum.ItemArmorSubclass.Cloth,
	[152737] = Enum.ItemArmorSubclass.Leather,
	[153136] = Enum.ItemArmorSubclass.Leather,
	[153139] = Enum.ItemArmorSubclass.Leather,
	[153142] = Enum.ItemArmorSubclass.Leather,
	[153145] = Enum.ItemArmorSubclass.Leather,
	[153148] = Enum.ItemArmorSubclass.Leather,
	[152739] = Enum.ItemArmorSubclass.Leather,
	[153151] = Enum.ItemArmorSubclass.Leather,
	[152741] = Enum.ItemArmorSubclass.Mail,
	[152744] = Enum.ItemArmorSubclass.Mail,
	[153137] = Enum.ItemArmorSubclass.Mail,
	[153138] = Enum.ItemArmorSubclass.Mail,
	[153147] = Enum.ItemArmorSubclass.Mail,
	[153149] = Enum.ItemArmorSubclass.Mail,
	[153152] = Enum.ItemArmorSubclass.Mail,
	[153158] = Enum.ItemArmorSubclass.Mail,
	[152743] = Enum.ItemArmorSubclass.Plate,
	[153140] = Enum.ItemArmorSubclass.Plate,
	[153143] = Enum.ItemArmorSubclass.Plate,
	[153146] = Enum.ItemArmorSubclass.Plate,
	[153150] = Enum.ItemArmorSubclass.Plate,
	[153153] = Enum.ItemArmorSubclass.Plate,
	[153155] = Enum.ItemArmorSubclass.Plate,
	[153157] = Enum.ItemArmorSubclass.Plate,
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

	-- Whoever is able to use Enum.ItemWeaponSubclass.Bows can also use Enum.ItemWeaponSubclass.Crossbow + Enum.ItemWeaponSubclass.Guns
	addon.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Crossbow] = addon.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bows];
	addon.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Guns] = addon.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bows];
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
	CreateSettingsHeader(Enum.ItemClass.Armor);
	CreateSettingsEditBox(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Cloth);
	CreateSettingsEditBox(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Leather);
	CreateSettingsEditBox(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Mail);
	CreateSettingsEditBox(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Plate);
	CreateSettingsCheckBox("sendAllBoEs", "Also mail acquired appearances");
	CreateSettingsCheckBox("includeBoAArmorTokens", "Include BoA Armor Tokens");

	-- Weapons
	CreateSettingsHeader(Enum.ItemClass.Weapon);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe1H);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Axe2H);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace1H);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Mace2H);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword1H);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Sword2H);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Warglaive);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Dagger);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Unarmed);

	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Polearm);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Staff);

	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Wand);
	CreateSettingsEditBox(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Bows);

	CreateSettingsEditBox(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield);
	CreateSettingsEditBox(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic, INVTYPE_HOLDABLE);

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
							GameTooltip:AddLine(C_Container.GetContainerItemLink(t[1], t[2]));
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
					GameTooltip:AddLine(C_Container.GetContainerItemLink(t[1], t[2]));
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

	if (not self.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Armor]) then
		print(Enum.ItemClass.Armor);
		self.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Armor] = {};
	end

	if (not self.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Weapon]) then

		self.ADB.recipients[S.myRealm][S.myFactionGroup][Enum.ItemClass.Weapon] = {};

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
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				local itemID = C_Container.GetContainerItemID(bag, slot);
				local itemLink = C_Container.GetContainerItemLink(bag, slot);
				local TSMgreenlight = false;
				
				if (itemID and itemLink) then
					local name, _, quality, _, _, _, _, _, equipSlot, _, _, itemClassID, itemSubClassID = GetItemInfo(itemID);
					
					if (name) then
						if (includeBoAArmorTokens and string.find(name, "Unsullied")) then
							itemSubClassID = BoAArmorTokens[itemID]
							itemClassID = Enum.ItemClass.Armor
						end

						if (includeBoAArmorTokens and itemClassID == Enum.ItemClass.Armor and itemSubClassID == Enum.ItemArmorSubclass.Generic and BoAArmorTokens[itemID]) then
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
							and (not (itemClassID == Enum.ItemClass.Armor and itemSubClassID == Enum.ItemArmorSubclass.Generic) or (itemClassID == Enum.ItemClass.Armor and itemSubClassID == Enum.ItemArmorSubclass.Generic and equipSlot == "INVTYPE_HOLDABLE"))
							and (not S.PlayerHasTransmog(itemLink) or sendAllBoEs) and S.IsBagItemTradable(bag, slot, includeBoAArmorTokens)) then

							-- Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Generic is used for offhands and jewelery and propably more, filtering it by using INVTYPE_HOLDABLE
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
			C_Container.PickupContainerItem(item[1], item[2]);
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
