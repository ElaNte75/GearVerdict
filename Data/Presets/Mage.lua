local _, addon = ...
local presets = addon.Presets

-- Mage presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("MAGE", {
    specID = 62,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of arcane-mage",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.79,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_INTELLECT_SHORT = 0.99,
        ITEM_MOD_CRIT_RATING_SHORT = 0.8,
        ITEM_MOD_HASTE_RATING_SHORT = 0.66,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.43,
        ITEM_MOD_SPIRIT_SHORT = 0.27,
    },
})

presets:Register("MAGE", {
    specID = 63,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of fire-mage",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.53,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.76,
        ITEM_MOD_INTELLECT_SHORT = 0.47,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.25,
        ITEM_MOD_SPIRIT_SHORT = 0.11,
        ITEM_MOD_HASTE_RATING_SHORT = 0,
    },
})

presets:Register("MAGE", {
    specID = 64,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of frost-mage",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.64,
        ITEM_MOD_HASTE_RATING_SHORT = 1.09,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.65,
        ITEM_MOD_INTELLECT_SHORT = 0.18,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.02,
        ITEM_MOD_SPIRIT_SHORT = 0.01,
    },
})
