//-------------------------------------------------------------
// 音（BGMと効果音）
// Javaに最初から入っている音声の機能（javax.sound.sampled）を使うので，
// Processingに追加のライブラリを入れなくても鳴らせる．
//   bgm.wav       … tools/make_bgm.py で作っている
//   explosion.wav … tools/make_se.py で作っている
//   homing.wav    … tools/make_se.py で作っている
//   shot.wav      … tools/make_se.py で作っている
//-------------------------------------------------------------

import javax.sound.sampled.*;

Clip bgm;              // BGMの音声データ
float bgmVolume = -10; // BGMの音量（デシベル）．0が元の大きさで，マイナスにするほど小さくなる

SoundEffect explosionSound; // 敵を倒したときの爆発音
SoundEffect homingSound;    // ホーミングレーザーの発射音
SoundEffect shotSound;      // 自機のレーザーの発射音

// dataフォルダの音声ファイルを読み込み，音量を設定する．読み込めなければnullを返す
Clip loadSound(String fileName, float volume) {
  try {
    AudioInputStream stream = AudioSystem.getAudioInputStream(new File(dataPath(fileName)));
    Clip clip = AudioSystem.getClip();
    clip.open(stream);
    FloatControl gain = (FloatControl) clip.getControl(FloatControl.Type.MASTER_GAIN);
    gain.setValue(volume);
    return clip;
  }
  catch (Exception e) {
    // 音が出せない環境でもゲームは遊べるように，エラーを表示するだけにする
    println(fileName + " を読み込めませんでした: " + e);
    return null;
  }
}

// 音を読み込んで，BGMのくり返し再生を始める（setupで1度だけ呼ぶ）
void startSound() {
  explosionSound = new SoundEffect("explosion.wav", 4, -4); // 敵を続けて倒すことがあるので4つ
  homingSound    = new SoundEffect("homing.wav", 2, -6);
  shotSound      = new SoundEffect("shot.wav", 3, -14);   // 何度も鳴るので小さめにする
  bgm = loadSound("bgm.wav", bgmVolume);
  if (bgm != null) {
    bgm.loop(Clip.LOOP_CONTINUOUSLY); // ずっとくり返す
  }
}

//-------------------------------------------------------------
// 効果音
// 1つのClipは同時に1回しか鳴らせないので，同じ音を何個か用意して順番に使う．
// これで，続けて鳴らしても前の音が途切れずに重なって聞こえる．
//-------------------------------------------------------------
class SoundEffect {
  Clip[] clips; // 同じ音を何個か用意しておく
  int next;     // 次に使うClipの番号

  // fileName: dataフォルダの音声ファイル名，count: 同時に鳴らせる数，volume: 音量（デシベル）
  SoundEffect(String fileName, int count, float volume) {
    clips = new Clip[count];
    for (int i=0; i<count; i++) {
      clips[i] = loadSound(fileName, volume);
    }
    next = 0;
  }

  // 音を鳴らす
  void play() {
    Clip clip = clips[next];
    next = (next + 1) % clips.length; // 次は隣のClipを使う
    if (clip != null) {
      clip.stop();
      clip.setFramePosition(0); // 頭から鳴らす
      clip.start();
    }
  }
}
