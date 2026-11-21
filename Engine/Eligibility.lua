local _, addon = ...
local eligibility = {}
addon.Eligibility = eligibility

-- Heaviest armor each class can wear (armor subclass: 1 cloth, 2 leather, 3 mail, 4 plate).
-- "upgrade" classes move to a heavier type at level 40. Classic rules: no Forever source confirms them,
-- the client's own equip check below still has the last word.
eligibility.armor = {
    PRIEST = { max = 1 }, MAGE = { max = 1 }, WARLOCK = { max = 1 },
    ROGUE = { max = 2 }, DRUID = { max = 2 },
    HUNTER = { max = 2, upgrade = 3, level = 40 }, SHAMAN = { max = 2, upgrade = 3, level = 40 },
    WARRIOR = { max = 3, upgrade = 4, level = 40 }, PALADIN = { max = 3, upgrade = 4, level = 40 },
}

function eligibility:MaxArmor(class, level)
    local rule = self.armor[class]
    if not rule then return nil end
    if rule.upgrade and level >= rule.level then return rule.upgrade end
    return rule.max
end

-- The game's "Requires Level %d" line, as a pattern (to tell it apart from other red requirement lines).
local function levelLinePattern()
    local text = ITEM_MIN_LEVEL or "Requires Level %d"
    return "^" .. text:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%d", "%%d+") .. "$"
end

-- levelsAhead (optional, Dungeon Journal only): an item up to that many levels above the player counts
-- as a goal. It is then judged as if the player had its required level (armor type included), and
-- the red "Requires Level" line no longer blocks it. Returns true, goalLevel (nil = wearable now).
function eligibility:Check(link, item, levelsAhead)
    if (item.classID ~= 4 and item.classID ~= 2) or not item.equipLoc or item.equipLoc == "" then
        return nil, "Unsupported equipment"
    end
    local level = UnitLevel("player")
    if not item.required then return nil, "Level requirement not met" end
    local goal
    if item.required > level then
        if not levelsAhead or item.required > level + levelsAhead then return nil, "Level requirement not met" end
        goal, level = item.required, item.required
    end
    local _, class = UnitClass("player")
    local maxArmor = self:MaxArmor(class, level)
    if not maxArmor then return nil, "Unknown class" end
    if item.classID == 2 then
        -- Weapons: the learned-skill check is the red tooltip line below. Fishing poles and misc are skipped.
        if item.subclassID == 14 or item.subclassID == 20 then return nil, "Unsupported weapon type" end
    elseif item.equipLoc == "INVTYPE_SHIELD" or item.equipLoc == "INVTYPE_HOLDABLE" then
        -- Shields and held-in-off-hand items: the client equip check and red lines decide.
    else
        if item.subclassID and item.subclassID > 4 then return nil, "Unsupported armor type" end
        if item.subclassID and item.subclassID > maxArmor then return nil, "Armor type not wearable yet" end
    end
    local equippable = C_Item.IsEquippableItem or IsEquippableItem
    if not equippable or not equippable(link) then return nil, "Item cannot be equipped" end
    local levelLine = goal and levelLinePattern()
    if not C_TooltipInfo or not C_TooltipInfo.GetHyperlink then return nil, "Requirements API unavailable" end
    local info = C_TooltipInfo.GetHyperlink(link)
    if not info or not info.lines or not next(info.lines) then return nil, "Requirements unavailable" end
    for _, line in ipairs(info.lines) do
        for _, side in ipairs({ "left", "right" }) do
            local text, color = line[side .. "Text"], line[side .. "Color"]
            if text and not addon:IsPublic(text) then return nil, "Restricted requirements" end
            if text and text ~= "" and color then
                local r, g, b = color.r, color.g, color.b
                if not addon:IsPublic(r) or not addon:IsPublic(g) or not addon:IsPublic(b) then
                    return nil, "Restricted requirements"
                end
                if r and g and b and r > 0.7 and g < 0.3 and b < 0.3 and not (levelLine and text:match(levelLine)) then
                    return nil, "Unmet item requirement"
                end
            end
        end
    end
    return true, goal
end

function eligibility:CanReplace(link, slot)
    local unique = C_Item.GetItemUniquenessByID
    if not unique then return nil, "Uniqueness API unavailable" end
    local isUnique, _, limit, category = unique(link)
    if isUnique == nil then return nil, "Uniqueness unavailable" end
    if not isUnique and (not category or category == 0) then return true end
    local categorized = category and category ~= 0
    if categorized and not limit then return nil, "Unknown equipment restriction" end
    local id = tonumber(link:match("item:(%d+)"))
    if not categorized and not id then return nil, "Unknown unique item" end
    limit = categorized and limit or 1
    local count = 0
    for _, otherSlot in ipairs({ 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }) do
        if otherSlot ~= slot then
            local other = GetInventoryItemLink("player", otherSlot)
            if other then
                if categorized then
                    local otherUnique, _, _, otherCategory = unique(other)
                    if otherUnique == nil then return nil, "Equipped restriction unavailable" end
                    if otherCategory == category then count = count + 1 end
                elseif tonumber(other:match("item:(%d+)")) == id then
                    count = count + 1
                end
            end
        end
    end
    if count >= limit then return nil, "Unique-equipped restriction" end
    return true
end
