local _, addon = ...
local engine = {}
addon.Builds = engine

-- Talent builds of the player's class (data in Data/TalentBuilds.lua). A build is either a classic
-- specialization (follows the leveling guide chosen on the Leveling page) or a hybrid with its own talent
-- order. Picking one replaces the old specialization choice on the Specialization page.

local function classFile() return select(2, UnitClass("player")) end

-- The builds of a class, or nil when we have none for it (the old specialization list is used then).
function engine:List(class)
    local data = addon.TalentBuilds and addon.TalentBuilds.byClass
    return data and data[class or classFile()] or nil
end

function engine:Find(id, class)
    for _, build in ipairs(self:List(class) or {}) do
        if build.id == id then return build end
    end
end

-- The build the player picked, or the classic build matching an older specialization choice.
function engine:Chosen()
    local list = self:List()
    if not list or not addon.Presets then return nil end
    local saved = addon.Presets:BuildChoice()
    local build = saved and self:Find(saved)
    if build then return build end
    local spec = addon.Presets:ManualSpecID()
    for _, entry in ipairs(list) do
        if entry.classic and entry.spec == spec then return entry end
    end
end

-- id = nil: no build, no recommendations.
function engine:Choose(id)
    local build = id and self:Find(id)
    addon.Presets:SetBuildChoice(build and build.id or nil)
    -- Classic builds are the plain specialization choice; hybrids keep it as it was (gear uses their gearSpec).
    if build and build.classic then addon.Presets:SetManualSpecID(build.spec)
    elseif not build then addon.Presets:SetManualSpecID(nil) end
end

-- "Arms 3 | Fury 31 | Protection 17" (tree names from the data; numbers only when they are missing).
function engine:TreesText(build, class)
    local t = build.trees
    if not t then return "" end
    local names = addon.TalentBuilds.treeNames and addon.TalentBuilds.treeNames[class or select(2, UnitClass("player"))]
    if not names then return t[1] .. " / " .. t[2] .. " / " .. t[3] end
    return ("%s %d  |  %s %d  |  %s %d"):format(names[1], t[1], names[2], t[2], names[3], t[3])
end

-- Leveling steps of a hybrid build: one per level, { level, tree, talent, rank, max, spellID }.
local expanded = {}
function engine:Steps(build)
    if not build or not build.order then return nil end
    if expanded[build.id] then return expanded[build.id] end
    local talents = addon.TalentBuilds.talents
    local first = addon.TalentAdvisor and addon.TalentAdvisor.FIRST_LEVEL or 10
    local steps, ranks = {}, {}
    for index, spellID in ipairs(build.order) do
        local talent = talents[spellID]
        if talent then
            ranks[spellID] = (ranks[spellID] or 0) + 1
            steps[#steps + 1] = { level = first + index - 1, tree = talent[2], talent = talent[1],
                rank = ranks[spellID], max = talent[3], spellID = spellID }
        end
    end
    expanded[build.id] = steps
    return steps
end

-- The names of a build's key talents (data field key), at most `limit` (default 4), for the description line.
function engine:KeyNames(build, limit)
    local names = {}
    for _, spellID in ipairs(build and build.key or {}) do
        local talent = addon.TalentBuilds.talents[spellID]
        if talent and #names < (limit or 4) then names[#names + 1] = talent[1] end
    end
    return names
end
