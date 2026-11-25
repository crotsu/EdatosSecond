"""
Edatos の BGM（Edatos/data/bgm.wav）を合成するスクリプト．

ファミコン風の音（矩形波のメロディ，三角波のベース，ノイズのドラム）で
16小節のオリジナル曲を作り，ループ再生しても継ぎ目が目立たない WAV を書き出す．

使い方:  python3 tools/make_bgm.py
必要なもの: numpy
"""

import wave
from pathlib import Path

import numpy as np

SR = 22050          # サンプリング周波数
BPM = 150           # テンポ
STEP = 60 / BPM / 4 # 16分音符1つの長さ（秒）
BARS = 16
STEPS = BARS * 16   # 曲全体の16分音符の数
N = int(round(STEPS * STEP * SR))

OUT = Path(__file__).resolve().parent.parent / "Edatos" / "data" / "bgm.wav"

NOTE_INDEX = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
              "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def freq(name):
    """'A4' や 'G#5' を周波数（Hz）にする．"""
    pitch, octave = name[:-1], int(name[-1])
    midi = 12 * (octave + 1) + NOTE_INDEX[pitch]
    return 440.0 * 2 ** ((midi - 69) / 12)


def pos(step):
    return int(round(step * STEP * SR))


def square(f, n, duty=0.5):
    """帯域制限した矩形波（パルス波）．ナイキスト周波数以下の倍音だけを足す．"""
    t = np.arange(n) / SR
    out = np.full(n, duty * 2 - 1.0)
    k = 1
    while k * f < SR * 0.45:
        out += (4 / (k * np.pi)) * np.sin(np.pi * k * duty) * np.cos(2 * np.pi * k * f * t - np.pi * k * duty)
        k += 1
    return out * 0.5


def triangle(f, n):
    t = np.arange(n) / SR
    return 2 * np.abs(2 * ((t * f) % 1) - 1) - 1


def envelope(n, attack=0.005, release=0.03, decay_to=0.7):
    """アタック → 少し減衰 → 最後にリリースで0へ．プツッというノイズを防ぐ．"""
    env = np.ones(n)
    a = min(int(attack * SR), n)
    r = min(int(release * SR), n - a)
    env[:a] = np.linspace(0, 1, a, endpoint=False)
    body = n - a - r
    if body > 0:
        env[a:a + body] = np.linspace(1, decay_to, body)
    if r > 0:
        env[n - r:] = np.linspace(env[n - r - 1] if n - r - 1 >= 0 else 1, 0, r)
    return env


def add(buf, start, sig):
    """bufのstartの位置に音を足す．曲の最後からはみ出した分（余韻）は曲の頭に重ねて，
    ループ再生したときの継ぎ目を自然にする．"""
    end = min(start + len(sig), len(buf))
    buf[start:end] += sig[:end - start]
    rest = sig[end - start:]
    if len(rest) > 0:
        buf[:len(rest)] += rest


# ---------------- 曲のデータ ----------------
# コード進行（2小節ずつ）: Am F G Em / Am F G E
CHORDS = [
    ("A2", ["A3", "C4", "E4"]), ("F2", ["F3", "A3", "C4"]),
    ("G2", ["G3", "B3", "D4"]), ("E2", ["E3", "G3", "B3"]),
    ("A2", ["A3", "C4", "E4"]), ("F2", ["F3", "A3", "C4"]),
    ("G2", ["G3", "B3", "D4"]), ("E2", ["E3", "G#3", "B3"]),
]

# メロディ: "音名:長さ（16分音符の数）"，r は休符．1小節 = 16
MELODY = """
E5:4 A5:4 G5:2 E5:2 D5:2 E5:2 | C5:4 D5:2 E5:6 r:4 |
F5:4 E5:2 D5:2 C5:4 A4:4 | C5:2 D5:2 C5:2 A4:2 C5:8 |
D5:4 G5:4 F5:2 D5:2 B4:2 D5:2 | G5:6 F5:2 D5:4 B4:4 |
E5:4 G5:2 B5:6 A5:2 G5:2 | E5:12 r:4 |
A5:2 G5:2 E5:4 A5:2 G5:2 E5:4 | C6:4 B5:4 A5:4 E5:4 |
F5:2 A5:2 C6:4 A5:2 F5:2 C5:4 | D5:2 E5:2 F5:4 E5:4 C5:4 |
G5:2 B5:2 D6:4 B5:2 G5:2 D5:4 | F5:4 E5:4 D5:4 B4:4 |
G#5:4 B5:4 E6:4 D6:2 B5:2 | G#5:8 B5:4 E5:4
"""


def parse_melody(text):
    notes, step = [], 0
    for bar in text.replace("\n", " ").split("|"):
        bar_len = 0
        for token in bar.split():
            name, length = token.split(":")
            length = int(length)
            if name != "r":
                notes.append((name, step, length))
            step += length
            bar_len += length
        assert bar_len == 16, f"1小節が16になっていない: {bar}"
    assert step == STEPS
    return notes


# ---------------- 合成 ----------------
lead = np.zeros(N)
arp = np.zeros(N)
bass = np.zeros(N)
drums = np.zeros(N)

# メロディ（矩形波 50%，少しビブラート気味に2つの矩形波を僅かにずらして重ねる）
for name, step, length in parse_melody(MELODY):
    n = pos(step + length) - pos(step)
    f = freq(name)
    sig = 0.6 * square(f, n, 0.5) + 0.4 * square(f * 1.003, n, 0.5)
    add(lead, pos(step), sig * envelope(n, release=0.02, decay_to=0.6))

for i, (root, chord) in enumerate(CHORDS):
    bar0 = i * 32  # 2小節 = 32ステップ
    # 分散和音（パルス波 25%，16分音符でコードの音を上がり下がり）
    pattern = [0, 1, 2, 1]
    for s in range(32):
        note = chord[pattern[s % 4]]
        f = freq(note) * 2  # 1オクターブ上で鳴らす
        n = pos(bar0 + s + 1) - pos(bar0 + s)
        add(arp, pos(bar0 + s), square(f, n, 0.25) * envelope(n, release=0.02, decay_to=0.2))
    # ベース（三角波，8分音符でオクターブを行き来する）
    for s in range(0, 32, 2):
        f = freq(root) * (2 if (s // 2) % 2 else 1)
        n = pos(bar0 + s + 2) - pos(bar0 + s)
        add(bass, pos(bar0 + s), triangle(f, n) * envelope(n, release=0.02, decay_to=0.8))

# ドラム
rng = np.random.default_rng(7)
for beat in range(BARS * 4):
    s = beat * 4
    # キック（1拍目と3拍目）：周波数が急に下がるサイン波
    if beat % 2 == 0:
        n = int(0.15 * SR)
        t = np.arange(n) / SR
        f = 50 + 120 * np.exp(-t * 35)
        kick = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 18)
        add(drums, pos(s), kick * 1.0)
    # スネア（2拍目と4拍目）：ノイズ + 短い音程
    else:
        n = int(0.13 * SR)
        t = np.arange(n) / SR
        snare = (rng.uniform(-1, 1, n) * 0.7 + np.sin(2 * np.pi * 190 * t) * 0.3) * np.exp(-t * 25)
        add(drums, pos(s), snare * 0.55)
    # ハイハット（8分音符）：とても短いノイズ
    for off in (0, 2):
        n = int(0.03 * SR)
        hat = np.diff(rng.uniform(-1, 1, n + 1)) * np.exp(-np.arange(n) / SR * 120)
        add(drums, pos(s + off), hat * 0.18)

mix = 0.30 * lead + 0.10 * arp + 0.32 * bass + 0.45 * drums

mix = mix / np.max(np.abs(mix)) * 0.8  # 音割れしないように音量をそろえる

pcm = (mix * 32767).astype(np.int16)
OUT.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(OUT), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())

print(f"{OUT} を書き出しました（{N / SR:.1f} 秒）")
