local _, addon = ...
local presets = addon.Presets

-- Warrior presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("WARRIOR", {
    specID = 71,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of arms-warrior",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.12,
        ITEM_MOD_CRIT_RATING_SHORT = 1.08,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 1.04,
        ITEM_MOD_STRENGTH_SHORT = 1,
        ITEM_MOD_AGILITY_SHORT = 0.84,
        ITEM_MOD_HASTE_RATING_SHORT = 0.83,
        ITEM_MOD_ATTACK_POWER_SHORT = 0.45,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.2,
    },
})

presets:Register("WARRIOR", {
    specID = 72,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of warrior (Fury)",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_EXPERTISE_RATING_SHORT = 1.53,
        ITEM_MOD_HIT_RATING_SHORT = 1.33,
        ITEM_MOD_CRIT_RATING_SHORT = 1.02,
        ITEM_MOD_STRENGTH_SHORT = 1,
        ITEM_MOD_HASTE_RATING_SHORT = 0.87,
        ITEM_MOD_AGILITY_SHORT = 0.8,
        ITEM_MOD_ATTACK_POWER_SHORT = 0.45,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.19,
    },
})

presets:Register("WARRIOR", {
    specID = 73,
    basis = "guide",
    source = "Guide survival order (NeverFF, StillSixty); MythicSim tank pages score threat only, not survival",
    revision = "2026-11-21",
    caps = presets.caps.melee,
    -- Strength 0.3 -> 0.1 (2026-11-21): it gives threat, not survival; Agility keeps 0.3 (dodge + armor).
    weights = {
        ITEM_MOD_STAMINA_SHORT = 1,
        ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 0.9,
        ITEM_MOD_DODGE_RATING_SHORT = 0.8,
        ITEM_MOD_PARRY_RATING_SHORT = 0.7,
        ITEM_MOD_BLOCK_RATING_SHORT = 0.6,
        ITEM_MOD_BLOCK_VALUE_SHORT = 0.4,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 0.5,
        ITEM_MOD_HIT_RATING_SHORT = 0.4,
        ITEM_MOD_STRENGTH_SHORT = 0.1,
        ITEM_MOD_AGILITY_SHORT = 0.3,
    },
})
