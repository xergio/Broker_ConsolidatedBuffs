
local addonName, addonNS = ...
local ldb = LibStub("LibDataBroker-1.1")


local BrokerConsolidatedBuffs = ldb:NewDataObject("Broker_ConsolidatedBuffs", {
	type = "data source",
	text = "Please wait",
	value = 1,
	icon = "Interface\\AddOns\\Broker_ConsolidatedBuffs\\BuffConsolidation",
	label = "ConsolidatedBuffs",

	OnTooltipShow = function(tooltip)
		tooltip:AddLine("Consolidated Buffs")
		tooltip:AddLine(" ")

		for i = 1, NUM_LE_RAID_BUFF_TYPES do
			local name, rank, texture, duration, expiration, spellId, slot = GetRaidBuffTrayAuraInfo(i)
			local r, g, b

			if name then
				r, g, b = 0, 1, 0
			else
				r, g, b = 1, 0, 0
			end

			tooltip:AddLine(_G["RAID_BUFF_"..i], r, g, b)
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
			SendChatMessage(ADDON_MISSING..": "..strsub(missing, 0, strlen(missing)-2), "SAY")
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
		
		BrokerConsolidatedBuffs.text = c.."/"..NUM_LE_RAID_BUFF_TYPES
	end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", updateBuffs)