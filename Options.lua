------------------------------------------------------------------------------
-- RinseOBags - Move items between bags and banks (fast)
------------------------------------------------------------------------------
-- Options.lua - Options
--
-- Author: Expelliarm5s / May 2021 / All Rights Reserved
--
-- Version 1.1.11
------------------------------------------------------------------------------
-- luacheck: ignore 212 globals DLAPI
-- luacheck: globals AceGUIWidgetLSMlists, max line length 160, ignore 212

local addonName, addon = ...
local Options = addon:NewModule("Options", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LSM = LibStub("LibSharedMedia-3.0")
local WidgetLists = AceGUIWidgetLSMlists
--------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Settings

Options.defaults = {
	profile = {
	},
	global = {
		nwSound = "Small Chain",
	},
}

------------------------------------------------------------------------------
-- Debug Stuff

function Options:DebugPrintf(...)
	if addon.isDebug then
		local status, res = pcall(format, ...)
		if status then
			addon:DebugLog("Opt~" .. res)
		end
	end
end

------------------------------------------------------------------------------
-- Addon Loading / Player Login/Logout

function Options:Login()
	Options:DebugPrintf("Login()")

	-- see https://wow.tools/files/#search=&page=1&sort=0&desc=asc
	if LSM then
		if not addon.isClassic then
			LSM:Register("sound", "Default", 567482)
			LSM:Register("sound", "Small Chain", 567577)
			LSM:Register("sound", "Bell Toll Alliance", 566564)
			LSM:Register("sound", "Bell Toll Horde", 565853)
			LSM:Register("sound", "Auction Window Close", 567499)
			LSM:Register("sound", "Quest Failed", 567459)
			LSM:Register("sound", "Fel Nova", 568582)
			LSM:Register("sound", "Simon Large Blue", 566076)
			LSM:Register("sound", "Simon Small Blue", 567002)
			LSM:Register("sound", "Portcullis Close", 566240)
			LSM:Register("sound", "PvP Flag Taken", 569200)
			LSM:Register("sound", "Sound Cannon", 566101)
			LSM:Register("sound", "Alarm 2", 567399)
		else
			LSM:Register("sound", "Default", SOUNDKIT.AUCTION_WINDOW_OPEN)
			LSM:Register("sound", "Small Chain", SOUNDKIT.PUT_DOWN_SMALL_CHAIN)
			LSM:Register("sound", "AH Bell", SOUNDKIT.AUCTION_WINDOW_CLOSE)
			LSM:Register("sound", "Simon Small Blue", SOUNDKIT.RAID_WARNING)
		end
	end

	-- reset to default
	if addon.db.global.nwSound == "Default" then
		addon.db.global.nwSound = "Small Chain"
	end
end

function Options.PlaySound(key)
	if LSM and key and LSM:Fetch("sound", key) then
		local sound = LSM:Fetch("sound", key)
		if sound == "Interface\\Quiet.ogg" then
			-- nix
			Options:DebugPrintf("Playing/1: silence")
		else
			if tonumber(sound) then
				if addon.isClassic then
					Options:DebugPrintf("PlaySound/2: %s", tostring(sound))
					PlaySound(sound, "master")
				else
					Options:DebugPrintf("PlaySoundFile/3: %s", tostring(sound))
					PlaySoundFile(sound, "master")
				end
			elseif type(sound) == "string" then
				if sound:match("^Sound") then
					Options:DebugPrintf("PlaySound/4: std sound")
					PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "master")
				else
					Options:DebugPrintf("PlaySoundFile/5: %s", sound)
					PlaySoundFile(sound, "master")
				end
			else
				Options:DebugPrintf("PlaySound/6: std sound")
				PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "master")
			end
		end
	else
		Options:DebugPrintf("PlaySound/7: std sound")
		PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "master")
	end
end

function Options.GetOptions(uiType, uiName, appName)
	if appName == addonName then

		local wowV, wowP = GetBuildInfo()
		local wowVersion = "|nGame: WoW, Flavor: " .. (addon.isClassic and "Classic" or "Retail") .. ", Version: " .. wowV .. ", Build: " .. wowP

		local soundWidget = "LSM30_Sound"
		if addon.isClassic then
			soundWidget = "LSM30_SoundClassic"
		end

		local options = {
			type = "group",
			name = addon.METADATA.NAME .. " (" .. addon.METADATA.VERSION .. ")",
			get = function(info)
					return addon.db.global[info[#info]] or ""
				end,
			set = function(info, value)
					addon.db.global[info[#info]] = value
					Options:DebugPrintf("OK~Set %s = %s", tostring(info[#info]), tostring(value))
					addon:Update()
				end,
			args = {
				desc1a = {
					type = "description",
					order = 0,
					name = "|cff99ccff-: by " .. GetAddOnMetadata(addonName, "Author") .. " :-|r|n|n" .. GetAddOnMetadata(addonName, "Notes"),
					fontSize = "medium",
				},
				desc1b = {
					type = "description",
					order = 0.01,
					name = wowVersion,
				},
				header01 = {
					type = "header",
					name = L["Settings"],
					order = 0.3,
				},
				nwSound = {
					type = "select",
					name = L["Sound on Finish"],
					desc = L["Select the sound that is played if on end of item move."],
					order = 0.4,
					width = "double",
					dialogControl = soundWidget,
					values = WidgetLists.sound,
					set = function(_, value)
						-- value = "Default"
						addon.db.global.nwSound = value
						Options:DebugPrintf("LSM: Key=%s", value)
						if LSM and value and LSM:Fetch("sound", value) then
							local sound = LSM:Fetch("sound", value)
							if sound then
								if type(sound) == "string" then
									Options:DebugPrintf("LSM: String=%s", sound)
								end
								if type(sound) == "number" then
									Options:DebugPrintf("LSM: Number=%s", tostring(sound))
								end
							end
						end
					end,
				},
				header02 = {
					type = "header",
					name = L["Detected Bags/Bank Addon"],
					order = 0.9,
				},
				detectedAddons = {
					type = "input",
					name = L["Addon"],
					desc = L["Detected Bags/Bank Addon"],
					order = 2.01,
					width = "double",
					get = function(info)
						return addon.detectedAddons or ""
					end,
				},
				desc2 = {
					type = "description",
					order = 4,
					name = addon.detectedAddonsWarning or "",
				},
			},
		}

		return options
	end
end

-- EOF
