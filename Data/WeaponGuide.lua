local _, addon = ...
local guide = {}
addon.WeaponGuide = guide

-- Per-spec weapon guide (data only). Provisional, from beta-era Forever guides (Icy Veins, wow.gg,
-- Mobalytics, Warcraft Tavern, Gfinity); see docs/superpowers/specs/2026-11-20-weapon-support-design.md.
--   melee / ranged: value of 1 weapon DPS (main hand / ranged slot). Rule: 1 DPS = 14 attack power, so
--     14 x the preset's Attack Power weight. Off hand counts half. nil = judged by stats only.
--   setups: allowed { twohand, dual, shield }; nil = any setup (casters, healers, Feral, BM/MM melee).
--     "dual" also accepts one one-hander with an empty off hand.
--   mainSlow / mainFast / offFast / rangedSlow: preferred speed limits (>= slow, <= fast).
--   types: allowed weapon subclasses for both hands (15 = dagger); nil = any learned type.
guide.OFFHAND = 0.5
guide.bySpec = {
    [71] = { melee = 6.3, setups = { twohand = true }, mainSlow = 3.3 },                       -- Arms
    [72] = { melee = 6.3, setups = { twohand = true, dual = true }, mainSlow = 2.6 },          -- Fury
    [73] = { melee = 2.0, setups = { shield = true }, mainFast = 2.0 },                        -- Prot Warrior
    [65] = {},                                                                                 -- Holy Paladin
    [66] = { melee = 2.0, setups = { shield = true }, mainFast = 2.0 },                        -- Prot Paladin
    [70] = { melee = 5.7, setups = { twohand = true }, mainSlow = 3.0 },                       -- Retribution
    [253] = { ranged = 4.1, rangedSlow = 2.8 },                                                -- Beast Mastery
    [254] = { ranged = 4.2, rangedSlow = 2.8 },                                                -- Marksmanship
    [255] = { melee = 2.8, setups = { twohand = true, dual = true }, mainSlow = 2.6 },         -- Survival (melee)
    [259] = { melee = 14, setups = { dual = true }, types = { [15] = true } },                 -- Assassination
    [260] = { melee = 14, setups = { dual = true }, mainSlow = 2.6, offFast = 1.6 },           -- Combat
    [261] = { melee = 14, setups = { dual = true } },                                          -- Subtlety
    [262] = {}, [264] = {},                                                                    -- Elemental, Resto Shaman
    [263] = { melee = 14, setups = { twohand = true }, mainSlow = 3.3 },                       -- Enhancement
    [256] = {}, [257] = {}, [258] = {},                                                        -- Priest
    [62] = {}, [63] = {}, [64] = {},                                                           -- Mage
    [265] = {}, [266] = {}, [267] = {},                                                        -- Warlock
    [102] = {}, [105] = {},                                                                    -- Balance, Resto Druid
    [103] = { melee = 5.0 },                                                                   -- Feral Cat
    [104] = { melee = 2.0 },                                                                   -- Feral Bear
}
guide.setupNames = { twohand = "two-hander", dual = "dual wield", shield = "one-hand + shield" }

function guide:Get(specID)
    return self.bySpec[specID] or {}
end
