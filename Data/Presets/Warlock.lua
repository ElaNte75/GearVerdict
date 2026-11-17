local _, addon = ...
local presets = addon.Presets

-- Warlock presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("WARLOCK", {
    specID = 265,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of affliction-warlock",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.69,
        ITEM_MOD_HIT_RATING_SHORT = 0.52,
        ITEM_MOD_HASTE_RATING_SHORT = 0.22,
        ITEM_MOD_INTELLECT_SHORT = 0.17,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0,
    },
})

presets:Register("WARLOCK", {
    specID = 266,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of demonology-warlock",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.29,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_HASTE_RATING_SHORT = 0.87,
        ITEM_MOD_CRIT_RATING_SHORT = 0.77,
        ITEM_MOD_INTELLECT_SHORT = 0.45,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.28,
    },
})

presets:Register("WARLOCK", {
    specID = 267,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of destruction-warlock",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.14,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.84,
        ITEM_MOD_HASTE_RATING_SHORT = 0.79,
        ITEM_MOD_INTELLECT_SHORT = 0.5,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.3,
    },
})
