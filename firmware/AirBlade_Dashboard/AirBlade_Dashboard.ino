#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- BLE UUIDs ---
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_RPM          "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_UUID_SPEED        "8b423985-7977-4b72-b2d6-4e5088277be9"
#define CHAR_UUID_ECT          "e3b1c67d-94bb-4286-904b-3cc34a4c6a99"
#define CHAR_UUID_TPS          "19a28e8d-71b5-4148-84be-97b7cbce39fa"
#define CHAR_UUID_BATTERY      "c19f5615-585a-4712-b062-1bd074a1a5b8"
#define CHAR_UUID_IAT          "d4e8f1a2-3b5c-4d6e-8f9a-0b1c2d3e4f5a"
#define CHAR_UUID_O2           "f6a8b1c2-4d5e-4f6a-8b9c-1d2e3f4a5b6c"

BLEServer* pServer = NULL;
BLECharacteristic* pCharRPM = NULL;
BLECharacteristic* pCharSpeed = NULL;
BLECharacteristic* pCharECT = NULL;
BLECharacteristic* pCharTPS = NULL;
BLECharacteristic* pCharBattery = NULL;
BLECharacteristic* pCharIAT = NULL;
BLECharacteristic* pCharO2 = NULL;
bool deviceConnected = false;

// Hardware Serial cho K-Line (L9637D)
#define RX_PIN 16
#define TX_PIN 17
#define K_LINE_BAUD 10400
#define ECU_TARGET_ADDR 0x33
#define TESTER_ADDR     0xF1
HardwareSerial KLineSerial(1);

// --- Trang thai ket noi K-Line (KWP2000) ---
bool ecuConnected = false;
unsigned long lastConnectAttempt = 0;
unsigned long lastPoll = 0;
const unsigned long CONNECT_RETRY_MS = 2000;
const unsigned long POLL_INTERVAL_MS = 250;

// Biến lưu trữ dữ liệu
uint16_t currentRPM = 0;
uint8_t currentSpeed = 0;
int8_t currentECT = 0;
uint8_t currentTPS = 0;
float currentVolt = 12.5;
int8_t currentIAT = 0;
float currentO2Voltage = 0;

// Bao loop() gui lai TOAN BO gia tri hien tai trong vai giay dau sau khi co
// client BLE moi ket noi, du gia tri khong doi so voi lan gui truoc — vi "gui
// khi doi" la so sanh voi client CU, con client MOI subscribe thi chua tung
// nhan duoc gi ca (BLE notify khong "phat lai" gia tri cu cho subscriber moi).
// Gui lien tuc trong 1 khoang thoi gian (khong phai 1 lan duy nhat) vi client
// can vai chuc ms - vai giay de hoan tat dang ky nhan thong bao (CCCD) cho tung
// characteristic; gui qua som se bi mat, khong ai luu lai de gui lai.
bool forceResendData = true;
unsigned long forceResendUntil = 0;
const unsigned long FORCE_RESEND_WINDOW_MS = 5000;

// Callback xử lý kết nối BLE
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      forceResendData = true;
      forceResendUntil = millis() + FORCE_RESEND_WINDOW_MS;
      // Cho phep loop() thu bat tay K-Line ngay lap tuc thay vi doi
      // toi chu ky CONNECT_RETRY_MS tiep theo.
      ecuConnected = false;
      lastConnectAttempt = 0;
      Serial.println("App da ket noi BLE!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("App da ngat ket noi BLE!");
      pServer->getAdvertising()->start(); // Bật lại quảng cáo
    }
};

void setupBLE() {
  Serial.println("Khoi tao BLE Server...");
  BLEDevice::init("Honda_AB2025_Dash");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Tạo Characteristics (Cho phép ĐỌC và TỰ ĐỘNG THÔNG BÁO khi có dữ liệu mới)
  pCharRPM = pService->createCharacteristic(CHAR_UUID_RPM, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharRPM->addDescriptor(new BLE2902());

  pCharSpeed = pService->createCharacteristic(CHAR_UUID_SPEED, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharSpeed->addDescriptor(new BLE2902());

  pCharECT = pService->createCharacteristic(CHAR_UUID_ECT, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharECT->addDescriptor(new BLE2902());

  pCharTPS = pService->createCharacteristic(CHAR_UUID_TPS, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharTPS->addDescriptor(new BLE2902());

  pCharBattery = pService->createCharacteristic(CHAR_UUID_BATTERY, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharBattery->addDescriptor(new BLE2902());

  pCharIAT = pService->createCharacteristic(CHAR_UUID_IAT, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharIAT->addDescriptor(new BLE2902());

  pCharO2 = pService->createCharacteristic(CHAR_UUID_O2, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharO2->addDescriptor(new BLE2902());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // Giúp iPhone kết nối nhanh hơn
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Da phat song BLE. Cho ket noi...");
}

// ============================================================
//  K-LINE (KWP2000) — Ket noi va doc du lieu that tu ECU
// ============================================================

void printHexSerial(uint8_t *data, int len, const char* prefix) {
  Serial.print(prefix);
  for (int i = 0; i < len; i++) {
    if (data[i] < 0x10) Serial.print("0");
    Serial.print(data[i], HEX);
    Serial.print(" ");
  }
  Serial.println();
}

uint8_t calcChecksum(uint8_t *data, int len) {
  uint16_t sum = 0;
  for (int i = 0; i < len; i++) sum += data[i];
  return (uint8_t)(sum & 0xFF);
}

// Gui 1 khung KWP2000 dinh dang vat ly: [C0|len] [target] [source] [payload...] [checksum]
// Tra ve tong so byte da gui (de biet do dai phan echo tren bus).
int sendKWPRequest(uint8_t *payload, int payloadLen) {
  uint8_t frame[16];
  int idx = 0;
  frame[idx++] = 0xC0 | (payloadLen & 0x3F);
  frame[idx++] = ECU_TARGET_ADDR;
  frame[idx++] = TESTER_ADDR;
  for (int i = 0; i < payloadLen; i++) frame[idx++] = payload[i];
  frame[idx] = calcChecksum(frame, idx);
  idx++;
  KLineSerial.write(frame, idx);
  return idx;
}

// Doc phan hoi tren bus: [echo cua chinh minh — dung sentLen byte] roi den
// [khung ECU that: format][target][source][payload...][checksum].
// windowMs la thoi gian cho TOI DA neu khong co gi ca (de phat hien "mat ket noi").
// Ngay khi doc duoc byte format cua khung ECU (byte ngay sau phan echo), tinh
// chinh xac tong so byte can doc tu do dai khai bao trong format byte roi thoat
// NGAY LAP TUC khi du — KHONG doan theo "im lang bao lau", vi khoang cach xu ly
// giua echo va phan hoi that cua ECU co the dai hon vai chuc ms, doan sai se cat
// mat phan hoi that (da tung gay bug "chi thay echo, ECU khong tra loi").
int readKLineBytes(uint8_t *buf, int maxLen, int sentLen, unsigned long windowMs) {
  unsigned long start = millis();
  int count = 0;
  int expectedTotal = maxLen; // chua biet do dai that, mac dinh doc toi khi het windowMs
  while (millis() - start < windowMs && count < maxLen) {
    if (KLineSerial.available()) {
      uint8_t b = KLineSerial.read();
      buf[count++] = b;
      if (count == sentLen + 1) {
        int payloadLen = buf[sentLen] & 0x3F;
        if (payloadLen > 0) expectedTotal = sentLen + 3 + payloadLen + 1;
      }
      if (count >= expectedTotal) break; // du dung so byte can, thoat ngay
    }
  }
  return count;
}

// Fast Initialization: danh thuc ECU theo ISO14230 (300ms idle -> 25ms low -> 25ms high)
void fastInitPulse() {
  KLineSerial.end();
  pinMode(TX_PIN, OUTPUT);
  digitalWrite(TX_PIN, HIGH);
  delay(300);
  digitalWrite(TX_PIN, LOW);
  delay(25);
  digitalWrite(TX_PIN, HIGH);
  delay(25);
  KLineSerial.begin(K_LINE_BAUD, SERIAL_8N1, RX_PIN, TX_PIN);
  delay(2);
}

// Thu ket noi ECU: Fast Init + StartCommunication, kiem tra co phan hoi THAT (ngoai phan echo cua chinh minh)
bool tryConnectECU() {
  Serial.println("[K-LINE] Dang thu Fast Init + Start Communication...");
  fastInitPulse();

  uint8_t startComm[] = {0x81};
  int sentLen = sendKWPRequest(startComm, sizeof(startComm));

  uint8_t resp[32];
  int n = readKLineBytes(resp, sizeof(resp), sentLen, 300);
  printHexSerial(resp, n, "[K-LINE RX] ");

  if (n > sentLen) {
    Serial.print("[K-LINE] ECU PHAN HOI THAT, ");
    Serial.print(n - sentLen);
    Serial.println(" byte keybytes.");

    // Do thu Mode 0x03 (Show Stored DTCs) mot lan de xem ECU co ho tro doc
    // ma loi thuc su khong — hien chi log raw, chua giai ma DTC.
    delay(20);
    uint8_t dtcReq[] = {0x03};
    int dtcSentLen = sendKWPRequest(dtcReq, sizeof(dtcReq));
    uint8_t dtcResp[32];
    int dtcN = readKLineBytes(dtcResp, sizeof(dtcResp), dtcSentLen, 300);
    if (dtcN > dtcSentLen) {
      printHexSerial(dtcResp + dtcSentLen, dtcN - dtcSentLen, "[K-LINE] Mode 03 (DTC) phan hoi: ");
    } else {
      Serial.println("[K-LINE] Mode 03 (DTC): khong phan hoi.");
    }

    return true;
  }

  Serial.println("[K-LINE] Chi thay echo cua chinh minh — chua co ECU phan hoi (kiem tra day K-Line da noi vao xe chua).");
  return false;
}

// ECU nay dung chuan OBD-II Mode/PID (Service 0x01 "Show current data") thay vi
// bo lenh KWP2000 "diagnostic session" (0x10/0x21/0x1A/0x17 deu bi tu choi —
// da kiem chung bang thuc nghiem tren ECU that). Cac PID duoi day la chuan
// cong khai SAE J1979, da doi chieu khop voi trang thai xe that.
//
// Gui Mode 0x01 + PID, doc phan hoi dang [0x41][PID][A][B...], tra ve so byte data (A,B..).
// Tra ve 0 neu khong nhan duoc phan hoi hop le.
int requestPID(uint8_t pid, uint8_t *out, int maxOut) {
  uint8_t req[] = {0x01, pid};
  int sentLen = sendKWPRequest(req, sizeof(req));

  uint8_t resp[16];
  int n = readKLineBytes(resp, sizeof(resp), sentLen, 200);
  if (n <= sentLen) return 0; // khong phan hoi — im lang, cap tren se xu ly mat ket noi

  // Phan hoi cua ECU la 1 khung KWP2000 day du: [format][target][source][payload...][checksum]
  // — GIONG het cau truc khung ma chinh minh gui di — chu KHONG PHAI chi la [0x41][pid][data...].
  // Phai bo qua 3 byte header nay truoc khi doc phan payload (0x41/pid/gia tri).
  uint8_t *frame = resp + sentLen;
  int frameLen = n - sentLen;
  if (frameLen < 4) return 0; // toi thieu: format+target+source+1 checksum

  int payloadLen = frame[0] & 0x3F;
  if (frameLen < 3 + payloadLen + 1) return 0; // khung chua du byte

  uint8_t *payload = frame + 3;
  if (payloadLen < 2 || payload[0] != 0x41 || payload[1] != pid) return 0; // frame khong hop le

  int valLen = payloadLen - 2;
  if (valLen > maxOut) valLen = maxOut;
  for (int i = 0; i < valLen; i++) out[i] = payload[2 + i];
  return valLen;
}

// Giu phien lam viec song (TesterPresent) + doc 5 PID that tu ECU moi chu ky.
void pollECU() {
  uint8_t testerPresent[] = {0x3E, 0x01};
  int sentLen = sendKWPRequest(testerPresent, sizeof(testerPresent));
  uint8_t tpResp[16];
  int n = readKLineBytes(tpResp, sizeof(tpResp), sentLen, 150);
  if (n <= sentLen) {
    Serial.println("[K-LINE] Mat phan hoi ECU — se thu ket noi lai.");
    ecuConnected = false;
    return;
  }

  uint8_t val[4];

  if (requestPID(0x0C, val, 2) == 2) {                 // Engine RPM
    currentRPM = (((uint16_t)val[0] * 256) + val[1]) / 4;
  }
  if (requestPID(0x0D, val, 1) == 1) {                 // Vehicle Speed
    currentSpeed = val[0];
  }
  if (requestPID(0x05, val, 1) == 1) {                 // Engine Coolant Temp
    currentECT = (int)val[0] - 40;
  }
  if (requestPID(0x11, val, 1) == 1) {                 // Throttle Position
    currentTPS = (uint8_t)(((uint16_t)val[0] * 100) / 255);
  }
  if (requestPID(0x42, val, 2) == 2) {                 // Control Module Voltage
    currentVolt = (((uint16_t)val[0] * 256) + val[1]) / 1000.0;
  }
  if (requestPID(0x0F, val, 1) == 1) {                 // Intake Air Temp
    currentIAT = (int)val[0] - 40;
  }
  if (requestPID(0x14, val, 2) == 2) {                 // O2 Sensor Bank1-Sensor1 Voltage
    currentO2Voltage = val[0] / 200.0;
  }

  Serial.print("[LIVE] RPM=");
  Serial.print(currentRPM);
  Serial.print(" Speed=");
  Serial.print(currentSpeed);
  Serial.print("km/h ECT=");
  Serial.print(currentECT);
  Serial.print("C TPS=");
  Serial.print(currentTPS);
  Serial.print("% Volt=");
  Serial.print(currentVolt);
  Serial.print(" IAT=");
  Serial.print(currentIAT);
  Serial.print("C O2=");
  Serial.print(currentO2Voltage, 2);
  Serial.println("V");
}

void setup() {
  Serial.begin(115200);

  // Khởi tạo Serial cho K-Line (Baudrate 10400 chuẩn Honda)
  KLineSerial.begin(K_LINE_BAUD, SERIAL_8N1, RX_PIN, TX_PIN);

  // Khởi tạo Bluetooth LE
  setupBLE();
}

void loop() {
  if (deviceConnected) {
    // ==========================================
    // KHU VỰC 1: CODE THẬT (GIAO TIẾP VỚI XE)
    // Fast Init + KWP2000 that qua K-Line, ket qua in ra Serial USB
    // ==========================================
    unsigned long now = millis();
    if (!ecuConnected) {
      if (now - lastConnectAttempt >= CONNECT_RETRY_MS) {
        lastConnectAttempt = now;
        ecuConnected = tryConnectECU();
      }
    } else {
      if (now - lastPoll >= POLL_INTERVAL_MS) {
        lastPoll = now;
        pollECU();
      }
    }

    // ==========================================
    // KHU VỰC 2: BAO CAO DU LIEU THAT QUA BLE
    // Chi notify khi gia tri thuc su thay doi — giam nhieu song BLE thua,
    // do RPM/Speed/TPS thay doi lien tuc con ECT/Volt hau nhu dung yen.
    // ==========================================
    static uint16_t lastRPM = 0xFFFF;
    static uint8_t lastSpeed = 0xFF;
    static int8_t lastECT = -128;
    static uint8_t lastTPS = 0xFF;
    static float lastVolt = -1;
    static int8_t lastIAT = -128;
    static float lastO2Voltage = -1;
    static unsigned long lastForceResendBurst = 0;

    if (forceResendData) {
      if (millis() < forceResendUntil) {
        // Van con trong khoang thoi gian dam bao — ep gui lai vai lan (khong
        // chi 1 lan, nhung cung khong phai moi vong lap de tranh nghen BLE)
        // de chac chan trung luc client da dang ky xong CCCD.
        if (millis() - lastForceResendBurst >= 300) {
          lastForceResendBurst = millis();
          lastRPM = 0xFFFF; lastSpeed = 0xFF; lastECT = -128; lastTPS = 0xFF;
          lastVolt = -1; lastIAT = -128; lastO2Voltage = -1;
        }
      } else {
        forceResendData = false;
      }
    }

    // Giua moi lan notify() cach nhau vai ms — gui nhieu characteristic lien
    // tiep khong co khoang cach de ngan xep BLE cua ESP32 xu ly kip se khien
    // vai goi tin bi ROI MAT AM THAM (khong bao loi), client van "ket noi
    // binh thuong" nhung mai khong nhan duoc gia tri that cho characteristic
    // do — day chinh la nguyen nhan ECT/Volt bi ket o so mac dinh du RPM/TPS
    // van cap nhat dung.
    const int NOTIFY_GAP_MS = 8;

    if (currentRPM != lastRPM) {
      pCharRPM->setValue((uint8_t*)&currentRPM, 2);
      pCharRPM->notify();
      lastRPM = currentRPM;
      delay(NOTIFY_GAP_MS);
    }
    if (currentSpeed != lastSpeed) {
      pCharSpeed->setValue(&currentSpeed, 1);
      pCharSpeed->notify();
      lastSpeed = currentSpeed;
      delay(NOTIFY_GAP_MS);
    }
    if (currentECT != lastECT) {
      pCharECT->setValue((uint8_t*)&currentECT, 1);
      pCharECT->notify();
      lastECT = currentECT;
      delay(NOTIFY_GAP_MS);
    }
    if (currentTPS != lastTPS) {
      pCharTPS->setValue(&currentTPS, 1);
      pCharTPS->notify();
      lastTPS = currentTPS;
      delay(NOTIFY_GAP_MS);
    }
    if (abs(currentVolt - lastVolt) >= 0.05) {
      String voltStr = String(currentVolt, 1);
      pCharBattery->setValue(voltStr.c_str());
      pCharBattery->notify();
      lastVolt = currentVolt;
      delay(NOTIFY_GAP_MS);
    }
    if (currentIAT != lastIAT) {
      pCharIAT->setValue((uint8_t*)&currentIAT, 1);
      pCharIAT->notify();
      lastIAT = currentIAT;
      delay(NOTIFY_GAP_MS);
    }
    if (abs(currentO2Voltage - lastO2Voltage) >= 0.02) {
      String o2Str = String(currentO2Voltage, 2);
      pCharO2->setValue(o2Str.c_str());
      pCharO2->notify();
      lastO2Voltage = currentO2Voltage;
      delay(NOTIFY_GAP_MS);
    }

    delay(20); // Vong lap nhanh de bat kip thay doi RPM/toc do, khong lam gi neu khong co gi moi
  } else {
    // Không có ai kết nối, nghỉ ngơi 1 xíu
    delay(500);
  }
}
