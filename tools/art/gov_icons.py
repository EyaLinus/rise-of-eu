"""Government icons (16x16 grid): one per law group, reform tier and estate.
Writes assets/src/pixel/icons/<key>.txt. Run tools/build_art.sh after.
Keys match data/government.json ids: law_<id>, reform_<id>, estate_<id> (scripts/ui/gov_screen.gd)."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from pixlib import layer, stack, write
import hud_icons

OUT = hud_icons.OUT
ICONS = {}

# --- laws ---------------------------------------------------------------------------------------------
ICONS["law_wirtschaft"] = (layer([
    "......Y.......",
    ".....YGD......",
    "YYYYYYGDDDDDDD",
    ".G....GD....G.",
    "GGG...GD...GGG",
    "G.G...GD...G.G",
    "GYYG..GD..GYYG",
    "DDDD..GD..DDDD",
    "......GD......",
    "....YYGDDD....",
    "...DDDDDDDD...",
], 1, 3), "law_wirtschaft – economic order: gold balance scale")

ICONS["law_heer"] = stack(
    layer([
        "...RR.......",
        "..RRE.......",
        "..RE........",
    ], 2, 1),
    layer([
        "...aaaaa....",
        "..aaaaaagg..",
        ".aaaaaaaggg.",
        ".aaaaaaaggg.",
        ".dddddddddd.",
        ".aaaaaaaggg.",
        ".aadagadagg.",
        ".aaaaaaaggg.",
        "..aaaaaagg..",
        "...gggggg...",
    ], 2, 4)), "law_heer – army law: knight helmet with red plume"
ICONS["law_heer"] = (ICONS["law_heer"][0], ICONS["law_heer"][1])

ICONS["law_staat"] = (layer([
    "......YY......",
    "....YYGGDD....",
    "..YYGGGGGGDD..",
    "GGGGGGGGGGGGGG",
    "DDDDDDDDDDDDDD",
    ".PQ..PQ..PQ.PQ",
    ".PQ..PQ..PQ.PQ",
    ".PQ..PQ..PQ.PQ",
    ".PQ..PQ..PQ.PQ",
    ".PQ..PQ..PQ.PQ",
    "QQQQQQQQQQQQQQ",
    "DDDDDDDDDDDDDD",
], 1, 2), "law_staat – state structure: columned hall")

ICONS["law_kirche"] = (layer([
    ".....Y......",
    "....YGD.....",
    ".....D......",
    ".....E......",
    "....ERE.....",
    "...ERRRE....",
    "..ERRRRRE...",
    ".ERRRRRRRE..",
    "..PPPPPPQ...",
    "..PbPPPbQ...",
    "..PPPHPPQ...",
    "..PPHOHPQ...",
    "..QQHOHQQ...",
], 3, 1), "law_kirche – church policy: chapel with gold cross")

ICONS["law_aussen"] = (layer([
    "....BBBB....",
    "..BBLLBBBB..",
    ".BLLLLBBBBB.",
    ".BLLLBBBLLB.",
    "BBBLBBBLLLBN",
    "BBBBBBBLLLBN",
    "BBBBBBBBLBBN",
    "BBLLBBBBBBBN",
    ".BLLLBBBBBN.",
    ".BBLLBBBBNN.",
    "..BBBBBBNN..",
    "....NNNN....",
], 2, 2), "law_aussen – foreign policy: globe")

# --- state reforms --------------------------------------------------------------------------------------
ICONS["reform_grundlage"] = (layer([
    "...aaaag.....",
    "...agggd.....",
    "aaaagaaaaag..",
    "agggdagggd...",
    "dddddddddddd.",
    "aaagaaaagaaag",
    "agggdagggdggd",
    "ddddddddddddd",
    "aagaaaagaaaag",
    "aggdagggdaggd",
    "ddddddddddddd",
], 1, 3), "reform_grundlage – foundation of rule: stacked cornerstones")

ICONS["reform_verwaltung"] = stack(
    layer([
        "..........ww",
        ".........wwa",
        "........wwa.",
        ".......wwa..",
        "......wwa...",
        ".....wwa....",
        "....wa......",
        "...k........",
    ], 3, 1),
    layer([
        "PPPPPPPP",
        "PQQQQQPQ",
        "PPPPPPPQ",
        "PQQQQPPQ",
        "PPPPPPPQ",
        "QQQQQQQQ",
    ], 1, 9),
    layer([
        ".dd.",
        "dNNd",
        "dNNd",
        "dddd",
    ], 11, 11)), "reform_verwaltung – administration: quill, ink pot and ledger"
ICONS["reform_verwaltung"] = (ICONS["reform_verwaltung"][0], ICONS["reform_verwaltung"][1])

ICONS["reform_heerwesen"] = stack(
    layer(["H"] * 14, 2, 1),
    layer([
        "RRRRRRRRR",
        "RRRYYRRRE",
        "RRYGGDRRE",
        "RRRYDRRRE",
        "RRRRRRRRE",
        "RRRRRRRE.",
        "RRRRRRE..",
        "RRRE.....",
    ], 3, 2)), "reform_heerwesen – military system: red banner on a pole"
ICONS["reform_heerwesen"] = (ICONS["reform_heerwesen"][0], ICONS["reform_heerwesen"][1])

ICONS["reform_staatsidee"] = (layer([
    "......Y.......",
    "..Y...Y...Y...",
    "...Y..Y..Y....",
    "....YYYYY.....",
    "...YGGGGGD....",
    "YYYYGwGwGDYYYY",
    "...YGGGGGD....",
    "...YGDDDGD....",
    "....DDDDD.....",
    "...D..D..D....",
    "..D...D...D...",
    "......D.......",
], 1, 2), "reform_staatsidee – idea of the state: radiant sun")

ICONS["reform_herrschaft"] = (layer([
    ".....Y......",
    "....YGD.....",
    ".....D......",
    "...YGGGD....",
    "..YGGGGGD...",
    ".YGwGGGGGD..",
    ".RRRRRRRRE..",
    ".YGGGGGGGD..",
    ".GGGGGGGGD..",
    "..GGGGGGD...",
    "...DDDDD....",
], 2, 2), "reform_herrschaft – form of rule: gold royal orb with red band")

# --- estates --------------------------------------------------------------------------------------------
ICONS["estate_adel"] = (layer([
    "BBBBBBBBBBN",
    "BBBBYBBBBBN",
    "BBBYGDBBBBN",
    "BBBBGBBBBBN",
    "BBYYGDDBBBN",
    "BBBBGBBBBBN",
    "BBBBGBBBBBN",
    ".BBBDBBBBN.",
    ".BBBBBBBBN.",
    "..BBBBBBN..",
    "...BBBBN...",
    "....NNN....",
], 2, 2), "estate_adel – nobility: blue coat of arms with a gold sword")

ICONS["estate_klerus"] = (layer([
    ".....ww.....",
    "....wwwa....",
    "...wwGwaa...",
    "..wwwGwwaa..",
    "..wwGGGwaa..",
    "..wwwGwwaa..",
    "..wwwGwwaa..",
    "..wwwwwwaa..",
    "..YYYYYYDD..",
    "..wwwwwwaa..",
    "..aaaaaaaa..",
    "...R....R...",
    "...E....E...",
], 2, 1), "estate_klerus – clergy: white mitre with gold cross")

ICONS["estate_buerger"] = (layer([
    ".....RR.....",
    "....RRRE....",
    "...RRRRRE...",
    "..RRRRRRRE..",
    ".RRRRRRRRRE.",
    "..PPPPPPPQ..",
    "..PbPPPbPQ..",
    "..PNPPPNPQ..",
    "..PPPPPPPQ..",
    "..PbPHPbPQ..",
    "..PNHOHNPQ..",
    "..QQHOHQQQ..",
], 2, 2), "estate_buerger – burghers: gabled town house")

for key, (g, comment) in ICONS.items():
    write(os.path.join(OUT, key + ".txt"), g, comment + "\n16x16 grid, export x2 = 32 px. Generated by tools/art/gov_icons.py")
print(" ".join(ICONS))
