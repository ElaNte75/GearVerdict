local _, addon = ...
-- Warrior talent builds (data only). The first three are the classic specializations and follow the leveling guide
-- chosen on the Leveling page. The others are hybrid builds from Wowhead's Protection Warrior talent page
-- (https://www.wowhead.com/forever/guide/classes/warrior/protection/talent-builds-pve-tank, updated 2026/11/04,
-- collected 2026-11-21). order = spell ids, ONE PER LEVEL from level 10 to 60 (51 points). trees = points in
-- Arms/Fury/Protection at level 60. offense = hand-set 0 (full defense) to 100 (full offense) for the meter.
-- key = spell ids of the build's key talents (named in the guide); the picker shows which ones you already have.
-- source = where a hybrid build comes from (shown on the Specialization page).
-- weapons = the weapon setup the build wants (shown on the Specialization page).
-- gearSpec = which specialization's stat weights and weapon rules the build uses. Descriptions are our own.
local builds = { talents = {}, byClass = {} }
addon.TalentBuilds = builds

-- talents[spellID] = { name, tree, max rank }
builds.talents = {
    [12282] = { "Improved Heroic Strike", "arms", 3 },
    [12286] = { "Improved Rend", "arms", 3 },
    [12287] = { "Improved Thunder Clap", "protection", 3 },
    [12292] = { "Sweeping Strikes", "arms", 1 },
    [12294] = { "Mortal Strike", "arms", 1 },
    [12295] = { "Improved Tactical Mastery", "arms", 3 },
    [12296] = { "Anger Management", "arms", 1 },
    [12297] = { "Anticipation", "protection", 5 },
    [12298] = { "Shield Specialization", "protection", 5 },
    [12311] = { "Improved Shield Bash", "protection", 2 },
    [12312] = { "Improved Shield Wall", "protection", 2 },
    [12313] = { "Improved Disarm", "protection", 3 },
    [12317] = { "Enrage", "fury", 5 },
    [12319] = { "Flurry", "fury", 3 },
    [12320] = { "Cruelty", "fury", 5 },
    [12322] = { "Unbridled Wrath", "fury", 5 },
    [12323] = { "Piercing Howl", "fury", 1 },
    [12328] = { "Death Wish", "fury", 1 },
    [12792] = { "Defiance", "protection", 3 },
    [12797] = { "Improved Revenge", "protection", 3 },
    [12809] = { "Concussion Blow", "protection", 1 },
    [12834] = { "Deep Wounds", "arms", 3 },
    [12862] = { "Improved Slam", "arms", 2 },
    [12962] = { "Iron Will", "protection", 5 },
    [12975] = { "Last Stand", "protection", 1 },
    [16462] = { "Deflection", "arms", 5 },
    [16487] = { "Blood Craze", "fury", 3 },
    [16493] = { "Impale", "arms", 2 },
    [16538] = { "Bastion", "protection", 5 },
    [20500] = { "Improved Berserker Rage", "fury", 2 },
    [20502] = { "Improved Execute", "fury", 2 },
    [23584] = { "Dual Wield Specialization", "fury", 5 },
    [23881] = { "Bloodthirst", "fury", 1 },
    [23922] = { "Shield Slam", "protection", 1 },
    [29787] = { "Focused Rage", "protection", 3 },
    [1290261] = { "Weaponmaster", "arms", 5 },
    [1310316] = { "Master of Defense", "protection", 2 },
    [1310317] = { "Vanguard", "protection", 1 },
    [1323963] = { "Furious Precision", "fury", 3 },
    [1323967] = { "Gore Drinker", "fury", 2 },
    [1329555] = { "Reckless Swings", "fury", 1 },
}

builds.byClass.WARRIOR = {
    { id = "classic-71", name = "Arms", weapons = "Two-handed weapon (slow)", key = { 12294, 12292, 12834, 16493, 1290261 }, classic = true, spec = 71, gearSpec = 71, offense = 100, trees = { 33, 16, 2 },
      description = "Two-handed damage: Mortal Strike, Deep Wounds and Sweeping Strikes." },
    { id = "classic-72", name = "Fury", weapons = "Two one-hand weapons, or one two-hander", key = { 23881, 12328, 12319, 23584, 12320 }, classic = true, spec = 72, gearSpec = 72, offense = 100, trees = { 16, 33, 2 },
      description = "Dual-wield damage: Bloodthirst, Death Wish and Flurry." },
    { id = "classic-73", name = "Protection", weapons = "Shield + one-hand weapon", key = { 23922, 12975, 12792, 12298, 12809 }, classic = true, spec = 73, gearSpec = 73, offense = 20, trees = { 4, 16, 31 },
      description = "Classic tank: shield, Shield Slam and the defensive talents." },
    { id = "standard", name = "Standard Protection", source = "Wowhead, Protection Warrior talent builds (updated 2026/11/04)", weapons = "Shield + one-hand weapon", key = { 23922, 12317, 16462, 12297, 29787 }, gearSpec = 73, offense = 35, trees = { 4, 15, 32 },
      description = "All-round tank build. Good survivability with solid threat. Takes Enrage, Deflection and Anticipation and skips most rage-cost talents.",
      order = { 12298, 12298, 12298, 12298, 12298, 12797, 12797, 12797, 12297, 12297, 1310316, 1310316, 12975, 12792, 12792, 12792, 1310317, 12297, 12297, 12297, 12312, 12312, 12809, 29787, 29787, 16538, 16538, 16538, 16538, 16538, 23922, 12320, 12320, 12320, 12320, 12320, 12322, 12322, 12322, 12322, 12322, 12317, 12317, 12317, 12317, 12317, 16462, 16462, 16462, 16462, 29787 } },
    { id = "impale", name = "Impale Protection", source = "Wowhead, Protection Warrior talent builds (updated 2026/11/04)", weapons = "Shield + one-hand weapon", key = { 16493, 12834, 12286, 1310317, 23922 }, gearSpec = 73, offense = 42, trees = { 17, 2, 32 },
      description = "Tank build with a little more damage. Impale and Deep Wounds scale well, and Rend becomes part of your rotation.",
      order = { 12298, 12298, 12298, 12298, 12298, 12797, 12797, 12797, 12297, 12297, 1310316, 1310316, 12975, 12792, 12792, 12792, 1310317, 12297, 12297, 12297, 12312, 12312, 12809, 29787, 29787, 16538, 16538, 16538, 16538, 16538, 23922, 16462, 16462, 16462, 16462, 16462, 12286, 12286, 12286, 12295, 12282, 12834, 12834, 12834, 12320, 12320, 12282, 12282, 16493, 16493, 29787 } },
    { id = "fury-prot", name = "Fury-Prot", source = "Wowhead, Protection Warrior talent builds (updated 2026/11/04)", weapons = "Shield + one-hand weapon", key = { 23881, 12328, 12319, 16487, 1323967 }, gearSpec = 73, offense = 70, trees = { 3, 31, 17 },
      description = "Shield plus Fury talents: much more damage for a little less survivability. Best when you are slightly over-geared. Uses Bloodthirst, Death Wish and Flurry.",
      order = { 12282, 12282, 12282, 12320, 12320, 12320, 12320, 12320, 12322, 12322, 12322, 12322, 12322, 16487, 16487, 16487, 12317, 12317, 12317, 12317, 12317, 1329555, 20502, 20502, 12328, 1323967, 1323967, 12323, 12319, 12319, 12319, 20500, 20500, 23881, 12298, 12298, 12298, 12298, 12298, 12797, 12797, 12797, 12297, 12297, 12975, 1310316, 1310316, 12792, 12792, 12792, 1310317 } },
    { id = "dual-wield", name = "Dual Wield", source = "Wowhead, Protection Warrior talent builds (updated 2026/11/04)", weapons = "Two one-hand weapons", key = { 23881, 12328, 12319, 23584, 16493 }, gearSpec = 72, offense = 95, trees = { 20, 31, 0 },
      description = "No Protection talents at all: pure damage. Only for special fights, for example enemies whose hits cannot be blocked. You take far more damage.",
      order = { 12282, 12282, 12282, 12320, 12320, 12320, 12320, 12320, 12322, 12322, 12322, 12322, 12322, 12317, 12317, 12317, 12317, 12317, 1329555, 20502, 20502, 1323963, 1323963, 12328, 1323963, 23584, 23584, 23584, 12319, 12319, 12319, 23584, 23584, 23881, 16462, 16462, 16462, 16462, 16462, 12286, 12286, 12286, 12295, 12295, 12295, 12296, 12834, 12834, 12834, 16493, 16493 } },
    { id = "dungeon-deep", name = "Dungeon: Deep Protection", source = "Wowhead, Protection Warrior talent builds (updated 2026/11/04)", weapons = "Shield + one-hand weapon", key = { 23922, 12317, 16462, 12297, 12809 }, gearSpec = 73, offense = 30, trees = { 4, 15, 32 },
      description = "Relaxed dungeon tank. Stay in Defensive Stance with high Enrage uptime when fighting several enemies.",
      order = { 12298, 12298, 12298, 12298, 12298, 12797, 12797, 12797, 12287, 12287, 1310316, 1310316, 12287, 12792, 12792, 1310317, 12792, 12975, 12297, 12297, 12809, 29787, 29787, 29787, 12312, 16538, 16538, 16538, 16538, 16538, 23922, 12312, 12320, 12320, 12320, 12320, 12320, 12322, 12322, 12322, 12322, 12322, 12317, 12317, 12317, 12317, 12317, 16462, 16462, 16462, 16462 } },
    { id = "dungeon-cleave", name = "Dungeon: Cleave", source = "Wowhead, Protection Warrior talent builds (updated 2026/11/04)", weapons = "Shield + slow one-hand weapon", key = { 12292, 1290261, 16493, 12834, 12286 }, gearSpec = 73, offense = 62, trees = { 28, 5, 18 },
      description = "The highest-damage tank build for dungeons: Sweeping Strikes with Cleave and Revenge. Needs stance dancing and a slow weapon.",
      order = { 16462, 16462, 16462, 16462, 12298, 12298, 12298, 12298, 12298, 12797, 12797, 12797, 12287, 12287, 1310316, 1310316, 12792, 12792, 12792, 1310317, 12975, 12287, 16462, 12286, 12286, 12286, 12282, 12282, 12282, 12834, 12834, 12834, 12295, 12295, 12295, 12296, 16493, 16493, 12292, 1290261, 1290261, 1290261, 1290261, 1290261, 12320, 12320, 12320, 12320, 12320, 12862, 12862 } },
    { id = "pvp", name = "PvP Protection", source = "Wowhead, Protection Warrior talent builds (updated 2026/11/04)", weapons = "Shield + one-hand weapon", key = { 12809, 12311, 12313, 23922, 16487 }, gearSpec = 73, offense = 45, trees = { 0, 19, 32 },
      description = "Tanky PvP build with strong control: Concussion Blow, Improved Shield Bash and Disarm.",
      order = { 12320, 12320, 12320, 12320, 12320, 12298, 12298, 12298, 12298, 12298, 12962, 12962, 12962, 12962, 12962, 12797, 12797, 12797, 12975, 1310316, 1310316, 12313, 12313, 12313, 1310317, 12311, 12311, 29787, 29787, 29787, 12809, 16538, 16538, 16538, 16538, 16538, 23922, 12322, 12322, 12322, 12322, 12322, 16487, 16487, 16487, 12317, 12317, 12317, 12317, 12317, 12323 } },
}
