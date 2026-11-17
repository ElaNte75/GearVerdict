local _, addon = ...
local presets = addon.Presets

-- Shaman presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("SHAMAN", {
    specID = 262,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of elemental-shaman",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.32,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_HASTE_RATING_SHORT = 0.96,
        ITEM_MOD_CRIT_RATING_SHORT = 0.69,
        ITEM_MOD_INTELLECT_SHORT = 0.19,
    },
})

presets:Register("SHAMAN", {
    specID = 263,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of enhancement-shaman",
    revision = "2026-11-15",
    caps = presets.caps.hybrid,
    weights = {
        ITEM_MOD_EXPERTISE_RATING_SHORT = 4.06,
        ITEM_MOD_STRENGTH_SHORT = 2.2,
        ITEM_MOD_HASTE_RATING_SHORT = 2.15,
        ITEM_MOD_HIT_RATING_SHORT = 2.08,
        ITEM_MOD_INTELLECT_SHORT = 1.96,
        ITEM_MOD_CRIT_RATING_SHORT = 1.84,
        ITEM_MOD_AGILITY_SHORT = 1.43,
        ITEM_MOD_SPELL_POWER_SHORT = 1.37,
        ITEM_MOD_ATTACK_POWER_SHORT = 1,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.35,
    },
})

presets:Register("SHAMAN", {
    specID = 264,
    basis = "guide",
    source = "Guide priority orders (NeverFF, StillSixty, ChaosBoost); no simulation exists for healers",
    revision = "2026-11-15",
    caps = presets.caps.none,
    weights = {
        ITEM_MOD_SPELL_HEALING_DONE_SHORT = 1,
        ITEM_MOD_INTELLECT_SHORT = 0.6,
        ITEM_MOD_CRIT_RATING_SHORT = 0.5,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.45,
        ITEM_MOD_SPELL_POWER_SHORT = 0.5,
        ITEM_MOD_SPIRIT_SHORT = 0.3,
        ITEM_MOD_HASTE_RATING_SHORT = 0.25,
        ITEM_MOD_STAMINA_SHORT = 0.05,
    },
})
