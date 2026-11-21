# Weapon support — design (2026-11-20)

## Intent
When a weapon, shield, off-hand item or ranged weapon drops, GearVerdict checks the player can use it and
says whether it improves the chosen spec, following a small embedded per-spec "weapon guide".
Internal rules only (user's choice): no new Control Panel page; tooltip lines explain decisions.

## Approaches (user picked C = A + bag partner search)
- A. Per-spec guide (weapon DPS weight + allowed setups + speed preference), judged like ArmorPreference.
- B. Weapon DPS as a plain weight only: fast but wrong (sword for Assassination, 1H for Enhancement).
- C. **Chosen**: A, plus when a one-hand/off-hand item would replace a two-hander, look in the bags for
  the best partner for the other hand and compare the pair with the two-hander.

## Goals / non-goals
- Goals: correct arrow + tooltip for 2H, 1H, main-hand-only, off-hand weapons, shields, held-in-off-hand,
  ranged (bow/gun/crossbow/thrown/wand). Setups: two-hander; one-hand + shield/off-hand item; dual wield.
- Non-goals: two two-handers (Titan's Grip does not exist in Forever); relics; trinket effects; weapon
  enchants/procs; user-editable weapon guide; Control Panel page.
- Anti-goals: arrows that push a spec into a setup its guide rejects; heavy bag scans on every mouse move.

## Research (beta-era Forever guides; provisional like the other weights)
Findings: `side-session-notes/.../weapon-research.md` (copied summary in NOTES.md).
- 1 weapon DPS = 14 attack power (wowsims Forever / Classic rule). Main-hand and ranged DPS weight =
  14 x the preset's Attack Power weight; off-hand DPS counts half. Tanks (no AP weight): 2.0 (my call).
- Casters/healers: weapon judged by stats only (DPS weight 0); every setup allowed.

## Per-spec guide (Data/WeaponGuide.lua, data only)
| Spec | Melee DPS w. | Ranged DPS w. | Setups | Speed preference | Types |
|---|---|---|---|---|---|
| Arms | 6.3 | – | two-hand | main slow >= 3.3 | – |
| Fury | 6.3 | – | two-hand, dual | main slow >= 2.6 | – |
| Prot Warrior | 2.0 | – | shield | main fast <= 2.0 | – |
| Holy Paladin | – | – | any | – | – |
| Prot Paladin | 2.0 | – | shield | main fast <= 2.0 | – |
| Retribution | 5.7 | – | two-hand | main slow >= 3.0 | – |
| BM / MM Hunter | – | 4.1 / 4.2 | any (melee = stat stick) | ranged slow >= 2.8 | – |
| Survival Hunter | 2.8 | – | two-hand, dual | main slow >= 2.6 | – |
| Assassination | 14 | – | dual | – | daggers (both hands) |
| Combat | 14 | – | dual | main slow >= 2.6, off fast <= 1.6 | – |
| Subtlety | 14 | – | dual | – | – |
| Enhancement | 14 | – | two-hand (no dual wield in Forever) | main slow >= 3.3 | – |
| Feral Cat / Bear | 5.0 / 2.0 | – | any | none (forms use fixed speed) | – |
| All casters/healers | – | – | any | – | – |
"dual" also accepts a single one-hander with an empty off hand.

## Rules
1. Usability: Eligibility accepts weapons (classID 2), shields and held-in-off-hand items. Unlearned
   weapon skill = red tooltip line -> rejected (existing check, needs live check). Dual wield into the
   off hand only when the game says the player can dual wield (CanDualWield).
2. Value of a setup = stat score (existing Scoring, caps included) + DPS weight x weapon DPS
   (main hand full, off hand half, ranged with ranged weight).
3. Fits the guide = setup allowed for the spec and weapon types allowed. Moving from a fitting setup to a
   non-fitting one needs > 10% more value; moving from non-fitting to fitting wins when at most 10% lower
   (same 10% the user chose for armor). Both fitting or both not: plain value comparison, then speed.
4. Speed: when values are within 5% (my call), the weapon in the preferred speed range wins; one outside
   it needs > 5% more. Speed read from the item tooltip ("Speed 3.60"); unreadable = rule skipped.
   Added 2026-11-21 (user): speed is also in the points: a weapon off the preferred speed keeps 1% less of
   its DPS value per 0.1 s away (max 50%).
5. Cases: 2H drop -> compared with main + off hand together. 1H/off-hand drop while holding a 2H ->
   best partner from the bags for the other hand (or empty) compared with the 2H. 1H drop while holding
   a one-hander -> main hand slot, and off-hand slot when dual wield is possible. Ranged -> ranged slot.
6. Bag partner search runs only in case 5b; results cached until bags change.
7. Tooltip: existing "vs <item>" lines; extra short green lines: "With <partner> from bags",
   "Fits <spec>: two-hander" / "Preferred speed: 3.60". Arrows follow the same verdict.

## Modules
- Data/WeaponGuide.lua: the table above.
- Engine/WeaponData.lua: hand kind, speed reading, setup kind, value of a setup, fit + speed judging.
- Engine/WeaponComparison.lua: the cases, bag partner search + cache, result in the Comparison shape.
- Engine/Comparison.lua: routes weapon/shield/off-hand/ranged items to WeaponComparison; slot 18 added.
- Display/Tooltips.lua: reason lines.

## Left to the builder
Exact tooltip wording, cache invalidation event, test mocks.
