------------------------------------------------------------------------------
-- RinseOBags - Move items between bags and banks (fast)
------------------------------------------------------------------------------
-- Locale/enUS.lua - Strings for enUS
--
-- Author: Expelliarm5s / May 2021 / All Rights Reserved
--
-- Version 1.1.11
------------------------------------------------------------------------------
-- luacheck: max line length 280

local addonName, _ = ...
local silent = true
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true, silent)
if not L then return end
------------------------------------------------------------------------------

-- RinseOBags.lua
L["ALT+Left-Click on item to move all to bags or banks (or ALT+Right-Click to move some."] = true

-- RinseOBags_Rinse.lua
L["ALT+Left/Right-Click|r to move items to/from your bank."] = true
L["ALT+Left/Right-Click|r to move items to/from your Guild Bank."] = true
L["ALT+Left-Click on item to move all to bags or banks (or ALT+Right-Click to move some."] = true
L["Unsufficient guild rights!"] = true
L["STOPPED: Insufficient guild rights!"] = true
L["STOPPED: Reagent Bank is full!"] = true
L["STOPPED: Item doesn't fit into the Reagent Bank!"] = true
L["STOPPED: Bank is full!"] = true
L["STOPPED: Bags are full!"] = true
L["Giving up!"] = true
L["Rinsing out your bank: %s (ID %s) ..."] = true
L["Rinsing out your Guild Bank: %s (ID %s) ..."] = true
L["Rinsing out your current Guild Bank ..."] = true
L["Rinsing out your bags: %s (ID %s) ..."] = true
L["STOPPED: Item is soulbound or a quest item!"] = true
L["  ... finished!"] = true
L["  ... finished, at least %s moved!"] = true
L["STOPPED: Item is soulbound. You don't want this in your bags :-)"] = true
L["STOPPED: Some items are locked! Please try again."] = true
L["STOPPED: Some invalid item status! Please try again."] = true
L["STOPPED: Guild Bank tab was not viewable!"] = true
L["STOPPED: Current Guild Bank container is full!"] = true
L["Guild Bank closed!"] = true
L["Bank closed!"] = true
L["How many to move?"] = true
L["No destination open!"] = true

L["\n\n|cffff8888ATTENTION:|r "] = true
L["|cffff8888\n\n%s changes the bank and bags buttons heavily. %s can not be used together with %s!|r"] = true
L["Select the sound that is played if on end of item move."] = true
L["Sound on Finish"] = true
L["Settings"] = true
L["Detected Bags/Bank Addon"] = true
L["|cffff8888\n\nMoving items from Guild Bank to bags with ALT + right click doesn't work with %s!|r"] = true

L["ON"] = true
L["OFF"] = true

-- EOF
