/*
  ESP-NOW TEST — BEN GUI (NodeMCU ESP8266)
  Gui tin nhan test qua ESP-NOW (dang broadcast, khong can biet truoc MAC
  cua ESP32-S3) moi 2 giay.
*/
#include <ESP8266WiFi.h>
extern "C" {
  #include <espnow.h>
}

uint8_t broadcastAddress[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

typedef struct TestMessage {
  uint32_t counter;
  char text[32];
} TestMessage;

TestMessage msg;

void onDataSent(uint8_t *mac_addr, uint8_t sendStatus) {
  Serial.print("[GUI] Trang thai: ");
  Serial.println(sendStatus == 0 ? "THANH CONG" : "THAT BAI");
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== NodeMCU ESP-NOW Sender Test ===");

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();

  if (esp_now_init() != 0) {
    Serial.println("Loi khoi tao ESP-NOW!");
    return;
  }
  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(onDataSent);
  esp_now_add_peer(broadcastAddress, ESP_NOW_ROLE_COMBO, 0, NULL, 0);

  Serial.print("MAC cua NodeMCU: ");
  Serial.println(WiFi.macAddress());
  Serial.println("San sang gui ESP-NOW...");

  msg.counter = 0;
}

void loop() {
  msg.counter++;
  strcpy(msg.text, "Xin chao tu NodeMCU!");
  esp_now_send(broadcastAddress, (uint8_t*)&msg, sizeof(msg));
  Serial.print("[GUI] counter=");
  Serial.println(msg.counter);
  delay(2000);
}
