/*
  HONDA K-LINE (KWP2000) DIAGNOSTIC SCANNER
  Board: ESP32-S3 Dev Module
  Author: Antigravity AI Labs

  Mô tả:
  Chương trình này biến ESP32-S3 thành một máy quét lỗi kết nối với xe máy Honda (AB 2025).
  Nó thực hiện quy trình Fast Initialization (Đánh thức ECU 25ms), sau đó
  thiết lập cổng Serial1 ở 10400 baud và gửi lệnh "Start Communication".
*/

#include <Arduino.h>

// Định nghĩa chân kết nối với IC L9637D
#define K_LINE_RX_PIN 16
#define K_LINE_TX_PIN 17
#define K_LINE_BAUD   10400 // Tốc độ chuẩn của ISO 14230 (KWP2000)

void setup() {
  // Cổng Serial cắm cáp USB nối với Máy tính để xem Log (115200 baud)
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=============================================");
  Serial.println(" HONDA K-LINE SCANNER - ANTIGRAVITY AI LABS ");
  Serial.println("=============================================");
  Serial.println("Go vao Serial Monitor ky tu 'i' de bat dau Fast Init va ket noi ECU.");
  Serial.println("Cho doi lenh tu nguoi dung...\n");

  // Khởi tạo cổng Serial1 để giao tiếp với L9637D
  Serial1.begin(K_LINE_BAUD, SERIAL_8N1, K_LINE_RX_PIN, K_LINE_TX_PIN);
}

// Hàm in các byte ra màn hình dạng Hex (hệ cơ số 16)
void printHex(uint8_t *data, int len, const char* prefix) {
  Serial.print(prefix);
  for (int i = 0; i < len; i++) {
    if (data[i] < 0x10) Serial.print("0");
    Serial.print(data[i], HEX);
    Serial.print(" ");
  }
  Serial.println();
}

// Hàm đánh thức ECU (Fast Initialization)
void performFastInit() {
  Serial.println("\n[SYSTEM] Bat dau Fast Initialization...");

  // Tạm thời tắt Serial1 để dùng chân TX như một công tắc điện (GPIO) bình thường
  Serial1.end();
  pinMode(K_LINE_TX_PIN, OUTPUT);

  // 1. Giữ trạng thái rảnh (Idle) mức Cao trong 300ms
  digitalWrite(K_LINE_TX_PIN, HIGH);
  delay(300);

  // 2. Kéo xuống mức Thấp (LOW) chính xác 25ms (Bước kích điện)
  digitalWrite(K_LINE_TX_PIN, LOW);
  delay(25);

  // 3. Kéo lên mức Cao (HIGH) chính xác 25ms
  digitalWrite(K_LINE_TX_PIN, HIGH);
  delay(25);

  // 4. Bật lại Serial1 ngay lập tức để chuẩn bị gửi/nhận Data
  Serial1.begin(K_LINE_BAUD, SERIAL_8N1, K_LINE_RX_PIN, K_LINE_TX_PIN);
  delay(2); // Chờ 2ms ổn định bus

  // 5. Gửi lệnh Start Communication (0xC1 0x33 0xF1 0x81 0x66)
  /*
    Giải mã:
    0xC1 : Format byte (Header)
    0x33 : Target Address (Địa chỉ ECU Honda)
    0xF1 : Tester Address (Địa chỉ của ESP32 Scanner)
    0x81 : Lệnh Start Communication (Xin chào, hãy nói chuyện)
    0x66 : Checksum (C1 + 33 + F1 + 81 = 266 -> byte cuối là 66)
  */
  uint8_t startCommReq[] = {0xC1, 0x33, 0xF1, 0x81, 0x66};

  Serial1.write(startCommReq, sizeof(startCommReq));
  printHex(startCommReq, sizeof(startCommReq), "[ESP32 TX] ");

  Serial.println("[SYSTEM] Dang lang nghe phan hoi tu xe...");
}

void loop() {
  // 1. Kiểm tra xem người dùng có gõ lệnh từ máy tính không
  if (Serial.available()) {
    char c = Serial.read();
    // Nếu gõ 'i' hoặc 'I', thực hiện kích hoạt ECU
    if (c == 'i' || c == 'I') {
      performFastInit();
    }
  }

  // 2. Đọc dữ liệu đổ về từ K-Line (L9637D -> ESP32)
  if (Serial1.available()) {
    Serial.print("[K-LINE BUS] ");
    while (Serial1.available()) {
      uint8_t b = Serial1.read();
      if (b < 0x10) Serial.print("0");
      Serial.print(b, HEX);
      Serial.print(" ");

      // Chờ một chút để các byte tiếp theo kịp bay tới
      delay(2);
    }
    Serial.println();
  }
}
