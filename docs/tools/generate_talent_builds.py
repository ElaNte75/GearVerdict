"""Generates Data/TalentBuilds/<Class>Builds.lua from the Wowhead data in <data folder>/wowhead/.

Usage: python generate_talent_builds.py <addon folder> <data folder>
Inputs (see docs/REFRESHING-TALENT-BUILDS.md):
  ids_*.json         page -> [updated, [[heading, "a,b,c" tree points, "51 spell ids"], ...]]
  new_talents.json   spellID -> [name, tree name, max rank] for talents not in Data/TalentOrders*.lua
  sections.json      "page#index" -> {"keys": [spell ids the guide text names for that build]} (from guide_text.py)
  guide_notes.json   "page#index" -> {"desc": our short wording of the guide text, "weapons": only if the guide says}
Everything shown comes from the guide; nothing is invented. Classic builds carry only what the leveling guides give.
"""
import json, re, sys, os, glob

GV = sys.argv[1]
W = sys.argv[2] + "/wowhead/"
TREES = {"WARRIOR": ["arms", "fury", "protection"], "PALADIN": ["holy", "protection", "retribution"],
         "HUNTER": ["beast-mastery", "marksmanship", "survival"], "ROGUE": ["assassination", "combat", "subtlety"],
         "PRIEST": ["discipline", "holy", "shadow-magic"], "SHAMAN": ["elemental-combat", "enhancement", "restoration"],
         "MAGE": ["arcane", "fire", "frost"], "WARLOCK": ["affliction", "demonology", "destruction"],
         "DRUID": ["balance", "feral-combat", "restoration"]}
SPECS = {"WARRIOR": [(71, "Arms"), (72, "Fury"), (73, "Protection")], "PALADIN": [(65, "Holy"), (66, "Protection"), (70, "Retribution")],
         "HUNTER": [(253, "Beast Mastery"), (254, "Marksmanship"), (255, "Survival")], "ROGUE": [(259, "Assassination"), (260, "Combat"), (261, "Subtlety")],
         "PRIEST": [(256, "Discipline"), (257, "Holy"), (258, "Shadow")], "SHAMAN": [(262, "Elemental"), (263, "Enhancement"), (264, "Restoration")],
         "MAGE": [(62, "Arcane"), (63, "Fire"), (64, "Frost")], "WARLOCK": [(265, "Affliction"), (266, "Demonology"), (267, "Destruction")],
         "DRUID": [(102, "Balance"), (103, "Feral Cat"), (104, "Feral Bear"), (105, "Restoration")]}
SPEC_NAME = {s: n for v in SPECS.values() for s, n in v}
PAGE_SPEC = {"warrior/arms@dps": 71, "warrior/fury@dps": 72, "warrior/protection@tank": 73, "paladin/holy@healer": 65,
             "paladin/protection@tank": 66, "paladin/retribution@dps": 70, "hunter/beast-mastery@dps": 253,
             "hunter/marksmanship@dps": 254, "hunter/survival@dps": 255, "priest/discipline@healer": 256,
             "priest/holy@healer": 257, "priest/shadow@dps": 258, "shaman/elemental@dps": 262, "shaman/enhancement@dps": 263,
             "shaman/restoration@healer": 264, "mage/arcane@dps": 62, "mage/fire@dps": 63, "mage/frost@dps": 64,
             "druid/balance@dps": 102, "druid/feral@dps": 103, "druid/feral@tank": 104}
PAGE_LABEL = {"druid/feral@dps": "Feral DPS", "druid/feral@tank": "Feral Tank"}
PAGE_TITLE = {"druid/feral@dps": "Feral Druid DPS", "druid/feral@tank": "Feral Druid Tank"}
# Ids kept from the first version so saved choices stay valid.
FIXED_IDS = {("warrior/protection@tank", 0): "standard", ("warrior/protection@tank", 1): "impale",
             ("warrior/protection@tank", 2): "fury-prot", ("warrior/protection@tank", 3): "dual-wield",
             ("warrior/protection@tank", 4): "dungeon-deep", ("warrior/protection@tank", 5): "dungeon-cleave",
             ("warrior/protection@tank", 6): "pvp"}
# Labels: the guide's own build name; where a heading holds two builds, the guide's words that tell them apart.
LABELS = {
    ("warrior/protection@tank", 2): "Fury-Prot", ("warrior/protection@tank", 4): "PvE Dungeon (Deep Protection)", ("warrior/protection@tank", 5): "PvE Dungeon (Cleave)",
    ("paladin/retribution@dps", 0): "PvE Raid (Unsealed Wrath)", ("paladin/retribution@dps", 1): "Shockadin PvE Raid",
    ("paladin/retribution@dps", 2): "PvP", ("paladin/retribution@dps", 3): "Shockadin",
    ("hunter/survival@dps", 0): "Melee PvE Dungeon & Raid", ("hunter/survival@dps", 1): "Weaving PvE Dungeon & Raid",
    ("druid/feral@dps", 0): "High Mana Regen / Open World", ("druid/feral@dps", 1): "PvE Dungeon / Raid",
    ("druid/feral@dps", 2): "Hybrid Tank PvE", ("druid/feral@tank", 0): "Open World & Leveling (Restoration)",
    ("druid/feral@tank", 1): "Open World & Leveling (Balance)", ("druid/feral@tank", 2): "Dungeon & Raid",
    ("druid/feral@tank", 3): "Dungeon & Raid (second)", ("shaman/elemental@dps", 0): "PvE Raid (Restoration)",
    ("shaman/elemental@dps", 1): "PvE Raid (Enhancement)", ("shaman/elemental@dps", 3): "PvP (Elemental)",
    ("shaman/elemental@dps", 4): "PvP (Restoration)", ("shaman/enhancement@dps", 2): "PvP (Elemental)",
    ("shaman/enhancement@dps", 3): "PvP (Restoration)", ("shaman/restoration@healer", 1): "PvE Raid (deep Restoration)",
    ("mage/arcane@dps", 1): "PvE Raid & Dungeon (long fights)", ("mage/arcane@dps", 2): "PvE Raid & Dungeon (third)",
    ("mage/fire@dps", 1): "PvE Raid & Dungeon (Frost)",
}

meta = {}
for f in ["Data/TalentOrders.lua", "Data/TalentOrdersWowhead.lua"]:
    t = open(f"{GV}/{f}", encoding="utf-8").read()
    for m in re.finditer(r'\{ \d+, \d+, "([a-z\-]+)", "([^"]+)", \d+, \d+, (\d+), (\d+) \}', t):
        meta[m.group(4)] = (m.group(1), m.group(2), int(m.group(3)))
for k, (n, tr, mx) in json.load(open(W + "new_talents.json")).items():
    slug = tr.lower().replace(" ", "-")
    meta[k] = ({"elemental": "elemental-combat", "shadow": "shadow-magic"}.get(slug, slug), n, int(mx))
data = {}
for f in sorted(glob.glob(W + "ids_*.json")):
    data.update(json.load(open(f)))
sections = json.load(open(W + "sections.json"))
notes = json.load(open(W + "guide_notes.json"))

ABBR = {"PVE": "PvE", "PVP": "PvP", "DPS": "DPS"}
STRIP = ["WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "BEAST MASTERY", "MARKSMANSHIP",
         "SURVIVAL", "DISCIPLINE", "RETRIBUTION", "RESTORATION", "ENHANCEMENT", "ELEMENTAL", "ASSASSINATION", "SUBTLETY",
         "AFFLICTION", "DEMONOLOGY", "DESTRUCTION", "PROTECTION", "ARCANE", "FROST", "FIRE", "BALANCE", "FERAL", "HOLY",
         "SHADOW", "ARMS", "FURY", "COMBAT", "BEST", "TANK"]


def label(h):
    s = h.upper()
    for w in STRIP:
        s = re.sub(r"\b" + w + r"\b", "", s)
    s = re.sub(r"\bBUILDS?\b", "", s)
    s = re.sub(r"\s+", " ", s).strip(" -")
    words = [ABBR.get(w, w.lower() if w in ("AND", "OF") else w.capitalize()) for w in s.split()]
    return " ".join(words).replace(" and ", " & ") or "Build"


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def guide_rows(spec):
    t = open(f"{GV}/Data/TalentOrders.lua", encoding="utf-8").read()
    if spec == 104:
        spec = 103  # Feral Bear shares the Feral Cat order in the guide data
    blk = t.split("orders[%d] = {" % spec)[1].split("\n}")[0]
    return [(int(m.group(1)), int(m.group(2)), m.group(3)) for m in re.finditer(r'\{ (\d+), (\d+), "([a-z\-]+)"', blk)]


entries = {c: [] for c in TREES}
for cls, specs in SPECS.items():
    for sid, nm in specs:
        cnt = {t: 0 for t in TREES[cls]}
        for first, last, tree in guide_rows(sid):
            for lvl in range(first, last + 1):
                if lvl <= 60 and tree in cnt:
                    cnt[tree] += 1
        entries[cls].append({"id": f"classic-{sid}", "name": nm, "classic": True, "spec": sid, "gear": sid,
                             "trees": [cnt[t] for t in TREES[cls]]})

spec_rank = {s: i for v in SPECS.values() for i, (s, _) in enumerate(v)}
pages = sorted(data.items(), key=lambda kv: (kv[0].split("/")[0], spec_rank[PAGE_SPEC[kv[0]]], kv[0]))
for page, (upd, builds) in pages:
    cls = page.split("/")[0].upper()
    spec = PAGE_SPEC[page]
    for i, (heading, slider, ids) in enumerate(builds):
        key = f"{page}#{i}"
        ids_list = ids.split(",") if ids else []
        note = notes[key]
        guide_keys = [s for s in sections.get(key, {}).get("keys", []) if s in meta][:5]
        e = {"id": FIXED_IDS.get((page, i)) or f"{cls.lower()}-{page.split('@')[0].split('/')[1]}{'-tank' if page == 'druid/feral@tank' else ''}-{i + 1}",
             "name": f"{PAGE_LABEL.get(page, SPEC_NAME[spec])}: {LABELS.get((page, i)) or label(heading)}",
             "gear": spec, "trees": [int(x) for x in slider.split(",")], "desc": note["desc"], "weapons": note.get("weapons"),
             "source": f"Wowhead, {PAGE_TITLE.get(page) or SPEC_NAME[spec] + ' ' + cls.capitalize()} talent builds (updated {upd})",
             "key": guide_keys, "ids": ids_list if len(ids_list) == 51 else None}
        entries[cls].append(e)

outdir = GV + "/Data/TalentBuilds/"
os.makedirs(outdir, exist_ok=True)
for old in glob.glob(outdir + "*.lua"):
    os.remove(old)
summary = []
for cls, lst in entries.items():
    talents = set()
    for e in lst:
        talents.update(e.get("ids") or [])
        talents.update(e.get("key") or [])
    names = set()
    for e in lst:
        assert e["name"] not in names, e["name"]
        names.add(e["name"])
    lines = ["local _, addon = ...",
             f"-- {cls.capitalize()} talent builds. GENERATED by docs/tools/generate_talent_builds.py: do not edit by hand,",
             "-- see docs/REFRESHING-TALENT-BUILDS.md. Classic builds follow the leveling guide chosen on the Leveling page;",
             "-- the others are Wowhead's talent builds for each specialization (order = one spell id per level, 10-60).",
             "local builds = addon.TalentBuilds", ""]
    for s in sorted(talents, key=int):
        tr, nm, mx = meta[s]
        lines.append(f"builds.talents[{s}] = {{ {lua_str(nm)}, {lua_str(tr)}, {mx} }}")
    titles = [{"elemental-combat": "Elemental", "shadow-magic": "Shadow"}.get(t, t.replace("-", " ").title()) for t in TREES[cls]]
    lines += ["", f"builds.treeNames.{cls} = {{ {', '.join(lua_str(x) for x in titles)} }}", f"local list = {{}}", f"builds.byClass.{cls} = list"]
    for e in lst:
        parts = [f"id = {lua_str(e['id'])}", f"name = {lua_str(e['name'])}"]
        if e.get("classic"):
            parts += ["classic = true", f"spec = {e['spec']}"]
        parts += [f"gearSpec = {e['gear']}", f"trees = {{ {', '.join(map(str, e['trees']))} }}"]
        if e.get("source"):
            parts.append(f"source = {lua_str(e['source'])}")
        if e.get("weapons"):
            parts.append(f"weapons = {lua_str(e['weapons'])}")
        if e.get("key"):
            parts.append(f"key = {{ {', '.join(e['key'])} }}")
        if e.get("desc"):
            parts.append(f"description = {lua_str(e['desc'])}")
        if e.get("ids"):
            parts.append(f"order = {{ {', '.join(e['ids'])} }}")
        lines.append("list[#list + 1] = { " + ",\n    ".join(parts) + " }")
        summary.append(f"{cls} | {e['name']} | keys {len(e.get('key') or [])} | weapons {e.get('weapons') or '-'} | order {'yes' if e.get('ids') else 'no'}")
    open(outdir + f"{cls.capitalize()}Builds.lua", "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
print("\n".join(summary))
