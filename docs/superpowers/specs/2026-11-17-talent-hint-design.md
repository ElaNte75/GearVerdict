# Talent hint on level-up — design (approved 2026-11-17)

## Intent
On every level-up, tell the player which talent point to spend next, following the
Icy Veins leveling order for the spec chosen in GearVerdict, so they never need to open
the site. Nothing else: no talent list/tree page anywhere in the UI.

## User decisions
- Lives INSIDE GearVerdict, switched on/off by one option on an existing settings page.
- Shows only the next suggestion at level-up (+ a test/preview).
- Must look at the talents the player ALREADY has and steer them gradually back onto the
  guide's path when they deviated (user requirement, added at approval).

## Agent calls (user may correct)
- Option on the **Options** page: "Suggest next talent on level-up", default **off**.
- Display: center-screen banner for ~8 s (own small frame, theme-neutral) + the same line in chat.
  Text: `GearVerdict — Level 28: next talent -> Fury: Dual Wield Specialization (4/5)`.
- Preview: button next to the option + `/gv talent [level]` (no level = current level).
- Data: one data-only file with all 27 specs (from C:/Users/ElaNte/Desktop/Projects/Talent Priorities/icy-veins/).
  Spec IDs as in Data/SpecDetection.lua; Feral Cat (103) and Bear (104) share the Feral order.
- Range: levels 10-60 (guides end at 60). Above 60 / no spec chosen / unsupported -> nothing.

## Steering logic ("back on the right path")
1. Expand the guide into steps: step N = (level, talent name, target rank).
2. Read the player's current ranks per talent by NAME (GetNumTalentTabs/GetNumTalents/GetTalentInfo).
3. Next suggestion = the earliest guide step (from level 10 upward, up to the current level)
   whose target rank the player has not reached. That naturally fills missed guide points first.
4. If the player has no unspent points (UnitCharacterPoints / equivalent), say nothing at level-up
   (preview still works and says so).
5. Points the player put into talents outside the guide cannot be undone (no respec); the hint
   just keeps following the guide with the remaining points. Optional line when deviation found:
   "You are off the guide path; following it from here."
6. FALLBACK when the talent APIs are missing or return nothing usable (earlier Forever tests of
   talent detection were unreliable): suggest purely by level (step for that level). The preview
   output must show which mode was used, so the first live test tells us whether reading works.

## Verify live (Forever client 1.60.1)
- GetTalentInfo returns names/ranks matching Icy Veins names; unspent-points function exists;
  PLAYER_LEVEL_UP fires (and talent point is available at that moment; else listen to
  CHARACTER_POINTS_CHANGED briefly after).

## Build notes
- New modules (own files): Data/TalentOrders.lua (data only), Engine/TalentAdvisor.lua (steering logic),
  Display/TalentHint.lua (banner + chat + preview). Option + button on UI/PanelOptionsPage.lua,
  `talent` branch in Core/Core.lua slash handler. TOC update => FULL game restart.
- Tests in Tests/Tests.lua: data integrity (51 points per spec, ranks never exceed max, continuous),
  steering (on path, missed points, off-path points, no APIs -> level fallback, >60, no spec, option off).
- Update Facts page entry as "not verified yet" until seen live.
