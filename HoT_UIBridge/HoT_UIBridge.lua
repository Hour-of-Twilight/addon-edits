\
local ADDON = ...
local Bridge = CreateFrame("Frame")
Bridge:RegisterEvent("PLAYER_LOGIN")
Bridge:RegisterEvent("PLAYER_ENTERING_WORLD")
Bridge:RegisterEvent("PLAYER_TARGET_CHANGED")
Bridge:RegisterEvent("PLAYER_FOCUS_CHANGED")
Bridge:RegisterEvent("UNIT_INVENTORY_CHANGED")
Bridge:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

local UPGRADE_LABEL = "Item Level Upgrade"
local UPGRADE_SCAN_LINES = 20
local scanTip = CreateFrame("GameTooltip", "HoTUIBridgeScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local function TableContains(tbl, value)
	if type(tbl) ~= "table" then return false end
	for _, v in pairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

local function GetTooltipLineText(prefix, i)
	local obj = _G[prefix .. i]
	return obj and obj.GetText and obj:GetText() or nil
end

local function TooltipHasUpgradeLines(tip)
	local name = tip:GetName()
	if not name then return false end

	for i = 2, UPGRADE_SCAN_LINES do
		local text = GetTooltipLineText(name .. "TextLeft", i)
		if text and text:find(UPGRADE_LABEL, 1, true) then
			return true
		end
	end

	return false
end

local function GetItemLevelAndEquipSlot(itemLinkOrIdentifier)
	if not itemLinkOrIdentifier then return end
	local _, link, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLinkOrIdentifier)
	return itemLevel, itemEquipLoc, link
end

local function ComputeUpgradeInfo(itemLinkOrIdentifier)
	if not itemLinkOrIdentifier then return false end
	if type(ConvertEquipSlotStringToNumericId) ~= "function" then return false end
	if type(GetMaxItemLevelForSlot) ~= "function" then return false end
	if type(GetCurrentItemLevelForSlot) ~= "function" then return false end

	local itemLevel, itemEquipLoc, itemLink = GetItemLevelAndEquipSlot(itemLinkOrIdentifier)
	if not itemLevel or itemLevel <= 0 or not itemEquipLoc or itemEquipLoc == "" then
		return false
	end

	local numericSlotId = ConvertEquipSlotStringToNumericId(itemEquipLoc)
	if not numericSlotId then
		return false
	end

	local equipped = GetMaxItemLevelForSlot(numericSlotId)
	if equipped == 0 then
		equipped = GetCurrentItemLevelForSlot(numericSlotId)
	end

	local tracked = TableContains(_G.CharIlevelItemSlots, numericSlotId)
	local isUpgrade = itemLevel > equipped and (((equipped or 0) >= 0 and tracked) or ((not tracked) and (equipped or 0) > 0))
	if not isUpgrade then
		return false
	end

	local diff = itemLevel - equipped
	local color
	if diff >= 15 then
		color = "|cFFFF6600"
	elseif diff >= 8 then
		color = "|cFF00FF00"
	elseif diff >= 4 then
		color = "|cFF40FF40"
	else
		color = "|cFF80FF80"
	end

	return true, diff, color, itemLevel, equipped, tracked, itemLink
end

local function EnsureArrow(button)
	if not button or button.upgradeArrow then return end
	local arrow = button:CreateTexture(nil, "OVERLAY")
	arrow:SetTexture("Interface\\CraftingFrame\\UpgradeArrow")
	arrow:SetSize(13, 15)
	arrow:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	arrow:SetVertexColor(0, 1, 0, 0.9)
	arrow:Hide()
	button.upgradeArrow = arrow
end

local function UpdateArrow(button, itemIdentifier)
	if not button then return end
	EnsureArrow(button)

	local isUpgrade, _, _, _, _, tracked = ComputeUpgradeInfo(itemIdentifier)
	if isUpgrade and tracked then
		button.upgradeArrow:Show()
	else
		button.upgradeArrow:Hide()
	end
end

local function AppendUpgradeLinesToTooltip(tip, itemIdentifier)
	if not tip or not itemIdentifier then return end
	if TooltipHasUpgradeLines(tip) then return end

	local isUpgrade, diff, color = ComputeUpgradeInfo(itemIdentifier)
	if not isUpgrade then return end

	tip:AddLine(" ")
	tip:AddLine("|TInterface\\CraftingFrame\\UpgradeArrow:16:16:0:0|t |cFF00FF00" .. UPGRADE_LABEL .. "|r", 1, 1, 1)
	tip:AddLine("|cFFFFFFFF" .. color .. "+" .. diff .. "|r item levels over max equipped.|r", 0.8, 0.8, 0.8)
	tip:Show()
end

GameTooltip:HookScript("OnTooltipSetItem", function(self)
	local _, itemLink = self:GetItem()
	if itemLink then
		AppendUpgradeLinesToTooltip(self, itemLink)
	end
end)

local function GetUnitProgressionLevel(unit)
	if not unit or not UnitExists(unit) then return nil end

	if UnitIsUnit(unit, "player") then
		if type(GetCurrentItemLevelForSlot) == "function" and type(_G.CharIlevelItemSlots) == "table" then
			local total, count = 0, 0
			for _, slotID in pairs(_G.CharIlevelItemSlots) do
				local ilvl = GetCurrentItemLevelForSlot(slotID)
				if ilvl and ilvl > 0 then
					total = total + ilvl
					count = count + 1
				end
			end
			if count > 0 then
				return math.floor((total / count) + 0.5)
			end
		end
		return UnitLevel(unit)
	end

	if UnitIsPlayer(unit) and type(LookupGlobalLevelCache) == "function" then
		local name = UnitName(unit)
		if name and name ~= "" then
			local level = LookupGlobalLevelCache(name)
			if level then
				return level
			end
		end
	end

	return UnitLevel(unit)
end

local function EnsureUFLevel(frame, point)
	if not frame or frame.HoTLevelText then return end
	local parent = frame.Health or frame
	local fs = parent:CreateFontString(nil, "OVERLAY")
	if parent.GetFont then
		local font, size, flags = parent:GetFont()
		if font then
			fs:SetFont(font, math.max((size or 12), 12), flags)
		else
			fs:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		end
	else
		fs:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	end
	fs:SetTextColor(1, 0.82, 0)
	fs:SetShadowOffset(1, -1)
	fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	frame.HoTLevelText = fs
end

local function UpdateUFUnit(frame, unit)
	if not frame or not unit or not UnitExists(unit) then
		if frame and frame.HoTLevelText then frame.HoTLevelText:SetText("") end
		return
	end

	EnsureUFLevel(frame)
	local level = GetUnitProgressionLevel(unit)
	if level then
		frame.HoTLevelText:SetFormattedText("[%d]", level)
	else
		frame.HoTLevelText:SetText("")
	end
end

local function RefreshUnitFrames()
	UpdateUFUnit(_G.ElvUF_Player, "player")
	UpdateUFUnit(_G.ElvUF_Target, "target")
	UpdateUFUnit(_G.ElvUF_Focus, "focus")
	UpdateUFUnit(_G.ElvUF_TargetTarget, "targettarget")
end

local function PatchElvUI()
	local E = _G.ElvUI
	if not E or not E.GetModule then return end

	local B = E:GetModule("Bags", true)
	if B and not Bridge.ElvUIBagsHooked then
		Bridge.ElvUIBagsHooked = true
		hooksecurefunc(B, "UpdateSlot", function(self, frame, bagID, slotID)
			if not frame or not frame.Bags or not frame.Bags[bagID] then return end
			local slot = frame.Bags[bagID][slotID]
			if not slot then return end
			local itemIdentifier
			if slot.GetInventorySlot then
				local invSlot = slot:GetInventorySlot()
				if invSlot then
					itemIdentifier = GetInventoryItemLink("player", invSlot)
				end
			end
			if not itemIdentifier then
				itemIdentifier = GetContainerItemLink(bagID, slotID)
			end
			UpdateArrow(slot, itemIdentifier)
		end)
	end

	local NP = E:GetModule("NamePlates", true)
	if NP and not Bridge.NameplatePatched then
		Bridge.NameplatePatched = true
		local orig = NP.UnitLevel
		function NP:UnitLevel(frame)
			if frame and frame.unit and UnitExists(frame.unit) and UnitIsPlayer(frame.unit) then
				local level = GetUnitProgressionLevel(frame.unit)
				if level then
					local old = frame.oldLevel
					local r, g, b = 1, 0.82, 0
					if old and old.GetTextColor then
						r, g, b = old:GetTextColor()
					end
					return level, r, g, b
				end
			end
			return orig(self, frame)
		end
	end

	RefreshUnitFrames()
end

local function PatchBagnon()
	if not _G.Bagnon or not _G.Bagnon.ItemSlot or Bridge.BagnonHooked then return end
	Bridge.BagnonHooked = true

	hooksecurefunc(_G.Bagnon.ItemSlot, "Update", function(self)
		if not self then return end
		local itemIdentifier
		if self.GetBag then
			local bag = self:GetBag()
			local slot = self:GetID()
			if bag and slot then
				itemIdentifier = GetContainerItemLink(bag, slot)
			end
		end
		if not itemIdentifier and self.GetItem then
			itemIdentifier = self:GetItem()
		end
		UpdateArrow(self, itemIdentifier)
	end)
end

local function TryPatch()
	PatchElvUI()
	PatchBagnon()
	RefreshUnitFrames()
end

Bridge:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		TryPatch()
		C_Timer.After(2, TryPatch)
	elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_EQUIPMENT_CHANGED" then
		RefreshUnitFrames()
	end
end)
