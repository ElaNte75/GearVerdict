import json, re, sys, os, glob
# Reads the downloaded Wowhead pages (html/), cuts the guide markup into one section per talent build and
# matches each section to the extracted build orders (wowhead/ids_*.json) by heading. Writes wowhead/sections.json.
SP = sys.argv[1]
GV = sys.argv[2]


def markup_of(html):
    start = html.index('WH.markup.printHtml("') + len('WH.markup.printHtml("')
    i, buf = start, []
    while True:
        c = html[i]
        if c == "\\":
            buf.append(html[i:i + 2]); i += 2; continue
        if c == '"':
            break
        buf.append(c); i += 1
    return json.loads('"' + "".join(buf) + '"')


meta = {}
for f in ["Data/TalentOrders.lua", "Data/TalentOrdersWowhead.lua"]:
    t = open(f"{GV}/{f}", encoding="utf-8").read()
    for m in re.finditer(r'\{ \d+, \d+, "([a-z\-]+)", "([^"]+)", \d+, \d+, (\d+), (\d+) \}', t):
        meta[m.group(4)] = m.group(2)
t = open(f"{GV}/Data/TalentBuilds.lua", encoding="utf-8").read()
for m in re.finditer(r'\[(\d+)\] = \{ "([^"]+)"', t):
    meta[m.group(1)] = m.group(2)
for k, v in json.load(open(SP + "/wowhead/new_talents.json")).items():
    meta[k] = v[0]


def clean(text):
    text = re.sub(r"\[spell=(\d+)[^\]]*\]", lambda m: meta.get(m.group(1), "spell " + m.group(1)), text)
    text = re.sub(r"\[item=(\d+)[^\]]*\]", "(item)", text)
    text = re.sub(r"\[/?[a-z0-9\-]+[^\]]*\]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def sections(markup):
    tokens = [(m.start(), m.end(), "h", clean(m.group(1))) for m in re.finditer(r"\[h[234][^\]]*\](.*?)\[/h[234]\]", markup, re.S)]
    tokens += [(m.start(), m.end(), "t", m.group(1)) for m in re.finditer(r"\[talent=([^\]]+)\]", markup)]
    tokens.sort()
    out, heading, intro_from = [], "", 0
    for n, (s, e, kind, val) in enumerate(tokens):
        if kind == "h":
            heading, intro_from = val, e
            continue
        nxt = tokens[n + 1][0] if n + 1 < len(tokens) else len(markup)
        body = markup[e:nxt]
        intro = markup[intro_from:s] if intro_from is not None else ""
        intro_from = None
        spells = re.findall(r"\[spell=(\d+)", intro + body)
        out.append({"heading": heading, "intro": clean(intro), "text": clean(body), "spells": spells})
    return out


data = {}
for f in sorted(glob.glob(SP + "/wowhead/ids_*.json")):
    data.update(json.load(open(f)))
result, problems = {}, []
for page, (upd, builds) in data.items():
    cls, spec_role = page.split("/")
    spec, role = spec_role.split("@")
    html = open(f"{SP}/html/{cls}_{spec}_talent-builds-pve-{role}.html", encoding="utf-8").read()
    secs = sections(markup_of(html))
    used = set()
    for i, b in enumerate(builds):
        want = b[0].strip().upper()
        match = None
        for j, sec in enumerate(secs):
            if j in used:
                continue
            if sec["heading"].upper() == want or want in sec["heading"].upper() or sec["heading"].upper() in want:
                match = j
                break
        if match is None:
            problems.append(f"{page}#{i} '{b[0]}' not found in {[s['heading'] for s in secs]}")
            continue
        used.add(match)
        sec = secs[match]
        order = set(b[2].split(",")) if b[2] else set()
        keys = []
        for s in sec["spells"]:
            if s in order and s not in keys:
                keys.append(s)
        result[f"{page}#{i}"] = {"heading": b[0], "intro": sec["intro"], "text": sec["text"], "keys": keys}
json.dump(result, open(SP + "/wowhead/sections.json", "w"), indent=1)
print("matched", len(result), "problems", len(problems))
print("\n".join(problems))
