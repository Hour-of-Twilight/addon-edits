local addon = select(2,...);
local framecolors = addon.config.global.framecolors;
local texture = addon.config.media.statusbar;


classIdToName = {
    [0] = "WARLOCK", -- Timewalker
    [1]  = "WARRIOR",
    [2]  = "PALADIN",
    [3]  = "HUNTER",
    [4]  = "ROGUE",
    [5]  = "PRIEST",
    [6]  = "DEATHKNIGHT",
    [7]  = "SHAMAN",
    [8]  = "MAGE",
    [9]  = "WARLOCK",
    [10] = "DRUID",
    [11] = "Timewalker",
    [12] = "Warden",
    [13] = "WARRIOR", -- Warden
    [14] = "PRIEST", -- Historian
    [15] = "MAGE", -- Weaver
    [16] = "ROGUE", -- Watcher
    [17] = "HUNTER", -- Ranger
    [18] = "SHAMAN", -- Savage
    [19] = "test3", 
}

function GetClassNameFromId(classId)
    return classIdToName[classId] or "Unknown"
end

function HoT_SubClassFromUnit(unit)
	local name = UnitName(unit)
        local arg1, arg2 = LookupGlobalLevelCache(name)
	
	return classIdToName[arg2] or "WARLOCK"
end

--[[
/**
 * element: colour
 * contains class colors
 * https://github.com/s0h2x/
 *  (c) 2022, s0h2x
 *
 * This file is provided as is (no warranties).
 */
]]

-- /* lua lib */
local unpack = unpack
local select = select
local pairs = pairs
local next = next

-- /* WoW APIs */
local UnitIsConnected = UnitIsConnected
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList
local UnitPlayerControlled = UnitPlayerControlled
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local hooksecurefunc = hooksecurefunc

-- /* get textures */
local nextframes = {
	PlayerFrameTexture,TargetFrameTextureFrameTexture,TargetFrameToTTextureFrameTexture,
	FocusFrameTextureFrameTexture,FocusFrameToTTextureFrameTexture,
	PlayerFrameAlternateManaBarBorder,PetFrameTexture,
    Boss1TargetFrameTextureFrameTexture,Boss2TargetFrameTextureFrameTexture,
    Boss3TargetFrameTextureFrameTexture,Boss4TargetFrameTextureFrameTexture,
    Boss5TargetFrameTextureFrameTexture,
}

local nextcastbars = {
	CastingBarFrame,FocusFrameSpellBar,TargetFrameSpellBar,PetCastingBarFrame,
	ArenaEnemyFrame1CastingBar,ArenaEnemyFrame2CastingBar,ArenaEnemyFrame3CastingBar,
	ArenaEnemyFrame4CastingBar,ArenaEnemyFrame5CastingBar,PartyCastingBar1,
	PartyCastingBar2,PartyCastingBar3,PartyCastingBar4
}

local colors = setmetatable({},{__index = function(self, key)
	local tbl = RAID_CLASS_COLORS[key];
	tbl = {tbl.r*1.28, tbl.g*1.28, tbl.b*1.28}
	self[key] = tbl
	return tbl
end})
 
-- /* set statusbar color for other bars */
local setbarcolor = PlayerFrameHealthBar.SetStatusBarColor
local function otherbarscolour_hook(self)
    local class = HoT_SubClassFromUnit(self.unit)
    if class and UnitIsPlayer(self.unit) then
        setbarcolor(self, unpack(colors[class]))
	end
end

-- /* set statusbar color for UnitIsPlayer */
local function set_statuscolour(healthbar, unit)
	if UnitIsPlayer(unit) and unit == healthbar.unit and UnitClass(unit) then
		if (not UnitIsConnected(unit)) then
			healthbar:SetStatusBarColor(.6, .6, .6, .5)
			return
		end
		-- local _, class = UnitClass(unit)
		local class = HoT_SubClassFromUnit(unit)
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class];
		if class then
			healthbar:SetStatusBarColor(color.r*1.18, color.g*1.18, color.b*1.18)
		end
	elseif UnitExists(unit) and not UnitIsPlayer(unit) and unit == healthbar.unit then
		local reaction = FACTION_BAR_COLORS[UnitReaction(unit,'player')]
		if reaction then
			healthbar:SetStatusBarColor(reaction.r*1.42, reaction.g*1.42, reaction.b*1.42)
		else
			healthbar:SetStatusBarColor(0, .6, .1)
		end
		if (not UnitPlayerControlled(unit) and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit)) then
			healthbar:SetStatusBarColor(.5, .5, .5) -- gray if npc is tapped by other player
		end
	end
end

local function setuphook(self)
	hooksecurefunc(self,'SetStatusBarColor',otherbarscolour_hook)
	self:SetStatusBarTexture(texture)
end

for _,frame in pairs(nextcastbars) do setuphook(frame) end
for _,frame in next, nextframes do frame:SetVertexColor(unpack(framecolors)) end

-- /* setup statusbar texture */
hooksecurefunc(getmetatable(PlayerFrameHealthBar).__index, 'Show', function(sb)
	if sb:GetParent().healthbar then
		if (not sb.style) then
			sb:SetStatusBarTexture(texture)
			sb:GetStatusBarTexture():SetHorizTile(true)
			sb.style = true
		end
	end
end)
hooksecurefunc('UnitFrameHealthBar_Update',set_statuscolour)
hooksecurefunc('HealthBar_OnValueChanged',function(self) set_statuscolour(self,self.unit) end)
hooksecurefunc('CastingBarFrame_OnLoad',setuphook)