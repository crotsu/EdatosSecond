"""
Edatos の効果音を合成するスクリプト．

  Edatos/data/explosion.wav … 敵を倒したときの爆発音
  Edatos/data/homing.wav    … ホーミングレーザーの発射音
  Edatos/data/shot.wav      … 自機のレーザーの発射音

BGM に合わせて，どれもファミコン風の音にしている．

使い方:  python3 tools/make_se.py
必要なもの: numpy
"""

import wave
from pathlib import Path

import numpy as np

SR = 22050
DATA = Path(__file__).resolve().parent.parent / "Edatos" / "data"


def write_wav(path, sig):
    sig = sig / np.max(np.abs(sig)) * 0.9  # 音割れしないように音量をそろえる
    pcm = (sig * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"{path} を書き出しました（{len(sig) / SR:.2f} 秒）")


def explosion(length=0.75, seed=3):
    """爆発音．ノイズの音程（ノイズを切り替える速さ）をだんだん下げて
    「ドカーン」と低く消えていく音に，低い「ドン」という衝撃音を重ねる．"""
    n = int(length * SR)
    t = np.arange(n) / SR
    rng = np.random.default_rng(seed)

    # 1. ファミコン風のノイズ：一定の間隔でランダムな値に切り替える．
    #    切り替える間隔をだんだん長くすると，ノイズの音程が下がっていく
    rate = 9000 * np.exp(-t * 4.5) + 400  # 1秒あたりの切り替え回数
    phase = np.cumsum(rate / SR)
    steps = np.floor(phase).astype(int)
    values = rng.uniform(-1, 1, steps[-1] + 1)
    noise = values[steps]

    # 低域だけを通すフィルタで，時間とともにこもった音にする
    cutoff = 6000 * np.exp(-t * 5) + 300
    alpha = 1 - np.exp(-2 * np.pi * cutoff / SR)
    filtered = np.zeros(n)
    y = 0.0
    for i in range(n):
        y += alpha[i] * (noise[i] - y)
        filtered[i] = y

    # 音量：一瞬で最大になり，ゆっくり消える
    env = np.minimum(t / 0.003, 1) * np.exp(-t * 5.5)
    body = filtered * env

    # 2. 衝撃音：周波数が急に下がる低いサイン波（ドン）
    f = 40 + 140 * np.exp(-t * 25)
    thump = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 12)

    sig = 0.9 * body + 0.7 * thump
    # 最後の 20ms は0へ向けて小さくし，プツッという音を防ぐ
    fade = int(0.02 * SR)
    sig[-fade:] *= np.linspace(1, 0, fade)
    return sig


def homing(length=0.5):
    """ホーミングレーザーの発射音．
    弾が機体の下へ飛び出して止まる動きに合わせて音程を下げ，
    そこから敵へ加速する動きに合わせて音程を一気に上げる（ヒュン…シュイーン）．"""
    n = int(length * SR)
    t = np.arange(n) / SR
    turn = 0.16  # 音程が下がり切って，上がり始めるまでの時間（秒）

    # 音程の動き：turnまでは下がり，そのあと急に上がる
    f = np.where(t < turn,
                 900 * np.exp(-t * 6),
                 900 * np.exp(-turn * 6) * np.exp((t - turn) * 7))

    # パルス波（デューティ25%）．ファミコンらしい細い音
    phase = np.cumsum(f / SR) % 1
    pulse = np.where(phase < 0.25, 1.0, -1.0)

    # ビブラートの代わりに，2つの音を少しずらして重ね，うなりでキラキラさせる
    phase2 = np.cumsum(f * 1.5 / SR) % 1
    pulse2 = np.where(phase2 < 0.5, 1.0, -1.0)

    # 「シュー」という風の音：高い音だけ残したノイズを，上がり始めから強くする
    rng = np.random.default_rng(11)
    noise = np.diff(rng.uniform(-1, 1, n + 1))
    whoosh = noise * np.clip((t - turn) / 0.15, 0, 1)

    # 音量：発射の瞬間は強く，下がりきったところで小さく，上がりながら少し戻って消える
    env = np.where(t < turn,
                   np.exp(-t * 6),
                   np.exp(-turn * 6) + 0.5 * np.sin(np.pi * np.clip((t - turn) / (length - turn), 0, 1)))
    env = env * np.minimum(t / 0.003, 1)

    sig = (0.6 * pulse + 0.25 * pulse2 + 0.25 * whoosh) * env
    fade = int(0.03 * SR)
    sig[-fade:] *= np.linspace(1, 0, fade)
    return sig


def shot(length=0.12):
    """自機のレーザーの発射音．何度も鳴るので，短く軽い「ピュン」にする．
    高い音程から一気に下げると，弾が飛んでいくように聞こえる．"""
    n = int(length * SR)
    t = np.arange(n) / SR

    # 音程：1800Hzから急に下がる
    f = 300 + 1500 * np.exp(-t * 30)

    # パルス波（デューティ50%と12.5%を重ねて，少し鋭い音にする）
    phase = np.cumsum(f / SR) % 1
    sig = 0.7 * np.where(phase < 0.5, 1.0, -1.0) + 0.3 * np.where(phase < 0.125, 1.0, -1.0)

    # 音量：一瞬で最大になり，すぐ消える
    env = np.minimum(t / 0.002, 1) * np.exp(-t * 28)
    sig = sig * env
    fade = int(0.01 * SR)
    sig[-fade:] *= np.linspace(1, 0, fade)
    return sig


write_wav(DATA / "explosion.wav", explosion())
write_wav(DATA / "homing.wav", homing())
write_wav(DATA / "shot.wav", shot())
