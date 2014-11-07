
local addonName, addonNS = ...
local LDB = LibStub("LibDataBroker-1.1")
local LTT = LibStub("LibBabble-TalentTree-3.0"):GetLookupTable()
local LCT = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()
local LC  = {} -- LOCALE CLASSES
local CC  = {} -- CLASS COLOR

local classes_raw = {} -- conversion only
FillLocalizedClassList(classes_raw)
for token, localizedName in pairs(classes_raw) do
	local color = RAID_CLASS_COLORS[token];
	LC[token] = localizedName
	CC[token] = color.colorStr
end

local defaults = { -- http://www.wowhead.com/guide=1100/buffs-and-debuffs
	[1] = { -- Stats
		[1] = "Interface\\Icons\\spell_nature_regeneration",
		[2] = {
			{LC["DRUID"], CC["DRUID"]}, 
			{LC["MONK"], CC["MONK"]}, 
			{LC["PALADIN"], CC["PALADIN"]}
		}
	},
	[2] = { -- Stamina
		[1] = "Interface\\Icons\\spell_holy_wordfortitude",
		[2] = {
			{LC["WARRIOR"], CC["WARRIOR"]}, 
			{LC["PRIEST"], CC["PRIEST"]}, 
			{LC["WARLOCK"], CC["WARLOCK"]}
		}
	},
	[3] = { --Attack Power
		[1] = "Interface\\Icons\\ability_warrior_battleshout",
		[2] = {
			{LC["DEATHKNIGHT"], CC["DEATHKNIGHT"]}, 
			{LC["WARRIOR"], CC["WARRIOR"]}, 
			{LC["HUNTER"], CC["HUNTER"]}
		}
	},
	[4] = { --Haste
		[1] = "Interface\\Icons\\spell_nature_bloodlust",
		[2] = {
			{LC["DEATHKNIGHT"].." "..STAT_DPS_SHORT, CC["DEATHKNIGHT"]}, 
			{LC["ROGUE"], CC["ROGUE"]}, 
			{LC["PRIEST"].." "..LTT["Shadow"], CC["PRIEST"]}, 
			{LC["SHAMAN"], CC["SHAMAN"]}
		}
	},
	[5] = { --Spell Power
		[1] = "Interface\\Icons\\spell_holy_magicalsentry",
		[2] = {
			{LC["MAGE"], CC["MAGE"]}, 
			{LC["WARLOCK"], CC["WARLOCK"]}
		}
	},
	[6] = { -- Critical Strike
		[1] = "Interface\\Icons\\spell_nature_unyeildingstamina",
		[2] = {
			{LC["MAGE"], CC["MAGE"]}, 
			{LC["DRUID"].." "..LTT["Feral"], CC["DRUID"]}, 
			{LC["MONK"].." "..STAT_CATEGORY_MELEE, CC["MONK"]}
		}
	},
	[7] = { --Mastery
		[1] = "Interface\\Icons\\spell_holy_greaterblessingofkings",
		[2] = {
			{LC["DEATHKNIGHT"].." "..LTT["Blood"], CC["DEATHKNIGHT"]}, 
			{LC["SHAMAN"], CC["SHAMAN"]}, 
			{LC["DRUID"].." "..LTT["Balance"], CC["DRUID"]}, 
			{LC["PALADIN"], CC["PALADIN"]}
		}
	},
	[8] = { --Multistrike
		[1] = "Interface\\Icons\\inv_elemental_mote_air01",
		[2] = {
			{LC["ROGUE"], CC["ROGUE"]}, 
			{LC["PRIEST"].." "..LTT["Shadow"], CC["PRIEST"]}, 
			{LC["WARLOCK"], CC["WARLOCK"]}, 
			{LC["MONK"].." "..STAT_DPS_SHORT, CC["MONK"]}
		}
	},
	[9] = { --Versatility
		[1] = "Interface\\Icons\\spell_holy_mindvision",
		[2] = {
			{LC["DEATHKNIGHT"].." "..STAT_DPS_SHORT, CC["DEATHKNIGHT"]}, 
			{LC["WARRIOR"].." "..STAT_DPS_SHORT, CC["WARRIOR"]},
			{LC["DRUID"], CC["DRUID"]}, 
			{LC["PALADIN"].." "..STAT_DPS_SHORT, CC["PALADIN"]}
		}
	}
}

local function classColorLocalized(color, spec)
	return "\124c".. color..spec.."\124r"
end


local BrokerConsolidatedBuffs = LDB:NewDataObject("Broker_ConsolidatedBuffs", {
	type  = "data source",
	text  = "0/"..NUM_LE_RAID_BUFF_TYPES,
	value = "0/"..NUM_LE_RAID_BUFF_TYPES,
	icon  = "Interface\\AddOns\\Broker_ConsolidatedBuffs\\BuffConsolidation", -- I can't use the default because is a combination texture :(
	label = "ConsolidatedBuffs",

	OnTooltipShow = function(tooltip)
		tooltip:AddLine(CONSOLIDATE_BUFFS_TEXT)
		tooltip:AddLine(" ")

		for i = 1, NUM_LE_RAID_BUFF_TYPES do
			local name, rank, texture, duration, expiration, spellId, slot = GetRaidBuffTrayAuraInfo(i)
			local c

			if name then
				c = "FF00FF00"
			else
				c = "FFFF0000"
			end


			local classes = ""
			for ii = 1, #defaults[i][2] do
				classes = classes ..", ".. classColorLocalized(defaults[i][2][ii][2], defaults[i][2][ii][1])
			end
			tooltip:AddDoubleLine("\124T"..defaults[i][1]..":0\124t  \124c"..c.._G["RAID_BUFF_"..i].."\124r", strsub(classes, 2))
			--tooltip:AddLine("\124T"..defaults[i][1]..":0\124t  \124c"..c.._G["RAID_BUFF_"..i].."\124r  "..list)
			--tooltip:AddLine("     "..list)
		end
	end,

	OnClick = function(button)
		local missing = ""

		for i = 1, NUM_LE_RAID_BUFF_TYPES do
			if not GetRaidBuffTrayAuraInfo(i) then
				missing = missing .. _G["RAID_BUFF_"..i] ..", "
			end
		end

		if missing ~= "" then
			local channel = "SAY"
			if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
				channel = "INSTANCE_CHAT"
			elseif IsInRaid() then
				channel = "RAID"
			elseif IsInGroup() then
				channel = "PARTY"
			end
			SendChatMessage(ADDON_MISSING..": "..strsub(missing, 0, strlen(missing)-2), channel)
		end
	end
})


local function updateBuffs(self, event, unitID)
	if (unitID == "player" or event == "PLAYER_ENTERING_WORLD") then
		local c = 0
		for i = 1, NUM_LE_RAID_BUFF_TYPES do
			if GetRaidBuffTrayAuraInfo(i) then
				c = c + 1
			end
		end
		
		BrokerConsolidatedBuffs.text  = c.."/"..NUM_LE_RAID_BUFF_TYPES
		BrokerConsolidatedBuffs.value = c.."/"..NUM_LE_RAID_BUFF_TYPES -- for ElvUI datatexts
	end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", updateBuffs)
