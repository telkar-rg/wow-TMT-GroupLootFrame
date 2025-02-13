﻿local ADDON_NAME, ADDON_TABLE = ...

local TMT = _G["TransmogTracker"]
if not TMT then return end

ADDON_NAME_SHORT = "TMT_GLF"



local function DPrint(...)
	DEFAULT_CHAT_FRAME:AddMessage( "|cff66bbff"..ADDON_NAME_SHORT.."|r: " .. strjoin("|r; ", tostringall(...) ) )
	ChatFrame3:AddMessage( "|cff66bbff"..ADDON_NAME_SHORT.."|r: " .. strjoin("|r; ", tostringall(...) ) )
end
local print=DPrint


-- ################################################################
-- ################################################################
-- ################################################################
-- ################################################################

local TMT_GLF_GroupLootFrame_OpenNewFrame
local TMT_GLF_GroupLootFrame_OnHide

local ClientLocale
local PlayerFaction, PlayerClass
local tmog_itemSubClasses = {}

local pattern_item = "(\124c%x+\124Hitem:(%d+):[-:%d]+\124h%[(.-)%]\124h\124r)"


-- 1 = head
-- 2 = neck
-- 3 = shoulder
-- 4 = shirt
-- 5 = chest
-- 6 = waist
-- 7 = legs
-- 8 = feet
-- 9 = wrist
-- 10 = hands
-- 11 = finger 1
-- 12 = finger 2
-- 13 = trinket 1
-- 14 = trinket 2
-- 15 = back
-- 16 = main hand
-- 17 = off hand
-- 18 = ranged
-- 19 = tabard
local tmog_allowed = {
	["ALL"] = {
		["INVTYPE_HEAD"] 		= 1,
		["INVTYPE_SHOULDER"] 	= 1,
		["INVTYPE_BODY"] 		= 1,
		["INVTYPE_CHEST"] 		= 1,
		["INVTYPE_ROBE"] 		= 1,
		["INVTYPE_WAIST"] 		= 1,
		["INVTYPE_LEGS"] 		= 1,
		["INVTYPE_FEET"] 		= 1,
		["INVTYPE_WRIST"] 		= 1,
		["INVTYPE_HAND"] 		= 1,
		["INVTYPE_CLOAK"] 		= 1,
		["INVTYPE_WEAPON"] 		= 1,
		["INVTYPE_2HWEAPON"] 	= 1,
		["INVTYPE_WEAPONMAINHAND"] 	= 1,
	},
	["WARRIOR"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] 	= 1, -- needs 2nd check
		["INVTYPE_SHIELD"] 	= 1,
		["INVTYPE_RANGED"] 	= 1,
		["INVTYPE_THROWN"] 	= 1,
	},
	["DEATHKNIGHT"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
	},
	["PALADIN"] = {
		["INVTYPE_SHIELD"] 	= 1,
	},
	["PRIEST"] = {
		["INVTYPE_HOLDABLE"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1, -- needs 2nd check
	},
	["SHAMAN"] = {
		["INVTYPE_SHIELD"] 	= 1,
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
	},
	["DRUID"] = {
		["INVTYPE_HOLDABLE"] 	= 1
	},
	["ROGUE"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
		["INVTYPE_RANGED"] 	= 1,
		["INVTYPE_THROWN"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1, -- needs 2nd check
	},
	["MAGE"] = {
		["INVTYPE_HOLDABLE"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1,
	},
	["WARLOCK"] = {
		["INVTYPE_HOLDABLE"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1, -- needs 2nd check
	},
	["HUNTER"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
		["INVTYPE_RANGED"] 	= 1,
		["INVTYPE_THROWN"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] 	= 1, -- needs 2nd check
	},
	["GUNS_CROSSBOWS"] = {
		["HUNTER"] 	= 1,
		["ROGUE"] 	= 1,
		["WARRIOR"] = 1,
	},
	["WANDS"] = {
		["PRIEST"] 	= 1,
		["MAGE"] 	= 1,
		["WARLOCK"] = 1,
	},
}


-- ################################################################
-- ################################################################


function ADDON_TABLE.OnReady()
	-- called when "ADDON_LOADED" event fired
	ADDON_TABLE.Frame:UnregisterEvent("ADDON_LOADED")
	print("-- OnReady, ADDON_LOADED")
	
	ClientLocale = GetLocale()
	PlayerFaction = UnitFactionGroup("player") 	-- get EN PlayerFaction
	_, PlayerClass = UnitClass("player") 		-- get EN PlayerClass
	
	tmog_itemSubClasses = { GetAuctionItemSubClasses(1) }
	-- 1; Einhandäxte
	-- 2; Zweihandäxte
	-- 3; Bogen
	-- 4; Schusswaffen --
	-- 5; Einhandstreitkolben
	-- 6; Zweihandstreitkolben
	-- 7; Stangenwaffen
	-- 8; Einhandschwerter
	-- 9; Zweihandschwerter
	-- 10; Stäbe
	-- 11; Faustwaffen
	-- 12; Verschiedenes
	-- 13; Dolche
	-- 14; Wurfwaffen
	-- 15; Armbrüste --
	-- 16; Zauberstäbe --
	-- 17; Angelruten
end


function ADDON_TABLE.OnLoad()
	-- called when addon file is fully executed
	print("-- OnLoad")
	
	hooksecurefunc("GroupLootFrame_OpenNewFrame", TMT_GLF_GroupLootFrame_OpenNewFrame);
	-- hooksecurefunc("GroupLootFrame_OnShow", function() print('x') end )
	hooksecurefunc("GroupLootFrame_OnHide", TMT_GLF_GroupLootFrame_OnHide);
	
end


function ADDON_TABLE.OnEvent(frame, event, ...)

	if (event == 'ADDON_LOADED') then
		local name = ...;
		if name == ADDON_NAME then
			ADDON_TABLE.OnReady();
		end
	end

end

function ADDON_TABLE.NewZone()
	
end


-- ################################################################
-- ################################################################


function TMT_GLF_GroupLootFrame_OpenNewFrame(rollID, rollTime)
	-- local texture, name, count, quality = GetLootRollItemInfo(this.rollID);
	print("-- TMT_GLF_GroupLootFrame_OpenNewFrame", rollID)
	-- print(GetLootRollItemLink(rollID))
	local itemLink, itemId, itemName, itemType, itemSubType, itemEquipLoc, tmogState
	itemLink = GetLootRollItemLink(rollID)
	if not itemLink then return end
	
	itemLink, itemId, itemName = strmatch( itemLink, pattern_item )
	print("itemLink, itemId, itemName", itemLink, itemId, itemName)
	if not itemId then return end
	
	itemId = tonumber(itemId)
	if not itemId then return end
	
	_, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemId)
	print("itemType, itemSubType, itemEquipLoc", itemType, itemSubType, itemEquipLoc)
	if not itemEquipLoc or itemEquipLoc == "" then return end -- not equipable
	
	if TMT:checkItemId(itemId) then
		tmogState = 1 -- we know it
	elseif TMT:checkUniqueId(itemId) then
		tmogState = 2 -- we know it through others
	else
		tmogState = 3 -- we dont know it
	end
	
	-- check if we even want to track this
	if tmogState and tmogState == 3 then
		if not (tmog_allowed.ALL[itemEquipLoc] or tmog_allowed[PlayerClass][itemEquipLoc]) then
			print("this class", PlayerClass, "cannot tmog", itemEquipLoc)
			return
		end
		
		if itemEquipLoc == "INVTYPE_RANGEDRIGHT" then
			if ( itemSubType == tmog_itemSubClasses[16] ) then -- if WAND
				if not tmog_allowed.WANDS[PlayerClass] then
					print("this class", PlayerClass, "cannot tmog", itemSubType)
					return
				end
			else -- if GUNS CROSSBOWS
				if not tmog_allowed.GUNS_CROSSBOWS[PlayerClass] then
					print("this class", PlayerClass, "cannot tmog", itemSubType)
					return
				end
			end
		end
		
	end
	
	print("tmogState", tmogState)
	
	local frame, idx
	for i=1, NUM_GROUP_LOOT_FRAMES do
		frame = _G["GroupLootFrame"..i];
		if ( frame:IsShown() and frame.rollID == rollID) then
			idx = i
			break;
		end
	end
	print("idx", idx)
	if not idx then return end
	-- if idx ~= 1 then return end
	
	
	frame = _G["TMT_GLF_GroupLootFrame"..idx]
	frame:Hide()
	local texture = _G["TMT_GLF_GroupLootFrame"..idx.."Texture"];
	if tmogState == 1 then
		texture:SetTexture("Interface\\TAXIFRAME\\UI-Taxi-Icon-Green")
	elseif tmogState == 2 then
		texture:SetTexture("Interface\\TAXIFRAME\\UI-Taxi-Icon-Yellow")
	elseif tmogState == 3 then
		texture:SetTexture("Interface\\TAXIFRAME\\UI-Taxi-Icon-Red")
	else
		return
	end
	frame:Show()

end
function TMT_GLF_GroupLootFrame_OnHide(self)
	-- redundant, but lets be on the save side
	_G["TMT_GLF_GroupLootFrame"..self:GetID()]:Hide()
end




-- ################################################################
-- ################################################################
-- ################################################################
-- ################################################################





ADDON_TABLE.Frame = CreateFrame("Frame")
-- ADDON_TABLE.Frame:Show()
ADDON_TABLE.Frame:SetScript("OnEvent", ADDON_TABLE.OnEvent)
-- ADDON_TABLE.Frame:SetScript("OnUpdate", ADDON_TABLE.OnUpdate)
ADDON_TABLE.Frame:RegisterEvent("ADDON_LOADED")
-- ADDON_TABLE.Frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

ADDON_TABLE.OnLoad()


