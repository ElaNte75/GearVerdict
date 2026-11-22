local _, addon = ...
local comparison = {}
addon.Comparison = comparison
local slots = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
}
local equippedSlots = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

function comparison:Equipment(targets)
    local total, items = {}, {}
    local selected = GearVerdictDB.capsEnabled and equippedSlots or targets
    for _, slot in ipairs(selected) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local item, reason = addon.ItemData:Get(link)
            if not item then return nil, nil, reason end
            items[slot] = item
            for key, value in pairs(item.stats) do total[key] = (total[key] or 0) + value end
        end
    end
    return total, items
end

-- levelsAhead (optional): see Eligibility:Check; the result then carries goal = the required level.
function comparison:Evaluate(link, levelsAhead)
    local preset, reason = addon.Presets:Get()
    if not preset then return nil, reason end
    local candidate, issue = addon.ItemData:Get(link)
    if not candidate then return nil, issue end
    if addon.WeaponData:Handles(candidate.equipLoc) then
        local eligible, restriction = addon.Eligibility:Check(link, candidate, levelsAhead)
        if not eligible then return nil, restriction end
        local result, why = addon.WeaponComparison:Evaluate(link, candidate, preset, eligible == true and restriction or nil)
        return self:MarkQuality(result), why
    end
    local targets = slots[candidate.equipLoc]
    if not targets then return nil, "Special slots are not evaluated" end
    if candidate.equipLoc == "INVTYPE_TRINKET" then return nil, "Trinket effects are not evaluated" end
    local eligible, restriction = addon.Eligibility:Check(link, candidate, levelsAhead)
    if not eligible then return nil, restriction end
    local total, items, equipmentIssue = self:Equipment(targets)
    if not total then return nil, equipmentIssue end
    for _, slot in ipairs(targets) do
        if items[slot] and items[slot].key == candidate.key then return nil, "Already equipped" end
    end
    local best, comparisons = nil, {}
    for _, slot in ipairs(targets) do
        local allowed = addon.Eligibility:CanReplace(link, slot)
        if allowed then
            local previous = items[slot] or { stats = {} }
            local delta = addon.Scoring:Delta(total, previous, candidate, preset)
            local oldScore = addon.Scoring:Value(previous.stats, preset)
            local entry = { slot = slot, delta = delta, empty = items[slot] == nil,
                previousName = previous.name, previousLink = GetInventoryItemLink("player", slot),
                percent = not GearVerdictDB.capsEnabled and oldScore > 0 and delta / oldScore * 100 or nil }
            local upgrade, armorReason = addon.ArmorPreference:Judge(candidate, items[slot], delta)
            entry.upgrade, entry.armorReason = entry.empty or upgrade == true, armorReason
            comparisons[#comparisons + 1] = entry
            if not best or (entry.upgrade and not best.upgrade)
                or (entry.upgrade == best.upgrade and delta > best.delta) then best = entry end
        end
    end
    if not best then return nil, "Equipment restriction or unavailable requirements" end
    return self:MarkQuality({ delta = best.delta, slot = best.slot, empty = best.empty,
        upgrade = best.upgrade, candidate = candidate, comparisons = comparisons,
        goal = eligible == true and restriction or nil })
end

-- Options "Item quality": items below the chosen quality are never recommended (0 = all items, the default;
-- 1 = white and better; 2 = green and better). Only the new item counts: what you wear is not affected.
function comparison:MinQuality()
    local options = GearVerdictDB and GearVerdictDB.options
    return options and tonumber(options.minQuality) or 0
end

function comparison:MarkQuality(result)
    if result and result.candidate and (result.candidate.quality or 99) < self:MinQuality() then
        result.belowQuality = true
    end
    return result
end

function comparison:IsUpgrade(result)
    if result == nil or result.belowQuality then return false end
    return self:BeatsEquipped(result)
end

-- Better than what is worn, whatever the quality setting says.
function comparison:BeatsEquipped(result)
    if result == nil then return false end
    if result.upgrade ~= nil then return result.empty == true or result.upgrade == true end
    return result.empty == true or result.delta > 0.01
end
