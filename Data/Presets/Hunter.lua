local _, addon = ...
local presets = addon.Presets

-- Hunter presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("HUNTER", {
    specID = 253,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of hunter (Beast Mastery)",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.41,
        ITEM_MOD_AGILITY_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.91,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 0.73,
        ITEM_MOD_INTELLECT_SHORT = 0.59,
        ITEM_MOD_HASTE_RATING_SHORT = 0.4,
        ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 0.29,
        ITEM_MOD_ATTACK_POWER_SHORT = 0.29,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.26,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.13,
        ITEM_MOD_STRENGTH_SHORT = 0.1,
    },
})

presets:Register("HUNTER", {
    specID = 254,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of marksmanship-hunter",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.11,
        ITEM_MOD_AGILITY_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.84,
        ITEM_MOD_INTELLECT_SHORT = 0.58,
        ITEM_MOD_HASTE_RATING_SHORT = 0.38,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 0.31,
        ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 0.3,
        ITEM_MOD_ATTACK_POWER_SHORT = 0.3,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.21,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.13,
        ITEM_MOD_STRENGTH_SHORT = 0.11,
    },
})

presets:Register("HUNTER", {
    specID = 255,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of survival-hunter",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_AGILITY_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.77,
        ITEM_MOD_INTELLECT_SHORT = 0.67,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 0.62,
        ITEM_MOD_HASTE_RATING_SHORT = 0.41,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.39,
        ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 0.2,
        ITEM_MOD_ATTACK_POWER_SHORT = 0.2,
        ITEM_MOD_STRENGTH_SHORT = 0.17,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.13,
        ITEM_MOD_HIT_RATING_SHORT = 0,
    },
})
