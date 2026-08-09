const char index_html[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <title>AB 125 Dashboard</title>
  <!-- Ngăn trình duyệt tự động zoom, tạo cảm giác như App thật -->
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0">
  
  <!-- Thư viện Canvas Gauges chuyên vẽ đồng hồ xe -->
  <script src="https://cdn.rawgit.com/Mikhus/canvas-gauges/gh-pages/download/2.1.7/all/gauge.min.js"></script>
  
  <!-- Google Font -->
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;800&display=swap" rel="stylesheet">
  
  <style>
    :root {
      --bg-color: #0b0f19;
      --panel-bg: #111827;
      --accent: #ef4444;
      --text: #f3f4f6;
      --text-muted: #9ca3af;
    }
    
    body {
      background-color: var(--bg-color);
      color: var(--text);
      font-family: 'Outfit', sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
      box-sizing: border-box;
    }

    .header {
      text-align: center;
      margin-bottom: 30px;
    }

    .header h1 {
      margin: 0;
      font-size: 24px;
      font-weight: 800;
      letter-spacing: 1px;
      background: linear-gradient(90deg, #fff, #9ca3af);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .dashboard-container {
      background: var(--panel-bg);
      padding: 30px;
      border-radius: 30px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5), inset 0 1px 1px rgba(255,255,255,0.05);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 30px;
    }

    .gauges-wrapper {
      display: flex;
      gap: 20px;
      flex-wrap: wrap;
      justify-content: center;
    }

    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      margin-top: 20px;
      padding: 10px 20px;
      border-radius: 20px;
      background: rgba(255,255,255,0.03);
      border: 1px solid rgba(255,255,255,0.1);
      font-size: 14px;
      font-weight: 600;
      color: var(--text-muted);
      transition: all 0.3s ease;
    }

    .status-badge.connected { 
      color: #10b981; 
      border-color: rgba(16, 185, 129, 0.3);
      background: rgba(16, 185, 129, 0.05);
    }
    
    .status-badge.connected .dot {
      background: #10b981;
      box-shadow: 0 0 10px #10b981;
    }

    .dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: var(--text-muted);
    }

    /* Hiệu ứng loading nhẹ */
    @keyframes pulse {
      0% { opacity: 1; }
      50% { opacity: 0.5; }
      100% { opacity: 1; }
    }
    .pulsing { animation: pulse 2s infinite; }
  </style>
</head>
<body>

  <div class="header">
    <h1>HONDA AIR BLADE</h1>
  </div>

  <div class="dashboard-container">
    <div class="gauges-wrapper">
      <!-- ĐỒNG HỒ VÒNG TUA (RPM) -->
      <canvas data-type="radial-gauge"
              data-width="300"
              data-height="300"
              data-units="RPM x1000"
              data-title="ENGINE"
              data-min-value="0"
              data-max-value="12"
              data-major-ticks="0,1,2,3,4,5,6,7,8,9,10,11,12"
              data-minor-ticks="2"
              data-stroke-ticks="true"
              data-highlights='[
                  {"from": 9, "to": 12, "color": "rgba(239, 68, 68, .9)"}
              ]'
              data-color-plate="transparent"
              data-color-major-ticks="#f3f4f6"
              data-color-minor-ticks="#4b5563"
              data-color-title="#9ca3af"
              data-color-units="#9ca3af"
              data-color-numbers="#f3f4f6"
              data-color-needle-start="#ef4444"
              data-color-needle-end="#ef4444"
              data-value-box="true"
              data-value-box-border-radius="10"
              data-color-value-box-rect="rgba(255,255,255,0.1)"
              data-color-value-box-rect-end="rgba(255,255,255,0.05)"
              data-color-value-text="#fff"
              data-font-value="Outfit"
              data-animation-rule="linear"
              data-animation-duration="150"
              data-borders="false"
              data-value="0"
              id="rpm-gauge">
      </canvas>

      <!-- Bạn có thể copy thêm Canvas để làm đồng hồ Nhiệt độ (Temp) hoặc Tốc độ (Km/h) -->
    </div>

    <div class="status-badge pulsing" id="ws-status">
      <div class="dot"></div>
      <span id="ws-text">Đang kết nối vào xe...</span>
    </div>
  </div>

  <script>
    var rpmGauge = document.getElementById('rpm-gauge');
    var wsStatus = document.getElementById('ws-status');
    var wsText = document.getElementById('ws-text');
    
    // Kết nối tới WebSocket Server của ESP32 (Thường chạy ở Port 81)
    var gateway = `ws://${window.location.hostname}:81/`;
    var websocket;
    
    function initWebSocket() {
      console.log('Đang mở kết nối WebSocket...');
      websocket = new WebSocket(gateway);
      websocket.onopen = onOpen;
      websocket.onclose = onClose;
      websocket.onmessage = onMessage;
    }
    
    function onOpen(event) {
      console.log('Đã kết nối');
      wsText.innerHTML = 'Đã đồng bộ với ECU';
      wsStatus.classList.add('connected');
      wsStatus.classList.remove('pulsing');
    }
    
    function onClose(event) {
      console.log('Mất kết nối');
      wsText.innerHTML = 'Mất kết nối! Đang thử lại...';
      wsStatus.classList.remove('connected');
      wsStatus.classList.add('pulsing');
      setTimeout(initWebSocket, 2000); // Tự động reconnect sau 2s
    }
    
    function onMessage(event) {
      // Dữ liệu ESP32 đẩy sang (Ví dụ JSON: {"rpm": 1500, "temp": 85})
      try {
        var data = JSON.parse(event.data);
        
        if(data.rpm !== undefined) {
            // Chia 1000 vì mặt đồng hồ mình cấu hình hiển thị 1,2,3... (x1000)
            rpmGauge.setAttribute('data-value', data.rpm / 1000);
        }
        
      } catch (e) {
        console.error("Lỗi parse data:", e);
      }
    }
    
    // Khởi chạy khi load xong trang
    window.addEventListener('load', initWebSocket);
  </script>
</body>
</html>
)rawliteral";
