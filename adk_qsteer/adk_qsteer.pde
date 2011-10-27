#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>

/** 赤外線LEDを接続したポート */
#define IR_LED      (2)

/** チョロQに関する定数 */
#define BAND_A      (B00)    /* バンドA */
#define BAND_B      (B01)    /* バンドB */
#define BAND_C      (B10)    /* バンドC */
#define BAND_D      (B11)    /* バンドD */
#define CTRL_F      (B0001)  /* 前進 */
#define CTRL_B      (B0010)  /* 後退 */
#define CTRL_L      (B0011)  /* ステアリング左 */
#define CTRL_R      (B0100)  /* ステアリング右 */
#define CTRL_TF     (B0101)  /* ターボ＋前進 */
#define CTRL_FL     (B0110)  /* 前進＋ステアリング左 */
#define CTRL_FR     (B0111)  /* 前進＋ステアリング右 */
#define CTRL_STOP   (B1111)  /* 停止 */

/** 各ビットのデータ長 */
#define BASE_TIME   (400)
#define HIGH_TIME   (930)
#define LOW_TIME    (430)
#define START_BIT   (1740)
#define A_DELAY     (7540)
#define B_DELAY     (21850)
#define C_DELAY     (36200)
#define D_DELAY     (50550)

#define MANUFACTURE ("iwatan lab")
#define MODEL       ("qsteer")
#define DESCRIPTION ("説明")
#define VERSION     ("1.0")
#define URI         ("http://market.android.com/details?id=jp.iwatanlab.microbridge.qsteer")
#define SERIAL      ("0000000012345678")

/** OpenAccessoryオブジェクト */
AndroidAccessory acc(MANUFACTURE, MODEL, DESCRIPTION, VERSION, URI, SERIAL);


void setup() {
  Serial.begin(115200);
  Serial.print("Start\n");
  pinMode(IR_LED, OUTPUT);
  acc.powerOn(); /* OpenAccessoryを起動 */
}

void loop() {
  byte msg[2];
  
  /* Androidと接続しているかのチェック */
  if (acc.isConnected()) {
    // Serial.println("isConnected");
    
    /* Androidからのデータを受信 */
    if (acc.read(msg, sizeof(msg), 1) > 0) {
      sendData(msg[0], msg[1]);
    }
    
    /* Androidへデータを送信 */
    acc.write(msg, 3);
  }
  
  delay(10);

}


/**
 * 赤外線LEDの制御
 *
 * @param[in] level 出力レベル
 * @param[in] time 出力時間
 */
void ctrlIr(int level, int time) {
  
  /* 開始時間を測定 */
  unsigned long start = micros();
  
  /* 指定時間の間、38KHzで赤外線LEDを点滅する */
  do {
    digitalWrite(IR_LED, level);
    delayMicroseconds(8);
    digitalWrite(IR_LED, LOW);
    delayMicroseconds(7);
  } while (long(start + time - micros()) > 0);
}

/**
 * データ送信
 *
 * @param[in] data データ
 */
void sendData(byte band, byte data) {
  int i=0;
 
  for(i = 0; i<2; i++) {
    /* スタートビット送信 */
    ctrlIr(HIGH, START_BIT);
    
    /* バンド部分送信 */
    for(int i=0; i<2; i++) {
      int b = bitRead(band, 1-i);
      ctrlIr(LOW, BASE_TIME);
      if (b == 0) {
        ctrlIr(HIGH, LOW_TIME);
      } else {
        ctrlIr(HIGH, HIGH_TIME);
      }
    }
    
    /* データ部分送信 */
    for(int i=0; i<4; i++) {
      int b = bitRead(data, 3-i);
      ctrlIr(LOW, BASE_TIME);
      if (b == 0) {
        ctrlIr(HIGH, LOW_TIME);
      } else {
        ctrlIr(HIGH, HIGH_TIME);
      }
    }
    
    /* データ後の通信がない時間 */
    switch(band) {
      case BAND_B:
        ctrlIr(LOW, B_DELAY);
        break;
        
      case BAND_C:
        ctrlIr(LOW, C_DELAY);
        break;
        
      case BAND_D:
        ctrlIr(LOW, D_DELAY);
        break;
      
      case BAND_A:
      default:
        ctrlIr(LOW, A_DELAY);
        break;
    }
  }
}

