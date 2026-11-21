# Dual Spec + virtual loadout — DRAFT plan (parked)

Status: PARKED by the user on 2026-11-18 until their character reaches level 40 (currently 28).
NOT approved, NOT built. Resume with brainstorming: confirm the open questions below first.

## What the user wants
- On Forever, Dual Spec is trained at level 40+ and costs gold (Classic-like), so many players lack it.
  GearVerdict must detect: level 40+ AND Dual Spec actually learned.
- If yes: the Specialization page (UI/PanelSpecPage.lua, today one spec only) allows choosing a SECOND spec,
  and upgrade arrows appear for that spec too.
- Tooltips (Display/Tooltips.lua) say which spec(s) an item is good for.
- Comparison basis = "virtual loadout" (like the user's retail addon StatVerdict): per spec, remember the gear
  worn while that spec is active, refreshed on every equipment change. Example: playing Enhancement but
  collecting for Restoration -> a Resto item is compared against the gear saved from the last Resto session,
  not against what is worn now.

## Findings so far (2026-11-18)
- Forever has no real specializations: GearVerdict's spec is a manual choice per character
  (GearVerdictDB.specChoices, Data/Presets.lua). So "which spec is active right now" is unknown today,
  yet the virtual loadout needs it to know where to save the worn gear.
- A HeadsUpAuras probe showed C_SpecializationInfo on Forever has GetActiveSpecGroup, SetActiveSpecGroup and
  GetCombatConfigIDForSpecGroup; global GetActiveTalentGroup is MISSING. Not yet checked: GetNumSpecGroups /
  GetNumTalentGroups (learned-or-not), what GetActiveSpecGroup returns, which event fires on a switch,
  the Dual Spec spell ID. A ready probe was written once (GearVerdict_Debug/DualSpecProbe.lua: function
  answers at login + on talent events, spellbook scan for "spec" spells) and removed unused; rebuild it at 40.

## Proposed direction (agent's proposal, not agreed)
- Map talent set 1 -> spec A and talent set 2 -> spec B (user sets it once). Then the active spec follows the
  game's active talent set automatically, and the worn gear is saved under that spec.
- Without Dual Spec learned: behave exactly as today (one manual spec, compare with worn gear).
- New code in its own module(s) (e.g. Engine/DualSpec.lua, Engine/Loadouts.lua); Comparison:Evaluate takes the
  spec + the saved loadout instead of reading GetInventoryItemLink directly.

## Open questions for the user (ask at 40)
1. No saved loadout yet for the second spec: compare with what is worn now (agent's pick) or show nothing
   until that spec has been played once?
2. How arrows look when an item is good for spec A only / spec B only / both (e.g. colors per spec).
3. Tooltip layout: one line per spec with spec name in class color (earlier user note in NOTES "LATER").
4. Detection method: confirm with the probe in game (never ask the user to type /run).
