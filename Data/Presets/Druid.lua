local _, addon = ...
local presets = addon.Presets

-- Druid presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("DRUID", {
    specID = 102,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of balance-druid",
    revision = "2026-11-15",
    caps = presets.caps.spell,
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 1.12,
        ITEM_MOD_SPELL_POWER_SHORT = 1,
        ITEM_MOD_HASTE_RATING_SHORT = 0.84,
        ITEM_MOD_CRIT_RATING_SHORT = 0.67,
        ITEM_MOD_INTELLECT_SHORT = 0.28,
        ITEM_MOD_MANA_REGENERATION_SHORT = 0.14,
    },
})

presets:Register("DRUID", {
    specID = 103,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of feral-druid",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_AGILITY_SHORT = 1,
        ITEM_MOD_STRENGTH_SHORT = 0.89,
        ITEM_MOD_CRIT_RATING_SHORT = 0.78,
        ITEM_MOD_HIT_RATING_SHORT = 0.69,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 0.67,
        ITEM_MOD_HASTE_RATING_SHORT = 0.55,
        ITEM_MOD_ATTACK_POWER_SHORT = 0.36,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.12,
    },
})

presets:Register("DRUID", {
    specID = 104,
    basis = "guide",
    source = "Guide survival order (NeverFF, StillSixty); MythicSim tank pages score threat only, not survival",
    revision = "2026-11-15",
    caps = presets.caps.melee,
    weights = {
        ITEM_MOD_STAMINA_SHORT = 1,
        ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 0.9,
        ITEM_MOD_DODGE_RATING_SHORT = 0.8,
        ITEM_MOD_AGILITY_SHORT = 0.7,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 0.5,
        ITEM_MOD_HIT_RATING_SHORT = 0.4,
        ITEM_MOD_STRENGTH_SHORT = 0.3,
    },
})

presets:Register("DRUID", {
    specID = 105,
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
        ITEM_MOD_HASTE_RATING_SHORT = 0.25,
        ITEM_MOD_STAMINA_SHORT = 0.05,
    },
})
