# Refreshing the talent builds (Wowhead)

How the build list on the Specialization page is made and how to bring it up to date. Wowhead changes its
guides from time to time, so run this every ~10 days (or when a guide's "Updated:" date moves).
Data: `Data/TalentBuilds.lua` (shared table + Warrior's first builds) and `Data/TalentBuilds/<Class>Builds.lua`
(generated, one per class). Logic: `Engine/Builds.lua`, `Engine/TalentPlacer.lua`, `UI/BuildPicker.lua`.

## Principle

**Everything shown comes from the guides. Nothing is invented.** Wowhead gives the builds (names, talent order,
points per tree, the text about each build, the date); the leveling guides (Icy Veins / Wowhead) give the classic
order. We only present it simply: our short wording of the guide's own text, a bar of the points per tree.
Where the guide says nothing (for example the weapons of most builds), the page shows nothing.

## What a build is

- **Classic builds** (`classic = true`, one per specialization) carry only the specialization and its points per tree
  from the leveling guide; the level-up hint follows the guide chosen on the Leveling page.
- **Wowhead builds**: `id`, `name` ("<Spec>: <the guide's build name>"), `source` (page + updated date), `gearSpec`
  (the page's specialization: its stat weights judge gear), `trees` (points per tree), `description` (our short
  wording of what the guide writes about that build), `weapons` (ONLY when the guide names them), `key` (up to five
  talents the guide's text names for that build and the build takes) and `order` = 51 spell ids, one per level 10-60.
  A build without a complete order on the page (Balance Druid, Discipline PvP at the time of writing) has no `order`.

## Where the data comes from

Wowhead WoW Forever guides, one "Talents & Builds" page per specialization:
`https://www.wowhead.com/forever/guide/classes/<class>/<spec>/talent-builds-pve-<dps|tank|healer>`
Pages that exist (checked 2026-11-21): warrior arms/fury (dps), protection (tank); paladin holy (healer), protection
(tank), retribution (dps); hunter beast-mastery/marksmanship/survival (dps); rogue assassination/combat/subtlety (dps);
priest discipline/holy (healer), shadow (dps); shaman elemental/enhancement (dps), restoration (healer); mage
arcane/fire/frost (dps); warlock affliction/demonology/destruction (dps); druid balance (dps), feral (dps and tank),
restoration (healer). The class index page is a 404. Open a guide and follow its top navigation if a URL changes.
**No "Talent Order" on the page (only the classic builds exist for these):** all Rogue, all Warlock, Restoration Druid.
Check again at every refresh, pages get completed over time. The pages are rendered by script in the browser:
a plain download of the HTML does NOT contain the talent orders (only a compact code), so use the browser.

## Step by step

1. In the built-in browser open any Wowhead page of the list above. Store the extractor in the tab (once per session),
   it survives navigation inside the same site:

   ```js
   sessionStorage.__x = `(()=>{const doc=document;const names={};const full=doc.body.innerText;
   const nodes=[...doc.querySelectorAll("h2,h3,h4,.ctc-main-order-list,.ctc-tree-slider")];
   const builds=[];let heading="",slider="";
   for(const el of nodes){
     if(/^H[234]$/.test(el.tagName)){const t=el.innerText.trim();if(!/^Talent Order$/i.test(t))heading=t.slice(0,70)}
     else if(el.classList.contains("ctc-tree-slider")){slider=[...el.querySelectorAll(".ctc-tree-header")].map(h=>h.innerText.replace(/\\s+/g," ").trim()).join("|")}
     else{const ids=[...el.querySelectorAll(".ctc-main-order-line")].map(r=>{const a=r.querySelector("a");
       const id=((a&&a.href||"").match(/spell=(\\d+)/)||[])[1]||"?";const nm=r.querySelector(".ctc-main-order-line-name");
       names[id]=nm?nm.innerText:"?";return id});builds.push({h:heading,s:slider,ids:ids.join(","),t:""})}}
   let pos=0;builds.forEach(b=>{const k=full.indexOf(b.h,pos);if(k>=0){pos=k+b.h.length;b.t=full.slice(pos,pos+260).replace(/\\s+/g," ").trim()}});
   const upd=(full.match(/Updated:\\s*([0-9\\/]+)/)||[])[1];
   const s=doc.querySelector(".ctc-tree-slider");
   const trees=s?[...s.querySelectorAll(".ctc-tree")].map(t=>{const hn=t.querySelector(".ctc-tree-header-name");
     return (hn?hn.innerText.trim():"?")+":"+[...t.querySelectorAll(".ctc-tree-talent")].map(d=>{const a=d.querySelector("a");
     const m=a&&a.href.match(/(?:spell=|ll=)(\\d+)/);return (m?m[1]:"?")+"x"+d.dataset.maxPoints}).join(",")}).join(" || "):"";
   return {url:location.pathname.replace("/forever/guide/classes/",""),upd,names,builds,trees}})()`;
   ```
2. For each page: `navigate` to it, then run
   `const r=eval(sessionStorage.__x);const all=JSON.parse(sessionStorage.__all||'{}');all[r.url]=r;sessionStorage.__all=JSON.stringify(all);`
   (a `browser_batch` of navigate + run pairs does several pages per call). A page with `builds=0` has no talent order.
3. Print what you need from `sessionStorage.__all`: for every page its `upd` date and for every build the heading
   (`h`), the points per tree (`s`), the 51 spell ids (`ids`) and a short text (`t`, read it, then write our own
   description). The talent names and tree/max of ids the addon does not know yet are in `names` and `trees`.
   Saving the output to local files: the browser pane cannot reach localhost, so copy it into files by hand.
4. Put the data where the tools read it (see `docs/tools/wowhead-snapshot/wowhead/`):
   `ids_N.json` = `{ "<class>/<spec>@<dps|tank|healer>": [updatedDate, [[heading, "a,b,c" tree points, "id,id,..."], ...]] }`
   and `new_talents.json` = `{ "<spellID>": [name, tree name, max rank] }` for talents not in `Data/TalentOrders*.lua`
   (take tree and max rank from the page's tree view, the `trees` field of the extractor).
5. Download the same pages as plain HTML (Python `urllib`, the guide text is in `WH.markup.printHtml("...")`) into
   `<data folder>/html/` and run `python docs/tools/guide_text.py <data folder> <addon folder>`: it cuts the guide
   text into one section per build, matches it to the builds by heading and writes `sections.json` (the talents
   each build's text names). Read each section and write `guide_notes.json`: `{"page#index": {"desc": "...",
   "weapons": "..." only if the text names weapons}}`. Keep the meaning of the guide; do not add anything.
6. Run `python docs/tools/generate_talent_builds.py <addon folder> <data folder>`. It rewrites `Data/TalentBuilds/*.lua`.
   Hand-kept in the script: `LABELS` (names for builds that share a heading, taken from the guide's words) and
   `FIXED_IDS` (the first Warrior ids, so saved choices stay valid).
7. Check the data against the live pages: run the extractor again and compare, per build, the number of steps, a
   checksum of the spell ids and the tree points with `ids_*.json` (done on 2026-11-21: 74 builds, 0 differences).
8. Run the tests, then `/reload` in the game and look at the Specialization page.

## Rules the generator uses

- `gearSpec` = the page's specialization (a build on the Protection page is judged with Protection weights).
- No meter, no invented key talents, no invented weapons, no invented descriptions. Classic builds show only their
  points per tree and which leveling guide they follow.
- Names: "<Spec>: <label>" from the page heading; builds that share one heading are told apart with the guide's own
  words (`LABELS`).
- Order in the list: classic builds first, then each specialization's Wowhead builds as the page lists them.
- Tree names: guide data uses `elemental-combat` (Shaman) and `shadow-magic` (Priest) as slugs; the picker shows
  `builds.treeNames`.

## Checks

`Tests/Tests.lua`, block "Talent builds": for every class, every build: unique id and name, gear spec belongs to the
class and has weights, tree points >= 50, no meter value, classic builds add nothing of their own, Wowhead builds
have a source and a description, 51 steps with known talents never above their max rank, at most 5 key talents and
each one is taken by the build, one classic build per specialization. Tests run on Lua 5.4 through Python's `lupa`; the addon itself stays Lua 5.1 compatible.

## In the game

- Specialization page: the build list follows the guide's order; hover a build to preview it.
- "Place talents" and "Auto" (`Engine/TalentPlacer.lua`) only stage points in the talent window, never apply them.
- After a refresh, pick a hybrid build, press Preview on the Leveling page and compare the next talent with the
  first unmet step in the build's order.

## Open points (decide, then write here)

- Hybrid gear weights: hybrids use the weights of their `gearSpec` (Fury-Prot = Protection). Own weights for
  hybrids are not built.
- Strict weapon rules per build (e.g. Dual Wield must not accept a two-hander) are not built; `weapons` is only text.
- Choice nodes in the talent tree: `Engine/TalentAdvisor.lua` reads only the active (or first) entry.
- Weapons are shown only for the few builds whose text names them. The other Wowhead guide pages for each
  specialization (overview, BiS gear) may say more; reading them would be a separate step.

## Refresh log

- 2026-11-21 (second pass): everything rebuilt to follow the guides only (no meter, guide text for descriptions, keys
  and weapons). Data checked against the live pages: 74 builds, 0 differences.
- 2026-11-21: all classes. Warrior (Protection page 2026/11/04, Arms/Fury 2026/11/04), Paladin, Hunter, Priest, Shaman,
  Mage, Druid (Balance, Feral). No talent order: Rogue, Warlock, Restoration Druid (classic builds only).
  Incomplete orders (no `order`): Balance Druid (both builds), Discipline Priest PvP.
