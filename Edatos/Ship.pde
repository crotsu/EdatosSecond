//---------------
// 戦闘機（自機）
//---------------

class Ship {
  PImage img;         // 戦闘機の画像
  int hp;             // 戦闘機のHP
  int maxHp;          // 戦闘機の最大HP
  int x, y;           // 戦闘機のxy座標
  int speedX, speedY; // 戦闘機のx,y軸方向の移動速度
  boolean alive;      // 戦闘機が生きているかどうか. Trueが生存，Falseが死亡．
  int interval;       // レーザーの発射間隔．値が小さいほど連写できる
  int shotType;       // レーザーの攻撃方法．0:通常，1:ダブル，2:3way，3:5way
  boolean canPress;   // レーザーを発射できるかどうか．Trueなら発射できる，Falseならできない．
  int timeCount = 0;  // 経過フレーム数．interval以上になったら発射できるようにする

  // コンストラクタ(データ作成時に1度だけ行う) 
  Ship() {
    img = loadImage("ship.png");
    alive = true;
    maxHp = hp = 300;
    x = width/2;     // 戦闘機の初期出現位置．x軸方向は真ん中
    y = 4*height/5;  // 戦闘機の初期出現位置．y軸方向は上からから4/5のところ
    speedX = 2;   
    speedY = 2;   
    interval = 30;  // レーザーの発射間隔．値が小さいほど連写できる
    shotType = 0; // レーザーの攻撃方法．
    canPress = true; // ゲーム開始直後から発射できるようにする
  }

  // 戦闘機の移動
  void move(int sx, int sy) {
    // マウスとの距離がspeedX未満なら，マウスの位置に合わせる
    // （これをしないと，1ずつずれたまま左右に行ったり来たりして震えてしまう）
    if (abs(x - sx) < speedX) {
      x = sx;
    }
    else if (x > sx) {
      x = x - speedX;
    }
    else if (x < sx) {
      x = x + speedX;
    }
    // y軸方向の移動は無効にしている（戦闘機は左右にだけ動く）
    if (y > sy) {
      //y = y - speedY;
    }
    if (y < sy) {
      //y = y + speedY;
    }    
  }
  
  // 戦闘機の表示
  void display(int mx, int my) {
    move(mx, my);
    image(img, x, y);
  }
  
  // 戦闘機が倒されたかどうかチェック
  boolean isAlive() {
    // 戦闘機のHPが0以下なら
    if (hp<=0) {
      alive = false;
      x = -999;
      y = -999;
    }
    return alive;
  }
}
