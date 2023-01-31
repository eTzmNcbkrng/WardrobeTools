-- Simple Dressing Room Improvements
local addonName, ns = ...;
if (addonName == "WardrobeTools") then return; end -- Disabled in standalone version

-- Adds Target and Undress buttons
local S, C = unpack(ns);
local UnitRace = UnitRace;

local modelUndress = function()
	DressUpModel:Undress();
end

local modelSwap = function()
	if (UnitIsPlayer("target")) then
		local _, race = UnitRace("target");
		DressUpModel:SetUnit("target");
		SetDressUpBackground(DressUpFrame, race);
	else
		DressUpModel:SetUnit("player");
		SetDressUpBackground(DressUpFrame, S.myRace);
	end
end

local buttonUndress = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate");
buttonUndress:SetPoint("Center", DressUpFrame, "TopLeft", 55, -422);
buttonUndress:SetSize(80, 22);
buttonUndress:SetText("Undress");
buttonUndress:SetScript("OnClick", modelUndress);

local buttonTarget = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate");
buttonTarget:SetPoint("LEFT", buttonUndress, "RIGHT", 0, 0);
buttonTarget:SetSize(80, 22);
buttonTarget:SetText("Target");
buttonTarget:SetScript("OnClick", modelSwap);
