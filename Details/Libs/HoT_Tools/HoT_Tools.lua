local HoT_Tools, old_minor = LibStub:NewLibrary("HoT_Tools", "1")

if not HoT_Tools then return end

HoT_Tools.PLAYER_SUBCLASS_CACHE = {}

HoT_Tools.CLASS_COLORS = {
    ["TIMEWALKER"] = {
        0, -- [1]
        1, -- [2]
        0, -- [3]
        ['r'] = 0, -- [1]
        ['g'] = 1, -- [2]
        ['b'] = 0, -- [3]
    },
    ["WEAVER"] = {
        0.411, -- [1]
        0.8, -- [2]
        0.941, -- [3]
        ['r'] = 0.411, -- [1]
        ['g'] = 0.8, -- [2]
        ['b'] = 0.941, -- [3]
    },
    ["RANGER"] = {
        0.67, -- [1]
        0.83, -- [2]
        0.45, -- [3]
        ['r'] = 0.67, -- [1]
        ['g'] = 0.83, -- [2]
        ['b'] = 0.45, -- [3]
    },
    ["WATCHER"] = {
        1, -- [1]
        0.96, -- [2]
        0.41, -- [3]
        ['r'] = 1, -- [1]
        ['g'] = 0.96, -- [2]
        ['b'] = 0.41, -- [3]
    },
    ["WARDEN"] = {
        0.78, -- [1]
        0.61, -- [2]
        0.43, -- [3]
        ['r'] = 0.78, -- [1]
        ['g'] = 0.61, -- [2]
        ['b'] = 0.43, -- [3]
    },
    ["HISTORIAN"] = {
        1, -- [1]
        1, -- [2]
        1, -- [3]
        ['r'] = 1, -- [1]
        ['g'] = 1, -- [2]
        ['b'] = 1, -- [3]
    },
}

HoT_Tools.SUBCLASS_NAMES = {
    ['Warden'] = "WARDEN",
    ['Historian'] = "HISTORIAN",
    ['Weaver'] = "WEAVER",
    ['Watcher'] = "WATCHER",
    ['Ranger'] = "RANGER",
}

--Courtesy of https://gist.github.com/Bengejd/b9be5b3036d2114f0807d494780ebcd3
local function HoT_wait(seconds)
    local start = tonumber(date('%S'))
    repeat until tonumber(date('%S')) > start + seconds
end

--Old Class Lookup using server cache
-- local function set_subclass(pname)
--     local _, subclass_id = LookupGlobalLevelCache(pname)
--     HoT_Tools.PLAYER_SUBCLASS_CACHE[pname] = string.upper(GetTimewalkerSubclassStr(subclass_id))
--     return HoT_Tools.PLAYER_SUBCLASS_CACHE[pname]
-- end

-- function HoT_Tools:check_subclass(player_name)
--     local pname = player_name or UnitName("player")
--     local _, subclass_id = LookupGlobalLevelCache(pname)
--     if(HoT_Tools.PLAYER_SUBCLASS_CACHE[pname] == "TIMEWALKER") then
--         return set_subclass(pname)  
--     elseif(HoT_Tools.PLAYER_SUBCLASS_CACHE[pname]) then
--         return HoT_Tools.PLAYER_SUBCLASS_CACHE[pname]
--     else
--         GlobalLevelCache[pname] = {0,0,0}
--         HoT_wait(1/5)
--         return set_subclass(pname)   
--     end
-- end

function HoT_Tools:check_subclass_by_aura(player_name)
    local pname = player_name or UnitName("player")
    for k, v in pairs(HoT_Tools.SUBCLASS_NAMES) do
        local name = UnitAura(pname, k)
        if(name) then
            return v
        end
    end
    return "TIMEWALKER"
end
