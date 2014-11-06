
local addonName, addonNS = ...
local ldb = LibStub("LibDataBroker-1.1")

local defaults = { -- http://www.wowhead.com/guide=1100/buffs-and-debuffs
	[1] = { -- Stats
		[1] = "Interface\\Icons\\spell_nature_regeneration",
		[2] = {"DRUID", "MONK", "PALADIN"}
	},
	[2] = { -- Stamina
		[1] = "Interface\\Icons\\spell_holy_wordfortitude",
		[2] = {"WARRIOR", "PRIEST", "WARLOCK"}
	},
	[3] = { --Attack Power
		[1] = "Interface\\Icons\\ability_warrior_battleshout",
		[2] = {"DEATHKNIGHT", "WARRIOR", "HUNTER"}
	},
	[4] = { --Haste
		[1] = "Interface\\Icons\\spell_nature_bloodlust",
		[2] = {"DEATHKNIGHT", "ROGUE", "PRIEST", "SHAMAN"}
	},
	[5] = { --Spell Power
		[1] = "Interface\\Icons\\spell_holy_magicalsentry",
		[2] = {"MAGE", "WARLOCK"}
	},
	[6] = { -- Critical Strike
		[1] = "Interface\\Icons\\spell_nature_unyeildingstamina",
		[2] = {"MAGE", "DRUID", "MONK"}
	},
	[7] = { --Mastery
		[1] = "Interface\\Icons\\spell_holy_greaterblessingofkings",
		[2] = {"DEATHKNIGHT", "SHAMAN", "DRUID", "PALADIN"}
	},
	[8] = { --Multistrike
		[1] = "Interface\\Icons\\inv_elemental_mote_air01",
		[2] = {"ROGUE", "PRIEST", "WARLOCK", "MONK"}
	},
	[9] = { --Versatility
		[1] = "Interface\\Icons\\spell_holy_mindvision",
		[2] = {"DEATHKNIGHT", "WARRIOR", "DRUID", "PALADIN"}
	}
}
classes_raw = {}
local classes = {}
FillLocalizedClassList(classes_raw)
for token, localizedName in pairs(classes_raw) do
	local color = RAID_CLASS_COLORS[token];
	classes[token] = {
		["name"]  = localizedName,
		["color"] = color.colorStr
	}
end

local function classColorLocalized(token)
	return "\124c".. classes[token]["color"]..classes[token]["name"].."\124r"
end


local BrokerConsolidatedBuffs = ldb:NewDataObject("Broker_ConsolidatedBuffs", {
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


			local list = classColorLocalized(defaults[i][2][1])
			for ii = 2, #defaults[i][2] do
				list = list ..", ".. classColorLocalized(defaults[i][2][ii])
			end
			tooltip:AddDoubleLine("\124T"..defaults[i][1]..":0\124t  \124c"..c.._G["RAID_BUFF_"..i].."\124r", list)
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
