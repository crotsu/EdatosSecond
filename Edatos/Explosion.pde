//-------------------------------------------------------------
// 敵を倒したときの爆発
// 「白い閃光」「火の玉」「広がる衝撃波の輪」「飛び散る火花」の4つを重ねて描く．
// 画像は使わず，図形で描く．
//-------------------------------------------------------------

class Explosion {
  float x, y;          // 爆発の中心座標
  int age;             // 爆発してからの経過フレーム数
  int lifeTime;        // 爆発が続く時間（フレーム数）
  ArrayList<Spark> sparks; // 飛び散る火花

  // コンストラクタ．(ex, ey)の位置で爆発する
  Explosion(float ex, float ey) {
    x = ex;
    y = ey;
    age = 0;
    lifeTime = 45;

    // 火花を40個作る．向きと速さをランダムにして，四方八方に飛び散らせる
    sparks = new ArrayList<Spark>();
    for (int i=0; i<40; i++) {
      float angle = random(TWO_PI);  // 飛ぶ向き（0から360度）
      float speed = random(2, 10);   // 飛ぶ速さ
      sparks.add(new Spark(x, y, speed * cos(angle), speed * sin(angle)));
    }
  }

  // 爆発の表示
  void display() {
    age++;
    float t = (float)age / lifeTime; // 爆発の進み具合．0（始まり）から1（終わり）

    pushStyle();     // 線の太さや色の設定を，描き終わったら元に戻すため保存しておく
    blendMode(ADD);  // 色を足し合わせて描く．重なったところが明るくなり，光って見える

    // 1. 白い閃光：最初の数フレームだけ，大きな光の玉が急速に小さくなる
    if (age < 8) {
      noStroke();
      float flash = 1.0 - age / 8.0; // 1から0へ小さくなる
      fill(255, 220, 150, 120 * flash);
      ellipse(x, y, 110 * flash, 110 * flash);
      fill(255, 255, 255, 255 * flash);
      ellipse(x, y, 50 * flash, 50 * flash);
    }

    // 2. 火の玉：オレンジの光が，ふくらみながらだんだん暗くなる
    noStroke();
    float fire = 1.0 - t; // 1から0へ暗くなる
    fill(255, 80, 10, 90 * fire);
    ellipse(x, y, 40 + 50 * t, 40 + 50 * t);
    fill(255, 170, 40, 120 * fire * fire);
    ellipse(x, y, 20 + 30 * t, 20 + 30 * t);

    // 3. 衝撃波の輪：だんだん大きく，細く，薄くなる
    noFill();
    strokeWeight(6 * (1 - t));
    stroke(255, 160, 60, 200 * (1 - t));
    float r = 140 * sqrt(t); // 最初は速く広がり，だんだんゆっくりになる
    ellipse(x, y, r, r);

    // 4. 火花：それぞれ動かして描く
    for (int i=0; i<sparks.size(); i++) {
      Spark spark = sparks.get(i);
      spark.move();
      spark.display(t);
    }

    blendMode(BLEND); // 普通の描き方に戻す
    popStyle();       // 保存しておいた線の太さや色の設定に戻す
  }

  // 爆発が続いているかどうかチェック（lifeTimeを過ぎたら終わり）
  boolean isAlive() {
    return age < lifeTime;
  }
}

// Explosionで使う火花
class Spark {
  float x, y;           // 火花の座標
  float speedX, speedY; // 火花の速度
  float px, py;         // 1フレーム前の座標（尾を引いて見えるように線で描くため）
  color c;              // 火花の色

  Spark(float sx, float sy, float spX, float spY) {
    x = px = sx;
    y = py = sy;
    speedX = spX;
    speedY = spY;
    // 色は黄色からオレンジの間でランダムにする
    c = lerpColor(color(255, 240, 120), color(255, 90, 20), random(1));
  }

  // 火花の移動：空気抵抗でだんだん遅くなる
  void move() {
    px = x;
    py = y;
    speedX = speedX * 0.93;
    speedY = speedY * 0.93;
    x = x + speedX;
    y = y + speedY;
  }

  // 火花の表示．tは爆発の進み具合（0から1）．終わりに近づくほど細く，薄くする
  void display(float t) {
    strokeWeight(3 * (1 - t) + 1);
    stroke(c, 255 * (1 - t));
    // 1フレーム前の位置から今の位置へ線を引き，速さに応じた長さの尾にする
    line(px - speedX, py - speedY, x, y);
  }
}
