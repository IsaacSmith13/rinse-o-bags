------------------------------------------------------------------------------
-- RinseOBags - Move items between bags and banks (fast)
------------------------------------------------------------------------------
-- RinseOBags.lua
--
-- Author: Expelliarm5s / May 2021 / All Rights Reserved
--
-- Version 1.1.11
------------------------------------------------------------------------------
-- luacheck: ignore 212 globals DLAPI

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")
-- local private = {}
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- General Settings

addon.METADATA = {
	NAME = GetAddOnMetadata(..., "Title"),
	VERSION = GetAddOnMetadata(..., "Version"),
	NOTES = GetAddOnMetadata(..., "Notes"),
}

------------------------------------------------------------------------------
-- Debug Stuff

function addon:DebugLog(...)
	-- external
	if DLAPI then DLAPI.DebugLog(addonName, ...) end
end

function addon:DebugPrintf(...)
	if addon.isDebug then
		local status, res = pcall(format, ...)
		if status then
			addon:DebugLog(res)
		end
	end
end

function addon:ToggleDebug()
	addon.isDebug = not addon.isDebug
	if (not addon.isDebug) then
		addon:Printf("Debug is off")
		addon:DebugPrintf("Debug is off")
	else
		addon:Printf("Debug is on")
		addon:DebugPrintf("Debug is on")
	end
end

------------------------------------------------------------------------------
-- Addon Initialization

-- called by AceAddon when Addon is fully loaded
function addon:OnInitialize()
	for modle in pairs(addon.modules) do
		addon[modle] = addon.modules[modle]
	end

	if DLAPI and DLAPI.SetFormat then DLAPI.SetFormat(addonName, "default") end
	addon:DebugPrintf("OnInitialize()")

	addon.handle = "rob"
	addon.isDebug = false

	addon.timerSec = 0.5
	addon.maxRinseCount = 15

	-- addon state flags
	addon.isEnabled = false
	addon.isInfight = false
	addon.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) or (WOW_PROJECT_ID ==  WOW_PROJECT_BURNING_CRUSADE_CLASSIC)

	-- loads data and options
	addon.db = AceDB:New(addonName .. "DB", addon.Options.defaults, true)
	AceConfigRegistry:RegisterOptionsTable(addonName, addon.Options.GetOptions)
	local optionsFrame = AceConfigDialog:AddToBlizOptions(addonName, GetAddOnMetadata(addonName, "Title"))
	addon.Options.frame = optionsFrame

	-- initializing *:Login loop through all modules
	-- done in addon:OnEnable()

	-- initializing *:Logout loop
	addon:RegisterEvent("PLAYER_LOGOUT", function()
		addon:OnLogout()
		end)

	addon.SRC = addon.SRC or {}
	for _, src in pairs(addon.SRC) do
		if src.OnInitialize then
			src.OnInitialize()
		end
	end

	addon.DST = addon.DST or {}
	for _, src in pairs(addon.DST) do
		if src.OnInitialize then
			src.OnInitialize()
		end
	end

	addon:RegisterChatCommand(addon.handle .. "debug", addon.ToggleDebug)

	addon.LDB = LDB:NewDataObject(addonName, {
		type = "data source",
		label = addonName,
		text = addon:GetLDBText(),
		icon = "Interface\\Icons\\INV_Misc_Bag_07_Green",
		OnEnter = function(this)
			local tooltip = LibQTip:Acquire(addon)
			tooltip:SmartAnchorTo(this)
			tooltip:SetAutoHideDelay(0.1, this)
			tooltip:EnableMouse(true)
			addon:Update()
			tooltip:Show()
		end,
		OnClick = function(this, button)
			if button == "RightButton" then
				InterfaceOptionsFrame_OpenToCategory(GetAddOnMetadata(addonName, "Title"))
			end
			addon:Update()
		end,
		})
end

function addon:GetLDBText(status, showAddonName)
	local showName = false or showAddonName

	if showName then
		return addonName .. (status and (": " .. tostring(status)) or "")
	else
		return status and (tostring(status)) or ""
	end
end

-- called by AceAddon on PLAYER_LOGIN
function addon:OnEnable()
	addon:DebugPrintf("OnEnable()")
	addon:Printf("|cFF33FF99(" .. addon.METADATA.VERSION .. ")|r: " ..
		L["ALT+Left-Click on item to move all to bags or banks (or ALT+Right-Click to move some."])

	addon:DebugPrintf("Calling Login() in all modules")
	for modle in pairs(addon.modules) do
		if addon.modules[modle].Login then
			addon:DebugPrintf(" -> %s:Login()", modle)
			addon.modules[modle]:Login()
		end
	end

	addon.isEnabled = true
	addon.SRC = addon.SRC or {}
	for _, src in pairs(addon.SRC) do
		if src.OnEnable then
			src.OnEnable()
		end
	end

	addon.DST = addon.DST or {}
	for _, src in pairs(addon.DST) do
		if src.OnEnable then
			src.OnEnable()
		end
	end

	addon:ReagentBankAlternativeFacts()
	addon:Update()
end

-- called on PLAYER_LOGOUT
function addon:OnLogout()
	-- loop through all modules calling *:Logout()
	addon:DebugPrintf("Calling Logout() in all modules")
	for modle in pairs(addon.modules) do
		if addon.modules[modle].Logout then
			addon:DebugPrintf(" -> %s:Logout()", modle)
			addon.modules[modle]:Logout()
		end
	end
end

function addon:Update()
	-- Header
	if addon.isEnabled then
		addon.LDB.text = addon:GetLDBText(L["ON"])
	else
		addon.LDB.text = addon:GetLDBText(L["OFF"])
	end

	for modle in pairs(addon.modules) do
		if addon.modules[modle].Update then
			addon:DebugPrintf(" -> %s:Update()", modle)
			addon.modules[modle]:Update()
		end
	end

	if not LibQTip:IsAcquired(addon) then
		return
	end

	-- Tooltip
	local tooltip = LibQTip:Acquire(addon)
	tooltip:Clear()
	tooltip:SetColumnLayout(2,"LEFT", "RIGHT")

	local line = tooltip:AddHeader()
	tooltip:SetCell(line, 1, "|cfffed100" .. addon.METADATA.NAME .. " (" .. addon.METADATA.VERSION .. ")", nil, "CENTER", 2)
	line = tooltip:AddLine()
	tooltip:SetCell(line, 1, "")
	tooltip:SetCell(line, 2, "")
	tooltip:AddSeparator()
	for modle in pairs(addon.modules) do
		if addon[modle].ModuleName then
			line = tooltip:AddLine()
			tooltip:SetCell(line, 1, addon[modle]:ModuleName())
			tooltip:SetCell(line, 2, addon.db.global[modle] and "enabled" or "disabled")
		end
	end

	tooltip:AddSeparator()
	tooltip:AddLine(format("%sRight-Click%s opens configuration", ITEM_QUALITY_COLORS[5].hex, FONT_COLOR_CODE_CLOSE))
end

-- EOF
