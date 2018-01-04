--[[ 

	Martin Karer / Sezz, 2016
	Syncs outfits between all characters of the same class

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

-- Lua API
local pairs, strformat, time = pairs, string.format, time;

-- WoW API/Constants
local GetOutfitSources, GetOutfits, DeleteOutfit, SaveOutfit = C_TransmogCollection.GetOutfitSources, C_TransmogCollection.GetOutfits, C_TransmogCollection.DeleteOutfit, C_TransmogCollection.SaveOutfit;

-----------------------------------------------------------------------------

local addon = S:CreateModule("AccountwideOutfits"):AddDefaultHandlers();

addon.OnInitialize = function(self)
	self:LoadSettings(true);
	self:SetEnabledState(self.DB.enabled);
end

addon.InitializeProfile = function(self)
	if (not self.ADB.outfits or type(self.ADB.outfits) ~= "table") then
		self.ADB.outfits = {};
	end

	if (not self.ADB.outfits[S.myClass] or type(self.ADB.outfits[S.myClass]) ~= "table") then
		self.ADB.outfits[S.myClass] = {};
	end

	self.outfits = self.ADB.outfits[S.myClass];
end

addon.OnEnable = function(self)
	self:InitializeProfile();

	if (not S.InGame) then
		self:RegisterEvent("PLAYER_LOGIN");
	else
		self:SyncOutfits();
	end
end

addon.OnDisable = function(self)
	-- disable events
	self:UnregisterAllEvents();
end

-----------------------------------------------------------------------------

local myCharacter = S.myName.."-"..S.myRealm;
local now = time(); -- load timestamp is fine, we don't need exact values
local deletedOutfit = { deletedAt = now }; 

local syncing = false;

addon.SyncOutfits = function(self)
	syncing = true;

	-- fetch outfits from server
	local serverOutfits = {};
	for _, outfit in pairs(GetOutfits()) do
		local appearanceSources, mainHandEnchant, offHandEnchant = GetOutfitSources(outfit.outfitID);
	
		serverOutfits[outfit.name] = {
			id = outfit.outfitID,
			icon = outfit.icon,
			appearanceSources = appearanceSources,
			mainHandEnchant = mainHandEnchant,
			offHandEnchant = offHandEnchant,
		};
	end

	-- compare outfits
	for name, outfit in pairs(self.outfits) do
		if (outfit.deletedAt) then
			-- deleted outfit -> remove from server
			if (serverOutfits[name]) then
				self:Print(strformat("Deleting outfit %s...", name));
				DeleteOutfit(serverOutfits[name].id);
				serverOutfits[name] = nil;
			end

			if (difftime(now, tonumber(outfit.deletedAt) or 0) / (24 * 60 * 60) > 60) then
				-- outfit has been deleted 60+ days ago, remove from cache
				self:Print(strformat("Deleting outfit %s from cache...", name));
				self.outfits[name] = nil;
			end
		elseif (outfit.modifiedBy) then
			-- modified outfit -> update server
			if (outfit.modifiedBy ~= myCharacter) then
				if (not serverOutfits[name]) then
					-- new outfit
					self:Print(strformat("Importing outfit %s...", name));
					local outfitID = SaveOutfit(name, outfit.appearanceSources, outfit.mainHandEnchant, outfit.offHandEnchant, outfit.icon);
					serverOutfits[name] = {
						id = outfitID,
						icon = outfit.icon,
						appearanceSources = outfit.appearanceSources,
						mainHandEnchant = outfit.mainHandEnchant,
						offHandEnchant = outfit.offHandEnchant,
					};
				else
					-- compare cached version with server version
					local needsUpdate = ((outfit.mainHandEnchant ~= serverOutfits[name].mainHandEnchant) or (outfit.offHandEnchant ~= serverOutfits[name].offHandEnchant) or (outfit.icon ~= serverOutfits[name].icon) or (#outfit.appearanceSources ~= #serverOutfits[name].appearanceSources));
					if (not needsUpdate) then
						for i = 1, #outfit.appearanceSources do
							if (outfit.appearanceSources[i] ~= serverOutfits[name].appearanceSources[i]) then
								needsUpdate = true;
								break;
							end
						end
					end

					-- update outfit
					if (needsUpdate) then
						self:Print(strformat("Updating outfit %s...", name));
						SaveOutfit(name, outfit.appearanceSources, outfit.mainHandEnchant, outfit.offHandEnchant, outfit.icon);
					end
				end
			end
		else
			if (not serverOutfits[name]) then
				-- new outfit (should have a .modifiedBy)
				self:PrintError(strformat("Outfit data for %s is incomplete - skipped.", name));
			end
		end
	end

	-- cache server outfits
	for name, outfit in pairs(serverOutfits) do
		if (self.outfits[name]) then
			self:Debug(name..": ID #"..outfit.id);
			self.outfits[name].id = outfit.id;
		else
			-- new outfit, propably created before first sync
			self:Debug(name..": ID #"..outfit.id.." (NEW)");
			self.outfits[name] = outfit;
			self.outfits[name].modifiedBy = myCharacter;
		end
	end

	-- remove ids for unknown outfits (those shouldn't exist)
	for name, outfit in pairs(self.outfits) do
		if (not serverOutfits[name] and not outfit.deletedAt) then
			outfit.id = nil;
			self:PrintError(strformat("Outfit %s not found on server!", name));
		end
	end

	-- done
	syncing = false;
end

addon.PLAYER_LOGIN = function(self, event)
	self:SyncOutfits();
	self:UnregisterEvent(event);
end

hooksecurefunc(C_TransmogCollection, "ModifyOutfit", function(outfitID, newName)
	if (not addon.enabledState or syncing) then return; end

	for name, outfit in pairs(addon.outfits) do
		if (outfit.id == outfitID) then
			-- Found outfit, mark current name for deletion and add a new one
			addon.outfits[newName] = S:Clone(outfit);
			addon.outfits[newName].modifiedBy = myCharacter;
			addon.outfits[name] = deletedOutfit;
			break;
		end
	end
end);

hooksecurefunc(C_TransmogCollection, "DeleteOutfit", function(outfitID)
	if (not addon.enabledState or syncing) then return; end

	for name, outfit in pairs(addon.outfits) do
		if (outfit.id == outfitID) then
			addon.outfits[name] = deletedOutfit;
			break;
		end
	end
end);

hooksecurefunc(C_TransmogCollection, "SaveOutfit", function(name, appearanceSources, mainHandEnchant, offHandEnchant, icon)
	-- We cannot use the passed arguments because they are different to C_TransmogCollection.GetOutfitSources() return values
	if (not addon.enabledState or syncing) then return; end

	local found = false;
	for _, outfit in pairs(GetOutfits()) do
		if (outfit.name == name) then
			found = true;

			local appearanceSources, mainHandEnchant, offHandEnchant = GetOutfitSources(outfit.outfitID);
			addon.outfits[name] = {
				id = outfit.outfitID,
				appearanceSources = appearanceSources,
				mainHandEnchant = mainHandEnchant,
				offHandEnchant = offHandEnchant,
				icon = icon,
				modifiedBy = myCharacter,
			};
			break;
		end
	end

	if (not found) then
		addon:PrintError(strformat("Recently saved outfit %s not found on server!", name));
	end
end);
