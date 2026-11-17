# GearVerdict Control Panel — design (approved 2026-11-15)

## Intent
Replace the three separate windows (main, Options, Custom Weights) with ONE premium window in the
FarmWise Control Panel style, so settings are in one tidy, consistent place. Add per-spec weights and
Pawn-format weight string import/export.

## Goals
- One window: FarmWise look (dark brown panels, gold border, gold section titles with thin line,
  left menu, footer note + Close). Colors copied from FarmWise.
- Left menu, in order: Specialization, Options, Custom Weights.
- Specialization: character name (class color), level + class; spec checkboxes (one at a time,
  untick = none); unsupported specs gray with tooltip; status line; saved per character.
- Options: arrow position (top right / top left), arrow color (picker + Default) with live preview
  of the real arrow on an item icon, tooltip value (points / percent) with explanatory tooltips.
- Custom Weights: weights of the CURRENTLY CHOSEN spec; columns stat / default / yours / reset;
  changed values gold; save on Enter or leaving the box; Reset all with confirmation; permanent
  yellow warning (careful + retail sources may not fit Forever); Import and Export buttons.
- Weights per spec (old single set migrates to Enhancement 263).
- Import: paste a Pawn string `( Pawn: v1: "Name": Stat=Value, ... )`; preview of changes before
  Apply; unused stats listed as ignored; stats missing from the string become 0 (Pawn meaning),
  listed in the preview; class mismatch warning.
- Export: the effective weights of the chosen spec as a Pawn string, selected for Ctrl+C.

## Non-goals
No weight value changes, no new specs/presets, no scoring changes, no minimap icon.

## Approaches
- Chosen: one window with sidebar pages, each page its own module, shared look helpers module.
- Rejected: restyling the three existing windows separately (keeps scattered settings).
- Import format: Pawn string only (de facto standard exported by Raidbots, Wowhead, sims).

## Agent calls (not user decisions)
- Missing stats in an imported string become 0; values allowed 0–1000, rounded to 3 decimals.
- SpellPower preferred over SpellDamage when a string has both.
- Old MainWindow/OptionsWindow/Settings files are retired (backup kept outside the addon).
