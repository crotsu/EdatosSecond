//-------------------------------------------------------------
// 戦闘機のホーミングレーザー
// 一度機体の下へ扇状に飛び出し，減速したあと敵に向かって加速する．
// 画像は使わず，光る弾と残像の尾を図形で描く．
//-------------------------------------------------------------

class HomingLaser {
  float x, y;           // 弾のxy座標
  float speedX, speedY; // 弾のx,y軸方向の移動速度
  boolean alive;        // 弾が残っているかどうか
  int damage;           // 敵に与えるダメージ
  int age;              // 発射してからの経過フレーム数

  int launchTime;       // 発射直後に下へ飛び出している時間（フレーム数）．この間は敵を追わない
  int lifeTime;         // 寿命（フレーム数）．敵の周りを回り続けないように，これを過ぎたら消える
  float maxSpeed;       // 追尾中の最高速度
  float accel;          // 追尾中の加速度
  float turnSpeed;      // 1フレームで曲がれる最大の角度（ラジアン）

  ArrayList<PVector> trail; // 残像の尾を描くための，過去の位置
  int trailLength;          // 尾の長さ（何フレーム分の位置を覚えておくか）

  // コンストラクタ．(sx, sy)から，速度(spX, spY)で飛び出す
  HomingLaser(float sx, float sy, float spX, float spY) {
    x = sx;
    y = sy + 10; // 機体の少し下から出す
    speedX = spX;
    speedY = spY;
    alive = true;
    damage = 100;
    age = 0;

    launchTime = 18;
    lifeTime   = 240;
    maxSpeed   = 12;
    accel      = 0.6;
    turnSpeed  = radians(9);

    trail = new ArrayList<PVector>();
    trailLength = 14;
  }

  // 弾の移動
  void move() {
    age++;
    if (age <= launchTime) {
      // 発射直後：下へ飛び出しながら，だんだん減速する（ふわっと浮いて止まる感じ）
      speedX = speedX * 0.92;
      speedY = speedY * 0.92;
    }
    else {
      // 追尾中：敵の方へ向きを変えながら，加速する
      steer();
    }
    x = x + speedX;
    y = y + speedY;

    // 今の位置を尾に追加し，古い位置は捨てる
    trail.add(new PVector(x, y));
    if (trail.size() > trailLength) {
      trail.remove(0);
    }
  }

  // 一番近い敵の方へ，少しずつ向きを変えて加速する
  void steer() {
    float angle = atan2(speedY, speedX); // 今進んでいる向き
    float targetAngle;                   // 向かいたい向き
    Enemy target = findNearestEnemy();
    if (target != null) {
      targetAngle = atan2(target.y - y, target.x - x); // 敵がいる向き
    }
    else {
      targetAngle = -HALF_PI; // 敵がいなければ真上へ向かう
    }

    // 向きの差を -PI から PI の範囲にする（右回りと左回りの近い方に曲がるため）
    float diff = targetAngle - angle;
    while (diff >  PI) diff -= TWO_PI;
    while (diff < -PI) diff += TWO_PI;

    // 一度に曲がれる角度をturnSpeedまでに制限する（急に曲がると不自然なので）
    angle = angle + constrain(diff, -turnSpeed, turnSpeed);

    // 最高速度まで加速する
    float speed = min(mag(speedX, speedY) + accel, maxSpeed);
    speedX = speed * cos(angle);
    speedY = speed * sin(angle);
  }

  // 一番近い（まだHPが残っている）敵を探す．敵がいなければnullを返す
  Enemy findNearestEnemy() {
    Enemy nearest = null;
    float nearestDist = 99999;
    for (int i=0; i<enemies.size(); i++) {
      Enemy enemy = enemies.get(i);
      float d = dist(enemy.x, enemy.y, x, y);
      if (enemy.hp>0 && d<nearestDist) {
        nearest = enemy;
        nearestDist = d;
      }
    }
    return nearest;
  }

  // 弾の表示
  void display() {
    // 敵との当たり判定（発射直後の飛び出し中は当たらない）
    if (age > launchTime) {
      for (int i=0; i<enemies.size(); i++) {
        Enemy enemy = enemies.get(i);
        if (alive==true && enemy.hp>0 && dist(enemy.x, enemy.y, x, y)<30) {
          enemy.hp = enemy.hp - damage;
          alive = false; // 敵に当たった弾は消える
        }
      }
    }
    if (alive==true) {
      move();
      drawShape();
    }
  }

  // 光る弾と残像の尾を描く
  void drawShape() {
    pushStyle();     // 線の太さや色の設定を，描き終わったら元に戻すため保存しておく
    blendMode(ADD);  // 色を足し合わせて描く．重なったところが明るくなり，光って見える

    // 残像の尾：古い位置ほど細く，薄くする
    for (int i=1; i<trail.size(); i++) {
      PVector p0 = trail.get(i-1);
      PVector p1 = trail.get(i);
      float t = (float)i / trail.size(); // 0（古い）から1（新しい）
      // 外側の太くてぼんやりした光
      strokeWeight(10 * t);
      stroke(40, 120, 255, 70 * t);
      line(p0.x, p0.y, p1.x, p1.y);
      // 内側の細くて明るい芯
      strokeWeight(4 * t);
      stroke(120, 230, 255, 220 * t);
      line(p0.x, p0.y, p1.x, p1.y);
    }

    // 弾の頭：外側から順に，大きくて薄い円 → 小さくて明るい円を重ねる
    noStroke();
    float pulse = 1.0 + 0.2 * sin(age * 0.6); // 大きさを少し脈打たせる
    fill(40, 120, 255, 60);
    ellipse(x, y, 26 * pulse, 26 * pulse);
    fill(120, 230, 255, 140);
    ellipse(x, y, 14 * pulse, 14 * pulse);
    fill(255, 255, 255, 255);
    ellipse(x, y, 6, 6);

    blendMode(BLEND); // 普通の描き方に戻す
    popStyle();       // 保存しておいた線の太さや色の設定に戻す
  }

  // 弾が残っているかどうかチェック（敵に当たったか，画面の外に出たか，寿命が来たら消える）
  boolean isAlive() {
    if (x<0-50 || x>width+50 || y<0-50 || y>height+50) {
      alive = false;
    }
    if (age > lifeTime) {
      alive = false;
    }
    return alive;
  }
}
