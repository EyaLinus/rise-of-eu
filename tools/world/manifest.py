#!/usr/bin/env python3
"""Adds missing flag entries of the world regions to assets/manifest.yaml (appended, file format kept)."""
import datetime
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import world  # noqa: E402

path = os.path.join(ROOT, "assets", "manifest.yaml")
text = open(path, encoding="utf-8").read()
today = datetime.date.today().isoformat()
add = ""
for r in world.REGIONS:
    for tag in r.NATIONS:
        if "  flag_%s:\n" % tag in text:
            continue
        add += ("  flag_{t}:\n    created: '{d}'\n    kind: flag\n    note: flag_{t} (tools/art/flags.py, tools/world/{m}.py)\n"
                "    outputs:\n    - assets/art/icons/flag_{t}.png\n    source: assets/src/pixel/flags/flag_{t}.txt\n    status: done\n"
                "    updated: '{d}'\n").format(t=tag, d=today, m=r.__name__.split(".")[-1])
if add:
    open(path, "a", encoding="utf-8").write(add)
print(add.count("kind: flag"), "flags added to the manifest")
