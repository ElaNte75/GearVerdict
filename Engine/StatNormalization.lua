local _, addon = ...
local normalization = {}
addon.StatNormalization = normalization

function normalization:Apply(stats)
    local clean = {}
    for stat, value in pairs(stats) do clean[stat] = value end
    local damage, power = clean.ITEM_MOD_SPELL_DAMAGE_DONE_SHORT, clean.ITEM_MOD_SPELL_POWER_SHORT
    if damage and power and damage ~= power then return nil, "Ambiguous spell damage stats" end
    if power == nil and damage ~= nil then clean.ITEM_MOD_SPELL_POWER_SHORT = damage end
    clean.ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = nil
    return clean
end
