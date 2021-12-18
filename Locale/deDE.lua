------------------------------------------------------------------------------
-- RinseOBags - Move items between bags and banks (fast)
------------------------------------------------------------------------------
-- Locale/deDE.lua - Strings for deDE
--
-- Author: Expelliarm5s / May 2021 / All Rights Reserved
--
-- Version 1.1.11
------------------------------------------------------------------------------
-- luacheck: max line length 280

local addonName, _ = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "deDE")
if not L then return end
------------------------------------------------------------------------------

-- RinseOBags.lua
L["ALT+Left-Click on item to move all to bags or banks (or ALT+Right-Click to move some."] = "ALT+Links-/Rechtsklick auf ein Item zum Verschieben zwischen Taschen und Bank/Materiallager/Gildenbank"

-- RinseOBags_Rinse.lua

L["ALT+Left/Right-Click|r to move items to/from your bank."] = "ALT+Links-/Rechtsklick|r zum Verschieben gleicher Items in/von der Bank"
L["ALT+Left/Right-Click|r to move items to/from your Guild Bank."] = "ALT+Links-/Rechtsklick|r zum Verschieben gleicher Items in/von der Gildenbank"
L["ALT+left-click on item to move all to bags or banks (or ALT+right-click to move some."] = "ALT-Linksklick zum Verschieben gleicher Items in/von der Bank oder ALT-Rechtsklick für einige."
L["Unsufficient guild rights!"] = "Fehlende Zugriffsrechte auf die Gildenbank!"
L["STOPPED: Insufficient guild rights!"] = "Abbruch: Fehlende Zugriffsrechte auf die Gildenbank!"
L["STOPPED: Reagent Bank is full!"] = "Abbruch: Materiallager ist voll!"
L["STOPPED: Item doesn't fit into the Reagent Bank!"] = "Abbruch: Item kann im Materiallager nicht gelagert werden!"
L["STOPPED: Bank is full!"] = "Abbruch: Bank ist voll!"
L["STOPPED: Bags are full!"] = "Abbruch: Taschen sind voll!"
L["Giving up!"] = "Abbruch!"
L["Rinsing out your bank: %s (ID %s) ..."] = "Verschiebe aus Deiner Bank: %s (ID %s) ..."
L["Rinsing out your Guild Bank: %s (ID %s) ..."] = "Verschiebe aus Deiner Gildenbank: %s (ID %s) ..."
L["Rinsing out your current Guild Bank ..."] = "Verschiebe alles aus Deiner Gildenbank ..."
L["Rinsing out your bags: %s (ID %s) ..."] = "Verschiebe aus Deinen Taschen: %s (ID %s) ..."
L["STOPPED: Item is soulbound or a quest item!"] = "Abbruch: Item ist seelengebunden oder ein Questitem"
L["  ... finished!"] = "  ... fertig!"
L["  ... finished, at least %s moved!"] = "  ... fertig, mind. %s verschoben!"
L["STOPPED: Item is soulbound. You don't want this in your bags :-)"] = "Abbruch: Item würde nach Verschieben seelengebunden. Willste nicht, oder?"
L["STOPPED: Some items are locked! Please try again."] = "Mindestens ein Item ist gesperrt. Versuche es gleich nocheinmal."
L["STOPPED: Some invalid item status! Please try again."] = "Abbruch: Ein Item hat einen komischen Status. Versuche es gleich nocheinmal."
L["STOPPED: Guild Bank tab was not viewable!"] = "Abbruch: Kann Gildenbankfach nicht anzeigen!"
L["STOPPED: Current Guild Bank container is full!"] = "Abbruch: Gildenbankfach ist voll!"
L["Guild Bank closed!"] = "Gildenbank geschlossen!"
L["Bank closed!"] = "Bank geschlossen!"
L["How many to move?"] = "Wie viele?"
L["No destination open!"] = "Kein Ziel geöffnet!"

L["\n\n|cffff8888ATTENTION:|r "] = "\n\n|cffff8888HINWEIS:|r "
L["|cffff8888\n\n%s changes the bank and bags buttons heavily. %s can not be used together with %s!|r"] = "|cffff8888\n\n%s verändert zu stark die Taschen und Bankfächer, daher funktioniert %s nicht mit %s!|r"
L["Select the sound that is played if on end of item move."] = "Wähle einen Sound aus, der bei Beendigung des Verschiebens ertönen soll."
L["Sound on Finish"] = "Fertig-Sound"
L["Settings"] = "Einstellungen"
L["Detected Bags/Bank Addon"] = "Erkannte Addons"
L["|cffff8888\n\nMoving items from Guild Bank to bags with ALT + right click doesn't work with %s!|r"] = "|cffff8888\n\nDas Verschieben von Items aus der Gildenbank mit Alt+Rechtsklick funktioniert leider nicht mit %s!|r"

L["ON"] = "EIN"
L["OFF"] = "AUS"

-- EOF
