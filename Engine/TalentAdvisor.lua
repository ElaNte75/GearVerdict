local _, addon = ...
local advisor = {}
addon.TalentAdvisor = advisor

-- Decides which talent to take next, following the Icy Veins leveling order of the chosen spec
-- (Data\TalentOrders.lua). It looks at the talents the player really has and steers back onto the
-- guide: the suggestion is the EARLIEST guide step (up to the current level) whose rank is not reached yet.
-- If the talent functions are missing or give nothing usable, it falls back to "the step of this level".

advisor.FIRST_LEVEL, advisor.LAST_LEVEL = 10, 60

-- Guide steps for a spec, one per level: { level, tree, talent, rank, max }. Built once per spec.
local expanded = {}
function advisor:Steps(specID)
    if expanded[specID] then return expanded[specID] end
    local order = addon.TalentOrders and addon.TalentOrders[specID]
    if not order then return nil end
    local steps = {}
    for _, row in ipairs(order) do
        for level = row[1], row[2] do
            steps[#steps + 1] = { level = level, tree = row[3], talent = row[4],
                rank = row[5] + (level - row[1] + 1), max = row[7] }
        end
    end
    table.sort(steps, function(a, b) return a.level < b.level end)
    expanded[specID] = steps
    return steps
end

function advisor:TreeName(tree)
    local name = tostring(tree or ""):gsub("%-", " ")
    return (name:gsub("(%a)(%w*)", function(first, rest) return first:upper() .. rest end))
end

-- Reads the player's talents by name. Returns nil when the talent functions are missing or empty.
-- Result: { ranks = { [lowercase name] = rank }, talents = N, spent = points, unspent = points or nil }
function advisor:Read()
    if not GetNumTalentTabs or not GetNumTalents or not GetTalentInfo then return nil end
    local ok, tabs = pcall(GetNumTalentTabs)
    if not ok or type(tabs) ~= "number" or tabs < 1 then return nil end
    local read = { ranks = {}, talents = 0, spent = 0 }
    for tab = 1, tabs do
        local okCount, count = pcall(GetNumTalents, tab)
        if okCount and type(count) == "number" then
            for index = 1, count do
                local okInfo, name, _, _, _, rank = pcall(GetTalentInfo, tab, index)
                if okInfo and type(name) == "string" and name ~= "" then
                    rank = tonumber(rank) or 0
                    read.ranks[name:lower()] = rank
                    read.talents = read.talents + 1
                    read.spent = read.spent + rank
                end
            end
        end
    end
    if read.talents == 0 then return nil end
    local unspent
    if UnitCharacterPoints then
        local okPoints, points = pcall(UnitCharacterPoints, "player")
        if okPoints and type(points) == "number" then unspent = points end
    end
    if unspent == nil and GetUnspentTalentPoints then
        local okPoints, points = pcall(GetUnspentTalentPoints)
        if okPoints and type(points) == "number" then unspent = points end
    end
    read.unspent = unspent
    return read
end

-- Pure steering: the earliest guide step up to `level` that the given ranks have not reached.
-- Returns step, off (true when talents outside the guide path were found), matched (guide talents found).
function advisor:Steer(steps, level, ranks)
    local final, matched = {}, 0
    for _, step in ipairs(steps) do
        final[step.talent:lower()] = step.rank
    end
    for name in pairs(final) do
        if ranks[name] ~= nil then matched = matched + 1 end
    end
    local off = false
    for name, rank in pairs(ranks) do
        if rank > (final[name] or 0) then off = true; break end
    end
    for _, step in ipairs(steps) do
        if step.level > level then break end
        if (ranks[step.talent:lower()] or 0) < step.rank then return step, off, matched end
    end
    return nil, off, matched
end

local function describe(step, level)
    return ("Level %d: next talent -> %s: %s (%d/%d)"):format(level, advisor:TreeName(step.tree), step.talent,
        step.rank, step.max)
end

-- Main entry. level = level to advise for (default: the player's). options.preview = ignore the on/off
-- option and the unspent-points rule (used by the Preview button and /gv talent).
-- Returns a table: status, level, mode ("talents" / "level" / nil), step, text, off, read, why.
-- status: "ok", "off", "nospec", "unsupported", "range", "nopoints", "done".
function advisor:Suggest(level, options)
    options = options or {}
    local result = { level = tonumber(level) or UnitLevel() or 0 }
    local db = GearVerdictDB and GearVerdictDB.options or {}
    if not options.preview and not db.talentHint then
        result.status, result.why = "off", "The option is switched off."
        return result
    end
    local specID = addon.Presets and addon.Presets:SelectedSpecID()
    if not specID or not addon.Presets:IsSupported(specID) then
        result.status, result.why = "nospec", "Choose your specialization in /gv first."
        return result
    end
    local steps = self:Steps(specID)
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
        local step, off, matched = self:Steer(steps, result.level, read.ranks)
        result.matched = matched
        if matched > 0 then
            result.mode, result.off = "talents", off
            if read.unspent == 0 and not options.preview then
                result.status, result.why = "nopoints", "No unspent talent points."
                return result
            end
            if not step then
                result.status, result.why = "done", "Everything the guide wants up to this level is taken."
                return result
            end
            result.status, result.step, result.text = "ok", step, describe(step, result.level)
            return result
        end
        result.why = "Talents were read, but none had the guide's names; using the level instead."
    else
        result.why = "Talent functions give nothing; using the level instead."
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
