local _, addon = ...
local presets = addon.Presets

-- Priest presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("PRIEST", {
    specID = 256,
    basis = "guide",
    source = "Guide priority orders (NeverFF, StillSixty, ChaosBoost); no simulation exists for healers",
    revision = "2026-11-15",
    caps = presets.caps.none,
    weights = {
        ITEM_MOD_SPELL_HEALING_DONE_SHORT = 1,
        ITEM_MOD_INTELLECT_SHORT = 0.6,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.5,
        ITEM_MOD_SPELL_POWER_SHORT = 0.5,
        ITEM_MOD_SPIRIT_SHORT = 0.4,
        ITEM_MOD_CRIT_RATING_SHORT = 0.35,
        ITEM_MOD_STAMINA_SHORT = 0.05,
    },
})

presets:Register("PRIEST", {
    specID = 257,
    basis = "guide",
    source = "Guide priority orders (NeverFF, StillSixty, ChaosBoost); no simulation exists for healers",
    revision = "2026-11-15",
    caps = presets.caps.none,
    weights = {
        ITEM_MOD_SPELL_HEALING_DONE_SHORT = 1,
        ITEM_MOD_SPIRIT_SHORT = 0.6,
        ITEM_MOD_INTELLECT_SHORT = 0.55,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.5,
        ITEM_MOD_SPELL_POWER_SHORT = 0.5,
        ITEM_MOD_CRIT_RATING_SHORT = 0.35,
        ITEM_MOD_STAMINA_SHORT = 0.05,
    },
})

presets:Register("PRIEST", {
    specID = 258,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of shadow-priest",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.19,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_CRIT_RATING_SHORT = 0.91,
        ITEM_MOD_HASTE_RATING_SHORT = 0.65,
        ITEM_MOD_INTELLECT_SHORT = 0.26,
    },
})
