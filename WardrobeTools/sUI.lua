--[[ 

	Martin Karer / Sezz, 2008-2016
	sUI Methods

--]]

local addonName, ns = ...;
local S = SezzUI and SezzUI[1] or { modules = {} };
local C = SezzUI and SezzUI[2] or { modules = {} };
local P = SezzUI and SezzUI[3] or { modules = {} };
ns.S = S;
ns.C = C;
ns.P = P;

if (SezzUI) then return; end

-----------------------------------------------------------------------------

-- Lua API
local pairs, strupper, getmetatable, setmetatable, tinsert, strmatch, floor, unpack, getmetatable, gmatch = pairs, string.upper, getmetatable, setmetatable, table.insert, string.match, math.floor, unpack, getmetatable, string.gmatch;

-- WoW API/Constants
local GetRealmName, UnitName, UnitLevel, _G = GetRealmName, UnitName, UnitLevel, _G;

-----------------------------------------------------------------------------

S.dummy = function() return; end;
S.myRealm = GetRealmName();
S.myFactionGroup = select(2, UnitFactionGroup("player"));
S.myName = UnitName("player");
S.myClass = select(2, UnitClass("player"));
S.myLevel = UnitLevel("player");

-----------------------------------------------------------------------------
-- Version check to support upcoming World of Warcraft builds/patches
-----------------------------------------------------------------------------

local versionData = {};
local versionString, BUILD = GetBuildInfo();
for str in gmatch(versionString, "([^.]+)") do
	tinsert(versionData, tonumber(str));
end

local MAJOR, MINOR, MICRO = unpack(versionData);
BUILD = tonumber(BUILD);

local isBeta = (MAJOR == 9);
S.IsBeta = function()
	return isBeta;
end

-----------------------------------------------------------------------------
-- Slash Commands
-----------------------------------------------------------------------------

function S:UnregisterSlashCommand(key, slash, index)
	if (type(slash) == "table") then
		for i, s in pairs(slash) do
			self:UnregisterSlashCommand(key, s, i);
		end
	else
		if (index == nil) then
			index = 1;
		end

		key = strupper(key);
		slash = strupper(slash);

		_G["SLASH_"..key..index] = nil;
		hash_SlashCmdList[slash] = nil;
		SlashCmdList[key] = nil;
		getmetatable(SlashCmdList).__index[key] = nil;
	end
end

function S:RegisterSlashCommand(key, slash, callback, index)
	if (type(slash) == "table") then
		for i, s in pairs(slash) do
			self:RegisterSlashCommand(key, s, callback, i);
		end
	else
		key = strupper(key);
		slash = strupper(slash);

		if (index == nil) then
			index = 1;

			while _G["SLASH_"..key..index] do
				index = index + 1;
			end
		end

		if (not SlashCmdList[key]) then
			SlashCmdList[key] = callback;
		end

		_G["SLASH_"..key..index] = slash;
	end
end

-----------------------------------------------------------------------------
-- UI
-----------------------------------------------------------------------------

S.UIParent = CreateFrame("Frame", "SezzUIParent", UIParent);
S.UIParent:SetAllPoints(UIParent);

S.Scale = function(self, i)
	return i;
end

S.SkinActionButton = S.dummy;

-----------------------------------------------------------------------------
-- SavedVariables
-----------------------------------------------------------------------------

local tableADB = GetAddOnMetadata(addonName, "X-SezzADB");
local tableCDB = GetAddOnMetadata(addonName, "X-SezzCDB");
local SezzCDB, SezzADB;

setmetatable(P,  {
	__index = function(t, k)
		if (SezzCDB and SezzCDB[k]) then
			return SezzCDB[k] or C.modules[k] or C.libs[k] or C[k];
		else
			return C.modules[k] or C.libs[k] or C[k];
		end
	end
});

-----------------------------------------------------------------------------
-- Modules
-----------------------------------------------------------------------------

-- Module Event Registering
-- Credits: P3lim
local mtEventHandler = {
	__call = function(funcs, self, ...)
		for __, func in pairs(funcs) do
			func(self, ...);
		end
	end
};

local moduleRegisterEvent = function(self, event, func, unit)
	local current = self[event];

	if (func) then
		if (current) then
			-- current event handler already exists
			if (type(current) == "function") then
				-- function -> convert to table and add func
				self[event] = setmetatable({current, func}, mtEventHandler);
			else
				-- table
				for _, func in pairs(current) do
					if (func == func) then return; end
				end

				tinsert(current, func);
			end
		else
			self[event] = func;
		end
	end

	if (not unit) then
		self:_RegisterEvent(event);
	else
		self:_RegisterUnitEvent(event, unit);
	end
end

local moduleRegisterUnitEvent = function(self, event, unit, func)
	moduleRegisterEvent(self, event, func, unit);
end

local moduleEventHandler = function(self, event, ...)
	if (self[event]) then
		self[event](self, event, ...);
	end
end

local initializeSavedVariables = function(self, tableName)
	if (not tableName) then return; end
	local DB = _G[tableName];

	-- check if settings exist
	if (DB and DB[self.debugName]) then
		if (type(DB[self.debugName]) ~= "table") then
			DB[self.debugName] = {};
		end
	elseif (DB) then
		-- Initialize empty configuration table
		if (not DB[self.debugName]) then
			-- initialize
			DB[self.debugName] = {};
		end
	end
	
	return DB;
end

local moduleSettingsLoadUser = function(self, includeAccountDB)
	if (self._parentModule) then
		-- only root modules have settings
		return;
	end

	if (not C.modules[self.debugName]) then
		C.modules[self.debugName] = {
			enabled = true,
		};
	end

	-- initialize/replace settings table
	if (tableCDB) then
		SezzCDB = initializeSavedVariables(self, tableCDB);
		self.DB = P[self.debugName];
	end

	if (includeAccountDB and tableADB) then
		SezzADB = initializeSavedVariables(self, tableADB);
		self.ADB = SezzADB[self.debugName];
	end

	-- apply metatable
	setmetatable(self.DB, {
		__index = function(t, k) 
			return rawget(t, k) or C.modules[self.debugName][k];
		end
	});
end

local moduleSettingsReset = function(self)
	-- empty settings
	wipe(SezzCDB[self.debugName]);

--	-- copy default settings to character settings
--	for k, v in pairs(S:GetModuleDefaultSettings(self.debugName)) do
--		SezzCDB[self.debugName][k] = v;
--	end
end

local modulePrint = function(self, text)
	DEFAULT_CHAT_FRAME:AddMessage("|cffCCCC88s:UI "..self.debugName.."|r "..tostring(text));
end

local modulePrintError = function(self, text)
	DEFAULT_CHAT_FRAME:AddMessage("|cffCCCC88s:UI "..self.debugName.."|r |cffff0000"..tostring(text).."|r");
end

local moduleSetEnabledState = function(self, state)
	if (self.enabledState ~= state) then
		self.enabledState = state;
	
		if (state and self.OnEnable) then
			self:OnEnable();
		elseif (not state and self.OnDisable) then
			self:OnDisable();
		end
	end
end

-- Default Initialization/Enable/Disable Handlers
local moduleOnInitialize = function(self)
	-- Load Settings
	self:LoadSettings();

	-- Initialize Sub-Modules
	if (self._modules) then
		for _, mod in pairs(self._modules) do
			mod.DB = self.DB;
			if (mod.OnInitialize) then
				mod:OnInitialize();
			end
		end
	end

	-- Enable/Disable
	self:SetEnabledState(self.DB.enabled);
end

local moduleOnEnableDisable = function(self)
	self:Debug("Module "..(self.enabledState and "enabled." or "disabled."));

	-- Sub-Modules
	if (self._modules) then
		for _, mod in pairs(self._modules) do
			mod:SetEnabledState(self.enabledState);
		end
	end
end

local moduleAddDefaultHandlers = function(self)
	-- OnInitialize
	if (not self.OnInitialize) then
		self.OnInitialize = moduleOnInitialize;
	end

	-- OnEnable
	if (not self.OnEnable) then
		self.OnEnable = moduleOnEnableDisable;
	end

	-- OnDisable
	if (not self.OnDisable) then
		self.OnDisable = moduleOnEnableDisable;
	end

	return self;
end

local moduleGetChildModule = function(self, name)
	if (self._modules) then
		return self._modules[name];
	end
end

local createModule;
do
	createModule = function(parent, name, frameName, frameType, frameTemplate)
		local f = CreateFrame(frameType or "Frame", frameName, S.UIParent, frameTemplate or nil);
		f.debugName = name;
		f.enabledState = false;
		f.Debug = S.dummy;

		-- Event Handler
		f:SetScript("OnEvent", moduleEventHandler);
		f.SetEnabledState = moduleSetEnabledState;
		f._RegisterEvent = f.RegisterEvent;
		f.RegisterEvent = moduleRegisterEvent;
		f._RegisterUnitEvent = f.RegisterUnitEvent;
		f.RegisterUnitEvent = moduleRegisterUnitEvent;

		-- Debugging
		f.Print = modulePrint;
		f.PrintError = modulePrintError;

		-- Settings
		f.DB = S:GetModuleDefaultSettings(name);
		f.LoadSettings = moduleSettingsLoadUser;
		f.ResetSettings = moduleSettingsReset;
		f.AddDefaultHandlers = moduleAddDefaultHandlers;

		-- Sub-Modules
		f.CreateModule = createModule;

		-- Store Module Reference
		if (parent == S) then
			parent.modules[name] = f;
		else
			if (not parent._modules) then
				parent._modules = {};
			end

			parent._modules[name] = f;
			f._parentModule = parent;
		end

		-- Return
		return f;
	end

	S.CreateModule = createModule;
end

function S:GetModuleDefaultSettings(name)
	if (C.modules[name]) then
		return C.modules[name];
	else
		return {};
	end
end

function S:GetModule(name, createNonexistent, createWithDefaultHandler)
	if (createNonexistent and not S.modules[name]) then
		return S:CreateModule(name);
	end

	return S.modules[name];
end

-----------------------------------------------------------------------------
-- Core Events
-----------------------------------------------------------------------------

S.UIParent:SetScript("OnEvent", moduleEventHandler);
S.UIParent._RegisterEvent = S.UIParent.RegisterEvent;
S.UIParent.RegisterEvent = moduleRegisterEvent;

S.UIParent:RegisterEvent("ADDON_LOADED", function(self, event, loadedAddonName)
	if (loadedAddonName == addonName) then
		self:UnregisterEvent(event);

		if (tableADB and not _G[tableADB]) then
			_G[tableADB] = {};
		end

		if (tableCDB and not _G[tableCDB]) then
			_G[tableCDB] = {};
		end
		
		-- Initializate modules
		for moduleName, module in pairs(S.modules) do
			if (module.OnInitialize and not module.__OnInitializeCalled) then
				module:OnInitialize();
				module.__OnInitializeCalled = true;
			end
		end
	end
end);

local HandleLevelUp = function(self, event, level)
	if (not level) then
		-- PLAYER_LOGIN
		level = UnitLevel("player");
	end

	S.myLevel = level;
end

S.UIParent:RegisterEvent("PLAYER_LEVEL_UP", HandleLevelUp);
S.UIParent:RegisterEvent("PLAYER_LOGIN", HandleLevelUp);

-----------------------------------------------------------------------------
-- Utilities
-----------------------------------------------------------------------------

-- Hidden Tooltip for Scanning (Credits: tekkub)
local tt = CreateFrame("GameTooltip", "SezzUIScanningTooltip", nil, "GameTooltipTemplate");
tt:SetOwner(WorldFrame, "ANCHOR_NONE");

local lcache, rcache = {}, {};
for i = 1, 30 do
	lcache[i], rcache[i] = tt:CreateFontString("$parentTextLeft"..i), tt:CreateFontString("$parentTextRight"..i);
	lcache[i]:SetFontObject(GameFontNormal);
	rcache[i]:SetFontObject(GameFontNormal);
	tt:AddFontStrings(lcache[i], rcache[i]);
end

tt.L = setmetatable({}, {
	__index = function(t, key)
		if (tt:NumLines() >= key and lcache[key]) then
			local v = lcache[key]:GetText();
			t[key] = v;
			return v;
		end

		return nil;
	end,
})

tt.R = setmetatable({}, {
	__index = function(t, key)
		if (tt:NumLines() >= key and rcache[key]) then
			local v = rcache[key]:GetText();
			t[key] = v;
			return v;
		end

		return nil;
	end,
})

tt.ClearCache = function(self)
	self:ClearLines();

	for i in pairs(self.L) do
		self.L[i] = nil;
	end

	for i in pairs(self.R) do
		self.R[i] = nil;
	end

	if (not self:IsOwned(WorldFrame)) then
		self:SetOwner(WorldFrame, "ANCHOR_NONE");
	end
end

local ttSetInventoryItem = tt.SetInventoryItem
tt.SetInventoryItem = function(self, ...)
	self:ClearCache();
	return ttSetInventoryItem(self, ...);
end

local ttSetHyperlink = tt.SetHyperlink;
tt.SetHyperlink = function(self, hyperlink)
	self:ClearCache();
	return ttSetHyperlink(self, hyperlink);
end

local ttSetBagItem = tt.SetBagItem;
tt.SetBagItem = function(self, bag, slot)
	self:ClearCache();
	return ttSetBagItem(self, bag, slot);
end

local ttSetTalent = tt.SetTalent;
tt.SetTalent = function(self, talent)
	self:ClearCache();
	return ttSetTalent(self, talent);
end

local ttSetMerchantItem = tt.SetMerchantItem;
tt.SetMerchantItem = function(self, i)
	self:ClearCache();
	return ttSetMerchantItem(self, i);
end

S.ScanningTooltip = tt;

-- Table Utilities
function S:Clone(t)
	if (type(t) ~= "table") then
		return t;
	end

	local mt = getmetatable(t);
	local res = {};

	for k, v in pairs(t) do
		if (type(v) == "table") then
			v = self:Clone(v);
		end

		res[k] = v;
	end

	setmetatable(res, mt);
	return res;
end
