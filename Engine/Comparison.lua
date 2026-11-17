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
local equippedSlots = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }

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

function comparison:Evaluate(link)
    local preset, reason = addon.Presets:Get()
    if not preset then return nil, reason end
    local candidate, issue = addon.ItemData:Get(link)
    if not candidate then return nil, issue end
    local targets = slots[candidate.equipLoc]
    if not targets then return nil, "Weapons and special slots need separate validation" end
    if candidate.equipLoc == "INVTYPE_TRINKET" then return nil, "Trinket effects are not evaluated" end
    local eligible, restriction = addon.Eligibility:Check(link, candidate)
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
            entry.upgrade = entry.empty or delta > 0.01
            comparisons[#comparisons + 1] = entry
            if not best or (entry.upgrade and not best.upgrade)
                or (entry.upgrade == best.upgrade and delta > best.delta) then best = entry end
        end
    end
    if not best then return nil, "Equipment restriction or unavailable requirements" end
    return { delta = best.delta, slot = best.slot, empty = best.empty,
        upgrade = best.upgrade, candidate = candidate, comparisons = comparisons }
end

function comparison:IsUpgrade(result)
    return result ~= nil and (result.empty == true or result.delta > 0.01)
end
