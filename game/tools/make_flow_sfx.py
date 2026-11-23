"""Synthesises the small placeholder SFX set used by the opening flow.
Run: python3 tools/make_flow_sfx.py  -> assets/reclaim/audio/*.wav
These are TEMPORARY procedural sounds (not final audio)."""
import wave
from pathlib import Path

import numpy as np

SR = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "reclaim" / "audio"
rng = np.random.default_rng(7)


def save(name: str, data: np.ndarray) -> None:
    data = np.clip(data / max(1e-6, np.abs(data).max()) * 0.85, -1, 1)
    pcm = (data * 32767).astype(np.int16)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    print(name, len(pcm) / SR, "s")


def lowpass(x: np.ndarray, a: float) -> np.ndarray:
    y = np.zeros_like(x); acc = 0.0
    for i, v in enumerate(x):
        acc += a * (v - acc); y[i] = acc
    return y


def rotor_loop() -> np.ndarray:
    # 2.0 s seamless loop: blade "thwop" at 9 Hz on top of filtered turbine noise.
    n = int(SR * 2.0); t = np.arange(n) / SR
    noise = lowpass(rng.standard_normal(n), 0.08)
    phase = (t * 9.0) % 1.0
    pulse = np.exp(-phase * 9.0)
    thwop = noise * (0.25 + 1.4 * pulse) + 0.5 * np.sin(2 * np.pi * 9.0 * t * 6) * pulse
    whine = 0.05 * np.sin(2 * np.pi * 420 * t)
    return thwop + whine


def thump() -> np.ndarray:
    n = int(SR * 0.7); t = np.arange(n) / SR
    body = np.sin(2 * np.pi * (70 - 40 * t) * t) * np.exp(-t * 7)
    grit = lowpass(rng.standard_normal(n), 0.15) * np.exp(-t * 10) * 0.6
    return body + grit


def click() -> np.ndarray:
    n = int(SR * 0.09); t = np.arange(n) / SR
    return np.sin(2 * np.pi * 1300 * t) * np.exp(-t * 60) + 0.4 * np.sin(2 * np.pi * 2600 * t) * np.exp(-t * 90)


def confirm() -> np.ndarray:
    n = int(SR * 0.35); t = np.arange(n) / SR
    f = np.where(t < 0.12, 660, 990)
    return np.sin(2 * np.pi * f * t) * np.exp(-((t % 0.12) * 14)) * 0.8


def build() -> np.ndarray:
    # three hammer taps + canvas flap
    n = int(SR * 1.1); out = np.zeros(n)
    for k, start in enumerate((0.0, 0.28, 0.56)):
        s = int(start * SR); m = int(0.18 * SR); tt = np.arange(m) / SR
        tap = (np.sin(2 * np.pi * (900 - 200 * k) * tt) * 0.6 + rng.standard_normal(m) * 0.5) * np.exp(-tt * 38)
        out[s:s + m] += tap
    s = int(0.8 * SR); m = n - s; tt = np.arange(m) / SR
    out[s:] += lowpass(rng.standard_normal(m), 0.2) * np.exp(-tt * 9) * 0.8
    return out


def wind() -> np.ndarray:
    n = int(SR * 3.0); t = np.arange(n) / SR
    w = lowpass(rng.standard_normal(n), 0.02) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.33 * t))
    fade = np.minimum(1, np.minimum(t / 0.3, (3.0 - t) / 0.3))
    return w * fade


def radio() -> np.ndarray:
    n = int(SR * 0.45); t = np.arange(n) / SR
    burst = rng.standard_normal(n) * np.exp(-t * 6)
    beep = np.sin(2 * np.pi * 1800 * t) * (t < 0.08)
    return lowpass(burst, 0.5) * 0.6 + beep


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    save("rotor_loop.wav", rotor_loop())
    save("land_thump.wav", thump())
    save("ui_click.wav", click())
    save("ui_confirm.wav", confirm())
    save("hq_build.wav", build())
    save("wind.wav", wind())
    save("radio.wav", radio())
