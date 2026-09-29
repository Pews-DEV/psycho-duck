"""Gera os efeitos sonoros placeholder do Psycho Duck (estilo sfxr, Python puro).

Uso: python tools/make_sfx.py
Saída: assets/audio/sfx/<nome>.wav (mono, 16 bits, 22050 Hz).
Para trocar um som por um próprio, substitua o .wav mantendo o nome.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")


# --- Osciladores ------------------------------------------------------------------

def _wave(kind, phase, duty=0.5):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < duty else -1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "triangle":
        return 4.0 * abs(p - 0.5) - 1.0
    return math.sin(2 * math.pi * p)  # sine


def tone(kind, f0, f1, dur, vol=0.5, attack=0.005, curve=1.5, duty=0.5, vibrato=0.0, vib_rate=0.0):
    """Tom com varredura de f0 a f1 e envelope de decaimento."""
    n = int(dur * RATE)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        freq = f0 + (f1 - f0) * t
        if vibrato:
            freq *= 1.0 + vibrato * math.sin(2 * math.pi * vib_rate * i / RATE)
        phase += freq / RATE
        env = min(1.0, i / max(1, attack * RATE)) * (1.0 - t) ** curve
        out.append(_wave(kind, phase, duty) * env * vol)
    return out


def noise(dur, vol=0.5, smooth=0.0, curve=1.5, attack=0.002, seed=None):
    """Ruído branco com passa-baixa simples (smooth de 0 a ~0.98)."""
    rng = random.Random(seed)
    n = int(dur * RATE)
    out = []
    last = 0.0
    for i in range(n):
        t = i / n
        sample = rng.uniform(-1, 1)
        last = last * smooth + sample * (1.0 - smooth)
        env = min(1.0, i / max(1, attack * RATE)) * (1.0 - t) ** curve
        out.append(last * env * vol * (1.0 + smooth * 2))
    return out


def notes(freqs, each, kind="square", vol=0.35, gap=0.0, curve=1.2, duty=0.5):
    """Sequência de notas (arpejo / fanfarra)."""
    out = []
    for f in freqs:
        out += tone(kind, f, f, each, vol, curve=curve, duty=duty)
        out += silence(gap)
    return out


def silence(dur):
    return [0.0] * int(dur * RATE)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def delay(track, seconds):
    return silence(seconds) + track


def save(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = min(1.0, 0.95 / peak)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))


# --- Notas --------------------------------------------------------------------------
C5, D5, E5, F5, G5, A5, B5, C6, E6, G6 = 523, 587, 659, 698, 784, 880, 988, 1047, 1319, 1568


SOUNDS = {
    # Pato
    "shoot": lambda: mix(tone("square", 950, 280, 0.09, 0.35, duty=0.3, curve=2), noise(0.03, 0.15, 0.3, seed=1)),
    "jump": lambda: tone("square", 260, 620, 0.12, 0.3, duty=0.25, curve=1),
    "land": lambda: noise(0.06, 0.35, 0.85, curve=2, seed=2),
    "player_hurt": lambda: mix(tone("saw", 320, 90, 0.25, 0.4, curve=1.2), noise(0.15, 0.3, 0.5, seed=3)),
    "player_death": lambda: mix(tone("saw", 420, 40, 0.9, 0.45, curve=0.8, vibrato=0.08, vib_rate=14), noise(0.5, 0.25, 0.7, seed=4)),
    # Inimigos
    "enemy_hit": lambda: mix(tone("square", 420, 180, 0.06, 0.3, duty=0.5, curve=2), noise(0.04, 0.25, 0.4, seed=5)),
    "crit_hit": lambda: mix(tone("square", 900, 300, 0.09, 0.35, duty=0.25, curve=1.5), noise(0.06, 0.3, 0.2, seed=6)),
    "enemy_death": lambda: mix(noise(0.28, 0.5, 0.75, curve=1.3, seed=7), tone("square", 320, 50, 0.22, 0.3, curve=1.5)),
    "elite_death": lambda: mix(noise(0.5, 0.55, 0.85, curve=1.1, seed=8), tone("saw", 260, 35, 0.45, 0.35, curve=1.2)),
    "enemy_shoot": lambda: tone("square", 520, 330, 0.07, 0.2, duty=0.5, curve=2),
    "sniper_charge": lambda: tone("sine", 220, 960, 0.9, 0.25, attack=0.3, curve=0.3),
    "sniper_shot": lambda: mix(tone("square", 1600, 350, 0.16, 0.35, duty=0.15, curve=1.8), noise(0.12, 0.3, 0.1, seed=9)),
    "skimmer_warn": lambda: notes([1100, 0, 1100], 0.06, vol=0.3),
    "orb_drop": lambda: tone("sine", 700, 260, 0.22, 0.4, curve=1.2),
    "puddle": lambda: mix(noise(0.35, 0.35, 0.9, curve=1, seed=10), tone("sine", 180, 90, 0.3, 0.2)),
    "carrier_spawn": lambda: notes([220, 330, 440], 0.07, kind="square", vol=0.25, duty=0.25),
    "boss_appear": lambda: mix(tone("saw", 90, 45, 1.3, 0.45, attack=0.2, curve=0.6, vibrato=0.1, vib_rate=7), noise(1.0, 0.2, 0.95, curve=0.8, seed=11)),
    "boss_attack": lambda: mix(tone("square", 170, 120, 0.22, 0.3, duty=0.3, curve=1.2), noise(0.15, 0.2, 0.6, seed=12)),
    "boss_death": lambda: mix(noise(1.2, 0.6, 0.9, curve=0.9, seed=13), tone("saw", 200, 30, 1.1, 0.4, curve=0.9), delay(noise(0.5, 0.4, 0.8, seed=14), 0.3)),
    # Coletas
    "soul_pickup": lambda: notes([E6, G6], 0.05, kind="square", vol=0.22, duty=0.25),
    "heal_pickup": lambda: notes([C5, E5, G5, C6], 0.06, kind="triangle", vol=0.4),
    # Poste
    "pole_laser": lambda: mix(tone("sine", 1900, 650, 0.09, 0.3, curve=1.4), tone("square", 950, 320, 0.09, 0.12, duty=0.1)),
    "pole_build": lambda: mix(tone("square", 180, 820, 0.4, 0.3, duty=0.3, curve=0.8), delay(notes([C6, E6, G6], 0.05, vol=0.2), 0.3)),
    # Interface
    "ui_hover": lambda: tone("square", 1250, 1250, 0.025, 0.12, duty=0.25, curve=2),
    "ui_click": lambda: tone("square", 820, 620, 0.05, 0.25, duty=0.25, curve=1.5),
    "card_pick": lambda: notes([E5, A5, E6], 0.06, kind="square", vol=0.28, duty=0.25),
    "buy": lambda: notes([B5, E6], 0.07, kind="square", vol=0.3, duty=0.25),
    "deny": lambda: notes([150, 0, 150], 0.07, kind="square", vol=0.3),
    "reroll": lambda: mix(noise(0.18, 0.2, 0.6, seed=15), delay(tone("square", 500, 1000, 0.1, 0.25, duty=0.25), 0.08)),
    "door": lambda: mix(noise(0.08, 0.45, 0.9, curve=2, seed=16), delay(noise(0.08, 0.45, 0.9, curve=2, seed=17), 0.14)),
    # Partida
    "wave_start": lambda: notes([G5, C6, G6], 0.08, kind="square", vol=0.3, duty=0.25),
    "wave_clear": lambda: notes([C5, E5, G5, C6, E6], 0.07, kind="square", vol=0.3, duty=0.5),
    "arena_grow": lambda: mix(noise(1.4, 0.5, 0.97, curve=0.7, seed=18), tone("saw", 60, 40, 1.3, 0.3, attack=0.2, curve=0.8)),
    "skin_unlock": lambda: notes([C5, E5, G5, C6, G5, C6, E6], 0.08, kind="square", vol=0.3, duty=0.25),
    "game_over": lambda: notes([G5, E5, C5, 392], 0.22, kind="triangle", vol=0.45, curve=0.8),
}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, build in SOUNDS.items():
        save(name, build())
    print(f"{len(SOUNDS)} sons em {os.path.abspath(OUT)}")
