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

-- Two-step choice (2026-11-21): first the specialization, then a variant of it. A build belongs to the spec whose
-- weights it uses (classic builds: spec; Wowhead builds: gearSpec = the spec page they come from).
-- Exception (user's finding 2026-11-21): a build with NO points in its page's tree is not that spec (Warrior
-- "Protection: Dual Wield" 20/31/0, Paladin "Protection: Offensive Off" 23/0/28). It belongs to the spec of the tree
-- holding most of its points (Fury, Retribution). Which tree is a spec's: the tree its classic build fills most.
local function mostIndex(trees)
    local best = 1
    for index = 2, 3 do if trees[index] > trees[best] then best = index end end
    return best
end

function engine:TreeOf(specID, class)
    for _, build in ipairs(self:List(class) or {}) do
        if build.classic and build.spec == specID and build.trees then return mostIndex(build.trees) end
    end
end

function engine:SpecOf(build, class)
    if not build then return nil end
    if build.classic then return build.spec or build.gearSpec end
    local page = build.gearSpec
    local tree = build.trees and self:TreeOf(page, class)
    if not tree or build.trees[tree] > 0 then return page end
    local wanted = mostIndex(build.trees)
    for _, entry in ipairs(self:List(class) or {}) do
        if entry.classic and entry.trees and mostIndex(entry.trees) == wanted then return entry.spec end
    end
    return page
end

-- True when the build was moved away from its page's spec (see SpecOf).
function engine:Moved(build)
    return build ~= nil and not build.classic and self:SpecOf(build) ~= build.gearSpec
end

-- The name shown in tooltips and the status line: the spec it is judged as, then the variant.
-- A moved build says where the guide lists it: "Fury: Dual Wield (Protection page)".
function engine:DisplayName(build)
    if not build then return "" end
    if not self:Moved(build) then return build.name end
    local spec = addon.SpecDetection:SpecName(self:SpecOf(build)) or "?"
    local page = build.name:match("^([^:]+):") or "?"
    return spec .. ": " .. self:VariantName(build) .. " (" .. page .. " page)"
end

-- The weapon setup in plain words for the Weapons line (user request 2026-11-21): only WHAT to hold
-- ("One-hand weapon + shield", "Two one-hand weapons", "Two-handed weapon"). Returns setup, detail: detail is the
-- guide's own weapon text when it says more than the setup (speed, a named weapon) and goes into the description.
-- Setup: from the guide's text when it names one, else from the spec's weapon guide (Data/WeaponGuide.lua).
function engine:WeaponSetup(build)
    if not build then return nil end
    local text = build.weapons
    local lower = text and text:lower() or ""
    if lower:find("dual wield") or lower:find("two one%-hand") then
        return "Two one-hand weapons (dual wield)", nil
    end
    if lower:find("two%-hand") then
        local detail = text ~= "Two-handed weapon" and text or nil
        return "Two-handed weapon", detail
    end
    local guide = addon.WeaponGuide and addon.WeaponGuide:Get(self:SpecOf(build)) or {}
    local setups = guide.setups
    local setup
    if setups and setups.shield then
        setup = "One-hand weapon + shield"
    elseif setups and setups.twohand and setups.dual then
        setup = "Two-handed weapon, or two one-hand weapons"
    elseif setups and setups.twohand then
        setup = "Two-handed weapon"
    elseif setups and setups.dual then
        setup = "Two one-hand weapons (dual wield)"
    elseif guide.ranged then
        setup = "Ranged weapon (bow, gun or crossbow) + any melee weapon"
    else
        setup = "Any weapon setup (judged by its stats)"
    end
    return setup, text
end

-- Defense share of a build's talent points, for the Defense <-> Offense meter (every spec except healers).
-- Defense = points in the defensive tree: Protection for Warrior/Paladin, Feral Combat for a Druid bear build.
-- Classes or specs without one are pure damage: share 0 ("Offense 100%"). Counted from the guide's points.
-- Returns share, defensive points, total points, defensive tree name (nil when there is none); nil for healers.
engine.HEALER_SPECS = { [65] = true, [105] = true, [256] = true, [257] = true, [264] = true }
engine.DEFENSE_TREE = { WARRIOR = 3, PALADIN = 2 }
function engine:DefenseShare(build, class)
    class = class or select(2, UnitClass("player"))
    local spec = self:SpecOf(build, class)
    if not spec or self.HEALER_SPECS[spec] or not build.trees then return nil end
    local total = build.trees[1] + build.trees[2] + build.trees[3]
    if total <= 0 then return nil end
    local tree = self.DEFENSE_TREE[class]
    if class == "DRUID" and spec == 104 then tree = self:TreeOf(104, class) end
    local names = addon.TalentBuilds.treeNames and addon.TalentBuilds.treeNames[class]
    if not tree then return 0, 0, total, nil end
    return build.trees[tree] / total, build.trees[tree], total, names and names[tree]
end

-- The specializations that have builds, in the class's own order: { id, name }.
function engine:Specs(class)
    local specs, seen = {}, {}
    for _, build in ipairs(self:List(class) or {}) do seen[self:SpecOf(build, class) or 0] = true end
    for _, spec in ipairs(addon.SpecDetection:ClassSpecs(class) or {}) do
        if seen[spec.id] then specs[#specs + 1] = spec end
    end
    return specs
end

-- The builds of one specialization (classic first, then the guide's order).
function engine:ForSpec(specID, class)
    local builds = {}
    for _, build in ipairs(self:List(class) or {}) do
        if self:SpecOf(build, class) == specID then builds[#builds + 1] = build end
    end
    return builds
end

-- Picking a specialization picks its classic build (or its first build when it has no classic one).
function engine:ChooseSpec(specID)
    local first = specID and self:ForSpec(specID)[1]
    self:Choose(first and first.id or nil)
end

-- The variant's name without the spec in front: "Protection: Fury-Prot" -> "Fury-Prot"; classic -> "Classic".
function engine:VariantName(build)
    if not build then return "" end
    if build.classic then return "Classic (leveling guide)" end
    return (build.name:gsub("^[^:]+:%s*", ""))
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
