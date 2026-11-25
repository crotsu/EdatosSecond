//------------------------------------------------
// 本格シューティングゲーム完成版（コメント付き）
//------------------------------------------------

// 主要なデータ宣言
Starfield starfield;       // 背景の星
Ship ship;                 // 戦闘機
ArrayList<Enemy> enemies;  // 敵
ArrayList<Laser> lasers;   // 戦闘機のレーザー
ArrayList<HomingLaser> homingLasers; // 戦闘機のホーミングレーザー（hキーで発射）
ArrayList<Explosion> explosions;     // 敵を倒したときの爆発
ArrayList<Bullet> bullets; // 敵の砲弾
int score = 0;             // スコア
boolean titleScreen = true; // オープニング画面を表示中かどうか．Trueならオープニング画面，Falseならゲーム中

// 画像（loadImageはファイルを読むので時間がかかる．setupで1度だけ読み込んで使い回す）
PImage enemyImg;  // 敵の画像
PImage laserImg;  // レーザーの画像
PImage bulletImg; // 敵の弾の画像

//-------------------------------
// ゲーム起動時に１度だけ実行する
//-------------------------------
void setup() {
  size(400, 600);   // 画面サイズを400 x 600の長方形にする
  pixelDensity(1);  // 高解像度画面でも1倍で描画する（Processingの新しい標準は2倍）
  imageMode(CENTER);// 画像座標の指定方法を中心に設定

  // 画像を読み込む
  enemyImg  = loadImage("enemy_red.png");
  laserImg  = loadImage("laser.png");
  bulletImg = loadImage("bullet.png");

  starfield = new Starfield(100); // 背景の星の数を100にする
  resetGame(); // 戦闘機・敵・弾・レーザー・スコアを初期状態にする
  startSound(); // 音を読み込んで，BGMを流し始める
}

//------------------------------------------------------------
// ゲームを初期状態にする（起動時と，再スタート時に実行する）
//------------------------------------------------------------
void resetGame() {
  ship = new Ship();
  enemies = new ArrayList<Enemy>();
  bullets = new ArrayList<Bullet>();
  lasers  = new ArrayList<Laser>();
  homingLasers = new ArrayList<HomingLaser>();
  explosions = new ArrayList<Explosion>();
  score = 0;
}

//------------------------------------------------------------
// マウスのボタンが押された瞬間に１度だけ実行される
//------------------------------------------------------------
void mousePressed() {
  // オープニング画面でクリックしたら，ゲームを開始する
  if (titleScreen == true) {
    titleScreen = false;
    resetGame();
    ship.canPress = false; // 開始のクリックでレーザーが出ないようにする
  }
  // ゲームオーバー中にクリックしたら，ゲームを再スタートする
  else if (ship.alive == false) {
    resetGame();
    ship.canPress = false; // 再スタートのクリックでレーザーが出ないようにする
  }
}

//-------------------------------------------
// ゲーム実行時に１秒間に60回画面が更新される
//-------------------------------------------
void draw() {
  background(0); // 画面クリアー（画面を黒を塗りつぶす）
  starfield.draw(); // 背景の星を描画する

  // オープニング画面を表示中なら，ゲームの処理はせずにオープニング画面だけ描く
  if (titleScreen == true) {
    displayTitle();
    return; // ここでdraw()を終わる（これより下のゲームの処理は行わない）
  }

  // 敵の出現
  // 敵が1/60秒で2%の確率で，かつ敵の数が3未満のとき生成．つまり同時に3体しか出現しない
  if (random(1.0) < 0.02 && enemies.size()<3) {
    enemies.add(new Enemy());
  }
  
  
  // 敵の動作
  // ArrayListから要素を削除するときは，後ろから順番に調べる．
  // 前から調べると，削除した後ろの要素が1つ前に詰められて，次の要素を調べ忘れてしまうため．
  for (int i=enemies.size()-1; i>=0; i--) {
    Enemy enemy = enemies.get(i); // ArrayListから既に生成した敵を取得する
    enemy.display(); // 敵画像を表示
    if (enemy.isAlive()==true) {
      // 生きている敵だけが弾を発射．1/60秒で3%の確率
      if (random(1) < 0.03) {
        bullets.add(new Bullet(enemy.x, enemy.y));
      }
    }
    else {
      // 敵が倒されたときは（画面の外に出たときは除く），その場所で爆発させる
      if (enemy.hp <= 0) {
        explosions.add(new Explosion(enemy.x, enemy.y));
        explosionSound.play(); // 爆発音を鳴らす
      }
      // 敵が倒されたか画面の外に出たら，その敵をArrayListから削除
      enemies.remove(i);
    }
  }


  // 爆発の動作
  for (int i=explosions.size()-1; i>=0; i--) { // 削除があるので後ろから調べる
    Explosion explosion = explosions.get(i);
    explosion.display();
    if (explosion.isAlive()==false) { // 爆発が終わったら削除
      explosions.remove(i);
    }
  }


  // 敵の弾の動作
  for (int i=bullets.size()-1; i>=0; i--) { // 削除があるので後ろから調べる
    Bullet bullet = bullets.get(i); // ArrayListから既に生成した弾を取得する
    bullet.display(); // 弾画像を表示
    if (bullet.isAlive()==false) { // 弾が戦闘機に当たったか画面の外に出たら，その弾をArrayListから削除
      bullets.remove(i);
    }
  }
  
  
  // 戦闘機のレーザー発射
  // 発射してからの経過フレーム数を数え，ship.intervalになったら再び発射できるようにする
  if (ship.canPress == false) {
    ship.timeCount++; // 1/60秒で1回カウントされる
    if (ship.timeCount >= ship.interval) {
      ship.canPress = true;
    }
  }
  if (mousePressed && ship.alive==true) { // マウスの左ボタンがクリックされ，かつ戦闘機が生きていたら
    if (ship.canPress == true) { // 発射できる状態なら
      shoot(); // レーザー発射
      shotSound.play(); // 発射音を鳴らす
      ship.canPress = false; // 発射できないようにする
      ship.timeCount = 0;    // 発射した時点から数え直す（これで連打しても発射間隔が守られる）
    }
  }
  
  
  // 戦闘機のレーザーの動作
  for (int i=lasers.size()-1; i>=0; i--) { // 削除があるので後ろから調べる
    Laser laser = lasers.get(i); // ArrayListから既に生成したレーザーを取得する
    laser.display(); // レーザー画像を表示
    if (laser.isAlive()==false) { // レーザーが敵に当たったか画面の外に出たら，そのレーザーをArrayListから削除
      lasers.remove(i);
    }
  }


  // ホーミングレーザー発射（キーボードのhキー）
  // 通常のレーザーとは別に，発射してからの経過フレーム数を数える
  if (ship.canHoming == false) {
    ship.homingTimeCount++;
    if (ship.homingTimeCount >= ship.homingInterval) {
      ship.canHoming = true;
    }
  }
  if (keyPressed && (key=='h' || key=='H') && ship.alive==true) { // hキーが押され，かつ戦闘機が生きていたら
    if (ship.canHoming == true) {
      shootHoming(); // ホーミングレーザー発射
      homingSound.play(); // 発射音を鳴らす
      ship.canHoming = false;
      ship.homingTimeCount = 0;
    }
  }


  // ホーミングレーザーの動作
  for (int i=homingLasers.size()-1; i>=0; i--) { // 削除があるので後ろから調べる
    HomingLaser homing = homingLasers.get(i);
    homing.display();
    if (homing.isAlive()==false) { // 敵に当たったか，画面の外に出たか，寿命が来たら削除
      homingLasers.remove(i);
    }
  }

    
  // 戦闘機の動作
  selectShottype(); // スコアによって攻撃タイプを選択
  if (ship.isAlive()==true) { // 戦闘機のHPが0より大きければ生存
    ship.display(mouseX, mouseY); // ウィンドウ内のマウスカーソルの座標を取得して，戦闘機を動かす
  }
    
  // スコア表示
  displayScore(score);
  
  // 戦闘機のHP表示
  displayHP();
  
}

// スコアによって攻撃タイプを選択
void selectShottype()
{
  if (score>=500) {
    ship.shotType = 1;
  }
  if (score>=1000) {
    ship.shotType = 2;
  }
  if (score>=3000) {
    ship.shotType = 3;
  }
}

// 攻撃タイプによって，レーザーを発射
void shoot()
{
  if (ship.shotType == 0) {
    lasers.add(new Laser(ship.x, ship.y, 0, -5));
  }
  else if (ship.shotType == 1) {
    lasers.add(new Laser(ship.x-10, ship.y, 0, -25));
    lasers.add(new Laser(ship.x+10, ship.y, 0, -25));
  }
  else if (ship.shotType == 2) {
    lasers.add(new Laser(ship.x, ship.y,  1, -10));
    lasers.add(new Laser(ship.x, ship.y,  0, -10));
    lasers.add(new Laser(ship.x, ship.y, -1, -10));
  }
  else if (ship.shotType == 3) {
    lasers.add(new Laser(ship.x, ship.y,  4, -10));
    lasers.add(new Laser(ship.x, ship.y,  2, -10));
    lasers.add(new Laser(ship.x, ship.y,  0, -10));
    lasers.add(new Laser(ship.x, ship.y, -2, -10));
    lasers.add(new Laser(ship.x, ship.y, -4, -10));
  }
}

// ホーミングレーザーを発射（機体の下へ扇状に4発出し，そこから敵へ向かう）
void shootHoming()
{
  homingLasers.add(new HomingLaser(ship.x, ship.y, -4.0, 2.5));
  homingLasers.add(new HomingLaser(ship.x, ship.y, -1.5, 4.0));
  homingLasers.add(new HomingLaser(ship.x, ship.y,  1.5, 4.0));
  homingLasers.add(new HomingLaser(ship.x, ship.y,  4.0, 2.5));
}

// スコア表示
void displayScore(int score)
{
  textAlign(CENTER);
  textSize(30);
  fill(#FAE753);
  text(score,50,100);
}

// 戦闘機のHP表示
void displayHP()
{
  stroke(255);
  fill(0);
  rect(9,19,width-19,31);
  noStroke();
  fill(0,255,0);
  if (ship.hp>0) {
    rect(10,20,float(width-20)*float(ship.hp)/float(ship.maxHp),30);
  }
  else {
    text("Game Over",width/2,height/2);
    textSize(20);
    fill(255);
    text("Click to Restart",width/2,height/2+40);
  }
}

// オープニング画面の表示
void displayTitle()
{
  pushStyle(); // 文字の大きさや色の設定を，描き終わったら元に戻すため保存しておく
  textAlign(CENTER, CENTER);

  // タイトル文字：青い光を少しずつずらして何度も重ねて描き，その上に白い文字を描く
  textSize(56);
  blendMode(ADD); // 色を足し合わせて描く．重なったところが明るくなり，光って見える
  fill(40, 120, 255, 40);
  for (int dx=-4; dx<=4; dx+=2) {
    for (int dy=-4; dy<=4; dy+=2) {
      text("EDATOS", width/2+dx, 150+dy);
    }
  }
  blendMode(BLEND); // 普通の描き方に戻す
  fill(255);
  text("EDATOS", width/2, 150);

  // サブタイトル
  textSize(28);
  fill(120, 230, 255);
  text("SECOND", width/2, 205);

  // 戦闘機：sinを使って上下にゆっくり揺らす
  float floatY = 320 + 8 * sin(frameCount * 0.05);
  image(ship.img, width/2, floatY);

  // 操作説明：「:」の位置をそろえるため，左側は右寄せ，右側は左寄せで描く
  textSize(16);
  fill(200);
  String[] actions = {"MOVE", "SHOT", "HOMING"};
  String[] keys    = {"MOUSE", "CLICK", "H KEY"};
  for (int i=0; i<actions.length; i++) {
    float y = 420 + i * 25;
    textAlign(RIGHT, CENTER);
    text(actions[i], width/2 - 12, y);
    textAlign(CENTER, CENTER);
    text(":", width/2, y);
    textAlign(LEFT, CENTER);
    text(keys[i], width/2 + 12, y);
  }
  textAlign(CENTER, CENTER);

  // 「CLICK TO START」：sinを使って明るさを変え，点滅させる
  textSize(22);
  fill(#FAE753, 155 + 100 * sin(frameCount * 0.1));
  text("CLICK TO START", width/2, 540);

  popStyle(); // 保存しておいた設定に戻す
}
