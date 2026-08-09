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

BLEServer* pServer = NULL;
BLECharacteristic* pCharRPM = NULL;
BLECharacteristic* pCharSpeed = NULL;
BLECharacteristic* pCharECT = NULL;
BLECharacteristic* pCharTPS = NULL;
BLECharacteristic* pCharBattery = NULL;
bool deviceConnected = false;

// Hardware Serial cho K-Line (L9637D)
#define RX_PIN 16
#define TX_PIN 17
HardwareSerial KLineSerial(1);

// Biến lưu trữ dữ liệu
uint16_t currentRPM = 0;
uint8_t currentSpeed = 0;
int8_t currentECT = 0;
uint8_t currentTPS = 0;
float currentVolt = 12.5;

// Callback xử lý kết nối BLE
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
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

  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // Giúp iPhone kết nối nhanh hơn
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Da phat song BLE. Cho ket noi...");
}

void setup() {
  Serial.begin(115200);
  
  // Khởi tạo Serial cho K-Line (Baudrate 10400 chuẩn Honda)
  KLineSerial.begin(10400, SERIAL_8N1, RX_PIN, TX_PIN);
  
  // Khởi tạo Bluetooth LE
  setupBLE();
}

void loop() {
  if (deviceConnected) {
    // ==========================================
    // KHU VỰC 1: CODE THẬT (GIAO TIẾP VỚI XE)
    // Sẽ viết code chuẩn KWP2000 / ISO-9141 ở đây
    // ==========================================
    // requestPID(0x0C); ...

    // ==========================================
    // KHU VỰC 2: MOCK DATA (GIẢ LẬP DỮ LIỆU ĐỂ TEST APP)
    // ==========================================
    // Tạo hiệu ứng vặn ga ảo
    static bool accelerating = true;
    if (accelerating) {
      currentRPM += random(50, 400);
      if (currentRPM >= 12000) accelerating = false;
    } else {
      currentRPM -= random(50, 600);
      if (currentRPM <= 1500) accelerating = true;
    }

    currentSpeed = (uint8_t)(currentRPM / 100);
    currentECT = 85 + random(-2, 3);
    currentTPS = (uint8_t)((currentRPM * 100) / 12000);
    currentVolt = 14.2 + (random(-10, 10) / 100.0);

    // Bắn dữ liệu qua BLE
    pCharRPM->setValue((uint8_t*)&currentRPM, 2);
    pCharRPM->notify();
    
    pCharSpeed->setValue(&currentSpeed, 1);
    pCharSpeed->notify();
    
    pCharECT->setValue((uint8_t*)&currentECT, 1);
    pCharECT->notify();
    
    pCharTPS->setValue(&currentTPS, 1);
    pCharTPS->notify();
    
    // Gửi dạng chuỗi hoặc số thực, ở đây dùng string cho dễ xử lý bên App
    String voltStr = String(currentVolt, 1);
    pCharBattery->setValue(voltStr.c_str());
    pCharBattery->notify();

    delay(50); // Refresh rate ~20 FPS (cực mượt)
  } else {
    // Không có ai kết nối, nghỉ ngơi 1 xíu
    delay(500);
  }
}
