/*
  ESP-NOW TEST — BEN NHAN (ESP32-S3)
  Nhan tin nhan test tu NodeMCU (ESP8266) qua ESP-NOW, in ra Serial.
*/
#include <WiFi.h>
#include <esp_now.h>

typedef struct TestMessage {
  uint32_t counter;
  char text[32];
} TestMessage;

void onDataRecv(const esp_now_recv_info_t *info, const uint8_t *data, int len) {
  TestMessage msg;
  if (len != sizeof(msg)) {
    Serial.print("[NHAN] Sai kich thuoc goi tin: ");
    Serial.println(len);
    return;
  }
  memcpy(&msg, data, sizeof(msg));

  Serial.print("[NHAN] Tu MAC: ");
  for (int i = 0; i < 6; i++) {
    if (info->src_addr[i] < 0x10) Serial.print("0");
    Serial.print(info->src_addr[i], HEX);
    if (i < 5) Serial.print(":");
  }
  Serial.print(" | counter=");
  Serial.print(msg.counter);
  Serial.print(" | text=");
  Serial.println(msg.text);
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== ESP32-S3 ESP-NOW Receiver Test ===");

  WiFi.mode(WIFI_STA);
  Serial.print("MAC cua ESP32-S3: ");
  Serial.println(WiFi.macAddress());

  if (esp_now_init() != ESP_OK) {
    Serial.println("Loi khoi tao ESP-NOW!");
    return;
  }
  esp_now_register_recv_cb(onDataRecv);
  Serial.println("San sang nhan ESP-NOW...");
}

void loop() {
  delay(100);
}
