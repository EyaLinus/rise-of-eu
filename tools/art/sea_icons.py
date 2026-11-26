"""Sea decorations for the world map (map_view._draw_sea_deco), in the style of an old sea chart:
kraken, Poseidon, carrack, fishing boat, gulls, a jumping fish, a whale. Two frames where they move.
Writes assets/src/pixel/icons/sea_*.txt; tools/build_art.sh renders them x2 into assets/art/icons.

Shapes are drawn as fills (light top-left, dark bottom-right) and get the 1-px ink outline from pixlib.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from pixlib import blank, outline, stack, write  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "src", "pixel", "icons")


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = blank(w, h)

    def put(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 1 <= x < self.w - 1 and 1 <= y < self.h - 1:
            self.g[y][x] = c

    def ellipse(self, cx, cy, rx, ry, ramp):
        """Filled ellipse shaded with a (light, base, dark) ramp: light top-left, dark bottom-right."""
        light, base, dark = ramp
        for y in range(self.h):
            for x in range(self.w):
                dx, dy = (x - cx) / rx, (y - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    s = dx + dy
                    self.put(x, y, light if s < -0.75 else (dark if s > 0.55 else base))

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, c)

    def line(self, pts, c, width=1.0):
        """Polyline of the given width (1 = single pixels)."""
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
            for i in range(n + 1):
                t = i / n
                x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
                if width <= 1.0:
                    self.put(x, y, c)
                else:
                    r = width / 2.0
                    for yy in range(int(y - r), int(y + r) + 2):
                        for xx in range(int(x - r), int(x + r) + 2):
                            if (xx - x) ** 2 + (yy - y) ** 2 <= r * r:
                                self.put(xx, yy, c)

    def rows(self, rows, ox, oy):
        for y, r in enumerate(rows):
            for x, c in enumerate(r):
                if c != ".":
                    self.put(ox + x, oy + y, c)

    def done(self, diagonal=False):
        return outline(self.g, diagonal)


def waves(w, h, y, phase=0, crest=True):
    """A band of rolling waves along row y (own outlined layer, drawn in front of a figure's base)."""
    c = Canvas(w, h)
    for x in range(2, w - 2):
        top = y + (0 if (x + phase) % 6 < 3 else 1)
        c.put(x, top, "b" if crest else "B")
        c.put(x, top + 1, "B")
        if (x + phase) % 6 == 1 and crest:
            c.put(x, top - 1, "w")
    return c.done()


def tentacle(c, x0, y0, side, height, phase):
    """A curling kraken arm rising from the water at (x0, y0); side -1 curls left, +1 right."""
    pts = []
    for i in range(height + 1):
        t = i / height
        sway = math.sin(t * 2.6 + phase) * 1.6
        pts.append((x0 + side * (t * 3.0 + sway), y0 - i))
    tip = pts[-1]
    # the curl at the tip
    for a in range(0, 200, 30):
        r = 1.6
        pts.append((tip[0] + side * (r - r * math.cos(math.radians(a))), tip[1] - r * math.sin(math.radians(a)) * 0.9))
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        width = 2.2 if i < height * 0.55 else 1.0
        c.line([p, q], "R", width)
    # suckers on the inner side of the lower arm
    for i in range(2, int(height * 0.55), 2):
        x, y = pts[i]
        c.put(x - side, y, "r")


def kraken(frame):
    w, h = 34, 22
    body = Canvas(w, h)
    phase = 0.0 if frame == 0 else 1.2
    tentacle(body, 7, 17, -1, 11, phase)
    tentacle(body, 11, 17, -1, 7, phase + 0.8)
    tentacle(body, 26, 17, 1, 11, -phase)
    tentacle(body, 22, 17, 1, 7, -phase + 0.8)
    body.ellipse(16.5, 13.5, 5.2, 5.8, ("r", "R", "E"))
    # eyes
    for ex in (14, 19):
        body.put(ex, 13, "Y")
        body.put(ex, 14, "k" if frame == 0 else "Y")
    body.put(15, 13, "k" if frame else "Y")
    body.put(20, 13, "k" if frame else "Y")
    fig = body.done()
    return stack(fig, waves(w, h, 18, frame * 2))


def poseidon(frame):
    w, h = 28, 32
    c = Canvas(w, h)
    # trident in the right hand
    c.line([(20, 4), (20, 26)], "D")
    c.line([(21, 6), (21, 26)], "G")
    c.rect(18, 6, 23, 6, "G")
    for px in (18, 21, 23):
        c.line([(px, 6), (px, 2)], "Y" if px == 18 else "G")
    c.put(21, 1, "Y")
    c.put(18, 1, "Y")
    c.put(23, 1, "G")
    # torso rising from the sea
    c.ellipse(11.5, 21.0, 6.2, 6.5, ("t", "S", "s"))
    # arm up to the trident
    c.line([(15, 18), (18, 15), (20, 14)], "S", 2.4)
    c.line([(15, 17), (18, 14)], "t")
    # head
    c.ellipse(11.0, 9.5, 3.6, 4.0, ("t", "S", "s"))
    c.put(10, 9, "k")
    c.put(13, 9, "k")
    # beard and hair, white and grey
    c.rows(["..w.w.w..",
            ".wwwwwwww",
            ".awwwwwwa",
            "..awwwwa.",
            "...awwa..",
            "....aa..."], 7, 11)
    c.rows(["w......w",
            "a......a"], 7, 7)
    # golden crown
    c.rows(["Y.Y.Y.Y",
            "YGGGGGG",
            "GDGDGDD"], 8, 3)
    fig = c.done()
    return stack(fig, waves(w, h, 26, frame * 2))


def carrack(frame):
    w, h = 26, 24
    c = Canvas(w, h)
    # masts
    c.line([(9, 2), (9, 16)], "H")
    c.line([(16, 4), (16, 16)], "H")
    # sails (paper, a red stripe on the main sail)
    c.rows(["PPPPPPP",
            "wPPPPPPQ",
            "wPRRRPPQ",
            "wPPPPPPQ",
            "wPPPPPQQ",
            ".QQQQQQ"], 6, 4)
    c.rows(["PPPPP",
            "wPPPPQ",
            "wPPPPQ",
            ".QQQQ"], 14, 6)
    # pennant
    c.rows(["RRr", "RE."], 10, 2)
    # hull with castles fore and aft
    c.rows(["ooo...............",
            "oOOO............oo",
            "OOOOOOOOOOOOOOOOOH",
            "OYOOYOOYOOYOOYOOOH",
            ".OOOOOOOOOOOOOOOH.",
            "..HHHHHHHHHHHHHH.."], 3, 14)
    fig = c.done()
    bob = 1 if frame else 0
    if bob:
        fig = fig[-1:] + fig[:-1]  # one pixel down: the ship rides the swell
    return stack(fig, waves(w, h, 19, frame * 3))


def boat(frame):
    w, h = 16, 12
    c = Canvas(w, h)
    c.line([(7, 1), (7, 7)], "H")
    c.rows([".P....",
            ".PP...",
            ".PPP..",
            ".PPPP.",
            "wPPPPQ"], 7, 2)
    c.rows(["OOOOOOOOOH",
            ".HHHHHHHH."], 3, 7)
    fig = c.done()
    if frame:
        fig = fig[-1:] + fig[:-1]
    return stack(fig, waves(w, h, 9, frame * 2, crest=False))


def gulls(frame):
    w, h = 16, 10
    c = Canvas(w, h)
    up = ["w.....w",
          ".w...w.",
          "..wgw..",
          "...a..."]
    down = [".......",
            ".......",
            "wwwgwww",
            "a..a..a"]
    c.rows(up if frame == 0 else down, 1, 1)
    c.rows(down if frame == 0 else up, 8, 4)
    return c.done()


def fish(frame):
    w, h = 14, 12
    c = Canvas(w, h)
    if frame == 0:  # leaping: an arched silver fish over a splash ring
        c.rows(["..aaaa...w",
                ".abbbbbaww",
                "awkbbbbB.w",
                ".BBBBBBN..",
                "..NNNN...."], 2, 2)
        c.rows(["w.....w", ".bBBBb."], 3, 8)
    else:  # diving: only the tail and the splash
        c.rows(["w.w", ".a.", ".b."], 5, 4)
        c.rows(["w.w.w.w", ".bBBBb."], 3, 8)
    return c.done()


def whale(frame):
    w, h = 30, 16
    c = Canvas(w, h)
    c.ellipse(13.0, 11.5, 9.0, 3.6, ("a", "g", "d"))
    c.rows(["d..", "dd.", "ddd", ".dd"], 23, 7)  # tail fluke
    c.put(8, 10, "k")
    # spout: tall in one frame, a puff in the other
    if frame == 0:
        c.rows([".w.w.", "w.b.w", "..b..", "..b.."], 8, 1)
    else:
        c.rows(["..w..", ".wbw.", "..b.."], 8, 3)
    fig = c.done()
    return stack(fig, waves(w, h, 13, frame * 2))


SPRITES = {
    "kraken": (kraken, 2, "kraken rising from the waves, old sea-chart sea monster for open oceans"),
    "poseidon": (poseidon, 2, "Poseidon with trident and crown rising from the sea"),
    "ship": (carrack, 2, "carrack with sails and castles riding the swell"),
    "boat": (boat, 2, "small fishing boat with a lateen sail"),
    "gulls": (gulls, 2, "two gulls flapping (wings up / down)"),
    "fish": (fish, 2, "jumping fish (leap / dive with splash)"),
    "whale": (whale, 2, "whale with spout"),
}

if __name__ == "__main__":
    names = []
    for key, (fn, frames, note) in SPRITES.items():
        for f in range(frames):
            g = fn(f)
            name = "sea_%s_%d" % (key, f)
            write(os.path.join(OUT, name + ".txt"), g, "%s – %s, frame %d, %dx%d grid, export x2. Generated by tools/art/sea_icons.py"
                  % (name, note, f, len(g[0]), len(g)))
            names.append(name)
    print(" ".join(names))
