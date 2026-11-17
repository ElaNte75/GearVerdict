local _, addon = ...
local presets = addon.Presets

-- Rogue presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("ROGUE", {
    specID = 259,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of assassination-rogue",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_EXPERTISE_RATING_SHORT = 2.99,
        ITEM_MOD_AGILITY_SHORT = 2.05,
        ITEM_MOD_HIT_RATING_SHORT = 1.9,
        ITEM_MOD_CRIT_RATING_SHORT = 1.83,
        ITEM_MOD_HASTE_RATING_SHORT = 1.36,
        ITEM_MOD_STRENGTH_SHORT = 1.1,
        ITEM_MOD_ATTACK_POWER_SHORT = 1,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.42,
    },
})

presets:Register("ROGUE", {
    specID = 260,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of combat-rogue",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_EXPERTISE_RATING_SHORT = 2.8,
        ITEM_MOD_HIT_RATING_SHORT = 2.28,
        ITEM_MOD_AGILITY_SHORT = 1.81,
        ITEM_MOD_HASTE_RATING_SHORT = 1.6,
        ITEM_MOD_CRIT_RATING_SHORT = 1.34,
        ITEM_MOD_STRENGTH_SHORT = 1.1,
        ITEM_MOD_ATTACK_POWER_SHORT = 1,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.35,
    },
})

presets:Register("ROGUE", {
    specID = 261,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of subtlety-rogue",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_EXPERTISE_RATING_SHORT = 2.56,
        ITEM_MOD_HIT_RATING_SHORT = 2.15,
        ITEM_MOD_AGILITY_SHORT = 1.93,
        ITEM_MOD_CRIT_RATING_SHORT = 1.55,
        ITEM_MOD_HASTE_RATING_SHORT = 1.54,
        ITEM_MOD_STRENGTH_SHORT = 1.1,
        ITEM_MOD_ATTACK_POWER_SHORT = 1,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.26,
    },
})
