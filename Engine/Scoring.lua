local _, addon = ...
local scoring = {}
addon.Scoring = scoring
local ARMOR = "RESISTANCE0_NAME"

-- Armor value (agreed with the user 2026-11-21), from the game's armor formula, not a guess:
--   damage taken from a hit = 1 - armor / (armor + 400 + 85 * level)
-- With that formula, 1 Armor adds as much survival against physical hits as
--   health / (10 * (armor + 400 + 85 * level)) Stamina (1 Stamina = 10 health).
-- So the weight of 1 Armor = the spec's Stamina weight x that ratio, read live from the character.
-- Damage specs get a Stamina weight too (Data/Presets.lua), so Armor counts for every spec.
function scoring:ArmorWeight()
    local stamina = addon.Presets:Weight("ITEM_MOD_STAMINA_SHORT") or 0
    if stamina <= 0 or not UnitHealthMax or not UnitArmor or not UnitLevel then return 0 end
    local health = UnitHealthMax("player")
    local armor = select(2, UnitArmor("player"))
    local level = UnitLevel("player")
    if type(health) ~= "number" or health <= 0 or type(level) ~= "number" or level <= 0 then return 0 end
    if not addon:IsPublic(health) or not addon:IsPublic(armor) then return 0 end
    armor = type(armor) == "number" and math.max(armor, 0) or 0
    return stamina * health / (10 * (armor + 400 + 85 * level))
end

function scoring:Value(stats, preset)
    local score = 0
    for key in pairs(preset.weights) do
        local amount = stats[key] or 0
        local weight = addon.Presets:Weight(key) or 0
        local cap = GearVerdictDB.capsEnabled and UnitLevel("player") == 60 and preset.caps[key]
        if cap then
            score = score + math.min(amount, cap.threshold) * weight
                + math.max(0, amount - cap.threshold) * cap.after
        else
            score = score + amount * weight
        end
    end
    local armor = stats[ARMOR]
    if armor and armor ~= 0 and not preset.weights[ARMOR] then score = score + armor * self:ArmorWeight() end
    return score
end

function scoring:Delta(total, previous, candidate, preset)
    local changed = {}
    for key, value in pairs(total) do changed[key] = value end
    for key, value in pairs(previous.stats) do changed[key] = (changed[key] or 0) - value end
    for key, value in pairs(candidate.stats) do changed[key] = (changed[key] or 0) + value end
    return self:Value(changed, preset) - self:Value(total, preset)
end
