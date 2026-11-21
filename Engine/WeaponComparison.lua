local _, addon = ...
local compare = { bag = nil }
addon.WeaponComparison = compare

-- Weapon, shield, off-hand and ranged comparison (design 2026-11-20). Builds the same result shape as
-- Comparison:Evaluate. Setups: two-hander, one-hand + shield/off-hand item, dual wield.
local MAIN, OFF, RANGED = 16, 17, 18
local BAG_SECONDS = 1

-- Weapon item with its speed attached (speed is read from the tooltip once and cached).
local function prepare(link, item)
    if item and item.classID == 2 and item.speed == nil then
        item.speed = addon.WeaponData:Speed(link, item) or false
    end
    if item and item.speed == false then item.speed = nil end
    return item
end

local function equipped(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then return nil end
    local item, reason = addon.ItemData:Get(link)
    if not item then return nil, reason end
    return prepare(link, item), link
end

-- Usable items in the bags (re-read at most once a second; bag arrows evaluate many slots at once).
function compare:BagItems()
    local now = GetTime and GetTime() or 0
    if self.bag and now - self.bag.time < BAG_SECONDS then return self.bag.items end
    local items = {}
    local container = C_Container
    if container and container.GetContainerNumSlots and container.GetContainerItemLink then
        for bag = 0, NUM_BAG_SLOTS or 4 do
            for slot = 1, container.GetContainerNumSlots(bag) or 0 do
                local link = container.GetContainerItemLink(bag, slot)
                if link and addon:IsPublic(link) then
                    local item = addon.ItemData:Get(link)
                    if item and addon.WeaponData:Kind(item) then
                        local usable, goal = addon.Eligibility:Check(link, item)
                        if usable and not goal then items[#items + 1] = { link = link, item = prepare(link, item) } end
                    end
                end
            end
        end
    end
    self.bag = { time = now, items = items }
    return items
end

local function merged(...)
    local stats = {}
    for index = 1, select("#", ...) do
        local item = select(index, ...)
        if item then for key, value in pairs(item.stats) do stats[key] = (stats[key] or 0) + value end end
    end
    return { stats = stats }
end

local function names(...)
    local list = {}
    for index = 1, select("#", ...) do
        local item = select(index, ...)
        if item then list[#list + 1] = item.name end
    end
    return #list > 0 and table.concat(list, " + ") or nil
end

-- One option: the new setup against the old one. partner = bag item that completes the new setup.
function compare:Option(context, slot, new, old, partner)
    local guide, preset = context.guide, context.preset
    local oldItems = { old.main, old.off, old.ranged }
    local newItems = { new.main, new.off, new.ranged }
    local before, after = merged(oldItems[1], oldItems[2], oldItems[3]), merged(newItems[1], newItems[2], newItems[3])
    local statDelta = addon.Scoring:Delta(context.total, before, after, preset)
    local oldScore = addon.Scoring:Value(before.stats, preset)
        + addon.WeaponData:DpsValue(guide, old.main, old.off, old.ranged)
    local delta = statDelta + addon.WeaponData:DpsValue(guide, new.main, new.off, new.ranged)
        - addon.WeaponData:DpsValue(guide, old.main, old.off, old.ranged)
    local empty = not (old.main or old.off or old.ranged)
    local upgrade, reason = true, nil
    if not empty then upgrade, reason = addon.WeaponData:Judge(guide, new, old, delta, oldScore) end
    local previousName = names(old.main, old.off, old.ranged)
    return { slot = slot, delta = delta, empty = empty, upgrade = upgrade == true, weaponReason = reason,
        previousName = previousName, previousLink = context.links[slot] or context.links[MAIN],
        partner = partner and partner.item.name,
        percent = not GearVerdictDB.capsEnabled and oldScore > 0 and delta / oldScore * 100 or nil }
end

local function better(a, b)
    if not b then return true end
    if a.upgrade ~= b.upgrade then return a.upgrade end
    return a.delta > b.delta
end

-- Best option when the other hand is filled from the bags (or left empty).
function compare:WithPartner(context, slot, candidate, wantsMain, old)
    local best
    local function try(partner)
        local new = wantsMain and { main = candidate, off = partner and partner.item }
            or { main = partner and partner.item, off = candidate }
        local option = self:Option(context, slot, new, old, partner)
        if better(option, best) then best = option end
    end
    try(nil)
    for _, entry in ipairs(self:BagItems()) do
        local kind = addon.WeaponData:Kind(entry.item)
        local fitsHand = wantsMain and addon.WeaponData:IsOff(kind, context.dual) or (not wantsMain and addon.WeaponData:IsMain(kind))
        if fitsHand and entry.item.key ~= candidate.key then try(entry) end
    end
    return best
end

function compare:Evaluate(link, candidate, preset, goal)
    local kind = addon.WeaponData:Kind(candidate)
    local context = { preset = preset, guide = addon.WeaponGuide:Get(preset.specID), links = {},
        dual = addon.WeaponData:CanDualWield() }
    prepare(link, candidate)
    local items = {}
    for _, slot in ipairs({ MAIN, OFF, RANGED }) do
        local item, otherLink = equipped(slot)
        if GetInventoryItemLink("player", slot) and not item then return nil, otherLink end
        items[slot], context.links[slot] = item, GetInventoryItemLink("player", slot)
        if item and item.key == candidate.key then return nil, "Already equipped" end
    end
    local total = addon.Comparison:Equipment({ MAIN, OFF, RANGED })
    if not total then return nil, "Equipped item data unavailable" end
    context.total = total
    local main, off = items[MAIN], items[OFF]
    local holdsTwoHand = main and addon.WeaponData:Kind(main) == "twohand"
    local options = {}
    local function add(slot, option)
        if option and addon.Eligibility:CanReplace(link, slot) then options[#options + 1] = option end
    end
    if kind == "ranged" then
        add(RANGED, self:Option(context, RANGED, { ranged = candidate }, { ranged = items[RANGED] }))
    elseif kind == "twohand" then
        add(MAIN, self:Option(context, MAIN, { main = candidate }, { main = main, off = off }))
    elseif holdsTwoHand then
        if addon.WeaponData:IsMain(kind) then
            add(MAIN, self:WithPartner(context, MAIN, candidate, true, { main = main }))
        elseif addon.WeaponData:IsOff(kind, context.dual) then
            add(OFF, self:WithPartner(context, OFF, candidate, false, { main = main }))
        end
    else
        if addon.WeaponData:IsMain(kind) then
            add(MAIN, self:Option(context, MAIN, { main = candidate, off = off }, { main = main, off = off }))
        end
        if addon.WeaponData:IsOff(kind, context.dual) then
            add(OFF, self:Option(context, OFF, { main = main, off = candidate }, { main = main, off = off }))
        end
    end
    if #options == 0 then return nil, "Not usable in your weapon setup" end
    local best
    for _, option in ipairs(options) do
        if better(option, best) then best = option end
    end
    return { delta = best.delta, slot = best.slot, empty = best.empty, upgrade = best.upgrade,
        candidate = candidate, comparisons = options, goal = goal }
end
