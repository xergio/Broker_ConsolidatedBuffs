
-- Upvalues
local _G = _G
local bit, strsub, strlen, select, max = bit, strsub, strlen, select, max

local addonName, addonNS = ...
local LQT = LibStub('LibQTip-1.0')
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
		},
		[3] = {LCT["Dog"], LCT["Gorilla"], LCT["Shale Spider"], LCT["Worm"]}
	},
	[2] = { -- Stamina
		[1] = "Interface\\Icons\\spell_holy_wordfortitude",
		[2] = {
			{LC["WARRIOR"], CC["WARRIOR"]},
			{LC["PRIEST"], CC["PRIEST"]},
			{LC["WARLOCK"], CC["WARLOCK"]}
		},
		[3] = {LCT["Bear"], LCT["Goat"], LCT["Rylak"], LCT["Silithid"]}
	},
	[3] = { --Attack Power
		[1] = "Interface\\Icons\\ability_warrior_battleshout",
		[2] = {
			{LC["DEATHKNIGHT"], CC["DEATHKNIGHT"]},
			{LC["WARRIOR"], CC["WARRIOR"]},
			{LC["HUNTER"], CC["HUNTER"]}
		},
		[3] = {}
	},
	[4] = { --Haste
		[1] = "Interface\\Icons\\spell_nature_bloodlust",
		[2] = {
			{LC["DEATHKNIGHT"].." "..STAT_DPS_SHORT, CC["DEATHKNIGHT"]},
			{LC["ROGUE"], CC["ROGUE"]},
			{LC["PRIEST"].." "..LTT["Shadow"], CC["PRIEST"]},
			{LC["SHAMAN"], CC["SHAMAN"]}
		},
		[3] = {LCT["Hyena"], LCT["Rylak"], LCT["Sporebat"], LCT["Wasp"]}
	},
	[5] = { --Spell Power
		[1] = "Interface\\Icons\\spell_holy_magicalsentry",
		[2] = {
			{LC["MAGE"], CC["MAGE"]},
			{LC["WARLOCK"], CC["WARLOCK"]}
		},
		[3] = {LCT["Serpent"], LCT["Silithid"], LCT["Water Strider"]}
	},
	[6] = { -- Critical Strike
		[1] = "Interface\\Icons\\spell_nature_unyeildingstamina",
		[2] = {
			{LC["MAGE"], CC["MAGE"]},
			{LC["DRUID"].." "..LTT["Feral"], CC["DRUID"]},
			{LC["MONK"].." "..STAT_CATEGORY_MELEE, CC["MONK"]}
		},
		[3] = {LCT["Devilsaur"], LCT["Quilen"], LCT["Raptor"], LCT["Shale Spider"], LCT["Water Strider"], LCT["Wolf"]}
	},
	[7] = { --Mastery
		[1] = "Interface\\Icons\\spell_holy_greaterblessingofkings",
		[2] = {
			{LC["DEATHKNIGHT"].." "..LTT["Blood"], CC["DEATHKNIGHT"]},
			{LC["SHAMAN"], CC["SHAMAN"]},
			{LC["DRUID"].." "..LTT["Balance"], CC["DRUID"]},
			{LC["PALADIN"], CC["PALADIN"]}
		},
		[3] = {LCT["Cat"], LCT["Hydra"], LCT["Spirit Beast"], LCT["Tallstrider"]}
	},
	[8] = { --Multistrike
		[1] = "Interface\\Icons\\inv_elemental_mote_air01",
		[2] = {
			{LC["ROGUE"], CC["ROGUE"]},
			{LC["PRIEST"].." "..LTT["Shadow"], CC["PRIEST"]},
			{LC["WARLOCK"], CC["WARLOCK"]},
			{LC["MONK"].." "..STAT_DPS_SHORT, CC["MONK"]}
		},
		[3] = {LCT["Bat"], LCT["Clefthoof"], LCT["Core Hound"], LCT["Dragonhawk"], LCT["Wind Serpent"]}
	},
	[9] = { --Versatility
		[1] = "Interface\\Icons\\spell_holy_mindvision",
		[2] = {
			{LC["DEATHKNIGHT"].." "..STAT_DPS_SHORT, CC["DEATHKNIGHT"]},
			{LC["WARRIOR"].." "..STAT_DPS_SHORT, CC["WARRIOR"]},
			{LC["DRUID"], CC["DRUID"]},
			{LC["PALADIN"].." "..STAT_DPS_SHORT, CC["PALADIN"]}
		},
		[3] = {LCT["Bird of Prey"], LCT["Boar"], LCT["Clefthoof"], LCT["Porcupine"], LCT["Ravager"], LCT["Stag"], LCT["Worm"]}
	}
}

local function classColorLocalized(color, spec)
	return "\124c".. color..spec.."\124r"
end


local BrokerConsolidatedBuffs = LDB:NewDataObject("Broker_ConsolidatedBuffs", {
	type  = "data source",
	text  = "0/".._G.NUM_LE_RAID_BUFF_TYPES,
	value = "0/".._G.NUM_LE_RAID_BUFF_TYPES,
	icon  = "Interface\\AddOns\\Broker_ConsolidatedBuffs\\BuffConsolidation", -- I can't use the default because is a combination texture :(
	label = "ConsolidatedBuffs",

	OnEnter = function(self)
		local tooltip = LQT:Acquire("Broker_ConsolidatedBuffsTooltip", 3, "LEFT", "LEFT", "LEFT")
		self.tooltip  = tooltip

		tooltip:AddHeader(_G.CONSOLIDATE_BUFFS_TEXT)
		tooltip:AddLine(" ")
		tooltip:AddHeader(_G.STATISTICS, _G.ALL_CLASSES, _G.PETS)--CONSOLIDATE_BUFFS_TEXT)
		tooltip:AddSeparator()
		--tooltip:AddLine(" ")

		local buffmask = _G.GetRaidBuffInfo() or 0
		local mask = 1
		for i = 1, _G.NUM_LE_RAID_BUFF_TYPES do
			local name, rank, texture, duration, expiration, spellId, slot = _G.GetRaidBuffTrayAuraInfo(i)
			local c

			if name then
				c = "FF00FF00"
			else
				if bit.band(buffmask, mask) > 0 then
					c = "FFFF0000"
				else
					c = "FF888888"
				end
			end

			local classes = ""
			for ii = 1, #defaults[i][2] do
				classes = classes ..", ".. classColorLocalized(defaults[i][2][ii][2], defaults[i][2][ii][1])
			end
			local pets = ""
			for ii = 1, #defaults[i][3] do
				pets = pets ..", ".. defaults[i][3][ii]
			end
			tooltip:AddLine(
				"\124T"..defaults[i][1]..":0\124t  \124c"..c.._G["RAID_BUFF_"..i]:gsub("-\n", "").."\124r",
				strsub(classes, 2),
				strsub(pets, 2)
			)
			--tooltip:AddLine(" ")

			--tooltip:AddLine("\124T"..defaults[i][1]..":0\124t  \124c"..c.._G["RAID_BUFF_"..i]:gsub("-\n", "").."\124r  "..list)
			--tooltip:AddLine("     "..list)

			mask = bit.lshift(mask, 1)
		end

		tooltip:SmartAnchorTo(self)
		tooltip:Show()
	end,

	OnLeave = function(self)
		LQT:Release(self.tooltip)
		self.tooltip = nil
	end,

	OnClick = function(button)
		local missing = ""
		local buffmask = _G.GetRaidBuffInfo() or 0
		local mask = 1

		for i = 1, _G.NUM_LE_RAID_BUFF_TYPES do
			if not _G.GetRaidBuffTrayAuraInfo(i) and bit.band(buffmask, mask) > 0 then
				missing = missing .. _G["RAID_BUFF_"..i]:gsub("-\n", "") ..", "
			end
			mask = bit.lshift(mask, 1)
		end

		if missing ~= "" then
			local channel = "SAY"
			if _G.IsInGroup(_G.LE_PARTY_CATEGORY_INSTANCE) then
				channel = "INSTANCE_CHAT"
			elseif _G.IsInRaid() then
				channel = "RAID"
			elseif _G.IsInGroup() then
				channel = "PARTY"
			end
			_G.SendChatMessage(_G.ADDON_MISSING..": "..strsub(missing, 0, strlen(missing)-2), channel)
		end
	end
})


local function updateBuffs(self, event, unitID)
	if (unitID == "player" or event == "PLAYER_ENTERING_WORLD") then
		local c = 0
		for i = 1, _G.NUM_LE_RAID_BUFF_TYPES do
			if _G.GetRaidBuffTrayAuraInfo(i) then
				c = c + 1
			end
		end

		local buffcount = select(2, _G.GetRaidBuffInfo())

		BrokerConsolidatedBuffs.text  = c.."/"..max(c, buffcount)
		BrokerConsolidatedBuffs.value = c.."/"..max(c, buffcount) -- for ElvUI datatexts
	end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", updateBuffs)
