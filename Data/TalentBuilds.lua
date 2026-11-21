local _, addon = ...
-- Talent builds, shared tables. The builds themselves are in Data/TalentBuilds/<Class>Builds.lua, GENERATED from the
-- Wowhead WoW Forever talent-builds pages and the leveling guides (docs/REFRESHING-TALENT-BUILDS.md).
-- builds.talents[spellID] = { name, tree, max rank }
-- builds.byClass[CLASS] = list of builds: { id, name, classic?, spec?, gearSpec, trees = { a, b, c }, source?, weapons?,
--   key? (talents the guide names for the build), description?, order? (51 spell ids, one per level 10-60) }
local builds = { talents = {}, byClass = {}, treeNames = {} }
addon.TalentBuilds = builds
