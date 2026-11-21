# Refreshing the talent builds (Wowhead)

How the build list on the Specialization page is made and how to bring it up to date. Wowhead changes its
guides from time to time, so run this every ~10 days (or when a guide's "Updated:" date moves).
Data file: `Data/TalentBuilds.lua` (data only). Logic: `Engine/Builds.lua`, `Engine/TalentPlacer.lua`.

## What a build is

- Classic builds (`classic = true`, one per specialization) have no order of their own. They follow the leveling
  guide the player chose on the Leveling page (Icy Veins / Wowhead, `Data/TalentOrders*.lua`).
- Hybrid builds come from Wowhead's talent-builds page of a specialization. Each has:
  `id`, `name`, `source`, `weapons`, `key` (4-6 key talent spell ids), `gearSpec` (specialization id whose stat
  weights and weapon rules gear is judged with), `offense` (0 = full defense ... 100 = full offense, hand-set for the meter),
  `trees` (points in tree 1 / 2 / 3 at level 60), `description` (our own words, never copied) and
  `order` = 51 spell ids, ONE PER LEVEL from level 10 to 60.
- `builds.talents[spellID] = { name, tree, maxRank }` is shared by all builds of a class.

## Where the data comes from

Wowhead WoW Forever guides, one "Talents & Builds" page per specialization:
`https://www.wowhead.com/forever/guide/classes/<class>/<spec>/talent-builds-pve-<dps|tank|healer>`
(Warrior: `.../warrior/protection/talent-builds-pve-tank` holds all the Protection hybrids.)
Per page, check the line "Updated: YYYY/MM/DD" and the author. The class index page
(`/forever/guide/classes/<class>`) is a 404; reach the specialization pages from a guide's top navigation.
Some pages have no "Talent Order" (Rogue, Warlock, Balance and Restoration Druid when last checked): for those
only the classic builds exist, and the page says so. Check again at every refresh, pages get completed over time.

## Step by step

1. Open the page in the built-in browser (or any browser). Note the "Updated" date.
2. Run this in the page console. It returns, per build, the 51 spell ids and the talent names, and the
   points per tree (the tree sliders):

   ```js
   const names = {};
   const lists = [...document.querySelectorAll('.ctc-main-order-list')].map(list =>
     [...list.querySelectorAll('.ctc-main-order-line')].map(row => {
       const link = row.querySelector('a');
       const id = (link.href.match(/spell=(\d+)/) || [])[1];
       names[id] = row.querySelector('.ctc-main-order-line-name').innerText;
       return id;
     }));
   const sliders = [...document.querySelectorAll('.ctc-tree-slider')].map(s => s.innerText.replace(/\n/g, ' '));
   JSON.stringify({ names, lists: lists.map(l => l.join(',')), sliders });
   ```

   Build names and the descriptive text are headings and paragraphs on the page (read them, do not copy them).
3. Match the lists to the builds in page order (the Nth `.ctc-main-order-list` is the Nth build). Sanity check:
   each list has 51 entries and the points per tree add up to the numbers in the build's "A/B/C" header.
4. Fill the data file. Tree and maximum rank of each talent: take them from the existing
   `Data/TalentOrders.lua` / `TalentOrdersWowhead.lua` rows (`{ first, last, tree, name, rankBefore, rankAfter, max, spellID }`);
   for a talent that is not there, read it from the page's tree view and add it to `builds.talents`.
5. Write the `description` (one or two sentences, our own words), the `weapons` text (what the build wants
   in the hands: from the guide's text) and 4-6 `key` talents (the ones the guide names as the core).
   Set `offense` by judgment from the guide's own words (defense/healing at the low end, damage at the high end),
   and `gearSpec` to the specialization whose stat weights fit the build best (see "Open points" below).
6. Set `source = "Wowhead, <page title> (updated YYYY/MM/DD)"`. The Specialization page shows it under the description.
7. Run the tests (see below), then `/reload` in the game and look at the Specialization page.

## Checks

`Tests/Tests.lua` ("Talent builds" block) checks for every build: 51 steps, tree points add up to 51, every spell
is known and never above its maximum rank, the gear specialization has weights, a weapons text, 4-6 key talents
that exist, and a Wowhead source line. A failing check names the build.
Tests run on Lua 5.4 through Python's `lupa` (`lupa.lua54`); the addon itself must stay Lua 5.1 compatible.

## In the game

- Specialization page: the build list is sorted from most defense to most offense; hover a build to preview it.
- "Place talents" and "Auto" (see `Engine/TalentPlacer.lua`) only stage points in the talent window, never apply them.
- After a refresh, pick a hybrid build, press Preview on the Leveling page and compare the next talent with the
  first unmet step in the build's order.

## Open points (decide, then write here)

- Hybrid gear weights: hybrids use the weights of their `gearSpec` (Fury-Prot = Protection). Own weights for
  hybrids are not built.
- Strict weapon rules per build (e.g. Dual Wield must not accept a two-hander) are not built; `weapons` is only text.
- Choice nodes in the talent tree: `Engine/TalentAdvisor.lua` reads only the active (or first) entry.

## Refresh log

- 2026-11-21: Warrior (Protection page, updated 2026/11/04): 7 hybrids + 3 classic builds.
