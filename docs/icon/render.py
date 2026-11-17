import sys, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 4            # supersampling
N = 400 * S


def hexc(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mask_poly(pts):
    m = Image.new('L', (N, N), 0)
    ImageDraw.Draw(m).polygon([(x * S, y * S) for x, y in pts], fill=255)
    return m


def mask_circle(cx, cy, r):
    m = Image.new('L', (N, N), 0)
    ImageDraw.Draw(m).ellipse([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], fill=255)
    return m


def mask_ring(cx, cy, r, w):
    m = mask_circle(cx, cy, r + w / 2)
    inner = mask_circle(cx, cy, r - w / 2)
    return Image.fromarray(np.minimum(np.array(m), 255 - np.array(inner)).astype('uint8'))


def mask_stroke(pts, w, closed=True):
    m = Image.new('L', (N, N), 0)
    d = ImageDraw.Draw(m)
    p = [(x * S, y * S) for x, y in pts]
    if closed:
        p = p + [p[0]]
    d.line(p, fill=255, width=int(w * S), joint='curve')
    for x, y in p:
        r = w * S / 2
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    return m


def grad_linear(stops, angle=90):
    # angle 90 = top to bottom, 45 = top-left to bottom-right
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32) / N
    a = math.radians(angle)
    t = xx * math.cos(a) + yy * math.sin(a)
    t = (t - t.min()) / (t.max() - t.min())
    return _ramp(t, stops)


def grad_radial(stops, cx, cy, r):
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    t = np.sqrt((xx - cx * S) ** 2 + (yy - cy * S) ** 2) / (r * S)
    return _ramp(np.clip(t, 0, 1), stops)


def _ramp(t, stops):
    out = np.zeros(t.shape + (4,), np.float32)
    pos = [s[0] for s in stops]
    cols = [np.array(hexc(*s[1:]) if len(s) > 2 else hexc(s[1]), np.float32) for s in stops]
    for c in range(4):
        out[..., c] = np.interp(t, pos, [col[c] for col in cols])
    return Image.fromarray(out.astype('uint8'), 'RGBA')


def paint(canvas, mask, fill, opacity=1.0):
    if isinstance(fill, str):
        layer = Image.new('RGBA', (N, N), hexc(fill))
    else:
        layer = fill
    a = np.array(layer)[..., 3].astype(np.float32) * (np.array(mask).astype(np.float32) / 255) * opacity
    layer = layer.copy()
    layer.putalpha(Image.fromarray(a.astype('uint8')))
    canvas.alpha_composite(layer)


def shadow(canvas, mask, dy=6, blur=7, opacity=0.65, color='#000000'):
    m = Image.new('L', (N, N), 0)
    m.paste(mask, (0, int(dy * S)))
    m = m.filter(ImageFilter.GaussianBlur(blur * S))
    paint(canvas, m, color, opacity)


def glow(canvas, mask, color, blur=10, opacity=0.9):
    paint(canvas, mask.filter(ImageFilter.GaussianBlur(blur * S)), color, opacity)


def bez(p0, p1, p2, p3, n=24):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def scale(pts, f, cx=200, cy=200):
    return [(cx + (x - cx) * f, cy + (y - cy) * f) for x, y in pts]


def shift(pts, dx, dy):
    return [(x + dx, y + dy) for x, y in pts]


GOLD = [(0, '#fff3b0'), (0.3, '#f0c04a'), (0.62, '#a8700f'), (0.82, '#e9b545'), (1, '#fff0a0')]
GOLD_IN = [(0, '#7a4c08'), (0.5, '#d9a032'), (1, '#fff0a8')]
STEEL = [(0, '#f4f8fc'), (0.45, '#a3b2c3'), (1, '#46525f')]
GREEN = [(0, '#d2ffb0'), (0.4, '#4fe25a'), (1, '#0b7d20')]


def frame(c):
    paint(c, Image.new('L', (N, N), 255), grad_radial([(0, '#22306a'), (0.55, '#101a3c'), (1, '#060a1a')], 200, 185, 290))
    paint(c, mask_circle(200, 200, 150), grad_radial([(0, '#fff2b0', 190), (0.45, '#e8b84a', 70), (1, '#e8b84a', 0)], 200, 200, 150))
    for a in range(0, 360, 45):
        r = 135 if a % 90 == 0 else 95
        w = 9 if a % 90 == 0 else 6
        ang = math.radians(a)
        tip = (200 + r * math.cos(ang), 200 + r * math.sin(ang))
        side = math.radians(a + 90)
        pts = [tip, (200 + w * math.cos(side), 200 + w * math.sin(side)), (200, 200),
               (200 - w * math.cos(side), 200 - w * math.sin(side))]
        paint(c, mask_poly(pts), '#f5d27a', 0.28)
    ring = mask_ring(200, 200, 172, 28)
    shadow(c, ring, 5, 6, 0.7)
    paint(c, mask_ring(200, 200, 172, 32), '#2a1a04')
    paint(c, ring, grad_linear(GOLD, 70))
    paint(c, mask_ring(200, 200, 158.5, 3), grad_linear(GOLD_IN, 90))
    paint(c, mask_ring(200, 200, 185.5, 2), '#fff6cc', 0.7)
    paint(c, mask_ring(200, 200, 172, 3), '#fff6cc', 0.25)
    for x, y, a in ((200, 22, 90), (200, 378, 270), (22, 200, 0), (378, 200, 180)):
        ang = math.radians(a)
        tip = (x + 22 * math.cos(ang), y + 22 * math.sin(ang))
        side = math.radians(a + 90)
        base = (x - 4 * math.cos(ang), y - 4 * math.sin(ang))
        pts = [tip, (base[0] + 13 * math.cos(side), base[1] + 13 * math.sin(side)),
               (base[0] - 13 * math.cos(side), base[1] - 13 * math.sin(side))]
        m = mask_poly(pts)
        shadow(c, m, 2, 2, 0.6)
        paint(c, mask_stroke(pts, 4), '#3a2406')
        paint(c, m, grad_linear(GOLD, 90))


ARROW = [(200, 128), (262, 196), (228, 196), (228, 266), (172, 266), (172, 196), (138, 196)]


def arrow(c, pts):
    m = mask_poly(pts)
    glow(c, m, '#54ff62', 12, 0.85)
    paint(c, mask_stroke(pts, 12), '#04300c')
    paint(c, m, grad_linear(GREEN, 90))
    tip = pts[0]
    hl = [tip, (tip[0] + 0.75 * (pts[1][0] - tip[0]), tip[1] + 0.75 * (pts[1][1] - tip[1])),
          (tip[0] + 0.25 * (pts[1][0] - tip[0]), tip[1] + 0.95 * (pts[1][1] - tip[1]))]
    paint(c, mask_poly(hl), '#f0ffe0', 0.5)


def shield_pts(f=1.0):
    right = [(200, 98)] + bez((200, 98), (230, 116), (258, 122), (282, 124), 12)[1:] + \
            bez((282, 124), (284, 220), (262, 272), (200, 308))[1:]
    left = [(400 - x, y) for x, y in reversed(right[1:-1])]
    return scale(right + left, f, 200, 200)


def concept_a():
    c = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    frame(c)
    outer = shield_pts(1.0)
    shadow(c, mask_poly(outer), 8, 9, 0.75)
    paint(c, mask_poly(scale(outer, 1.04, 200, 200)), '#1c1205')
    paint(c, mask_poly(outer), grad_linear(GOLD, 80))
    inner = scale(outer, 0.86, 200, 205)
    paint(c, mask_poly(inner), grad_linear(STEEL, 45))
    left_half = [p for p in inner if p[0] <= 200.5]
    paint(c, mask_poly(left_half + [(200, max(p[1] for p in inner))]), grad_linear([(0, '#8090a5'), (1, '#222b36')], 90), 0.45)
    paint(c, mask_poly([(150, 136), (200, 118), (200, 132), (156, 150)]), '#ffffff', 0.5)
    arrow(c, scale(ARROW, 0.92, 200, 205))
    return c


def concept_b():
    c = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    frame(c)
    plate = [(144, 120), (177, 106)] + bez((177, 106), (186, 120), (214, 120), (223, 106))[1:] + \
            [(256, 120), (288, 150), (272, 174), (258, 164)] + bez((258, 164), (256, 220), (256, 260), (254, 286))[1:] + \
            bez((254, 286), (230, 302), (170, 302), (146, 286))[1:] + bez((146, 286), (144, 260), (144, 220), (142, 164))[1:] + \
            [(128, 174), (112, 150)]
    plate = shift(plate, -18, 8)
    shadow(c, mask_poly(plate), 8, 9, 0.75)
    paint(c, mask_stroke(plate, 14), '#1c1205')
    paint(c, mask_stroke(plate, 8), grad_linear(GOLD, 80))
    paint(c, mask_poly(plate), grad_linear(STEEL, 45))
    paint(c, mask_poly([p for p in plate if p[0] <= 182.5] + [(182, 300)]), grad_linear([(0, '#8090a5'), (1, '#222b36')], 90), 0.45)
    for y in (200, 244):
        band = bez((132, y), (160, y + 18), (204, y + 18), (232, y), 30)
        paint(c, mask_stroke(band, 7, False), grad_linear(GOLD, 90))
    paint(c, mask_poly(shift([(160, 126), (182, 116), (186, 128), (166, 140)], -18, 8)), '#ffffff', 0.55)
    arrow(c, shift(scale(ARROW, 0.62, 200, 200), 76, -36))
    return c


def save(c, name):
    out = c.resize((400, 400), Image.LANCZOS)
    out.save(name + '.png')
    return out


if __name__ == '__main__':
    import os
    d = sys.argv[1]
    a = save(concept_a(), os.path.join(d, 'a'))
    b = save(concept_b(), os.path.join(d, 'b'))
    both = Image.new('RGBA', (900, 400), (40, 40, 40, 255))
    both.paste(a, (0, 0))
    both.paste(b, (500, 0))
    both.save(os.path.join(d, 'both.png'))
