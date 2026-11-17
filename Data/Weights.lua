local _, addon = ...
local weights = {}
addon.Weights = weights

-- Custom weights are kept per specialization: GearVerdictDB.weightsBySpec[specID][statKey] = value.
-- Only values that differ from the preset default are stored.

weights.names = {
    ITEM_MOD_HIT_RATING_SHORT = "Hit Rating",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "Expertise Rating",
    ITEM_MOD_INTELLECT_SHORT = "Intellect",
    ITEM_MOD_SPELL_POWER_SHORT = "Spell Power",
    ITEM_MOD_STRENGTH_SHORT = "Strength",
    ITEM_MOD_SPELL_PENETRATION_SHORT = "Spell Penetration",
    ITEM_MOD_HASTE_RATING_SHORT = "Haste Rating",
    ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike Rating",
    ITEM_MOD_AGILITY_SHORT = "Agility",
    ITEM_MOD_SPIRIT_SHORT = "Spirit",
    ITEM_MOD_STAMINA_SHORT = "Stamina",
    ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Ranged Attack Power",
    ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "Armor Penetration",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "Healing",
    ITEM_MOD_MANA_REGENERATION_SHORT = "Mana per 5 sec.",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense Rating",
    ITEM_MOD_DODGE_RATING_SHORT = "Dodge Rating",
    ITEM_MOD_PARRY_RATING_SHORT = "Parry Rating",
    ITEM_MOD_BLOCK_RATING_SHORT = "Block Rating",
    ITEM_MOD_BLOCK_VALUE_SHORT = "Block Value",
}

local function store()
    GearVerdictDB.weightsBySpec = GearVerdictDB.weightsBySpec or {}
    return GearVerdictDB.weightsBySpec
end

local function round(value)
    return math.floor(value * 1000 + 0.5) / 1000
end

-- The old single set of custom weights belonged to Enhancement, the only preset at the time.
function weights:Migrate()
    local old = GearVerdictDB.weights
    if type(old) == "table" and next(old) then
        for key, value in pairs(old) do
            if self:Custom(263, key) == nil then self:Set(263, key, value) end
        end
    end
    GearVerdictDB.weights = nil
end

function weights:Name(key)
    return self.names[key] or _G[key] or key
end

function weights:Default(specID, key)
    local preset = specID and addon.Presets.bySpec[specID]
    return preset and preset.weights[key]
end

function weights:Custom(specID, key)
    local list = specID and store()[specID]
    return list and list[key]
end

function weights:Effective(specID, key)
    local custom = self:Custom(specID, key)
    if custom ~= nil then return custom end
    return self:Default(specID, key)
end

function weights:IsCustom(specID, key)
    return self:Custom(specID, key) ~= nil
end

function weights:IsValid(value)
    return type(value) == "number" and value == value and value >= 0 and value <= 1000
end

function weights:Set(specID, key, value)
    local default = self:Default(specID, key)
    if default == nil or not self:IsValid(value) then return false end
    value = round(value)
    local all = store()
    local list = all[specID] or {}
    if math.abs(value - default) < 0.0005 then list[key] = nil else list[key] = value end
    all[specID] = next(list) and list or nil
    return true
end

function weights:Reset(specID, key)
    local list = store()[specID]
    if list then
        list[key] = nil
        if not next(list) then store()[specID] = nil end
    end
end

function weights:ResetAll(specID)
    store()[specID] = nil
end

function weights:HasCustom(specID)
    return store()[specID] ~= nil
end

-- Stats of the spec's preset, most important (highest default) first.
function weights:Keys(specID)
    local preset = specID and addon.Presets.bySpec[specID]
    local keys = {}
    if not preset then return keys end
    for key in pairs(preset.weights) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b)
        local wa, wb = preset.weights[a], preset.weights[b]
        if wa ~= wb then return wa > wb end
        return self:Name(a) < self:Name(b)
    end)
    return keys
end

function weights:Format(value)
    if value == nil then return "-" end
    local text = string.format("%.3f", value)
    if text:sub(-1) == "0" then text = text:sub(1, -2) end
    return text
end
