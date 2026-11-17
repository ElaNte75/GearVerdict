import sys, os, math
from PIL import Image, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import *  # noqa


def ellipse_pts(cx, cy, rx, ry, a0=0, a1=360, n=60):
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def rot(pts, ang, cx, cy):
    a = math.radians(ang)
    return [(cx + (x - cx) * math.cos(a) - (y - cy) * math.sin(a),
             cy + (x - cx) * math.sin(a) + (y - cy) * math.cos(a)) for x, y in pts]


def metal(c, pts, grad=STEEL, rim='#1a1206', rimw=6, shade=True, sh=True):
    m = mask_poly(pts)
    if sh:
        shadow(c, m, 6, 7, 0.7)
    paint(c, mask_stroke(pts, rimw), rim)
    paint(c, m, grad_linear(grad, 50))
    if shade:
        paint(c, m, grad_linear([(0, '#000000', 0), (0.55, '#000000', 0), (1, '#000000', 150)], 0), 1)


def helmet_pts(cx, cy, s):
    # front great helm: rounded top, straight sides, slightly flared bottom
    top = bez((cx - 50 * s, cy - 5 * s), (cx - 50 * s, cy - 70 * s), (cx + 50 * s, cy - 70 * s), (cx + 50 * s, cy - 5 * s), 30)
    return top + [(cx + 52 * s, cy + 55 * s), (cx + 30 * s, cy + 68 * s), (cx - 30 * s, cy + 68 * s), (cx - 52 * s, cy + 55 * s)]


def helmet(c, cx, cy, s, glow_eyes=True):
    pts = helmet_pts(cx, cy, s)
    metal(c, pts)
    # central ridge
    paint(c, mask_stroke([(cx, cy - 48 * s), (cx, cy + 62 * s)], 7 * s, False), grad_linear(GOLD, 90))
    # brow band
    band = bez((cx - 50 * s, cy - 4 * s), (cx - 20 * s, cy + 6 * s), (cx + 20 * s, cy + 6 * s), (cx + 50 * s, cy - 4 * s), 20)
    paint(c, mask_stroke(band, 8 * s, False), grad_linear(GOLD, 90))
    # T visor
    slit = [(cx - 40 * s, cy + 12 * s), (cx + 40 * s, cy + 12 * s), (cx + 40 * s, cy + 22 * s), (cx + 6 * s, cy + 22 * s),
            (cx + 6 * s, cy + 56 * s), (cx - 6 * s, cy + 56 * s), (cx - 6 * s, cy + 22 * s), (cx - 40 * s, cy + 22 * s)]
    m = mask_poly(slit)
    paint(c, m, '#05140a')
    if glow_eyes:
        glow(c, m, '#5dff6a', 9 * s, 1.0)
        paint(c, mask_poly(scale(slit, 0.9, cx, cy + 20 * s)), '#d8ffc0', 0.9)
    for dx in (-36, 36):
        for dy in (36, 50):
            paint(c, mask_circle(cx + dx * s, cy + dy * s, 3.2 * s), '#f3d27a')
    paint(c, mask_poly([(cx - 40 * s, cy - 30 * s), (cx - 18 * s, cy - 52 * s), (cx - 14 * s, cy - 44 * s), (cx - 34 * s, cy - 22 * s)]), '#ffffff', 0.5)


def concept_scales():
    c = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    frame(c)
    tilt = 12
    cx, cy = 200, 118
    metal(c, [(190, 118), (210, 118), (215, 296), (185, 296)], GOLD, '#2a1a04', 6, False)
    metal(c, [(140, 296), (260, 296), (274, 320), (126, 320)], GOLD, '#2a1a04', 6, False)
    beam = rot([(86, 112), (314, 112), (314, 125), (86, 125)], tilt, cx, cy)
    metal(c, beam, GOLD, '#2a1a04', 6, False)
    metal(c, ellipse_pts(200, 118, 16, 16), GOLD, '#2a1a04', 5, False)
    paint(c, mask_circle(200, 118, 6), '#1f9e35')
    lx, ly = rot([(94, 118)], tilt, cx, cy)[0]
    rx, ry = rot([(306, 118)], tilt, cx, cy)[0]
    drop = 96
    for (x, y) in ((lx, ly), (rx, ry)):
        pan_y = y + drop
        for dx in (-42, 42):
            paint(c, mask_stroke([(x, y), (x + dx, pan_y)], 3.5, False), '#f0c860')
        pan = ellipse_pts(x, pan_y, 52, 22, 0, 180, 30)
        metal(c, pan + [(x - 52, pan_y)], GOLD, '#2a1a04', 6, False)
        paint(c, mask_poly(ellipse_pts(x, pan_y, 52, 7)), '#fff1b0', 0.85)
    win_x, win_y = rx, ry + drop
    lose_x, lose_y = lx, ly + drop
    glow(c, mask_circle(win_x, win_y - 26, 46), '#4dff5a', 20, 0.8)
    helmet(c, win_x, win_y - 48, 0.64)
    ring = mask_ring(lose_x, lose_y - 26, 19, 10)
    shadow(c, ring, 3, 3, 0.6)
    paint(c, ring, grad_linear([(0, '#e4e8ee'), (1, '#6b7480')], 60))
    paint(c, mask_circle(lose_x, lose_y - 47, 8), '#9a2a2a')
    paint(c, mask_circle(lose_x - 2, lose_y - 49, 3), '#ffb0a0', 0.8)
    arrow(c, shift(scale(ARROW, 0.4, 200, 200), win_x - 200, win_y - 340))
    return c


def concept_helm():
    c = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    frame(c)
    arrow(c, shift(scale(ARROW, 0.62, 200, 200), 0, -58))
    helmet(c, 200, 222, 1.32)
    return c


def concept_seal():
    c = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    frame(c)
    parch = rot([(110, 110), (290, 110), (296, 290), (104, 296)], -8, 200, 200)
    metal(c, parch, [(0, '#f6e7bf'), (0.6, '#d9bf86'), (1, '#a8844a')], '#3a2a10', 4, False)
    for y in (140, 160, 180):
        paint(c, mask_stroke(rot([(130, y), (270, y)], -8, 200, 200), 3, False), '#8a6a3a', 0.5)
    # ribbons
    for pts, col in (([(186, 236), (204, 236), (176, 330), (168, 312), (154, 322)], '#7a1414'),
                     ([(200, 236), (218, 236), (246, 322), (232, 314), (222, 330)], '#8f1a1a')):
        metal(c, pts, [(0, '#c23a3a'), (1, '#5a0c0c')], '#2a0606', 3, False)
    # wax blob
    blob = []
    for i in range(72):
        a = math.radians(i * 5)
        r = 68 + 5 * math.sin(i * 1.7) + 4 * math.sin(i * 0.9 + 1)
        blob.append((200 + r * math.cos(a), 220 + r * math.sin(a)))
    m = mask_poly(blob)
    shadow(c, m, 7, 7, 0.7)
    paint(c, m, grad_radial([(0, '#e04a3a'), (0.7, '#a01818'), (1, '#5a0808')], 185, 200, 80))
    paint(c, mask_ring(200, 220, 48, 6), '#5a0808', 0.7)
    paint(c, mask_ring(200, 218, 48, 3), '#ff8a70', 0.35)
    plate = scale([(176, 196), (190, 190), (200, 196), (210, 190), (224, 196), (232, 210), (224, 214), (222, 248), (178, 248), (176, 214), (168, 210)], 1.0, 200, 220)
    paint(c, mask_poly(shift(plate, 1.5, 2)), '#4a0606', 0.8)
    paint(c, mask_poly(plate), '#c83a2c')
    arrow(c, shift(scale(ARROW, 0.38, 200, 200), 0, 18))
    paint(c, mask_poly([(158, 182), (176, 168), (180, 176), (164, 190)]), '#ffffff', 0.45)
    return c


def concept_lens():
    c = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    frame(c)
    # handle
    handle = rot([(194, 250), (206, 250), (210, 340), (190, 340)], -40, 200, 250)
    handle = shift(handle, 34, 0)
    metal(c, handle, [(0, '#8a5a2a'), (1, '#3a2010')], '#1a0e04', 5, False)
    lx, ly, r = 178, 176, 78
    # breastplate behind, gray outside the lens
    plate = [(110, 140), (150, 124), (178, 140), (206, 124), (246, 140), (262, 176), (244, 184), (238, 276), (118, 276), (112, 184), (94, 176)]
    metal(c, plate, [(0, '#8d96a2'), (1, '#3c434d')], '#141820', 5)
    # inside the lens: glowing green version
    lens = mask_circle(lx, ly, r)
    inside = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    paint(inside, mask_poly(plate), grad_linear(GREEN, 60))
    paint(inside, mask_poly(plate), grad_linear([(0, '#000000', 0), (0.6, '#000000', 0), (1, '#000000', 120)], 0))
    arrow(inside, shift(scale(ARROW, 0.5, 200, 200), lx - 200, ly - 196))
    glow(c, lens, '#7dff7a', 10, 0.5)
    paint(c, lens, '#0c2a14', 0.85)
    paint(c, lens, inside)
    paint(c, lens, grad_radial([(0, '#ffffff', 0), (0.75, '#ffffff', 0), (1, '#c8ffd0', 90)], lx, ly, r))
    paint(c, mask_poly(ellipse_pts(lx - 30, ly - 34, 22, 12)), '#ffffff', 0.35)
    rim = mask_ring(lx, ly, r + 6, 14)
    shadow(c, rim, 5, 5, 0.7)
    paint(c, mask_ring(lx, ly, r + 6, 18), '#2a1a04')
    paint(c, rim, grad_linear(GOLD, 60))
    return c


if __name__ == '__main__':
    d = sys.argv[1]
    imgs = [save(f(), os.path.join(d, n)) for n, f in
            (('c1_scales', concept_scales), ('c2_helm', concept_helm), ('c3_seal', concept_seal), ('c4_lens', concept_lens))]
    sheet = Image.new('RGBA', (1660, 520), (36, 36, 42, 255))
    for i, im in enumerate(imgs):
        x = 10 + i * 412
        sheet.paste(im, (x, 10))
        sheet.paste(im.resize((64, 64), Image.LANCZOS), (x + 120, 432))
        sheet.paste(im.resize((32, 32), Image.LANCZOS), (x + 220, 448))
    sheet.save(os.path.join(d, 'sheet4.png'))
