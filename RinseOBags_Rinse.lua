------------------------------------------------------------------------------
-- RinseOBags - Move items between bags and banks (fast)
------------------------------------------------------------------------------
-- RinseOBags_Rinse.lua - Source and Destination
--
-- Author: Expelliarm5s / May 2021 / All Rights Reserved
--
-- Version 1.1.11
------------------------------------------------------------------------------
-- luacheck: ignore 212 globals DLAPI
-- luacheck: ignore 211

-- luacheck: globals BACKPACK_CONTAINER
-- luacheck: globals CursorHasItem GetContainerItemID SplitContainerItem SplitGuildBankItem
-- luacheck: globals MAX_GUILDBANK_SLOTS_PER_TAB NUM_GUILDBANK_COLUMNS NUM_SLOTS_PER_GUILDBANK_GROUP
-- luacheck: globals GetNumGuildBankTabs GetGuildBankTabInfo GetGuildBankItemInfo GetCurrentGuildBankTab GetGuildBankItemLink
-- luacheck: globals PickupGuildBankItem PutItemInBackpack PutItemInBag ContainerIDToInventoryID GetInventoryItemID LE_ITEM_CLASS_CONTAINER
-- luacheck: globals BANK_CONTAINER REAGENTBANK_CONTAINER NUM_BANKBAGSLOTS IsReagentBankUnlocked ReagentBankFrame

-- luacheck: globals Bagnon ARKINVDB AdiBagsDB ARKINVDB BagginsDB Combuctor DJBags_DB GenieDB InventorianDB OneBag3DB Stackpack_Command
-- luacheck: globals DJBagsCategoryDialog LiteBagOptions


local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceGUI = LibStub("AceGUI-3.0")
local private = {}

------------------------------------------------------------------------------
-- Helper Functions

function addon:OnTooltipSetItem(tooltip, ...)
	-- addon:DebugPrintf("OnTooltipSetItem()")

	if addon.DST["BANK"] and addon.DST["BANK"].IsOpen and addon.DST["BANK"].IsOpen() and not CursorHasItem() then
		tooltip:AddLine(string.format("|cffeda55f" .. L["ALT+Left/Right-Click|r to move items to/from your bank."]))
	end
	if ARKINVDB then
		if addon.DST["GUILDBANK"] and addon.DST["GUILDBANK"].IsOpen and addon.DST["GUILDBANK"].IsOpen() and not CursorHasItem() then
			tooltip:AddLine(string.format("|cffeda55f" .. L["ALT+Left-Click|r to move items to/from your Guild Bank."]))
		end
	else
		if addon.DST["GUILDBANK"] and addon.DST["GUILDBANK"].IsOpen and addon.DST["GUILDBANK"].IsOpen() and not CursorHasItem() then
			tooltip:AddLine(string.format("|cffeda55f" .. L["ALT+Left/Right-Click|r to move items to/from your Guild Bank."]))
		end
	end
end

------------------------------------------------------------------------------
-- Rinse Functions + Timer

function addon:Rinse()
	addon:DebugPrintf("Rinse(), Source %s, ItemID %s",
		tostring(addon.MOVE.Source), tostring(addon.MOVE.ID))

	if addon.MOVE.Source then
		if addon.MOVE.Source == "BAG" then
			if addon.DST["GUILDBANK"] and addon.DST["GUILDBANK"].IsOpen and addon.DST["GUILDBANK"].IsOpen() then
				addon.MOVE.Dest = "GUILDBANK"
			end
			if addon.DST["BANK"] and addon.DST["BANK"].IsOpen and addon.DST["BANK"].IsOpen() then
				addon.MOVE.Dest = "BANK"
			end
		else
			if addon.MOVE.Source == "GUILDBANK" or addon.MOVE.Source == "BANK" then
				addon.MOVE.Dest = "BAG"
			end
		end

		if addon.MOVE.Dest then
			addon:DebugPrintf("  rinse to %s", tostring(addon.MOVE.Dest))
			if addon.SRC[addon.MOVE.Source].Rinse then
				addon:DebugPrintf("8~  -> SRC." .. addon.MOVE.Source .. ".Rinse()")
				addon.SRC[addon.MOVE.Source].Rinse()
			end
		else
			addon:RinseAbort("|cffff8888" .. L["No destination open!"] .. "|r", "ERR~no DEST defined!")
		end
	else
		addon:RinseAbort(nil, "ERR~no SOURCE defined!")
	end
end

function addon:RinseAbort(userMsg, logMsg)
	-- addon:DebugPrintf("RinseAbort(%s, %s)", tostring(userMsg), tostring(logMsg))

	if userMsg then
		addon:Printf(userMsg)
	end

	logMsg = logMsg or userMsg
	if logMsg then
		addon:DebugPrintf("End~" .. logMsg)
	end

	addon.MOVE = addon.MOVE or {}
	addon.MOVE.ID = nil
	addon.MOVE.Count = 0
	addon.MOVE.Moved = 0
	addon.MOVE.Source = nil
	addon.MOVE.Dest = nil
	private.inRinse = nil
	private.rinseLast = nil

	if addon.moveTimer then
		addon:DebugPrintf("WARN~  stopped Timer")
		addon.moveTimer:Cancel()
		addon.moveTimer = nil
		if userMsg then
			if userMsg:match("finished") or userMsg:match("fertig") then
				addon.Options.PlaySound(addon.db.global.nwSound)
			else
				PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST, "master")
			end
		end
	end
end

function addon:StartTimer()
	if addon.moveTimer then
		addon:DebugPrintf("WARN~  Timer already active!")
		return
	end

	addon:DebugPrintf("WARN~  created Timer every %s Seconds", addon.timerSec)
	addon.moveTimer = C_Timer.NewTicker(addon.timerSec, function()
		addon:DebugPrintf("8~  Tick")
		if private.inRinse then
			addon:DebugPrintf("ERR~INRINSE!")
			return
		end

		addon:DebugPrintf("8~  Count=%s Moved=%s", tostring(addon.MOVE.Count), tostring(addon.MOVE.Moved))
		if addon.MOVE.Count and addon.MOVE.Count > 0 then
			if addon.MOVE.Moved and addon.MOVE.Moved >= addon.MOVE.Count then
				local msg = format(L["  ... finished, at least %s moved!"], tostring(addon.MOVE.Count))
				addon:RinseAbort(msg , "OK~" .. msg)
				return
			end
		end

		private.inRinse = true
		addon.MOVE = addon.MOVE or {}
		if addon.MOVE.ID then
			addon:Rinse()
		end
		private.inRinse = nil
	end)
end

--[[
	In case of an alternative bags addon the detection of the open Reagent Bank tab is not possible,
	so consider an open Reagent Bank as "alternative fact".

	Checked Bag Addons so far:

	AdiBags:
		- no detection of Reagent Bank
	ArkInventory:
		- no detection of Reagent Bank
		- Hook buttons for source Guild Bank (-> HookArkInv() in GUILDBANKFRAME_OPENED()), LeftButton only
	Baggins:
		- changes to much how bags/bank works, incompatible!
	Bagnon:
		- no detection of Reagent Bank
		- Hook buttons for source Guild Bank (-> HookBagnon() in GUILDBANKFRAME_OPENED())
	Combuctor: ok
	DJBags: ok
	Genie:
		- changes to much how bags/bank works, incompatible!
	Inventorian: ok
	LiteBag: ok
	OneBag3: ok
	Stackpack:
		- changes to much how bags/bank works, incompatible!
--]]


function addon:ReagentBankAlternativeFacts()
	local detected = false
	local detectedAddons = ""

	local addons = {
		AdiBags = AdiBagsDB, -- checked!
		ArkInventory = ARKINVDB, -- checked!
		Baggins = BagginsDB, -- bags>bank ok bank>bags: incombatible!
		Bagnon = Bagnon, -- checked!
		Combuctor = Combuctor, -- checked!
		DJBags = DJBags_DB, -- checked, Category Dialog disabled
		Genie = GenieDB, -- incompatible!
		Inventorian = InventorianDB, -- checked!
		LiteBag = LiteBagOptions, -- checked!
		OneBag3 = OneBag3DB, -- checked!
		Stackpack = Stackpack_Command, -- incompatible!
		}

	for name, obj in pairs(addons) do
		if obj then
			detected = true
			detectedAddons = detectedAddons .. name .. " " .. (GetAddOnMetadata(name, "Version") or "") .. " "

			if name == "Baggins" then
				addon.detectedAddonsWarning = addon.detectedAddonsWarning or L["\n\n|cffff8888ATTENTION:|r "]
				addon.detectedAddonsWarning = addon.detectedAddonsWarning
					.. format(L["|cffff8888\n\n%s changes the bank and bags buttons heavily. %s can not be used together with %s!|r"], name, name, addonName)
			end
			if name == "Genie" then
				addon.detectedAddonsWarning = addon.detectedAddonsWarning or L["\n\n|cffff8888ATTENTION:|r "]
				addon.detectedAddonsWarning = addon.detectedAddonsWarning
					.. format(L["|cffff8888\n\n%s changes the bank and bags buttons heavily. %s can not be used together with %s!|r"], name, name, addonName)
			end
			if name == "Stackpack" then
				addon.detectedAddonsWarning = addon.detectedAddonsWarning or L["\n\n|cffff8888ATTENTION:|r "]
				addon.detectedAddonsWarning = addon.detectedAddonsWarning
					.. format(L["|cffff8888\n\n%s changes the bank and bags buttons heavily. %s can not be used together with %s!|r"], name, name, addonName)
			end
			if name == "ArkInventory" then
				addon.detectedAddonsWarning = addon.detectedAddonsWarning or L["\n\n|cffff8888ATTENTION:|r "]
				addon.detectedAddonsWarning = addon.detectedAddonsWarning
					.. format(L["|cffff8888\n\nMoving items from Guild Bank to bags with ALT + right click doesn't work with %s!|r"], name)
			end
			if name == "DJBags" then
				addon.detectedAddonsWarning = addon.detectedAddonsWarning or L["\n\n|cffff8888ATTENTION:|r "]
				addon.detectedAddonsWarning = addon.detectedAddonsWarning
					.. format(L["|cffff8888\n\n%s changes the bank and bags buttons. %s can not be used together with %s!|r"], name, L["Item Categories"], addonName)
				if DJBagsCategoryDialog and DJBagsCategoryDialog.DisplayForItem then
					DJBagsCategoryDialog.DisplayForItem = function() end
				end
			end
		end
	end

	addon.detectedAddons = detectedAddons
	return detected
end

------------------------------------------------------------------------------
-- Find free slots in bags/bank

function addon:FindFreeGuildBankSlot(itemID)
	addon:DebugPrintf("FindFreeGuildBankSlot(%s)", tostring(itemID))

	if not itemID then
		return
	end

	local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(itemID)

	local tab = GetCurrentGuildBankTab()
	if tab then
		local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals, filtered = GetGuildBankTabInfo(tab)
		if isViewable then
			if numWithdrawals ~= 0 then
				local numSlots = MAX_GUILDBANK_SLOTS_PER_TAB or 98
				for slot=1, numSlots do
					local bankItemLink = GetGuildBankItemLink(tab, slot)
					if not bankItemLink then
						addon:DebugPrintf("  found free slot at slot %s", tostring(slot))
						return slot, false
					end
				end
			else
				addon:Printf(L["Unsufficient guild rights!"])
				addon:DebugPrintf("ERR~  unsufficient guild rights!")
			end
		end
	end
	addon:DebugPrintf("ERR~  no free slots?!")
	return
end

function addon:IsBagUsable(bagID)
	addon:DebugPrintf("9~IsBagUsable(%s)", tostring(bagID))

	if not bagID or not tonumber(bagID) then
		return false
	end

	if bagID == BACKPACK_CONTAINER then
		return true
	end

	if bagID < BACKPACK_CONTAINER then
		-- Bank + Reagentbank
		return true
	end

	local bagItemID = GetInventoryItemID("player", ContainerIDToInventoryID(bagID))
	if not bagItemID then
		addon:DebugPrintf("ERR~  bagItemID is nil!")
		return false
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel,
		itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon,
		itemSellPrice, itemClassID, itemSubClassID, bindType, expacID,
		itemSetID, isCraftingReagent = GetItemInfo(bagItemID)

	if itemClassID and itemSubClassID and itemClassID == LE_ITEM_CLASS_CONTAINER and itemSubClassID == 0 then
		return true
	end

	return false
end

function addon:FindFreeBagSlot(itemID)
	addon:DebugPrintf("FindFreeBagSlot(%s)", tostring(itemID))

	if not itemID then
		return
	end

	local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(itemID)

	for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		-- currently no check for profession bags
		if addon:IsBagUsable(bagID) then
			local bagSize = GetContainerNumSlots(bagID)
			for slot = 1, bagSize do
				local bagItemID = GetContainerItemID(bagID, slot)
				if not bagItemID then
					addon:DebugPrintf("  found free slot at bagID %s slot %s", tostring(bagID), tostring(slot))
					return bagID, slot
				end
			end
		else
			addon:DebugPrintf("  bagID %s is not usable!")
		end
	end
	addon:DebugPrintf("ERR~  no free slots?!")
end

private.INVALIDTYPE = -99
function addon:FindFreeReagentBankSlot(itemID)
	addon:DebugPrintf("FindFreeReagentBankSlot(%s)", tostring(itemID))

	if not itemID then
		return
	end

	if not IsReagentBankUnlocked or not IsReagentBankUnlocked() then
		addon:DebugPrintf("ERR~  Reagent Bank not purchased!")
		return
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
							itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice,
							itemTypeClassID, itemSubClassID, bindType, expacID, itemSetID,
							isCraftingReagent = GetItemInfo(itemID)

	if not itemTypeClassID or itemTypeClassID ~= 7 then
		addon:DebugPrintf("ERR~  Item type %s doesn't fit into the Reagent Bank!", itemTypeClassID)
		return private.INVALIDTYPE
	end

	local bagID = REAGENTBANK_CONTAINER
	local bagSize = GetContainerNumSlots(bagID)
	for slot = 1, bagSize do
		local bagItemID = GetContainerItemID(bagID, slot)
		if not bagItemID then
			addon:DebugPrintf("  found free slot at bagID %s slot %s", tostring(bagID), tostring(slot))
			return bagID, slot
		end
	end
	addon:DebugPrintf("ERR~  no free slots?!")
end

function addon:FindFreeBankSlot(itemID)
	addon:DebugPrintf("FindFreeBankSlot(%s)", tostring(itemID))

	if not itemID then
		return
	end

	local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(itemID)

	local bankBags = {BANK_CONTAINER}
	for i=1, NUM_BANKBAGSLOTS do
		bankBags[#bankBags+1] = NUM_BAG_SLOTS + i
	end
	for _, bagID in pairs(bankBags) do
		-- currently no check for profession bags
		if addon:IsBagUsable(bagID) then
			local bagSize = GetContainerNumSlots(bagID)
			for slot = 1, bagSize do
				local bagItemID = GetContainerItemID(bagID, slot)
				if not bagItemID then
					addon:DebugPrintf("  found free slot at bagID %s slot %s", tostring(bagID), tostring(slot))
					return bagID, slot
				end
			end
		end
	end
	addon:DebugPrintf("ERR~  no free slots?!")
end

function addon:BagIDToTag(bagID)
	addon:DebugPrintf("8~BagIDToTag(%s)", tostring(bagID))
	if not bagID or not tonumber(bagID) then
		return
	end

	if bagID == BANK_CONTAINER or bagID == REAGENTBANK_CONTAINER then
		return "BANK"
	elseif bagID >= BACKPACK_CONTAINER and bagID <= NUM_BAG_SLOTS then
		return "BAG"
	elseif bagID >= (NUM_BAG_SLOTS + 1) and bagID <= (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
		return "BANK"
	end
end

------------------------------------------------------------------------------
-- Button Functions

-- Button Script for Container BACKPACK_CONTAINER .. NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
function addon:ContainerFrameItemButton_OnModifiedClick(this, button, ...)
	addon:DebugPrintf("OK~ContainerFrameItemButton_OnModifiedClick(%s, %s)", tostring(this), tostring(button))

	if (button == "LeftButton" or button == "RightButton") and IsAltKeyDown() and not CursorHasItem() then
		local bagID, slot = this:GetParent():GetID(), this:GetID()
		addon:DebugPrintf("  %s clicked on bag=%s slot=%s", tostring(button), tostring(bagID), tostring(slot))

		local source = addon:BagIDToTag(bagID)
		addon:DebugPrintf("8~  -> SRC.%s.OnClick()", tostring(source))
		if addon.SRC[source] and addon.SRC[source].OnClick then
			addon.SRC[source].OnClick(this, bagID, slot, button, this.count)
		end
	else
		return addon.hooks["ContainerFrameItemButton_OnModifiedClick"](this, button, ...)
	end
end

-- Button Script for Container BANK_CONTAINER + REAGENTBANK_CONTAINER
function addon:BankFrameItemButtonGeneric_OnModifiedClick(this, button, ...)
	addon:DebugPrintf("OK~BankFrameItemButtonGeneric_OnModifiedClick(%s, %s)", tostring(this), tostring(button))

	if (button == "LeftButton" or button == "RightButton") and IsAltKeyDown() and not CursorHasItem() then
		local bagID, slot = this:GetParent():GetID(), this:GetID()
		addon:DebugPrintf("  %s clicked on bag=%s slot=%s", tostring(button), tostring(bagID), tostring(slot))

		local source = addon:BagIDToTag(bagID)
		addon:DebugPrintf("8~  -> SRC.%s.OnClick()", tostring(source))
		if addon.SRC[source] and addon.SRC[source].OnClick then
			addon.SRC[source].OnClick(this, bagID, slot, button, this.count)
		end
	else
		return addon.hooks["BankFrameItemButtonGeneric_OnModifiedClick"](this, button, ...)
	end
end

-- Button Script for Guild Bank
function addon:GuildBankItemButton_OnClick(this, button, ...)
	addon:DebugPrintf("OK~GuildBankItemButton_OnClick(%s, %s)", tostring(this), tostring(button))

	if (button == "LeftButton" or button == "RightButton") and IsAltKeyDown() then
		-- CursorHasItem() not working on GuildBank
		local tab = GetCurrentGuildBankTab()
		local slot = this:GetID()
		addon:DebugPrintf("  %s clicked on tab=%s slot=%s", tostring(button), tostring(tab), tostring(slot))

		local source = "GUILDBANK"
		addon:DebugPrintf("8~  -> SRC.%s.OnClick()", tostring(source))
		if addon.SRC[source] and addon.SRC[source].OnClick then
			if IsShiftKeyDown() then
				addon.SRC[source].OnClick(this, tab, -1, button, this.count)
			else
				addon.SRC[source].OnClick(this, tab, slot, button, this.count)
			end
		end
	else
		if this._hooked then
			this._hooked(this, button, ...)
		end
	end
end

------------------------------------------------------------------------------
-- OpenStackMoveFrame

-- addon:OpenStackMoveFrame(count, this, "BOTTOMLEFT", "TOPLEFT", "BAG", itemID, itemLink)
function addon:OpenStackMoveFrame(maxStack, parent, anchor, anchorTo, source, itemID, itemLink)
	addon:DebugPrintf("OpenStackMoveFrame(%s, %s, %s, %s, %s, %s, %s)",
		tostring(maxStack), tostring(parent), tostring(anchor), tostring(anchorTo), tostring(source), tostring(itemID), tostring(itemLink))

	local OSMF = AceGUI:Create("Window")
	OSMF.frame:ClearAllPoints();
	OSMF.frame:SetPoint(anchor, parent, anchorTo, 0, 0);
	OSMF.frame:SetClampedToScreen(true)
	OSMF:SetLayout("Flow")
	OSMF:SetTitle(L["How many to move?"])
	OSMF:SetWidth(200)
	OSMF:SetHeight(100)
	OSMF:EnableResize(false)
	OSMF:SetCallback("OnClose", function(_w)
			addon:DebugPrintf("OnClose for widget %s", tostring(_w))
			AceGUI:Release(_w)
		end)

	local btnOK = AceGUI:Create("Button")
	if btnOK.SetText then
		btnOK:SetText(OKAY)
	end

	local cB = AceGUI:Create("EditBox")
	if cB.SetText then
		cB:SetText("1")
	end
	cB:SetRelativeWidth(1)
	cB:SetCallback("OnEnterPressed",
		function()
			local value = cB:GetText()
			if value ~= "" then
				btnOK:Fire("OnClick")
			end
		end
	)
	OSMF:AddChild(cB)

	btnOK:SetRelativeWidth(0.4)
	btnOK:SetCallback("OnClick",
		function()
			local toMove = cB:GetText()
			addon:DebugPrintf("   OnClick OK: %s", tostring(toMove))
			if toMove and tonumber(toMove) and tonumber(toMove) > 0 then
				addon:Printf(L["Rinsing out your %s: %s x %s (ID %s) ..."], tostring(source), tostring(toMove), tostring(itemLink), tostring(itemID))
				addon:DebugPrintf("Begin~OK~Rinsing out your %s: %s x %s (ID %s) ...", tostring(source), tostring(toMove), tostring(itemLink), tostring(itemID))
				addon.MOVE = addon.MOVE or {}
				addon.MOVE.ID = itemID
				addon.MOVE.Source = source
				addon.MOVE.Count = tonumber(toMove)
				addon.MOVE.CountMoved = 0
				addon:StartTimer()
			end
			OSMF.frame.obj:Fire("OnClose")
		end)
	OSMF:AddChild(btnOK)

	local btnCANCEL = AceGUI:Create("Button")
	if btnCANCEL.SetText then
		btnCANCEL:SetText(CANCEL)
	end

	btnCANCEL:SetRelativeWidth(0.599999)
	btnCANCEL:SetCallback("OnClick",
		function()
			addon:DebugPrintf("   OnClick CANCEL")
			OSMF.frame.obj:Fire("OnClose")
		end)
	OSMF:AddChild(btnCANCEL)

	local t = 0.2
	addon:DebugPrintf("  new Timer after %s sec for EditBox:SetFocus()", tostring(t))
	C_Timer.After(t, function()
		cB:SetFocus()
		cB:HighlightText()
	end)
end

------------------------------------------------------------------------------
-- Bags

addon.SRC = addon.SRC or {}
addon.SRC.BAG = {}

function addon.SRC.BAG.OnInitialize()
	addon:DebugPrintf("SRC.BAG.OnInitialize()")
end

function addon.SRC.BAG.OnEnable()
	addon:DebugPrintf("SRC.BAG.OnEnable()")

	-- hook for bags BACKPACK_CONTAINER .. NUM_BAG_SLOTS
	if not addon:IsHooked("ContainerFrameItemButton_OnModifiedClick") then
		addon:DebugPrintf("  ContainerFrameItemButton_OnModifiedClick() hooked!")
		addon:RawHook("ContainerFrameItemButton_OnModifiedClick", true)
	end

	-- Tooltip
	if not addon:IsHooked(GameTooltip, "OnTooltipSetItem") then
		addon:DebugPrintf("  GameTooltip is hooked.")
		addon:HookScript(GameTooltip, "OnTooltipSetItem")
	end
	-- FIXME: hook to BattlePetTooltip
end

function addon.SRC.BAG.OnClick(this, bagID, slot, button, count)
	addon:DebugPrintf("SRC.BAG.OnClick(%s, %s, %s, %s)", tostring(bagID), tostring(slot), tostring(button), tostring(count))

	if not bagID or not slot then
		return
	end

	local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bagID, slot)
	if locked then
		addon:DebugPrintf("ERR  ~%s (%s) is locked!", tostring(itemLink), tostring(itemID))
	else
		if itemID and tonumber(itemID) then
			if button == "LeftButton" then
				addon:Printf(L["Rinsing out your bags: %s (ID %s) ..."], tostring(itemLink), tostring(itemID))
				addon:DebugPrintf("Begin~OK~Rinsing out your bags: %s (ID %s) ...", tostring(itemLink), tostring(itemID))
				addon.MOVE = addon.MOVE or {}
				addon.MOVE.ID = itemID
				addon.MOVE.Source = "BAG"
				addon:StartTimer()
			elseif button == "RightButton" then
				addon:OpenStackMoveFrame(count, this, "BOTTOMLEFT", "TOPLEFT", "BAG", itemID, itemLink)
			else
				addon:DebugPrintf("ERR~  invalid hook, button %s!", tostring(button))
			end
		else
			-- click on empty slot
			addon:DebugPrintf("ERR~  invalid itemID: %s (%s)!", tostring(itemLink), tostring(itemID))
		end
	end
end

function addon.SRC.BAG.RinseToGUILDBANK(bagID, slot, itemCount)
	addon:DebugPrintf("SRC.BAG.RinseToGUILDBANK(%s, %s)", tostring(bagID), tostring(slot))

	local toMove = 0
	local tab = GetCurrentGuildBankTab()
	local toSlot = addon:FindFreeGuildBankSlot(addon.MOVE.ID)

	if not toSlot then
		addon:RinseAbort("|cffff8888" .. L["STOPPED: Current Guild Bank container is full!"] .. "|r")
		return toMove
	end

	local doPickup = true
	if addon.MOVE.Count and addon.MOVE.Count > 0 then
		toMove = addon.MOVE.Count - addon.MOVE.Moved
		if toMove < itemCount then
			doPickup = false
		else
			toMove = itemCount
		end
		addon:DebugPrintf("  %s to move, %s already moved, move %s", tostring(addon.MOVE.Count), tostring(addon.MOVE.Moved), tostring(toMove))
		if toMove == 0 then
			return toMove
		end
	end

	if doPickup then
		addon:DebugPrintf("7~  pick it up from bag %s slot %s", tostring(bagID), tostring(slot))
		PickupContainerItem(bagID, slot)
	else
		addon:DebugPrintf("7~  split it up from bag %s slot %s", tostring(bagID), tostring(slot))
		SplitContainerItem(bagID, slot, toMove)
	end

	addon:DebugPrintf("7~  place it into tab %s slot %s", tostring(tab), tostring(toSlot))
	PickupGuildBankItem(tab, toSlot)
	ClearCursor()

	return toMove
end

function addon.SRC.BAG.RinseToBANK(bagID, slot, itemCount)
	addon:DebugPrintf("SRC.BAG.RinseToBANK(%s, %s)", tostring(bagID), tostring(slot))

	local toMove = 0
	local toBag, toSlot
	if (ReagentBankFrame and ReagentBankFrame:IsShown()) or addon:ReagentBankAlternativeFacts() then
		toBag, toSlot = addon:FindFreeReagentBankSlot(addon.MOVE.ID)

		if not toBag or toBag == private.INVALIDTYPE  then
			if not toBag then
				-- switch to normal bank
				addon:DebugPrintf("WARN~  reagent bank full, try normal bank")
				toBag, toSlot = addon:FindFreeBankSlot(addon.MOVE.ID)
				if not toBag then
					addon:RinseAbort("|cffff8888" .. L["STOPPED: Bank is full!"] .. "|r")
					return toMove
				end
				-- go on!
			else
				-- switch to normal bank
				addon:DebugPrintf("WARN~  item doesn't fit into the reagent bank, try normal bank")
				toBag, toSlot = addon:FindFreeBankSlot(addon.MOVE.ID)
				if not toBag then
					addon:RinseAbort(L["STOPPED: Item doesn't fit into the Reagent Bank!"])
					return toMove
				end
				-- go on!
			end
		end
	else
		toBag, toSlot = addon:FindFreeBankSlot(addon.MOVE.ID)
		if not toBag then
			-- switch to normal bank
			addon:DebugPrintf("WARN~  reagent bank full, try normal bank")
			toBag, toSlot = addon:FindFreeBankSlot(addon.MOVE.ID)
			if not toBag then
				addon:RinseAbort("|cffff8888" .. L["STOPPED: Bank is full!"] .. "|r")
				return toMove
			end
		end
	end

	local doPickup = true
	if addon.MOVE.Count and addon.MOVE.Count > 0 then
		toMove = addon.MOVE.Count - addon.MOVE.Moved
		if toMove < itemCount then
			doPickup = false
		else
			toMove = itemCount
		end
		addon:DebugPrintf("  %s to move, %s already moved, move %s", tostring(addon.MOVE.Count), tostring(addon.MOVE.Moved), tostring(toMove))
		if toMove == 0 then
			return toMove
		end
	end

	if doPickup then
		addon:DebugPrintf("7~  pick it up from bag %s slot %s", tostring(bagID), tostring(slot))
		PickupContainerItem(bagID, slot)
	else
		addon:DebugPrintf("7~  split it up from bag %s slot %s", tostring(bagID), tostring(slot))
		SplitContainerItem(bagID, slot, toMove)
	end

	addon:DebugPrintf("7~  place it into bag %s slot %s", tostring(toBag), tostring(toSlot))
	PickupContainerItem(toBag, toSlot)
	ClearCursor()

	return toMove
end

function addon.SRC.BAG.Rinse()
	addon:DebugPrintf("SRC.BAG.Rinse()")

	for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bagID) do
			local icon, itemCount, locked, quality, readable, lootable, contItemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bagID, slot)
			if itemID then
				if not locked then
					if addon.MOVE.ID == itemID then
						local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
							itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice,
							itemTypeClassID, itemSubClassID, bindType, expacID, itemSetID,
							isCraftingReagent = GetItemInfo(itemID)
						-- check for soulbound, GetItemInfo() can return nil
						if itemName and itemLink then
							if addon.MOVE.Dest and addon.MOVE.Dest ~= "BANK" then
								if (bindType == LE_ITEM_BIND_ON_ACQUIRE or bindType == LE_ITEM_BIND_QUEST) then
									addon:RinseAbort("|cffff8888" .. L["STOPPED: Item is soulbound or a quest item!"] .. "|r")
									return
								end
							end
						end

						addon:DebugPrintf("  moving %s x %s from bagID %s slot %s, itemType=%s, itemTypeClassID=%s, itemSubClassID=%s ",
							tostring(itemCount), tostring(itemLink), tostring(bagID), tostring(slot),
							tostring(itemType), tostring(itemTypeClassID), tostring(itemSubClassID)
							)

						private.rinseCount = private.rinseCount or addon.maxRinseCount
						if private.rinseCount < 0 then
							addon:RinseAbort(L["Giving up!"])
							private.rinseCount = nil
							private.rinseLast = nil
							return false
						end

						private.rinseLast = private.rinseLast or ""
						private.rinseToMove = private.rinseToMove or 0
						if tostring(bagID) .. tostring(slot) .. tostring(itemCount) == private.rinseLast then
							addon:DebugPrintf("WARN~rinse %s again, tries: %s", tostring(private.rinseLast), tostring(private.rinseCount))
							private.rinseCount = private.rinseCount - 1
							private.rinseToMove = 0
						else
							private.rinseLast = tostring(bagID) .. tostring(slot) .. tostring(itemCount)
							private.rinseCount = nil
							addon.MOVE.Moved = addon.MOVE.Moved + private.rinseToMove
						end

						addon:DebugPrintf("8~  -> RinseTo" .. addon.MOVE.Dest .. "()")
						if addon.SRC.BAG["RinseTo" .. addon.MOVE.Dest] then
							private.rinseToMove = addon.SRC.BAG["RinseTo" .. addon.MOVE.Dest](bagID, slot, itemCount)
						end
						return
					end
				end
			end
		end
	end

	addon:RinseAbort(L["  ... finished!"], "OK~  ... finished!")
end

addon.DST = addon.DST or {}
addon.DST.BAG = {}

function addon.DST.BAG.OnInitialize()
	addon:DebugPrintf("DST.BAG.OnInitialize()")

end

function addon.DST.BAG.OnEnable()
	addon:DebugPrintf("DST.BAG.OnEnable()")
end

------------------------------------------------------------------------------
-- Bank

addon.SRC = addon.SRC or {}
addon.SRC.BANK = {}

function addon.SRC.BANK.OnInitialize()
	addon:DebugPrintf("SRC.BANK.OnInitialize()")
end

function addon.SRC.BANK.OnEnable()
	addon:DebugPrintf("SRC.BANK.OnEnable()")

	-- hook for bags NUM_BAG_SLOTS + 1 .. NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
	if not addon:IsHooked("ContainerFrameItemButton_OnModifiedClick") then
		addon:DebugPrintf("  ContainerFrameItemButton_OnModifiedClick() hooked!")
		addon:RawHook("ContainerFrameItemButton_OnModifiedClick", true)
	end

	-- hook for bag BANK_CONTAINER
	if not addon:IsHooked("BankFrameItemButtonGeneric_OnModifiedClick") then
		addon:DebugPrintf("  BankFrameItemButtonGeneric_OnModifiedClick() hooked!")
		addon:RawHook("BankFrameItemButtonGeneric_OnModifiedClick", true)
	end
end

function addon.SRC.BANK.OnClick(this, bagID, slot, button, count)
	addon:DebugPrintf("SRC.BANK.OnClick(%s, %s, %s, %s)", tostring(bagID), tostring(slot), tostring(button), tostring(count))

	if not bagID or not slot then
		return
	end

	local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bagID, slot)
	if locked then
		addon:DebugPrintf("ERR~  %s (%s) is locked!", tostring(itemLink), tostring(itemID))
	else
		if itemID and tonumber(itemID) then
			if button == "LeftButton" then
				addon:Printf(L["Rinsing out your bank: %s (ID %s) ..."], tostring(itemLink), tostring(itemID))
				addon:DebugPrintf("Begin~OK~Rinsing out your bank: %s (ID %s) ...", tostring(itemLink), tostring(itemID))
				addon.MOVE = addon.MOVE or {}
				addon.MOVE.ID = itemID
				addon.MOVE.Source = "BANK"
				addon:StartTimer()
			elseif button == "RightButton" then
				addon:OpenStackMoveFrame(count, this, "BOTTOMLEFT", "TOPLEFT", "BANK", itemID, itemLink)
			else
				addon:DebugPrintf("ERR~  invalid hook, button %s!", tostring(button))
			end
		else
			-- click on empty slot
			addon:DebugPrintf("ERR~  invalid itemID: %s (%s)!", tostring(itemLink), tostring(itemID))
		end
	end
end

function addon.SRC.BANK.RinseToBAG(bagID, slot, itemCount)
	addon:DebugPrintf("SRC.BANK.RinseToBAG(%s, %s)", tostring(bagID), tostring(slot))

	local toMove = 0
	local toBag, toSlot = addon:FindFreeBagSlot(addon.MOVE.ID)

	if not toBag then
		addon:RinseAbort("|cffff8888" .. L["STOPPED: Bags are full!"] .. "|r", "ERR~STOPPED: Bags are full!")
		return toMove
	end

	local doPickup = true
	if addon.MOVE.Count and addon.MOVE.Count > 0 then
		toMove = addon.MOVE.Count - addon.MOVE.Moved
		if toMove < itemCount then
			doPickup = false
		else
			toMove = itemCount
		end
		addon:DebugPrintf("  %s to move, %s already moved, move %s", tostring(addon.MOVE.Count), tostring(addon.MOVE.Moved), tostring(toMove))
		if toMove == 0 then
			return toMove
		end
	end

	if doPickup then
		addon:DebugPrintf("7~  pick it up from bag %s slot %s", tostring(bagID), tostring(slot))
		PickupContainerItem(bagID, slot)
	else
		addon:DebugPrintf("7~  split it up from bag %s slot %s", tostring(bagID), tostring(slot))
		SplitContainerItem(bagID, slot, toMove)
	end

	addon:DebugPrintf("7~  place it into bag %s slot %s", tostring(toBag), tostring(toSlot))
	PickupContainerItem(toBag, toSlot)
	ClearCursor()

	return toMove
end

function addon.SRC.BANK.Rinse()
	addon:DebugPrintf("SRC.BANK.Rinse()")

	-- check for opened reagent bank
	local bankBags
	if ReagentBankFrame and ReagentBankFrame:IsShown() then
		bankBags = {REAGENTBANK_CONTAINER}
	else
		bankBags = {BANK_CONTAINER}
		for i=1, NUM_BANKBAGSLOTS do
			bankBags[#bankBags+1] = NUM_BAG_SLOTS + i
		end
	end

	-- for "alternate" views of bank content, a.k.a. bank addons, ingame bank tab
	-- is closed, so consider reagent bank as source too
	if addon:ReagentBankAlternativeFacts() then
		bankBags = {REAGENTBANK_CONTAINER, BANK_CONTAINER}
		for i=1, NUM_BANKBAGSLOTS do
			bankBags[#bankBags+1] = NUM_BAG_SLOTS + i
		end
	end

	for _, bagID in pairs(bankBags) do
		for slot = 1, GetContainerNumSlots(bagID) do
			local icon, itemCount, locked, quality, readable, lootable, contItemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bagID, slot)
			if itemID then
				if not locked then
					if addon.MOVE.ID == itemID then
						local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
							itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice,
							itemTypeClassID, itemSubClassID, bindType, expacID, itemSetID,
							isCraftingReagent = GetItemInfo(itemID)
						if itemName and itemLink then
							if addon.MOVE.Dest and addon.MOVE.Dest ~= "BAG" then
								if (bindType == LE_ITEM_BIND_ON_ACQUIRE or bindType == LE_ITEM_BIND_QUEST) then
									addon:RinseAbort("|cffff8888" .. L["STOPPED: Item is soulbound or a quest item!"] .. "|r")
									return
								end
							end
						end

						addon:DebugPrintf("  moving %s x %s from bagID %s slot %s",
							tostring(itemCount), tostring(itemLink), tostring(bagID), tostring(slot))

						private.rinseCount = private.rinseCount or addon.maxRinseCount
						if private.rinseCount < 0 then
							addon:RinseAbort(L["Giving up!"])
							private.rinseCount = nil
							private.rinseLast = nil
							return false
						end

						private.rinseLast = private.rinseLast or ""
						private.rinseToMove = private.rinseToMove or 0
						if tostring(bagID) .. tostring(slot) .. tostring(itemCount) == private.rinseLast then
							addon:DebugPrintf("WARN~rinse %s again, tries: %s", tostring(private.rinseLast), tostring(private.rinseCount))
							private.rinseCount = private.rinseCount - 1
							private.rinseToMove = 0
						else
							private.rinseLast = tostring(bagID) .. tostring(slot) .. tostring(itemCount)
							private.rinseCount = nil
							addon.MOVE.Moved = addon.MOVE.Moved + private.rinseToMove
						end

						addon:DebugPrintf("8~  -> RinseTo" .. addon.MOVE.Dest .. "()")
						if addon.SRC.BANK["RinseTo" .. addon.MOVE.Dest] then
							private.rinseToMove = addon.SRC.BANK["RinseTo" .. addon.MOVE.Dest](bagID, slot, itemCount)
						end
						return
					end
				end
			end
		end
	end

	addon:RinseAbort(L["  ... finished!"], "OK~  ... finished!")
end


addon.DST = addon.DST or {}
addon.DST.BANK = {}

function addon.DST.BANK.OnInitialize()
	addon:DebugPrintf("DST.BANK.OnInitialize()")
end

function addon.DST.BANK.OnEnable()
	addon:DebugPrintf("DST.BANK.OnEnable()")

	addon:RegisterEvent("BANKFRAME_OPENED")
	addon:RegisterEvent("BANKFRAME_CLOSED")
end

function addon.DST.BANK.IsOpen()
	return addon.DST.BANK.isOpen
end

function addon:BANKFRAME_OPENED()
	addon:DebugPrintf("BANKFRAME_OPENED()")

	addon:RinseAbort()

	addon.DST.BANK.isOpen = true
end

function addon:BANKFRAME_CLOSED()
	addon:DebugPrintf("BANKFRAME_CLOSED()")

	if addon.DST.BANK.isOpen then
		addon:RinseAbort(L["Bank closed!"])
	end

	addon.DST.BANK.isOpen = false
end

------------------------------------------------------------------------------
-- Guild Bank

addon.SRC = addon.SRC or {}
addon.SRC.GUILDBANK = {}

function addon.SRC.GUILDBANK.OnInitialize()
	addon:DebugPrintf("SRC.GUILDBANK.OnInitialize()")
end

function addon.SRC.GUILDBANK.OnEnable()
	addon:DebugPrintf("SRC.GUILDBANK.OnEnable()")
end

function addon.SRC.GUILDBANK.OnClick(this, tab, slot, button, count)
	addon:DebugPrintf("SRC.GUILDBANK.OnClick(%s, %s, %s, %s)", tostring(tab), tostring(slot), tostring(button), tostring(count))

	if not tab or not slot then
		return
	end

	if slot == -1 then
		addon:Printf(L["Rinsing out your current Guild Bank ..."])
		addon:DebugPrintf("OK~Rinsing out your Guild Bank ...")
		addon.MOVE = addon.MOVE or {}
		addon.MOVE.ID = -1
		addon.MOVE.Source = "GUILDBANK"
		addon:StartTimer()
	end

	local itemLink = GetGuildBankItemLink(tab, slot)
	if itemLink then
		local linkType, itemID = string.match(itemLink, "|H([^:]+):(%d+)")
		if itemID and tonumber(itemID) then
			if button == "LeftButton" then
				addon:Printf(L["Rinsing out your Guild Bank: %s (ID %s) ..."], tostring(itemLink), tostring(itemID))
				addon:DebugPrintf("OK~Rinsing out your Guild Bank: %s (ID %s) ...", tostring(itemLink), tostring(itemID))
				addon.MOVE = addon.MOVE or {}
				addon.MOVE.ID = itemID
				addon.MOVE.Source = "GUILDBANK"
				addon:StartTimer()
			elseif button == "RightButton" then
				addon:OpenStackMoveFrame(count, this, "BOTTOMLEFT", "TOPLEFT", "GUILDBANK", itemID, itemLink)
			else
				addon:DebugPrintf("ERR~  invalid hook, button %s!", tostring(button))
			end
		else
			-- click on empty slot
			addon:DebugPrintf("ERR~  invalid itemID: %s (%s)!", tostring(itemLink), tostring(itemID))
		end
	else
		-- click on empty slot
		addon:DebugPrintf("ERR~  invalid itemLink: %s!", tostring(itemLink))
	end
end

function addon.SRC.GUILDBANK.RinseToBAG(tab, slot, itemCount)
	addon:DebugPrintf("SRC.GUILDBANK.RinseToBAG(%s, %s)", tostring(tab), tostring(slot))

	local toMove = 0
	local toBag, toSlot = addon:FindFreeBagSlot(addon.MOVE.ID)

	if not toBag then
		addon:RinseAbort("|cffff8888" .. L["STOPPED: Bags are full!"] .. "|r", "ERR~STOPPED: Bags are full!")
		return toMove
	end

	local doPickup = true
	if addon.MOVE.Count and addon.MOVE.Count > 0 then
		toMove = addon.MOVE.Count - addon.MOVE.Moved
		if toMove < itemCount then
			doPickup = false
		else
			toMove = itemCount
		end
		addon:DebugPrintf("  %s to move, %s already moved, move %s", tostring(addon.MOVE.Count), tostring(addon.MOVE.Moved), tostring(toMove))
		if toMove == 0 then
			return toMove
		end
	end

	if doPickup then
		addon:DebugPrintf("7~  pick it up from tab %s slot %s", tostring(tab), tostring(slot))
		PickupGuildBankItem(tab, slot)
	else
		addon:DebugPrintf("7~  split it up from tab %s slot %s", tostring(tab), tostring(slot))
		SplitGuildBankItem(tab, slot, toMove)
	end

	addon:DebugPrintf("7~  place it into bag %s slot %s", tostring(toBag), tostring(toSlot))
	PickupContainerItem(toBag, toSlot)
	ClearCursor()

	return toMove
end

function addon.SRC.GUILDBANK.Rinse()
	addon:DebugPrintf("SRC.GUILDBANK.Rinse()")

	local tab = GetCurrentGuildBankTab()
	local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals, filtered = GetGuildBankTabInfo(tab)
	if isViewable then
		if numWithdrawals ~= 0 then
			local numSlots = MAX_GUILDBANK_SLOTS_PER_TAB or 98
			for slot=1, numSlots do
				local bankItemLink = GetGuildBankItemLink(tab, slot)
				if bankItemLink then
					local linkType, itemID = string.match(bankItemLink, "|H([^:]+):(%d+)")
					if itemID and tonumber(itemID) then
						local texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(tab, slot)
						if not locked then
							if addon.MOVE.ID == -1 or addon.MOVE.ID == itemID then
								-- check for soulbound, GetItemInfo() can return nil
								local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType,
									itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice,
									itemTypeClassID, itemSubClassID, bindType, expacID, itemSetID,
									isCraftingReagent = GetItemInfo(itemID)
								if itemName and itemLink then
									if (bindType == LE_ITEM_BIND_ON_ACQUIRE or bindType == LE_ITEM_BIND_QUEST) then
										addon:RinseAbort("|cffff8888" .. L["STOPPED: Item is soulbound. You don't want this in your bags :-)"] .. "|r")
										return
									end
								end

								addon:DebugPrintf("  moving %s x %s from tab %s slot %s",
									tostring(itemCount), tostring(itemLink), tostring(tab), tostring(slot))

								private.rinseCount = private.rinseCount or addon.maxRinseCount
								if private.rinseCount < 0 then
									addon:RinseAbort(L["Giving up!"])
									private.rinseCount = nil
									private.rinseLast = nil
									return false
								end

								private.rinseLast = private.rinseLast or ""
								private.rinseToMove = private.rinseToMove or 0
								if tostring(tab) .. tostring(slot) .. tostring(itemCount) == private.rinseLast then
									addon:DebugPrintf("WARN~rinse %s again, tries: %s", tostring(private.rinseLast), tostring(private.rinseCount))
									private.rinseCount = private.rinseCount - 1
									private.rinseToMove = 0
								else
									private.rinseLast = tostring(tab) .. tostring(slot) .. tostring(itemCount)
									private.rinseCount = nil
									addon.MOVE.Moved = addon.MOVE.Moved + private.rinseToMove
								end

								addon:DebugPrintf("8~  -> RinseTo" .. addon.MOVE.Dest .. "()")
								if addon.SRC.GUILDBANK["RinseTo" .. addon.MOVE.Dest] then
									private.rinseToMove = addon.SRC.GUILDBANK["RinseTo" .. addon.MOVE.Dest](tab, slot, itemCount)
								end
								return
							end
						else
							addon:RinseAbort(L["STOPPED: Some items are locked! Please try again."],
								format("ERR~slot is locked: tab %s slot %s!", tostring(tab), tostring(slot)))
							return
						end
					else
						addon:RinseAbort(L["STOPPED: Some invalid item status! Please try again."],
								format("ERR~invalid itemID of %s: tab %s slot %s!", tostring(bankItemLink), tostring(tab), tostring(slot)))
						return
					end
				end
			end

			addon:RinseAbort(L["  ... finished!"], "OK~  ... finished!")
		else
			addon:RinseAbort(L["STOPPED: Insufficient guild rights!"], "ERR~STOPPED: Insufficient guild rights!")
		end
	else
		addon:RinseAbort(L["STOPPED: Guild Bank tab was not viewable!"], "ERR~STOPPED: Guild Bank tab was not viewable!")
	end
end

addon.DST = addon.DST or {}
addon.DST.GUILDBANK = {}

function addon.DST.GUILDBANK.OnInitialize()
	addon:DebugPrintf("DST.GUILDBANK.OnInitialize()")

end

function addon.DST.GUILDBANK.OnEnable()
	addon:DebugPrintf("DST.GUILDBANK.OnEnable()")

	if not addon.isClassic then
		addon:RegisterEvent("GUILDBANKFRAME_OPENED")
		addon:RegisterEvent("GUILDBANKFRAME_CLOSED")
	end
end

function addon.DST.GUILDBANK.IsOpen()
	return addon.DST.GUILDBANK.isOpen
end

function addon:HookBagnon()
	addon:DebugPrintf("HookBagnon()")
	local numSlots = 98
	local hooked
	for grpslot = 1, numSlots do
		local button = _G["BagnonGuildItem"..tostring(grpslot)]
		if button then
			if not button._hooked then
				hooked = true
				button._hooked = button:GetScript("OnClick")
				button:SetScript("OnClick", function(this, btn)
					addon:GuildBankItemButton_OnClick(this, btn)
				end)
			end
		end
	end
	if hooked then
		addon:DebugPrintf("  hooked all BagnonGuildItemX")
	end
end

function addon:HookArkInv()
	addon:DebugPrintf("HookArkInv()")
	local numSlots = 98
	local hooked
	for grp = 1, 8 do
		for grpslot = 1, numSlots do
			local button = _G["ARKINV_Frame4ScrollContainerBag"..tostring(grp).."Item"..tostring(grpslot)]
			if button then
				addon:DebugPrintf("HookArkInv() for Bag %s Slot %s", tostring(grp), tostring(grpslot))
				if not button._hooked then
					hooked = true
					button:SetScript("OnClick", function(this, btn)
						-- only LeftButton works, RightButton can't change how Arkinventory handles click
						if (btn == "LeftButton") and IsAltKeyDown() then
							ClearCursor()
							addon:GuildBankItemButton_OnClick(this, btn)
						end
					end)
				end
			end
		end
	end
	if hooked then
		addon:DebugPrintf("  hooked all BagnonGuildItemX")
	end
end

function addon:GUILDBANKFRAME_OPENED()
	addon:DebugPrintf("GUILDBANKFRAME_OPENED()")

	local hooked
	if NUM_GUILDBANK_COLUMNS and NUM_SLOTS_PER_GUILDBANK_GROUP then
		for column = 1, NUM_GUILDBANK_COLUMNS do
			for grpslot = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
				local button = _G["GuildBankColumn"..tostring(column).."Button"..tostring(grpslot)]
				if not button._hooked then
					hooked = true
					button._hooked = button:GetScript("OnClick")
					button:SetScript("OnClick", function(this, btn)
						addon:GuildBankItemButton_OnClick(this, btn)
					end)
				end
			end
		end
		if hooked then
			addon:DebugPrintf("  hooked all GuildBankColumnXButtonYs")
		end
	end

	if Bagnon then
		local t = 0.3
		addon:DebugPrintf("  new Timer after %s sec for HookBagnon", tostring(t))
		C_Timer.After(t, function() addon:HookBagnon() end)
	end

	if ARKINVDB then
		local t = 0.5
		addon:DebugPrintf("  new Timer after %s sec for HookArkInv", tostring(t))
		C_Timer.After(t, function() addon:HookArkInv() end)
	end

	addon:RinseAbort()

	addon.DST.GUILDBANK.isOpen = true
end

function addon:GUILDBANKFRAME_CLOSED()
	addon:DebugPrintf("GUILDBANKFRAME_CLOSED()")

	if addon.DST.GUILDBANK.isOpen then
		addon:RinseAbort(L["Guild Bank closed!"])
	end

	addon.DST.GUILDBANK.isOpen = false
end

-- EOF
