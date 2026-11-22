# Έλεγχος builds με το Wowhead — 2026-11-21

## Σύνοψη (απλά λόγια)

- **Οι σειρές ταλέντων είναι σωστές.** Και για τα 74 builds που έχουν σειρά ταλέντων, η σειρά και οι πόντοι
  ανά δέντρο είναι **ακριβώς ίδια** με τις σελίδες του Wowhead σήμερα. Κανένα build δεν άλλαξε στο Wowhead από τότε
  που τα περάσαμε, και το κείμενο των οδηγών είναι επίσης ίδιο λέξη προς λέξη.
- **Τίποτα περιττό:** δεν έχουμε κανένα build που να μην υπάρχει στο Wowhead.
- **Λείπουν builds που το Wowhead δείχνει μόνο με πόντους, χωρίς σειρά ταλέντων:**
  - Rogue (και τα 3 specs, 10 builds), Warlock (και τα 3 specs, 19 builds), Restoration Druid (5 builds).
  - **Νέο εύρημα:** Holy Priest «PvE Raid» (18/32/0) — υπάρχει στη σελίδα, δεν το έχουμε (δεν έχει σειρά).
  - Αυτό είναι **απόφαση για εσένα**: για τα Balance Druid και Discipline PvP κρατήσαμε builds *χωρίς σειρά*
    (μόνο πόντους + περιγραφή). Για Rogue/Warlock/Resto Druid/Holy Raid δεν το κάναμε. Ή τα προσθέτουμε όλα
    με τον ίδιο τρόπο, ή τα αφήνουμε όλα έξω — τώρα είναι ασυνεπές.
- **Discipline Priest PvP:** η σειρά του στο Wowhead έχει 50 βήματα, όχι 51 — αλλά το ίδιο το build έχει μόνο
  50 πόντους (29/16/5). Άρα η σειρά είναι **πλήρης** και μπορούμε να τη βάλουμε (με το τελευταίο επίπεδο ελεύθερο).
- **Balance Druid:** οι σειρές είναι ακόμα μισές στο Wowhead (3 και 10 βήματα). Μένουν χωρίς σειρά.
- **Λάθη στα ονόματα/περιγραφές (μικρά, αλλά φαίνονται):**
  1. Arcane Mage: οι περιγραφές του 2ου και 3ου build είναι **μπερδεμένες**. Το «χωρίς Arcane Power, για μεγάλες
     μάχες» είναι στην πραγματικότητα το **3ο** build (29/19/3), όχι το 2ο (35/13/3). Το όνομα «(long fights)»
     πρέπει να πάει στο 3ο.
  2. Feral Druid Tank: το «Dungeon & Raid (second)» είναι κατά τον οδηγό το **«pure bear»** build (έναν πόντο
     ακόμα σε Rend and Tear + Blood Frenzy). Του λείπει η περιγραφή και το όνομα «second» δεν είναι λέξη του οδηγού.
  3. Protection Paladin: το όνομα «Offensive Off» είναι κομμένο — ο οδηγός λέει **«Offensive Off-Tank»**.
  4. Retribution: το τελευταίο build λέγεται σκέτο «Shockadin», αλλά στον οδηγό είναι στην ενότητα **PvP**
     (κινδυνεύει να μπερδευτεί με το «Shockadin PvE Raid»).
  5. Arcane «(third)»: δεν είναι λέξη του οδηγού (διορθώνεται μαζί με το 1).
- **Όπλα / βασικά ταλέντα:** όλα τα «βασικά ταλέντα» που δείχνουμε αναφέρονται πράγματι στο κείμενο του οδηγού.
  Τα όπλα που γράφουμε είναι σωστά. Ένα πιθανό κενό: ο οδηγός του **Offensive Off-Tank** (Paladin) λέει ότι
  μπορείς να παίξεις με μονόχειρο+ασπίδα **ή** δίχειρο — δεν το γράφουμε.
- **Θέση στα specs:** σωστή παντού. Μόνο δύο builds μετακινούνται (όπως είχαμε συμφωνήσει): Warrior «Dual Wield»
  → Fury, Paladin «Offensive Off-Tank» → Retribution. Μερικά builds έχουν περισσότερους πόντους σε άλλο δέντρο
  (π.χ. Fury-Prot, Retprot, Holy Priest PvP), αλλά μένουν σωστά στη σελίδα τους.
- **Σελίδες στατιστικών (stat priority):** το Wowhead έχει σελίδα για **κάθε** spec (25 σελίδες). Οι σειρές είναι
  παρακάτω, έτοιμες για την επόμενη δουλειά. Τρεις έχουν παραλλαγές: Protection Warrior και Protection Paladin
  (Defensive / Balanced / Offensive) και Feral Tank (Defensive / Offensive).

**Τι χρειάζεται διόρθωση (όλα στα δεδομένα που φτιάχνει το εργαλείο, όχι στον κώδικα του addon):**
1. Arcane: διόρθωση ονομάτων/περιγραφών 2ου και 3ου build.
2. Feral Tank: όνομα + περιγραφή του 4ου build («pure bear»).
3. Prot Paladin: «Offensive Off-Tank».
4. Retribution: «PvP (Shockadin)» αντί για «Shockadin».
5. Discipline PvP: προσθήκη της σειράς 50 βημάτων.
6. Απόφαση: builds χωρίς σειρά (Rogue, Warlock, Resto Druid, Holy Priest Raid) — μέσα ή έξω;
7. (Προαιρετικό) Όπλα για Offensive Off-Tank.

---

## How the check was done

- Live pages read on 2026-11-21 in the built-in browser with the extractor of `docs/REFRESHING-TALENT-BUILDS.md`
  (`.ctc-main-order-list`, `.ctc-tree-slider`). Per build: heading, tree points, number of steps, a hash
  (djb2 of the comma-joined spell ids). The same hash was computed from `Data/TalentBuilds/*Builds.lua`.
- Guide text: all 28 talent-build pages downloaded again as HTML and run through `docs/tools/guide_text.py`
  into a scratch folder; the resulting `sections.json` was compared with
  `docs/tools/wowhead-snapshot/wowhead/sections.json`: **74 sections, 0 differences** (text, intro and named talents).
- Keys: every `key` spell id of every build is among the talents its guide section names (0 exceptions).
- Weapons: every guide section was searched for weapon words and compared with `weapons`.
- Nothing in the addon was changed.

Status legend: **OK** = name, tree points and 51-step order identical to the live page; **DIFFERENT** = something
differs (said what); **MISSING** = on the page, not in our data; **EXTRA** = in our data, not on the page.
Classic builds (one per spec, from the leveling guides) are not on these pages and were not part of this check.

## Warrior (template — all OK)

Pages: arms 2026/11/04, fury 2026/11/04, protection 2026/11/04 (unchanged).

| Spec | Build | Points | Status | Notes |
|---|---|---|---|---|
| Arms | PvE | 32/17/2 | OK | |
| Arms | PvP | 35/16/0 | OK | |
| Arms | Leveling | 35/16/0 | OK | |
| Fury | PvE Raid | 17/34/0 | OK | |
| Fury | PvE Dungeon | 17/34/0 | OK | |
| Fury | PvP | 17/34/0 | OK | |
| Protection | Standard | 4/15/32 | OK | |
| Protection | Impale | 17/2/32 | OK | |
| Protection | Fury-Prot | 3/31/17 | OK | Text mentions the old Fury-Prot "2x one-handers" playstyle as history; no weapons set (left as reviewed). |
| Protection | Dual Wield | 20/31/0 | OK | 0 Protection points → shown under Fury (SpecOf). Weapons OK. |
| Protection | PvE Dungeon (Deep Protection) | 4/15/32 | OK | |
| Protection | PvE Dungeon (Cleave) | 28/5/18 | OK | Weapons OK (slow weapon, Thrash Blade). |
| Protection | PvP | 0/19/32 | OK | |

## Paladin

Pages: holy 2026/11/04, protection 2026/11/04, retribution 2026/11/13 (unchanged).

| Spec | Build | Points | Status | Notes |
|---|---|---|---|---|
| Holy | PvE Raid | 31/7/13 | OK | |
| Holy | PvE Dungeon | 34/5/12 | OK | |
| Holy | PvP | 32/7/12 | OK | |
| Protection | Standard | 0/35/16 | OK | |
| Protection | Shockprot | 23/28/0 | OK | |
| Protection | Retprot | 0/21/30 | OK | More points in Retribution, stays under Protection (rule). |
| Protection | Offensive Off | 23/0/28 | DIFFERENT | Name cut: page says "OFFENSIVE OFF-TANK BUILD" (the label rule strips the word "TANK"). 0 Protection points → shown under Retribution (SpecOf). Text: one-hander or two-hander both fine — no `weapons`. Order OK. |
| Protection | PvE Dungeon | 0/32/19 | OK | |
| Protection | PvP | 23/28/0 | OK | |
| Retribution | PvE Raid (Unsealed Wrath) | 12/8/31 | OK | Weapons OK (slow two-hander). |
| Retribution | Shockadin PvE Raid | 23/0/28 | OK | Weapons OK (fast two-hander). |
| Retribution | PvP | 12/8/31 | OK | |
| Retribution | Shockadin | 21/0/30 | DIFFERENT | Order OK. Sits in the guide's PvP section ("Holy 'Shockadin' Build" under "Best Retribution Paladin PvP Build"); name should say PvP. |
| Retribution | (PvE Dungeon) | — | OK | Heading exists, guide says use the raid build; no build of its own. |

## Hunter

Pages: beast-mastery 2026/11/16, marksmanship 2026/11/04, survival 2026/11/17 (unchanged).

| Spec | Build | Points | Status | Notes |
|---|---|---|---|---|
| Beast Mastery | PvE Dungeon & Raid | 31/20/0 | OK | |
| Beast Mastery | PvP | 31/16/4 | OK | |
| Marksmanship | PvE Dungeon & Raid | 5/41/5 | OK | |
| Marksmanship | PvP | 0/40/11 | OK | |
| Survival | Melee PvE Dungeon & Raid | 16/10/25 | OK | |
| Survival | Weaving PvE Dungeon & Raid | 0/20/31 | OK | Weapons OK (two-hander). |
| Survival | PvP | 22/0/29 | OK | |

## Rogue (no talent order on Wowhead)

Pages: assassination 2026/11/17, combat 2026/11/17, subtlety 2026/11/17. Builds shown only as tree points.

| Spec | Build (page heading) | Points | Status | Notes |
|---|---|---|---|---|
| Assassination | PvE Dungeon and Raid | 31/19/1 | MISSING | no order |
| Assassination | PvP (1) | 14/10/27 | MISSING | no order |
| Assassination | PvP (2) | 31/8/12 | MISSING | no order |
| Combat | PvE Dungeon and Raid (1) | 16/35/0 | MISSING | no order |
| Combat | PvE Dungeon and Raid (2) | 13/33/5 | MISSING | no order |
| Combat | PvE Dungeon and Raid (3) | 21/30/0 | MISSING | no order |
| Combat | PvP | 14/10/27 | MISSING | no order |
| Subtlety | PvE Dungeon and Raid (1) | 12/8/31 | MISSING | no order |
| Subtlety | PvE Dungeon and Raid (2) | 28/2/21 | MISSING | no order |
| Subtlety | PvP | 14/10/27 | MISSING | no order |

## Priest

Pages: discipline 2026/11/04, holy 2026/11/04, shadow 2026/11/04 (unchanged).

| Spec | Build | Points | Status | Notes |
|---|---|---|---|---|
| Discipline | PvE Raid | 31/20/0 | OK | |
| Discipline | PvE Dungeon | 33/18/0 | OK | |
| Discipline | PvP | 29/16/5 | DIFFERENT | We have no `order`. Page order has 50 steps = all 50 points of the build (it spends only 50), so it is complete. |
| Holy | PvE Raid | 18/32/0 | MISSING | On the page with text ("standard raid healing build"), tree points only, no order. |
| Holy | PvE Dungeon | 21/30/0 | OK | |
| Holy | PvP | 34/17/0 | OK | More points in Discipline, stays under Holy (rule). |
| Shadow | PvE Raid | 15/3/33 | OK | |
| Shadow | PvE Dungeon | 13/0/38 | OK | |
| Shadow | PvP | 16/3/32 | OK | |

## Shaman

Pages: elemental 2026/11/16, enhancement 2026/11/19, restoration 2026/11/19 (unchanged).

| Spec | Build | Points | Status | Notes |
|---|---|---|---|---|
| Elemental | PvE Raid (Restoration) | 31/4/16 | OK | |
| Elemental | PvE Raid (Enhancement) | 32/11/8 | OK | |
| Elemental | PvE Dungeon | 32/11/8 | OK | Same order as raid (Enhancement), as the page says. |
| Elemental | PvP (Elemental) | 33/17/1 | OK | |
| Elemental | PvP (Restoration) | 30/0/21 | OK | |
| Enhancement | PvE Raid | 17/34/0 | OK | |
| Enhancement | PvE Dungeon | 17/26/8 | OK | |
| Enhancement | PvP (Elemental) | 18/26/7 | OK | |
| Enhancement | PvP (Restoration) | 0/19/32 | OK | More points in Restoration, stays under Enhancement (rule). |
| Restoration | PvE Raid | 0/17/34 | OK | |
| Restoration | PvE Raid (deep Restoration) | 0/10/41 | OK | |
| Restoration | PvE Dungeon | 0/17/34 | OK | Same order as raid. |
| Restoration | PvP | 0/17/34 | OK | |

## Mage

Pages: arcane 2026/11/18, fire 2026/11/04, frost 2026/11/15 (unchanged).

| Spec | Build | Points | Status | Notes |
|---|---|---|---|---|
| Arcane | PvE Raid & Dungeon | 32/16/3 | OK | |
| Arcane | PvE Raid & Dungeon (long fights) | 35/13/3 | DIFFERENT | Order OK. Label + description belong to the NEXT build: the text ("more damage in longer fights… at the cost of Arcane Power") stands before the 3rd build on the page, and only the 3rd build lacks Arcane Power (this one takes it). This build has no text of its own. |
| Arcane | PvE Raid & Dungeon (third) | 29/19/3 | DIFFERENT | Order OK. This is the "long fights / no Arcane Power" build; "(third)" is not a guide word. |
| Arcane | PvP | 32/19/0 | OK | |
| Fire | PvE Raid & Dungeon | 16/32/3 | OK | |
| Fire | PvE Raid & Dungeon (Frost) | 0/29/22 | OK | |
| Fire | PvP | 21/28/2 | OK | |
| Frost | PvE Raid | 18/0/33 | OK | |
| Frost | PvE Dungeon | 18/0/33 | OK | Same order as raid. |
| Frost | PvP | 17/0/34 | OK | |

## Warlock (no talent order on Wowhead)

Pages: affliction 2026/11/11, demonology 2026/11/04, destruction 2026/11/04. Tree points only. The raid builds sit
under sub-headings "Which Build Should You Pick?" / "Fire or Shadow?" inside the raid section.

| Spec | Build (page section) | Points | Status | Notes |
|---|---|---|---|---|
| Affliction | PvE Raid (1) | 35/11/5 | MISSING | no order |
| Affliction | PvE Raid (2) | 30/0/21 | MISSING | no order |
| Affliction | PvE Dungeon | 30/0/21 | MISSING | no order |
| Affliction | PvP (1) | 30/21/0 | MISSING | no order |
| Affliction | PvP (2) | 29/0/22 | MISSING | no order |
| Affliction | PvP (3) | 31/7/13 | MISSING | no order |
| Demonology | PvE Raid (Fire) | 2/31/18 | MISSING | no order |
| Demonology | PvE Raid (Shadow) | 2/31/18 | MISSING | no order |
| Demonology | PvE Dungeon | 2/31/18 | MISSING | no order |
| Demonology | PvP (1) | 20/31/0 | MISSING | no order |
| Demonology | PvP (2) | 7/33/11 | MISSING | no order |
| Demonology | PvP (3) | 16/24/11 | MISSING | no order |
| Destruction | PvE Raid (1) | 14/4/33 | MISSING | no order |
| Destruction | PvE Raid (2) | 14/6/31 | MISSING | no order |
| Destruction | PvE Raid (3) | 7/11/33 | MISSING | no order |
| Destruction | PvE Dungeon | 14/4/33 | MISSING | no order |
| Destruction | PvP (1) | 0/21/30 | MISSING | no order |
| Destruction | PvP (2) | 0/16/35 | MISSING | no order |
| Destruction | PvP (3) | 18/0/33 | MISSING | no order |

## Druid

Pages: balance 2026/11/16, feral dps 2026/11/04, feral tank 2026/11/04, restoration 2026/11/04 (unchanged).

| Spec | Build | Points | Status | Notes |
|---|---|---|---|---|
| Balance | PvE Raid & Dungeon | 38/0/13 | OK (no order) | Page order still incomplete: 3 steps. |
| Balance | PvP | 38/0/13 | OK (no order) | Page order still incomplete: 10 steps. |
| Feral DPS | High Mana Regen / Open World | 9/33/9 | OK | |
| Feral DPS | PvE Dungeon / Raid | 9/32/10 | OK | |
| Feral DPS | Hybrid Tank PvE | 9/32/10 | OK | |
| Feral DPS | PvP | 0/35/16 | OK | |
| Feral Tank | Open World & Leveling (Restoration) | 0/34/17 | OK | |
| Feral Tank | Open World & Leveling (Balance) | 8/32/11 | OK | |
| Feral Tank | Dungeon & Raid | 9/32/10 | OK | The guide's "hybrid" build (same order as Feral DPS Hybrid Tank). Name could say "(hybrid)". |
| Feral Tank | Dungeon & Raid (second) | 9/32/10 | DIFFERENT | Order OK. Guide calls it the "pure bear spec" (one more point in Rend and Tear, plus Blood Frenzy — checked against the order: Rend and Tear 5 vs 4, Blood Frenzy 1 vs 0). Our description is empty ("Dungeon and raid build.") and "(second)" is not a guide word. |
| Restoration | PvE Raid (1) | 21/0/30 | MISSING | no order |
| Restoration | PvE Raid (2) | 18/0/33 | MISSING | no order |
| Restoration | PvE Dungeon (1) | 35/0/16 | MISSING | no order |
| Restoration | PvE Dungeon (2) | 0/32/19 | MISSING | no order |
| Restoration | PvP | 16/11/24 | MISSING | no order |

## Builds without a talent order

| Build | In our data? | Wowhead now |
|---|---|---|
| Balance: PvE Raid & Dungeon | yes, no `order` | still incomplete (3 steps) |
| Balance: PvP | yes, no `order` | still incomplete (10 steps) |
| Discipline: PvP | yes, no `order` | **complete: 50 steps for a 50-point build** → can get an order |
| Holy Priest: PvE Raid | no | no order (points only) |
| Rogue: all 10 builds | no | no order |
| Warlock: all 19 builds | no | no order |
| Restoration Druid: all 5 builds | no | no order |

## Spec placement

Every Wowhead build has `gearSpec` = the spec of its page. Builds with 0 points in their page's tree (moved by
`Builds:SpecOf`): Warrior Protection "Dual Wield" (20/31/0 → Fury) and Paladin Protection "Offensive Off-Tank"
(23/0/28 → Retribution). No other build has 0 points in its page's tree. Builds whose biggest tree is not their
page's tree but which stay (rule): Warrior Fury-Prot, Paladin Retprot, Priest Holy PvP, Shaman Enhancement PvP
(Restoration). Nothing else odd. If Rogue builds are added later: the Assassination and Combat pages both list the
same 14/10/27 PvP build as Subtlety (it would stay under each page, per the rule).

## Stat priority pages (Wowhead WoW: Forever)

Every spec has one. URL pattern `https://www.wowhead.com/forever/guide/classes/<class>/<spec>/stat-priority-pve-<dps|tank|healer>`.
Orders copied as listed on the page (top = most important).

| Spec | URL (updated) | Stat order |
|---|---|---|
| Arms Warrior | `.../warrior/arms/stat-priority-pve-dps` (2026/11/04) | Hit until 8% > Expertise until 6.5% > Crit > Strength > Agility > Haste > Hit after 8% (page: speculative; ~1.5 Agility = 1 Strength) |
| Fury Warrior | `.../warrior/fury/stat-priority-pve-dps` (2026/10/29) | Weapon Skill until 305 > Hit until 9% > Crit > Strength > Agility > Stamina |
| Protection Warrior — Defensive | `.../warrior/protection/stat-priority-pve-tank` (2026/11/03) | Stamina > Defense until 440 > Armor > Agility > Defense after 440 > Parry > Dodge > Expertise 6.5% (soft cap) > Block Chance > Attack Power/Strength > Hit 8% > Crit > Expertise 14% (hard cap) > Haste |
| Protection Warrior — Balanced | same page | Stamina > Expertise 6.5% > Hit 8% > Defense until 440 > Expertise 14% > Armor > Attack Power/Strength > Agility > Defense after 440 > Parry > Dodge > Crit > Block Chance > Haste |
| Protection Warrior — Offensive | same page | Expertise 6.5% > Hit 8% > Expertise 14% > Crit > Attack Power/Strength > Stamina > Haste > Agility > Defense before 440 > Armor > Defense after 440 > Parry > Dodge > Block Chance (page also: 1% Expertise before soft cap = 115 AP, 1% Hit = 60 AP, 1% Expertise after soft cap = 46 AP, 1% Crit = 34 AP, 1% Haste = 21 AP) |
| Holy Paladin | `.../paladin/holy/stat-priority-pve-healer` (2026/10/29) | Healing Power > Intellect > Crit > Spirit |
| Protection Paladin — Defensive | `.../paladin/protection/stat-priority-pve-tank` (2026/10/28) | Stamina > Defense until 440 > Armor > Agility > Block Chance > Defense after 440 > Spell Power > Parry > Dodge > Strength > Hit 8% > Expertise 6.5% > Crit > Hit 17% (spell cap) > Expertise 14% > Haste > Intellect |
| Protection Paladin — Balanced | same page | Stamina > Spell Power > Hit 8% > Defense until 440 > Armor > Expertise 6.5% > Agility > Block Chance > Defense after 440 > Parry > Dodge > Crit > Hit 17% > Expertise 14% > Haste > Strength > Intellect |
| Protection Paladin — Offensive | same page | Spell Power > Hit 8% > Expertise 6.5% > Crit > Stamina > Hit 17% > Expertise 14% > Haste > Strength > Agility > Defense before 440 > Armor > Block Chance > Defense after 440 > Parry > Dodge > Intellect (page also: 1% Hit before melee cap = 21 SP, 1% Expertise before soft cap = 15 SP, 1% Crit = 12 SP, 1% Hit after melee cap = 9 SP, 1% Expertise after soft cap = 7.5 SP, 1% Haste = 7 SP) |
| Retribution Paladin | `.../paladin/retribution/stat-priority-pve-dps` (2026/10/31) | Weapon Skill > Weapon DPS & Speed > Hit 9% > Expertise 6.5% > Spell Damage > Intellect > Strength & Attack Power > Agility & Crit > Stamina |
| Beast Mastery Hunter | `.../hunter/beast-mastery/stat-priority-pve-dps` (2026/11/20) | % Hit until 8% > % Crit > % Haste > Agility > Intellect > (Ranged) Attack Power > Spirit > Stamina (ranked per 1% or per point) |
| Marksmanship Hunter | `.../hunter/marksmanship/stat-priority-pve-dps` (2026/11/20) | same as Beast Mastery |
| Survival Hunter | `.../hunter/survival/stat-priority-pve-dps` (2026/11/20) | % Hit > % Crit > % Haste > Agility > Strength > Attack Power > Intellect > Spirit > Stamina (page's intro line wrongly says "Marksmanship") |
| Assassination Rogue | `.../rogue/assassination/stat-priority-pve-dps` (2026/11/09) | Hit until 8% > Expertise 6.5% > Weapon skill 308 > Hit to 17% (poison cap) > Agility > Crit > Haste > Strength > Attack Power > Stamina |
| Combat Rogue | `.../rogue/combat/stat-priority-pve-dps` (2026/10/30) | same as Assassination |
| Subtlety Rogue | `.../rogue/subtlety/stat-priority-pve-dps` (2026/10/30) | same as Assassination |
| Discipline Priest | `.../priest/discipline/stat-priority-pve-healer` (2026/10/30) | Healing Power > Intellect > Spirit > Crit > Spell Damage > Stamina |
| Holy Priest | `.../priest/holy/stat-priority-pve-healer` (2026/10/31) | Healing Power > Intellect > Mp5 > Spirit > Spell Crit > Stamina |
| Shadow Priest | `.../priest/shadow/stat-priority-pve-dps` (2026/10/30) | Hit until 17% > Spell Crit > Spell Damage (Shadow) > Intellect > Spirit > Stamina |
| Elemental Shaman | `.../shaman/elemental/stat-priority-pve-dps` (2026/11/04) | Spell Piercing > Haste/Cast Speed > Hit until 17% > Spell Damage > Crit > Nature Damage > Fire Damage > Intellect > Spirit > Strength (leveling only) > Stamina |
| Enhancement Shaman | `.../shaman/enhancement/stat-priority-pve-dps` (2026/11/16) | Hit min. 8% > Expertise 6.5% > Crit > Strength > Intellect > Spell Piercing > Haste > Agility > Spell Damage > Attack Power > Spirit > Stamina |
| Restoration Shaman | `.../shaman/restoration/stat-priority-pve-healer` (2026/11/01) | Spell Healing > Crit > Haste/Cast Speed > Intellect > Spirit > Mp5 > Spell Damage, Hit 17%, Spell Piercing, Strength (all leveling only) > Stamina |
| Arcane Mage | `.../mage/arcane/stat-priority-pve-dps` (2026/11/17) | Hit until 17% > Spell Damage > Crit > Spell Piercing > Haste > Intellect > Spirit > Stamina |
| Fire Mage | `.../mage/fire/stat-priority-pve-dps` (2026/11/03) | Hit until 17% > Spell Damage (+Fire) > Crit > Spell Piercing > Haste > Intellect > Spirit > Stamina |
| Frost Mage | `.../mage/frost/stat-priority-pve-dps` (2026/10/29) | Hit until 11-12% (5-6 from talents) > Crit > Spell Damage (+Frost/Arcane) > Intellect > Spirit > Stamina |
| Affliction Warlock | `.../warlock/affliction/stat-priority-pve-dps` (2026/11/11) | Spell Power > +Shadow Damage > Crit > Hit (up to 12% from gear with 5/5 Suppression) > Haste > Spell Pierce > Intellect > Spirit (from Warlock sim stat weights) |
| Demonology Warlock | `.../warlock/demonology/stat-priority-pve-dps` (2026/11/03) | Spell Power > +Fire or +Shadow Damage (matching build) > Hit (17% minus 1% per Suppression point) > Crit > Haste > Spell Pierce > Intellect > Spirit |
| Destruction Warlock | `.../warlock/destruction/stat-priority-pve-dps` (2026/11/03) | Spell Power > +Fire Damage > Crit > Hit (up to 12% with 5/5 Suppression) > Haste > Spell Pierce > Intellect > Spirit (+Fire ≈ 2/3 of Spell Power) |
| Balance Druid | `.../druid/balance/stat-priority-pve-dps` (2026/10/30) | Hit until 17% > Spell Damage > Spell Penetration > Crit > Haste > Intellect > Spirit > Stamina |
| Feral Druid DPS | `.../druid/feral/stat-priority-pve-dps` (2026/10/29) | 1% Crit > 1% Hit (8% cap) > 1% reduced Dodge/Parry (6.5% cap) > 1% Haste > Weapon DPS > Agility = Strength > Attack Power > Intellect > Spirit > Stamina |
| Feral Druid Tank — Defensive | `.../druid/feral/stat-priority-pve-tank` (2026/11/03) | Stamina > Defense until 440 > Armor > Agility > Avoidance > Defense after 440 |
| Feral Druid Tank — Offensive | same page | Hit > Reduced chance to be Dodged/Parried > Haste > Crit > Weapon DPS > Strength > Agility (the page lists "Strength" once more at the end) |
| Restoration Druid | `.../druid/restoration/stat-priority-pve-healer` (2026/11/01) | Spell Healing > Crit > Spell Haste > Spirit > Intellect > MP5 > Stamina |

Most pages say the order is speculative (beta was capped at level 30). Only Protection Warrior/Paladin and Feral
Tank have variants; only Protection Warrior/Paladin give conversion numbers (Attack Power / Spell Power per 1%).

## What needs fixing

All fixes are in the generator inputs (`docs/tools/generate_talent_builds.py` LABELS, `guide_notes.json`,
`ids_*.json`), then regenerate — the generated `Data/TalentBuilds/*.lua` are not edited by hand.

1. Mage Arcane #2/#3: move "(long fights)" label + description to #3 (29/19/3); #2 (35/13/3) gets a neutral label
   and no invented text; drop "(third)".
2. Druid Feral Tank #4: label "(pure bear)" and the guide's description (extra Rend and Tear point, Blood Frenzy);
   optionally #3 "(hybrid)".
3. Paladin Protection #4: name "Offensive Off-Tank" (the label rule strips "TANK"; needs a LABELS entry).
4. Paladin Retribution #4: name "PvP (Shockadin)".
5. Priest Discipline PvP: add the 50-step order (the build spends 50 points; level 60's point stays free).
6. Decision for the user: add points-only builds (no order) for Rogue (10), Warlock (19), Restoration Druid (5),
   Holy Priest PvE Raid (1) — the same way Balance Druid is kept — or keep them all out.
7. Optional: weapons text for Paladin Offensive Off-Tank ("one-hand + shield or two-hander", from the guide).
