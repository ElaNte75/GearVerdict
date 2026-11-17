local _, addon = ...
local presets = addon.Presets

-- Paladin presets (data only). basis "simulated" = MythicSim numbers; "guide" = guide order, spacing guessed.
-- Where one item stat covers two simulated rows (melee/spell crit, attack/ranged attack power), the higher row is used.

presets:Register("PALADIN", {
    specID = 65,
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
        ITEM_MOD_SPIRIT_SHORT = 0.2,
        ITEM_MOD_STAMINA_SHORT = 0.05,
    },
})

presets:Register("PALADIN", {
    specID = 66,
    basis = "guide",
    source = "Guide survival order (NeverFF, StillSixty); MythicSim tank pages score threat only, not survival",
    revision = "2026-11-15",
    caps = presets.caps.hybrid,
    weights = {
        ITEM_MOD_STAMINA_SHORT = 1,
        ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 0.9,
        ITEM_MOD_DODGE_RATING_SHORT = 0.8,
        ITEM_MOD_PARRY_RATING_SHORT = 0.7,
        ITEM_MOD_BLOCK_RATING_SHORT = 0.6,
        ITEM_MOD_BLOCK_VALUE_SHORT = 0.4,
        ITEM_MOD_EXPERTISE_RATING_SHORT = 0.5,
        ITEM_MOD_HIT_RATING_SHORT = 0.4,
        ITEM_MOD_SPELL_POWER_SHORT = 0.3,
        ITEM_MOD_STRENGTH_SHORT = 0.3,
        ITEM_MOD_AGILITY_SHORT = 0.3,
        ITEM_MOD_INTELLECT_SHORT = 0.1,
    },
})

presets:Register("PALADIN", {
    specID = 70,
    basis = "simulated",
    source = "MythicSim Forever stat priority (client 1.60.1, level 63 boss), page of retribution-paladin",
    revision = "2026-11-15",
    caps = presets.caps.hybrid,
    weights = {
        ITEM_MOD_EXPERTISE_RATING_SHORT = 2.86,
        ITEM_MOD_SPELL_POWER_SHORT = 2.11,
        ITEM_MOD_CRIT_RATING_SHORT = 1.73,
        ITEM_MOD_INTELLECT_SHORT = 1.6,
        ITEM_MOD_HASTE_RATING_SHORT = 1.48,
        ITEM_MOD_AGILITY_SHORT = 1.36,
        ITEM_MOD_STRENGTH_SHORT = 1,
        ITEM_MOD_ATTACK_POWER_SHORT = 0.41,
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 0.1,
        ITEM_MOD_HIT_RATING_SHORT = 0,
    },
})
