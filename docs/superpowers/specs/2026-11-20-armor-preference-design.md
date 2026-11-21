# Heavier armor preference — short design (agreed 2026-11-20)

## Why
While leveling a Warrior, a Rugged Mail Vest (67 armor, no stats) got no arrow against a Scavenger Tunic
(leather, 33 armor, no stats): GearVerdict weighs only stats like Strength/Hit, never Armor, so both
scored 0. The user wants the heaviest armor type the character can wear preferred (armor proficiency:
Warrior/Paladin mail -> plate at 40, Shaman/Hunter leather -> mail at 40), even when it is slightly weaker.

## Agreed rules
- Same slot, both pieces are cloth/leather/mail/plate: the HEAVIER type is an upgrade when its stat score is
  at most 10% lower than the equipped piece (score 0 vs 0 = tie = heavier wins).
- A LIGHTER piece is an upgrade only when it is more than 10% better.
- Same type and a tie in stats: the piece with more Armor wins.
- Cloaks, rings, necks, trinkets: unchanged (no armor type that matters).
- Tooltip adds a short reason line under the "vs" row: "Heavier armor: Mail" or "More armor: +34".
- Only wearable pieces are judged (existing eligibility, incl. the level-40 switch).

## Approaches considered
- A: armor only breaks ties — fixes the reported case but ignores armor type.
- B: give Armor a small weight everywhere — can make a heavy piece with poor stats look better.
- C: count Armor only while leveling — larger work.
- Chosen by the user: armor-type preference with a 10% margin, plus A for same-type ties.

## Builder's calls
- New module Engine/ArmorPreference.lua (Judge), called from Comparison:Evaluate per slot.
- Margin is measured against the equipped piece's own stat score; when that is 0 the margin is 0.
- When the heavier piece is already better by stats, no reason line is added (it is a normal upgrade).
