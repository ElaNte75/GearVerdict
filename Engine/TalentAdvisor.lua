local _, addon = ...
local advisor = {}
addon.TalentAdvisor = advisor

-- Decides which talent to take next, following the leveling order of the chosen guide (Wowhead or Icy Veins,
-- Data\TalentOrders*.lua) for the chosen spec. It looks at the talents the player really has (Forever uses the
-- modern talent-tree functions, C_ClassTalents / C_Traits) and steers back onto the guide: the suggestion is the
-- EARLIEST guide step (up to the current level) whose rank is not reached yet. Guide talents that are not in the
-- player's tree are skipped. If the tree cannot be read, it falls back to "the step of this level".

advisor.FIRST_LEVEL, advisor.LAST_LEVEL = 10, 60
advisor.GUIDES = { wowhead = "Wowhead", icyveins = "Icy Veins" }
advisor.DEFAULT_GUIDE = "icyveins"

local function options() return GearVerdictDB and GearVerdictDB.options or {} end

-- Master switch of the Leveling page: off = every leveling feature stays silent.
function advisor:Enabled() return options().levelingEnabled and true or false end

function advisor:GuideKey()
    local key = options().levelingGuide
    return self.GUIDES[key] and key or self.DEFAULT_GUIDE
end

function advisor:GuideName(key) return self.GUIDES[key or self:GuideKey()] end

-- The old "Suggest next talent" option of the Options page becomes the master switch.
function advisor:Migrate()
    local db = GearVerdictDB and GearVerdictDB.options
    if not db or db.talentHint == nil then return end
    if db.levelingEnabled == nil then db.levelingEnabled = db.talentHint and true or nil end
    db.talentHint = nil
end

-- Guide steps for a spec, one per level: { level, tree, talent, rank, max, spellID }. Built once per guide + spec.
local expanded = {}
function advisor:Steps(specID, guide)
    guide = guide or self:GuideKey()
    local cacheKey = guide .. ":" .. tostring(specID)
    if expanded[cacheKey] then return expanded[cacheKey] end
    local orders = addon.TalentGuides and addon.TalentGuides[guide]
    local order = orders and orders[specID]
    if not order then return nil end
    local steps = {}
    for _, row in ipairs(order) do
        for level = row[1], row[2] do
            steps[#steps + 1] = { level = level, tree = row[3], talent = row[4],
                rank = row[5] + (level - row[1] + 1), max = row[7], spellID = row[8] }
        end
    end
    table.sort(steps, function(a, b) return a.level < b.level end)
    expanded[cacheKey] = steps
    return steps
end

function advisor:TreeName(tree)
    local name = tostring(tree or ""):gsub("%-", " ")
    return (name:gsub("(%a)(%w*)", function(first, rest) return first:upper() .. rest end))
end

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
    return nil
end

local function spellName(spellID)
    local name = C_Spell and call(C_Spell.GetSpellName, spellID)
    if not name and GetSpellInfo then name = call(GetSpellInfo, spellID) end
    return type(name) == "string" and name ~= "" and name or nil
end

-- Reads the player's talent tree. Returns nil when the talent functions are missing or give nothing.
-- Result: { bySpell = { [spellID] = rank }, names = { [spellID] = lowercase name }, ranks = { [lowercase name] = rank },
--           talents = N, spent = points, unspent = points or nil }
function advisor:Read()
    if not C_ClassTalents or not C_Traits then return nil end
    local configID = call(C_ClassTalents.GetActiveConfigID)
    if not configID then return nil end
    local config = call(C_Traits.GetConfigInfo, configID)
    local treeID = type(config) == "table" and type(config.treeIDs) == "table" and config.treeIDs[1]
    if not treeID then return nil end
    local nodes = call(C_Traits.GetTreeNodes, treeID)
    if type(nodes) ~= "table" then return nil end
    local read = { bySpell = {}, names = {}, ranks = {}, nodes = {}, byName = {}, configID = configID, talents = 0, spent = 0 }
    for _, nodeID in ipairs(nodes) do
        local node = call(C_Traits.GetNodeInfo, configID, nodeID)
        if type(node) == "table" then
            local entryID = type(node.activeEntry) == "table" and node.activeEntry.entryID
                or type(node.entryIDs) == "table" and node.entryIDs[1]
            local entry = entryID and call(C_Traits.GetEntryInfo, configID, entryID)
            local definition = type(entry) == "table" and entry.definitionID
                and call(C_Traits.GetDefinitionInfo, entry.definitionID)
            local spellID = type(definition) == "table" and tonumber(definition.spellID)
            if spellID then
                local rank = tonumber(node.currentRank) or tonumber(node.activeRank) or 0
                local name = spellName(spellID)
                read.bySpell[spellID] = rank
                read.nodes[spellID] = { nodeID = nodeID, entryID = entryID }
                if name then
                    read.byName[name:lower()] = read.nodes[spellID]
                    read.names[spellID] = name:lower()
                    read.ranks[name:lower()] = rank
                end
                read.talents = read.talents + 1
                read.spent = read.spent + rank
            end
        end
    end
    if read.talents == 0 then return nil end
    local currency = call(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
    if type(currency) == "table" and type(currency[1]) == "table" and tonumber(currency[1].quantity) then
        read.unspent = tonumber(currency[1].quantity)
    else
        local has = call(C_ClassTalents.HasUnspentTalentPoints)
        if has == false then read.unspent = 0 end
    end
    return read
end

-- The player's rank of a guide talent: by spell id first, by name second; nil = not in the tree.
local function rankOf(read, step)
    if step.spellID and read.bySpell[step.spellID] ~= nil then return read.bySpell[step.spellID] end
    return read.ranks[step.talent:lower()]
end

-- Pure steering: the earliest guide step up to `level` that the player has not reached.
-- Returns step, off (true when talents outside the guide path were found), matched (guide talents found).
function advisor:Steer(steps, level, read)
    local finalBySpell, finalByName, seen, matched = {}, {}, {}, 0
    for _, step in ipairs(steps) do
        if step.spellID then finalBySpell[step.spellID] = step.rank end
        finalByName[step.talent:lower()] = step.rank
        if not seen[step.talent] then
            seen[step.talent] = true
            if rankOf(read, step) ~= nil then matched = matched + 1 end
        end
    end
    local off = false
    for spellID, rank in pairs(read.bySpell) do
        local name = read.names[spellID]
        local allowed = finalBySpell[spellID] or (name and finalByName[name]) or 0
        if rank > allowed then off = true; break end
    end
    for _, step in ipairs(steps) do
        if step.level > level then break end
        local have = rankOf(read, step)
        if have ~= nil and have < step.rank then return step, off, matched end
    end
    return nil, off, matched
end

local function describe(step, level)
    return ("Level %d: %s (%d/%d)"):format(level, step.talent, step.rank, step.max)
end

-- Main entry. level = level to advise for (default: the player's). options.preview = ignore the master switch
-- and the unspent-points rule (used by the Preview button and /gv talent).
-- Returns a table: status, level, guide, mode ("talents" / "level" / nil), step, text, off, read, why.
-- status: "ok", "off", "nospec", "unsupported", "range", "nopoints", "done".
function advisor:Suggest(level, opts)
    opts = opts or {}
    local result = { level = tonumber(level) or UnitLevel("player") or 0, guide = self:GuideKey() }
    if not opts.preview and not self:Enabled() then
        result.status, result.why = "off", "The leveling helper is switched off."
        return result
    end
    local specID = addon.Presets and addon.Presets:SelectedSpecID()
    if not specID or not addon.Presets:IsSupported(specID) then
        result.status, result.why = "nospec", "Choose your specialization in /gv first."
        return result
    end
    local steps
    -- A hybrid build brings its own talent order and replaces the guide choice.
    local build = addon.Builds and addon.Builds:Chosen()
    if build and build.order then
        steps = addon.Builds:Steps(build)
        result.guide, result.build = build.name, build
    else
        steps = self:Steps(specID, result.guide)
    end
    if not steps then
        result.status, result.why = "unsupported", "No talent guide for this specialization."
        return result
    end
    if result.level < self.FIRST_LEVEL or result.level > self.LAST_LEVEL then
        result.status = "range"
        result.why = ("The guide covers levels %d-%d."):format(self.FIRST_LEVEL, self.LAST_LEVEL)
        return result
    end
    local read = self:Read()
    result.read = read
    if read then
        local step, off, matched = self:Steer(steps, result.level, read)
        result.matched = matched
        if matched > 0 then
            result.mode, result.off = "talents", off
            if read.unspent == 0 and not opts.preview then
                result.status, result.why = "nopoints", "No unspent talent points."
                return result
            end
            if not step and opts.preview then
                -- Everything up to now is taken: the preview shows the next guide point of a later level.
                local ahead = self:Steer(steps, self.LAST_LEVEL, read)
                if ahead then
                    result.status, result.step, result.ahead = "ok", ahead, true
                    result.text = describe(ahead, ahead.level)
                    return result
                end
            end
            if not step then
                result.status, result.why = "done", "Everything the guide wants up to this level is taken."
                return result
            end
            result.status, result.step, result.text = "ok", step, describe(step, result.level)
            return result
        end
        result.why = "Your talent tree was read, but none of the guide's talents are in it; using the level instead."
    else
        result.why = "Your talent tree could not be read; using the level instead."
    end
    result.mode = "level"
    for _, step in ipairs(steps) do
        if step.level == result.level then
            result.status, result.step, result.text = "ok", step, describe(step, result.level)
            return result
        end
    end
    result.status, result.why = "range", "No guide step for this level."
    return result
end
