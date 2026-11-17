local _, addon = ...
local transfer = {}
addon.WeightString = transfer

-- Reads and writes weight strings in the Pawn format, the common format exported by Raidbots,
-- Wowhead, simulators and addons:  ( Pawn: v1: "Name": Class=Shaman, Spec=Enhancement, Strength=1.0, ... )
-- A stat that is missing from a string is worth 0 (that is what Pawn means by leaving it out).

transfer.statNames = {
    strength = "ITEM_MOD_STRENGTH_SHORT",
    agility = "ITEM_MOD_AGILITY_SHORT",
    stamina = "ITEM_MOD_STAMINA_SHORT",
    intellect = "ITEM_MOD_INTELLECT_SHORT",
    spirit = "ITEM_MOD_SPIRIT_SHORT",
    hitrating = "ITEM_MOD_HIT_RATING_SHORT",
    critrating = "ITEM_MOD_CRIT_RATING_SHORT",
    hasterating = "ITEM_MOD_HASTE_RATING_SHORT",
    expertiserating = "ITEM_MOD_EXPERTISE_RATING_SHORT",
    attackpower = "ITEM_MOD_ATTACK_POWER_SHORT",
    spellpower = "ITEM_MOD_SPELL_POWER_SHORT",
    spelldamage = "ITEM_MOD_SPELL_POWER_SHORT",
    spellpenetration = "ITEM_MOD_SPELL_PENETRATION_SHORT",
    ap = "ITEM_MOD_ATTACK_POWER_SHORT",
    rap = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    rangedattackpower = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    armorpenetration = "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT",
    armorpenetrationrating = "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT",
    healing = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    mp5 = "ITEM_MOD_MANA_REGENERATION_SHORT",
    defenserating = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    dodgerating = "ITEM_MOD_DODGE_RATING_SHORT",
    parryrating = "ITEM_MOD_PARRY_RATING_SHORT",
    blockrating = "ITEM_MOD_BLOCK_RATING_SHORT",
    blockvalue = "ITEM_MOD_BLOCK_VALUE_SHORT",
}

transfer.exportNames = {
    ITEM_MOD_STRENGTH_SHORT = "Strength",
    ITEM_MOD_AGILITY_SHORT = "Agility",
    ITEM_MOD_STAMINA_SHORT = "Stamina",
    ITEM_MOD_INTELLECT_SHORT = "Intellect",
    ITEM_MOD_SPIRIT_SHORT = "Spirit",
    ITEM_MOD_HIT_RATING_SHORT = "HitRating",
    ITEM_MOD_CRIT_RATING_SHORT = "CritRating",
    ITEM_MOD_HASTE_RATING_SHORT = "HasteRating",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "ExpertiseRating",
    ITEM_MOD_ATTACK_POWER_SHORT = "AttackPower",
    ITEM_MOD_SPELL_POWER_SHORT = "SpellPower",
    ITEM_MOD_SPELL_PENETRATION_SHORT = "SpellPenetration",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Rap",
    ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "ArmorPenetration",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "Healing",
    ITEM_MOD_MANA_REGENERATION_SHORT = "Mp5",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "DefenseRating",
    ITEM_MOD_DODGE_RATING_SHORT = "DodgeRating",
    ITEM_MOD_PARRY_RATING_SHORT = "ParryRating",
    ITEM_MOD_BLOCK_RATING_SHORT = "BlockRating",
    ITEM_MOD_BLOCK_VALUE_SHORT = "BlockValue",
}

local function trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function number(value)
    local text = string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", "")
    return text
end

-- Returns a result table, or nil and a message the player can read.
function transfer:Parse(text, specID)
    if type(text) ~= "string" or trim(text) == "" then
        return nil, "Paste a weight string in the box above."
    end
    local version, name, body = trim(text):match('^%(%s*[Pp][Aa][Ww][Nn]%s*:%s*v(%d+)%s*:%s*"([^"]*)"%s*:%s*(.-)%s*%)$')
    if not version then
        return nil, 'This is not a Pawn weight string. It looks like: ( Pawn: v1: "Name": Strength=1.0, ... )'
    end
    if version ~= "1" then
        return nil, "This string uses Pawn version v" .. version .. ", which GearVerdict cannot read."
    end
    local result = { name = name, values = {}, ignored = {}, invalid = {}, count = 0 }
    local fromSpellPower = false
    for entry in (body .. ","):gmatch("([^,]*),") do
        entry = trim(entry)
        if entry ~= "" then
            local rawName, rawValue = entry:match("^([%w_]+)%s*=%s*(.-)$")
            local lower = rawName and rawName:lower()
            local key = lower and self.statNames[lower]
            local value = rawValue and tonumber(rawValue)
            if not rawName then
                result.invalid[#result.invalid + 1] = entry
            elseif lower == "class" then
                result.className = rawValue
            elseif lower == "spec" then
                result.specName = rawValue
            elseif not key or addon.Weights:Default(specID, key) == nil then
                result.ignored[#result.ignored + 1] = rawName
            elseif not addon.Weights:IsValid(value) then
                result.invalid[#result.invalid + 1] = entry
            elseif lower == "spelldamage" and fromSpellPower then
                result.ignored[#result.ignored + 1] = rawName
            else
                if result.values[key] == nil then result.count = result.count + 1 end
                result.values[key] = value
                fromSpellPower = fromSpellPower or lower == "spellpower"
            end
        end
    end
    if result.count == 0 then
        return nil, "No stat in this string is used by GearVerdict for this specialization."
    end
    local _, classFile = UnitClass("player")
    if result.className and classFile and result.className:upper():gsub("%s", "") ~= classFile then
        result.classMismatch = true
    end
    return result
end

-- What would change: list of { key, old, new } for every stat of the spec, in display order.
function transfer:Changes(specID, result)
    local changes = {}
    for _, key in ipairs(addon.Weights:Keys(specID)) do
        local old = addon.Weights:Effective(specID, key)
        local new = result.values[key] or 0
        changes[#changes + 1] = { key = key, old = old, new = new, missing = result.values[key] == nil }
    end
    return changes
end

function transfer:Apply(specID, result)
    for _, change in ipairs(self:Changes(specID, result)) do
        addon.Weights:Set(specID, change.key, change.new)
    end
end

function transfer:Export(specID)
    local _, classFile = UnitClass("player")
    local className = classFile and (classFile:sub(1, 1) .. classFile:sub(2):lower()) or "Unknown"
    local specName = addon.SpecDetection:SpecName(specID) or "Unknown"
    local parts = { "Class=" .. className, "Spec=" .. specName }
    for _, key in ipairs(addon.Weights:Keys(specID)) do
        local value = addon.Weights:Effective(specID, key)
        if value and value > 0 and self.exportNames[key] then
            parts[#parts + 1] = self.exportNames[key] .. "=" .. number(value)
        end
    end
    return '( Pawn: v1: "GearVerdict ' .. specName .. '": ' .. table.concat(parts, ", ") .. " )"
end
