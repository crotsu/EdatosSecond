//------------------
// 戦闘機のレーザー
//------------------

class Laser {
  PImage img;         // レーザーの画像
  int x, y;           // レーザーのxy座標
  int speedX, speedY; // レーザーのx,y軸方向の移動速度
  boolean alive;      // レーザーが残っているかどうか. Trueなら残っている，Falseなら（敵に当たったか画面外に出て）消える．
  int damage;         // レーザーが敵に与えるダメージ
  
  // コンストラクタ(データ作成時に1度だけ行う) 
  Laser(int sx, int sy, int spX, int spY) {
    img = laserImg; // setupで読み込んだ画像を使う
    alive = true;
    x = sx;
    y = sy - 5; // レーザーの初期位置を上に5だけずらす．これをやらないと戦闘機の上からレーザーが発射されるように見えない．
    speedX = spX;
    speedY = spY;
    damage = 100;
  }
  
  // レーザーの移動
  void move() {    
    x = x + speedX;
    y = y + speedY;      
  }
  
  // レーザーの表示
  void display() {
    // レーザーと全ての敵との当たり判定
    for (int i=0; i<enemies.size(); i++) {
      Enemy enemy = enemies.get(i); // ArrayListから既に生成した敵を取得する
      // レーザーが生きていて，敵のHPが残っていて，かつ敵とレーザーの中心座標間の距離が30未満なら
      // （aliveも調べるのは，1本のレーザーが重なった複数の敵に当たらないようにするため）
      // （敵のHPも調べるのは，既に倒した敵（次のフレームで削除される）にレーザーを無駄に当てないため）
      if (alive==true && enemy.hp>0 && dist(enemy.x, enemy.y, x, y)<30) {
        enemy.hp = enemy.hp - damage;
        alive = false; // 敵に当たったレーザーは消える
      }
    }
    // 当たって消えたレーザーは表示しない
    if (alive==true) {
      move();
      image(img, x, y);
    }
  }

  // レーザーが残っているかどうかチェック（敵に当たったか，ウィンドウの外に出たら消える）
  boolean isAlive() {
    if (x<0-50 || x>width+50 || y<0-50 || y>height+50) { // 画面外に完全に出るのを待つため範囲を50広げる
      alive = false;
    }
    return alive;
  }

}
