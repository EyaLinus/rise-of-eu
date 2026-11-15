#!/usr/bin/env python3
"""Generates the background music in assets/music/ (procedural, no samples, no third-party audio).

Everything is synthesised here from scratch (plucked lute/harp via Karplus-Strong, recorder, drone,
frame drum, synthetic reverb), so the result is our own work and free of any licence question.
Each track is composed from a seeded random generator: modal chord progressions, a short motif
that repeats with variations (AABA), arpeggiated accompaniment. Same seed = same file.

Output: OGG Vorbis q1, 32 kHz stereo, ~1 MB per track (1.5-2.5 minutes) (needs ffmpeg with libvorbis).

Usage: python3 tools/gen_music.py [--only NAME] [--wav]
"""
import argparse
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

RATE = 32000
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "music")

MODES = {
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "aeolian": [0, 2, 3, 5, 7, 8, 10],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "ionian": [0, 2, 4, 5, 7, 9, 11],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
}

# name, mood ("peace"/"war"), root midi, mode, bpm, beats per bar, seed, chord degree progressions,
# instruments
TRACKS = [
    dict(name="hof_im_fruehling", mood="peace", root=62, mode="dorian", bpm=84, beats=3, seed=11,
         progs=[[0, 6, 5, 6], [0, 3, 6, 0], [2, 3, 4, 0]], lead="recorder", acc="lute", drum=False),
    dict(name="pilgerweg", mood="peace", root=57, mode="aeolian", bpm=66, beats=4, seed=23,
         progs=[[0, 5, 2, 6], [0, 3, 4, 0], [5, 6, 0, 0]], lead="harp_hi", acc="harp", drum=False),
    dict(name="markttag", mood="peace", root=55, mode="mixolydian", bpm=104, beats=3, seed=37,
         progs=[[0, 6, 0, 4], [3, 0, 6, 0], [0, 3, 6, 4]], lead="recorder", acc="lute", drum=True),
    dict(name="abendlaute", mood="peace", root=60, mode="ionian", bpm=72, beats=4, seed=41,
         progs=[[0, 4, 5, 3], [0, 3, 4, 0], [5, 3, 4, 4]], lead="lute_hi", acc="harp", drum=False),
    dict(name="heerzug", mood="war", root=52, mode="phrygian", bpm=92, beats=4, seed=53,
         progs=[[0, 1, 0, 6], [0, 5, 6, 0], [3, 1, 0, 0]], lead="recorder_low", acc="lute", drum=True),
    dict(name="belagerung", mood="war", root=50, mode="aeolian", bpm=76, beats=4, seed=67,
         progs=[[0, 5, 6, 0], [0, 3, 4, 4], [5, 6, 4, 0]], lead="harp_hi", acc="lute", drum=True),
]


def midi_hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


# ---------------------------------------------------------------- instruments

def pluck(freq, dur, bright=0.5, decay=0.996, rng=None):
    """Karplus-Strong plucked string, vectorised one period at a time."""
    n = int(dur * RATE)
    period = max(2, int(RATE / freq))
    rng = rng or np.random.default_rng(0)
    buf = rng.uniform(-1, 1, period)
    # softer pluck: low-pass the excitation a few times
    for _ in range(int(3 * (1.0 - bright)) + 1):
        buf = 0.5 * (buf + np.roll(buf, 1))
    out = np.empty(n + period)
    out[:period] = buf
    i = period
    while i < n + period:
        prev = out[i - period:i]
        nxt = 0.5 * (prev + np.concatenate(([prev[-1]], prev[:-1]))) * decay
        k = min(period, n + period - i)
        out[i:i + k] = nxt[:k]
        i += k
    out = out[period:period + n]
    att = min(n, int(0.004 * RATE))
    out[:att] *= np.linspace(0, 1, att)
    rel = min(n, int(0.05 * RATE))
    out[-rel:] *= np.linspace(1, 0, rel)
    return out


def recorder(freq, dur, rng, vib=0.004):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    vibrato = 1.0 + vib * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.35, 0, 1)
    ph = 2 * np.pi * np.cumsum(freq * vibrato) / RATE
    s = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.07 * np.sin(3 * ph)
    noise = rng.normal(0, 1, n)
    noise = np.convolve(noise, np.ones(6) / 6, mode="same") * 0.04
    att = np.clip(t / 0.06, 0, 1)
    rel = np.clip((dur - t) / 0.12, 0, 1)
    return (s + noise) * att * rel * 0.55


def drone(freqs, dur):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    s = np.zeros(n)
    for f in freqs:
        for h, a in ((1, 1.0), (2, 0.35), (3, 0.18), (4, 0.08)):
            s += a * np.sin(2 * np.pi * f * h * t + h * 0.7) * (1 + 0.02 * np.sin(2 * np.pi * 0.13 * t * h))
    swell = 0.75 + 0.25 * np.sin(2 * np.pi * t / 9.0)
    return s / len(freqs) * swell * 0.12


def drum(dur, strong, rng):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    f = 70 + 60 * np.exp(-t * 30)
    body = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t * (9 if strong else 14))
    skin = rng.normal(0, 1, n) * np.exp(-t * 60) * 0.25
    skin = np.convolve(skin, np.ones(4) / 4, mode="same")
    return (body + skin) * (0.55 if strong else 0.32)


# ---------------------------------------------------------------- composition

def scale_note(spec, degree, octave=0):
    mode = MODES[spec["mode"]]
    o, d = divmod(degree, 7)
    return spec["root"] + mode[d] + 12 * (o + octave)


def chord(spec, deg):
    return [scale_note(spec, deg), scale_note(spec, deg + 2), scale_note(spec, deg + 4)]


def make_motif(rng, beats, chord_deg):
    """One bar of melody as (beat_offset, length, scale degree) relative to the chord root."""
    patterns = {
        3: [[1, 1, 1], [2, 1], [1, 0.5, 0.5, 1], [1.5, 0.5, 1], [3]],
        4: [[1, 1, 1, 1], [2, 1, 1], [1, 0.5, 0.5, 2], [1.5, 0.5, 2], [2, 2], [1, 1, 2]],
    }[beats]
    rhythm = patterns[rng.integers(len(patterns))]
    notes = []
    pos = 0.0
    deg = int(rng.choice([0, 2, 4]))
    for i, ln in enumerate(rhythm):
        if i > 0:
            step = int(rng.choice([-2, -1, -1, 1, 1, 2, 0]))
            deg = int(np.clip(deg + step, -2, 9))
        if pos == 0:  # strong beat: a chord tone
            deg = min((0, 2, 4, 7), key=lambda c: abs(c - deg))
        notes.append((pos, ln, deg))
        pos += ln
    return notes


def vary(rng, motif):
    out = []
    for pos, ln, deg in motif:
        if pos > 0 and rng.random() < 0.35:
            deg = int(np.clip(deg + rng.choice([-1, 1]), -2, 9))
        out.append((pos, ln, deg))
    return out


def compose(spec):
    rng = np.random.default_rng(spec["seed"])
    beat = 60.0 / spec["bpm"]
    bar = beat * spec["beats"]
    progs = spec["progs"]
    # form: A A B A A' C (each section = one 4-bar progression played twice)
    form = [0, 0, 1, 0, 2, 0]
    motifs = {}
    events = []  # (time, kind, payload)
    t = 2.0  # quiet drone lead-in
    section_bars = 8 if bar < 2.4 else 4  # keep tracks around two minutes
    for si, sec in enumerate(form):
        prog = progs[sec]
        if sec not in motifs:
            motifs[sec] = [make_motif(rng, spec["beats"], d) for d in prog]
        mot = motifs[sec] if si != 4 else [vary(rng, m) for m in motifs[sec]]
        sparse = si == 0  # first section: accompaniment only in the first half
        for b in range(section_bars):
            deg = prog[b % 4]
            bt = t + b * bar
            events.append((bt, "drone", (deg, bar)))
            # accompaniment: broken chord
            ch = chord(spec, deg)
            arp = [ch[0] - 12, ch[1], ch[2], ch[1]] if spec["beats"] == 4 else [ch[0] - 12, ch[1], ch[2]]
            sub = 2 if spec["bpm"] < 90 else 1
            steps = spec["beats"] * sub
            for k in range(steps):
                m = arp[k % len(arp)]
                events.append((bt + k * beat / sub, "acc", (m, beat / sub * 2.5, 0.8 if k == 0 else 0.5)))
            if spec["drum"]:
                events.append((bt, "drum", True))
                if spec["beats"] == 4:
                    events.append((bt + 2 * beat, "drum", False))
                    events.append((bt + 3.5 * beat, "drum", False))
                else:
                    events.append((bt + 2 * beat, "drum", False))
            if sparse and b < section_bars // 2:
                continue
            for pos, ln, md in mot[b % 4]:
                m = scale_note(spec, deg + md, 1)
                events.append((bt + pos * beat, "lead", (m, ln * beat * 0.95)))
        t += section_bars * bar
    total = t + 4.0
    return events, total


# ---------------------------------------------------------------- mixing

def add(buf, start, sig, pan=0.0, gain=1.0):
    i = int(start * RATE)
    if i >= buf.shape[1]:
        return
    sig = sig[: buf.shape[1] - i]
    l = np.cos((pan + 1) * np.pi / 4) * gain
    r = np.sin((pan + 1) * np.pi / 4) * gain
    buf[0, i:i + len(sig)] += sig * l
    buf[1, i:i + len(sig)] += sig * r


def reverb(buf, rng, seconds=2.2, wet=0.22):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    out = np.empty_like(buf)
    size = 1 << int(np.ceil(np.log2(buf.shape[1] + n)))
    for ch in range(2):
        ir = rng.normal(0, 1, n) * np.exp(-t * 6.9 / seconds)
        ir = np.convolve(ir, np.ones(8) / 8, mode="same")  # darker tail
        ir[: int(0.012 * RATE)] = 0  # pre-delay
        ir /= np.sqrt(np.sum(ir ** 2))
        wetsig = np.fft.irfft(np.fft.rfft(buf[ch], size) * np.fft.rfft(ir, size), size)[: buf.shape[1]]
        out[ch] = buf[ch] + wet * wetsig
    return out


def render(spec):
    rng = np.random.default_rng(spec["seed"] + 1000)
    events, total = compose(spec)
    buf = np.zeros((2, int(total * RATE) + RATE))
    for t, kind, payload in events:
        if kind == "drone":
            continue  # one continuous drone below, so bar lines never click
        elif kind == "acc":
            m, ln, vel = payload
            f = midi_hz(m)
            if spec["acc"] == "harp":
                sig = pluck(f, ln + 1.2, bright=0.6, decay=0.998, rng=rng)
            else:
                sig = pluck(f, ln + 0.6, bright=0.35, decay=0.994, rng=rng)
            add(buf, t + rng.normal(0, 0.006), sig, -0.35, 0.33 * vel)
        elif kind == "lead":
            m, ln = payload
            f = midi_hz(m)
            lead = spec["lead"]
            if lead == "recorder":
                sig = recorder(f, ln, rng)
            elif lead == "recorder_low":
                sig = recorder(f / 2, ln, rng, vib=0.006)
            elif lead == "lute_hi":
                sig = pluck(f, ln + 0.8, bright=0.55, decay=0.996, rng=rng) * 0.9
            else:
                sig = pluck(f, ln + 1.4, bright=0.75, decay=0.998, rng=rng) * 0.85
            add(buf, t, sig, 0.3, 0.42)
        elif kind == "drum":
            add(buf, t, drum(0.6, payload, rng), 0.1, 0.5)
    f = midi_hz(scale_note(spec, 0, -1))
    dr = drone([f, f * 1.5], total - 0.5)
    k = int(1.5 * RATE)
    dr[:k] *= np.linspace(0, 1, k)
    dr[-k:] *= np.linspace(1, 0, k)
    add(buf, 0.5, dr, 0.0, 0.8 if spec["mood"] == "war" else 0.6)
    buf = reverb(buf, rng)
    # fades so tracks start/end softly and can follow each other with a pause
    fi, fo = int(2.0 * RATE), int(5.0 * RATE)
    buf[:, :fi] *= np.linspace(0, 1, fi)
    buf[:, -fo:] *= np.linspace(1, 0, fo)
    buf *= 0.13 / np.sqrt(np.mean(buf ** 2))  # same loudness for every track
    peak = np.max(np.abs(buf))
    if peak > 0.9:  # headroom; the game sets the volume
        buf *= 0.9 / peak
    return buf


def write_wav(path, buf):
    data = (np.clip(buf.T, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    ap.add_argument("--wav", action="store_true", help="also keep the WAV next to the OGG (for inspection)")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for spec in TRACKS:
        if args.only and spec["name"] != args.only:
            continue
        buf = render(spec)
        ogg = os.path.join(OUT, spec["name"] + ".ogg")
        with tempfile.TemporaryDirectory() as tmp:
            wav = os.path.join(tmp, "t.wav")
            write_wav(wav, buf)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "1",
                            ogg], check=True)
            if args.wav:
                write_wav(os.path.join(OUT, spec["name"] + ".wav"), buf)
        rms = float(np.sqrt(np.mean(buf ** 2)))
        print("%-18s %5.1fs  rms %.3f  %4d KB" % (spec["name"], buf.shape[1] / RATE, rms,
                                                   os.path.getsize(ogg) // 1024))
    return 0


if __name__ == "__main__":
    sys.exit(main())
