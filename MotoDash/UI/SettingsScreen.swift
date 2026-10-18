import SwiftUI
import UniformTypeIdentifiers

struct SettingsScreen: View {
    let settings: AppSettings
    let connectionState: BleConnectionState
    let notificationAccessGranted: Bool
    var uploadState: AudioUploadState = .idle
    let onSetTheme: (String) -> Void
    var onSetBrandLogo: (String) -> Void = { _ in }
    var onSetBleDeviceName: (String) -> Void = { _ in }
    let onSetUnitSpeed: (String) -> Void
    let onSetUnitTemp: (String) -> Void
    let onSetSpeedWarnEnabled: (Bool) -> Void
    let onSetShiftWarnEnabled: (Bool) -> Void
    let onSetRpmWarnVal: (Int) -> Void
    let onSetAutoConnect: (Bool) -> Void
    let onSetWakeLock: (Bool) -> Void
    let onSetFullscreen: (Bool) -> Void
    let onSetDemoMode: (Bool) -> Void
    let onTriggerC4Mode: () -> Void
    let onSetAutoHideMusic: (Bool) -> Void
    var onSetSoundBootMusic: (Bool) -> Void = { _ in }
    var onSetSoundConnection: (Bool) -> Void = { _ in }
    var onSetSoundShiftWarn: (Bool) -> Void = { _ in }
    var onSetSoundSpeedWarn: (Bool) -> Void = { _ in }
    var onSetSoundEctWarn: (Bool) -> Void = { _ in }
    var onSetSoundIgnitionWarn: (Bool) -> Void = { _ in }
    var onSelectBootTrack: (Int, String) -> Void = { _, _ in }
    var onSelectWarnTrack: (Int, String) -> Void = { _, _ in }
    var onSetSpeakerVolume: (Int, String) -> Void = { _, _ in }
    var onUploadBootMusic: (URL) -> Void = { _ in }
    var onUseDefaultBootMusic: () -> Void = {}
    let onDisconnect: () -> Void
    let onReconnect: () -> Void
    let onNavigateTripHistory: () -> Void
    let onNavigateDiagnostics: () -> Void
    var onNavigateLogs: () -> Void = {}
    var onNavigateDrag: () -> Void = {}
    let onClearAllTrips: () -> Void
    let onOpenNotificationAccessSettings: () -> Void
    let onBack: () -> Void

    @State private var confirmClear = false
    @State private var tab = 0
    @State private var showFileImporter = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    RacingStripe()
                    ScreenHeader(title: "CÀI ĐẶT", onBack: onBack)
                        .padding(.leading, 12)
                }
                .padding(.bottom, 12)

                TabRow(selected: tab, onSelect: { tab = $0 })

                switch tab {
                case 0:
                    GeneralTab(
                        settings: settings,
                        connectionState: connectionState,
                        onSetTheme: onSetTheme,
                        onSetBrandLogo: onSetBrandLogo,
                        onSetBleDeviceName: onSetBleDeviceName,
                        onSetUnitSpeed: onSetUnitSpeed,
                        onSetUnitTemp: onSetUnitTemp,
                        onSetSpeedWarnEnabled: onSetSpeedWarnEnabled,
                        onSetShiftWarnEnabled: onSetShiftWarnEnabled,
                        onSetRpmWarnVal: onSetRpmWarnVal,
                        onSetAutoConnect: onSetAutoConnect,
                        onSetWakeLock: onSetWakeLock,
                        onSetFullscreen: onSetFullscreen,
                        onSetDemoMode: onSetDemoMode,
                        onTriggerC4Mode: onTriggerC4Mode,
                        onDisconnect: onDisconnect,
                        onReconnect: onReconnect,
                        onNavigateDiagnostics: onNavigateDiagnostics,
                        onNavigateLogs: onNavigateLogs,
                        onNavigateDrag: onNavigateDrag
                    )
                case 1:
                    SoundTab(
                        settings: settings,
                        connectionState: connectionState,
                        uploadState: uploadState,
                        onSetSoundBootMusic: onSetSoundBootMusic,
                        onSetSoundConnection: onSetSoundConnection,
                        onSetSoundShiftWarn: onSetSoundShiftWarn,
                        onSetSoundSpeedWarn: onSetSoundSpeedWarn,
                        onSetSoundEctWarn: onSetSoundEctWarn,
                        onSetSoundIgnitionWarn: onSetSoundIgnitionWarn,
                        onSelectBootTrack: onSelectBootTrack,
                        onSelectWarnTrack: onSelectWarnTrack,
                        onSetSpeakerVolume: onSetSpeakerVolume,
                        onPickBootMusicFile: { showFileImporter = true },
                        onUseDefaultBootMusic: onUseDefaultBootMusic
                    )
                case 2:
                    TripTab(
                        confirmClear: confirmClear,
                        onNavigateTripHistory: onNavigateTripHistory,
                        onClearAllTrips: {
                            if confirmClear {
                                onClearAllTrips()
                                confirmClear = false
                            } else {
                                confirmClear = true
                            }
                        }
                    )
                default:
                    MusicTab(
                        autoHideMusic: settings.autoHideMusic,
                        onSetAutoHideMusic: onSetAutoHideMusic,
                        notificationAccessGranted: notificationAccessGranted,
                        onOpenNotificationAccessSettings: onOpenNotificationAccessSettings
                    )
                }

                Text("Honda Air Blade 125 · ISO 14230-4 K-Line · v0.3.0 iOS")
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(11))
                    .tracking(1)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
            }
            .padding(16)
        }
        .dashboardBackground()
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio, .wav],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                onUploadBootMusic(url)
            }
        }
    }
}

private struct TabRow: View {
    let selected: Int
    let onSelect: (Int) -> Void

    private let labels = ["CHUNG", "ÂM THANH", "HÀNH TRÌNH", "NHẠC"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(labels.indices, id: \.self) { index in
                let active = selected == index
                Text(labels[index])
                    .foregroundColor(active ? .dashCyan : .dashTextSecondary)
                    .font(DashFont.shareTechMono(12))
                    .tracking(2)
                    .fontWeight(active ? .bold : .regular)
                    .modifier(ConditionalTabGlow(active: active))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(argb: 0xFF111111))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(active ? Color.dashCyan : Color(argb: 0xFF333333), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture { onSelect(index) }
            }
        }
        .padding(.bottom, 20)
    }
}

private struct ConditionalTabGlow: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active {
            content.textGlow(.dashCyan, radius: 8)
        } else {
            content
        }
    }
}

private struct GeneralTab: View {
    let settings: AppSettings
    let connectionState: BleConnectionState
    let onSetTheme: (String) -> Void
    var onSetBrandLogo: (String) -> Void = { _ in }
    var onSetBleDeviceName: (String) -> Void = { _ in }
    let onSetUnitSpeed: (String) -> Void
    let onSetUnitTemp: (String) -> Void
    let onSetSpeedWarnEnabled: (Bool) -> Void
    let onSetShiftWarnEnabled: (Bool) -> Void
    let onSetRpmWarnVal: (Int) -> Void
    let onSetAutoConnect: (Bool) -> Void
    let onSetWakeLock: (Bool) -> Void
    let onSetFullscreen: (Bool) -> Void
    let onSetDemoMode: (Bool) -> Void
    let onTriggerC4Mode: () -> Void
    let onDisconnect: () -> Void
    let onReconnect: () -> Void
    let onNavigateDiagnostics: () -> Void
    var onNavigateLogs: () -> Void = {}
    var onNavigateDrag: () -> Void = {}

    @State private var bleNameDraft: String = ""

    private var statusInfo: (String, Color, String) {
        switch connectionState {
        case .connected: return ("Đã kết nối", .dashGreen, "wifi")
        case .connecting, .scanning: return ("Đang kết nối...", .dashAmber, "wifi.exclamationmark")
        default: return ("Chưa kết nối", .dashTextSecondary, "wifi.slash")
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            SectionTitle("BLUETOOTH")
            BluetoothHero(
                bleName: settings.bleDeviceName,
                statusText: statusInfo.0,
                statusColor: statusInfo.1,
                systemImage: statusInfo.2,
                onReconnect: onReconnect,
                onDisconnect: onDisconnect
            )
            GroupCard {
                ToggleRow(emoji: "🔄", color: .dashCyan, label: "Tự động kết nối", desc: "Tự quét và kết nối \(settings.bleDeviceName) khi mở app", checked: settings.autoConnect, onCheckedChange: onSetAutoConnect)
                DashDivider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("ĐỔI TÊN BLUETOOTH CỦA MẠCH ESP32-S3 (LƯU VÀO CHIP)")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(11))
                        .tracking(1)
                    HStack(spacing: 8) {
                        TextField("Nhập tên Bluetooth mới...", text: $bleNameDraft)
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.4))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashCyan.opacity(0.4), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button(action: {
                            let target = bleNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !target.isEmpty {
                                onSetBleDeviceName(target)
                            }
                        }) {
                            Text("LƯU TÊN")
                                .foregroundColor(.black)
                                .font(DashFont.shareTechMono(12))
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(Color.dashCyan)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .onAppear {
                    if bleNameDraft.isEmpty {
                        bleNameDraft = settings.bleDeviceName
                    }
                }
            }

            SectionTitle("GIAO DIỆN ĐỒNG HỒ (7 THEMES)")
            GroupCard {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ThemeChip(label: "RACE", value: "sport", current: settings.theme, onSelect: onSetTheme)
                        ThemeChip(label: "CYBER", value: "cyber", current: settings.theme, onSelect: onSetTheme)
                        ThemeChip(label: "AIRBLADE", value: "airblade", current: settings.theme, onSelect: onSetTheme)
                        ThemeChip(label: "SUPERBIKE", value: "superbike", current: settings.theme, onSelect: onSetTheme)
                    }
                    HStack(spacing: 8) {
                        ThemeChip(label: "DAILY", value: "daily", current: settings.theme, onSelect: onSetTheme)
                        ThemeChip(label: "CLASSIC", value: "classic", current: settings.theme, onSelect: onSetTheme)
                        ThemeChip(label: "NITRO", value: "crazy", current: settings.theme, onSelect: onSetTheme)
                    }
                }
                .padding(12)
            }

            SectionTitle("HÃNG XE (LOGO ĐỒNG HỒ)")
            GroupCard {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        BrandChip(label: "HONDA", value: "honda", current: settings.brandLogo, onSelect: onSetBrandLogo)
                        BrandChip(label: "BMW", value: "bmw", current: settings.brandLogo, onSelect: onSetBrandLogo)
                        BrandChip(label: "YAMAHA", value: "yamaha", current: settings.brandLogo, onSelect: onSetBrandLogo)
                    }
                    HStack(spacing: 8) {
                        BrandChip(label: "DUCATI", value: "ducati", current: settings.brandLogo, onSelect: onSetBrandLogo)
                        BrandChip(label: "KAWASAKI", value: "kawasaki", current: settings.brandLogo, onSelect: onSetBrandLogo)
                        BrandChip(label: "REDBULL", value: "redbull", current: settings.brandLogo, onSelect: onSetBrandLogo)
                    }
                }
                .padding(12)
            }

            SectionTitle("ĐƠN VỊ ĐO LƯỜNG")
            GroupCard {
                HStack(spacing: 8) {
                    ThemeChip(label: "KM/H", value: "kmh", current: settings.unitSpeed, onSelect: onSetUnitSpeed)
                    ThemeChip(label: "MPH", value: "mph", current: settings.unitSpeed, onSelect: onSetUnitSpeed)
                    ThemeChip(label: "°C", value: "c", current: settings.unitTemp, onSelect: onSetUnitTemp)
                    ThemeChip(label: "°F", value: "f", current: settings.unitTemp, onSelect: onSetUnitTemp)
                }
                .padding(12)
            }

            SectionTitle("CẢNH BÁO TỐC ĐỘ")
            GroupCard {
                ToggleRow(emoji: "⚠️", color: .dashRed, label: "Cảnh báo quá tốc", desc: "Dựa theo bản đồ GPS (TomTom/OSM)", checked: settings.speedWarnEnabled, onCheckedChange: onSetSpeedWarnEnabled)
            }

            SectionTitle("CẢNH BÁO VÒNG TUA")
            GroupCard {
                ToggleRow(emoji: "💨", color: .dashAmber, label: "Cảnh báo shift (đổi số)", desc: "Flash đỏ khi RPM cao", checked: settings.shiftWarnEnabled, onCheckedChange: onSetShiftWarnEnabled)
                if settings.shiftWarnEnabled {
                    DashDivider()
                    HStack {
                        EmojiBadge(emoji: "🔥", color: .dashAmber)
                        Text("Ngưỡng Shift Light")
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(14))
                            .padding(.leading, 12)
                        Spacer()
                        StepperButton(text: "−") { onSetRpmWarnVal(min(max(settings.rpmWarnVal - 1, 4), 16)) }
                        Text("\(settings.rpmWarnVal)k")
                            .foregroundColor(.dashAmber)
                            .font(DashFont.shareTechMono(15))
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                        StepperButton(text: "+") { onSetRpmWarnVal(min(max(settings.rpmWarnVal + 1, 4), 16)) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            SectionTitle("CHỨC NĂNG NÂNG CAO & NHẬT KÝ")
            GroupCard {
                NavRow(emoji: "📋", color: .dashGreen, label: "Nhật ký hệ thống (Live Log)", desc: "Theo dõi trực tiếp BLE, K-Line, gói HEX & mã lỗi", onClick: onNavigateLogs)
                DashDivider()
                NavRow(emoji: "🔧", color: .dashRed, label: "Chẩn đoán ECU (10 thông số)", desc: "Xem IAT, O2, Góc đánh lửa, Phun xăng Ti, Chân chống", onClick: onNavigateDiagnostics)
                DashDivider()
                NavRow(emoji: "🏁", color: .dashCyan, label: "Đo gia tốc (Drag)", desc: "Bấm giờ 0-40, 0-60 km/h, 100m", onClick: onNavigateDrag)
                DashDivider()
                ToggleRow(emoji: "🎮", color: .dashAmber, label: "Demo mode", desc: "Dữ liệu giả lập, không cần ESP32", checked: settings.demoMode, onCheckedChange: onSetDemoMode)
                if connectionState == .connected {
                    DashDivider()
                    NavRow(emoji: "💣", color: .dashRed, label: "Chế độ C4", desc: "Đừng bấm. Nghiêm túc đấy.", onClick: onTriggerC4Mode)
                }
            }

            SectionTitle("MÀN HÌNH")
            GroupCard {
                ToggleRow(emoji: "🔆", color: .dashCyan, label: "Giữ sáng màn hình", desc: nil, checked: settings.wakeLock, onCheckedChange: onSetWakeLock)
                DashDivider()
                ToggleRow(emoji: "⛶", color: .dashCyan, label: "Toàn màn hình", desc: nil, checked: settings.fullscreen, onCheckedChange: onSetFullscreen)
            }
        }
    }
}

private struct SoundTab: View {
    let settings: AppSettings
    let connectionState: BleConnectionState
    let uploadState: AudioUploadState
    let onSetSoundBootMusic: (Bool) -> Void
    let onSetSoundConnection: (Bool) -> Void
    let onSetSoundShiftWarn: (Bool) -> Void
    let onSetSoundSpeedWarn: (Bool) -> Void
    let onSetSoundEctWarn: (Bool) -> Void
    let onSetSoundIgnitionWarn: (Bool) -> Void
    let onSelectBootTrack: (Int, String) -> Void
    let onSelectWarnTrack: (Int, String) -> Void
    let onSetSpeakerVolume: (Int, String) -> Void
    let onPickBootMusicFile: () -> Void
    let onUseDefaultBootMusic: () -> Void

    private var selectedBootTrack: Int { settings.bootTrackId }
    private var selectedWarnTrack: Int { settings.warnTrackId }
    private var selectedVolIdx: Int { settings.speakerVolIdx }

    var body: some View {
        VStack(alignment: .leading) {
            SectionTitle("CHỌN NHẠC KHỞI ĐỘNG XE (24kHz / 16kHz LOSSLESS)")
            GroupCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bấm vào thẻ để LƯU vào bộ nhớ App & ESP32, đồng thời PHÁT THỬ ngay trên loa MAX98357A + Còi HXD:")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(11))
                        .padding(.bottom, 4)

                    SoundTrackCard(
                        badge: "#6 ANIME",
                        title: "Okaerinasai (Chào Chủ Nhân)",
                        subtitle: "Giọng nữ Anime 24kHz Siêu Nét + 2 tiếng Bíp còi HXD chào",
                        selected: settings.soundBootMusic && selectedBootTrack == 0,
                        accent: .dashCyan,
                        onClick: { onSelectBootTrack(0, "#6 Okaerinasai") }
                    )
                    SoundTrackCard(
                        badge: "#7 MECHA",
                        title: "Gundam Cockpit System Online",
                        subtitle: "Âm hiệu buồng lái chiến đấu 24kHz + Còi HXD quét hệ thống",
                        selected: settings.soundBootMusic && selectedBootTrack == 1,
                        accent: .dashGreen,
                        onClick: { onSelectBootTrack(1, "#7 Gundam") }
                    )
                    SoundTrackCard(
                        badge: "#12 STREAMER",
                        title: "Độ Mixi Chào Anh Em Nhé!",
                        subtitle: "Giọng Độ Mixi chuẩn 16kHz + Nhạc hiệu vui nhộn",
                        selected: settings.soundBootMusic && selectedBootTrack == 2,
                        accent: .dashAmber,
                        onClick: { onSelectBootTrack(2, "#12 Độ Mixi") }
                    )
                    SoundTrackCard(
                        badge: "🔇 TẮT NHẠC",
                        title: "Tắt Hẳn Nhạc Khởi Động Xe (Im Lặng)",
                        subtitle: "Không phát nhạc & không kêu còi chào khi bật khóa điện",
                        selected: !settings.soundBootMusic || selectedBootTrack == 255,
                        accent: .dashRed,
                        onClick: { onSelectBootTrack(255, "🔇 Tắt nhạc khởi động") }
                    )
                }
                .padding(12)
            }

            SectionTitle("GIỌNG CẢNH BÁO QUÊN TẮT KHÓA (SAU 3 PHÚT)")
            GroupCard {
                VStack(alignment: .leading, spacing: 8) {
                    SoundTrackCard(
                        badge: "#9 TIẾNG VIỆT",
                        title: "Chủ nhân ơi! Quên tắt chìa khóa xe kìa!",
                        subtitle: "Giọng nữ Tiếng Việt 24kHz + Còi HXD bíp nháy khẩn cấp",
                        selected: settings.soundIgnitionWarn && selectedWarnTrack == 3,
                        accent: .dashRed,
                        onClick: { onSelectWarnTrack(3, "#9 Cảnh báo Tiếng Việt") }
                    )
                    SoundTrackCard(
                        badge: "#11 TIẾNG NHẬT",
                        title: "Keikoku! Kī o wasurete imasu yo!",
                        subtitle: "Giọng Anime Nhật 24kHz cảnh báo quên chìa khóa + Còi HXD",
                        selected: settings.soundIgnitionWarn && selectedWarnTrack == 4,
                        accent: .dashAmber,
                        onClick: { onSelectWarnTrack(4, "#11 Cảnh báo Tiếng Nhật") }
                    )
                    SoundTrackCard(
                        badge: "🔇 TẮT NHẮC",
                        title: "Tắt Hẳn Cảnh Báo Quên Tắt Khóa (Im Lặng)",
                        subtitle: "Không phát giọng nhắc & không hú còi HXD khi dừng xe",
                        selected: !settings.soundIgnitionWarn || selectedWarnTrack == 255,
                        accent: .dashRed,
                        onClick: { onSelectWarnTrack(255, "🔇 Tắt cảnh báo quên khóa") }
                    )
                }
                .padding(12)
            }

            SectionTitle("ÂM LƯỢNG LOA MAX98357A (ĐÃ LƯU BỘ NHỚ APP)")
            GroupCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        VolumeChip(label: "135% RÕ", selected: selectedVolIdx == 0) {
                            onSetSpeakerVolume(0, "135% Rõ")
                        }
                        VolumeChip(label: "200% XUYÊN CỐP", selected: selectedVolIdx == 1) {
                            onSetSpeakerVolume(1, "200% Xuyên Cốp")
                        }
                    }
                    HStack(spacing: 8) {
                        VolumeChip(label: "100% VỪA", selected: selectedVolIdx == 2) {
                            onSetSpeakerVolume(2, "100% Vừa")
                        }
                        VolumeChip(label: "50% NHỎ", selected: selectedVolIdx == 3) {
                            onSetSpeakerVolume(3, "50% Nhỏ")
                        }
                    }
                    VolumeChip(label: "🔇 0% TẮT HẲN LOA (IM LẶNG)", selected: selectedVolIdx == 4) {
                        onSetSpeakerVolume(4, "0% Tắt hẳn loa")
                    }
                }
                .padding(12)
            }

            SectionTitle("CÔNG TẮC BẬT / TẮT TỪNG LOẠI ÂM BÁO")
            GroupCard {
                HStack(spacing: 8) {
                    Button(action: {
                        onSetSoundBootMusic(false)
                        onSetSoundConnection(false)
                        onSetSoundShiftWarn(false)
                        onSetSoundSpeedWarn(false)
                        onSetSoundEctWarn(false)
                        onSetSoundIgnitionWarn(false)
                    }) {
                        Text("🔇 TẮT HẾT TẤT CẢ")
                            .foregroundColor(.dashRed)
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.dashRed.opacity(0.14))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashRed, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        onSetSoundBootMusic(true)
                        onSetSoundConnection(true)
                        onSetSoundShiftWarn(true)
                        onSetSoundSpeedWarn(true)
                        onSetSoundEctWarn(true)
                        onSetSoundIgnitionWarn(true)
                    }) {
                        Text("🔊 BẬT LẠI TẤT CẢ")
                            .foregroundColor(.dashGreen)
                            .font(DashFont.shareTechMono(12))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.dashGreen.opacity(0.14))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dashGreen, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                DashDivider()
                ToggleRow(emoji: "🎵", color: .dashCyan, label: "Nhạc chào mở máy (Boot Music)", desc: "Phát bài nhạc đã chọn (#6 / #7 / #12) khi bật khóa xe sau 6s", checked: settings.soundBootMusic, onCheckedChange: onSetSoundBootMusic)
                DashDivider()
                ToggleRow(emoji: "📱", color: .dashGreen, label: "Âm báo kết nối Bluetooth", desc: "Tiếng bíp còi HXD khi điện thoại kết nối / ngắt kết nối", checked: settings.soundConnection, onCheckedChange: onSetSoundConnection)
                DashDivider()
                ToggleRow(emoji: "🏎️", color: .dashAmber, label: "Còi / Loa báo Shift-light", desc: "Bíp cảnh báo khi tua máy ≥ 11.000 RPM", checked: settings.soundShiftWarn, onCheckedChange: onSetSoundShiftWarn)
                DashDivider()
                ToggleRow(emoji: "⚡", color: .dashRed, label: "Còi / Loa báo quá tốc độ", desc: "Bíp cảnh báo khi tốc độ xe ≥ 80 km/h", checked: settings.soundSpeedWarn, onCheckedChange: onSetSoundSpeedWarn)
                DashDivider()
                ToggleRow(emoji: "🌡️", color: .dashRed, label: "Còi / Loa báo quá nhiệt nước mát", desc: "Bíp cảnh báo khi nhiệt độ nước ≥ 105°C", checked: settings.soundEctWarn, onCheckedChange: onSetSoundEctWarn)
                DashDivider()
                ToggleRow(emoji: "🔑", color: .dashAmber, label: "Cảnh báo quên tắt khóa điện", desc: "Phát giọng #9/#11 + hú còi HXD sau 3 phút xe dừng", checked: settings.soundIgnitionWarn, onCheckedChange: onSetSoundIgnitionWarn)
            }

            SectionTitle("UPLOAD FILE NHẠC TÙY CHỈNH QUA BLUETOOTH")
            GroupCard {
                let connected = connectionState == .connected
                let busy: Bool = {
                    if case .uploading = uploadState { return true }
                    return false
                }()
                let statusDesc: String = {
                    switch uploadState {
                    case .idle: return connected ? "Chọn file WAV (16kHz/24kHz 16-bit, tối đa 12s)" : "Cần kết nối BLE với ESP32 trước"
                    case .uploading(let pct): return "Đang truyền qua BLE: \(Int(pct * 100))%"
                    case .done: return "Đã nạp xong — bật lại khóa xe để nghe thử"
                    case .error(let msg): return "Lỗi: \(msg)"
                    }
                }()
                NavRow(
                    emoji: "📂",
                    color: connected ? .dashCyan : .dashTextSecondary,
                    label: "Chọn file WAV nạp vào ESP32",
                    desc: statusDesc,
                    labelColor: connected ? .white : .dashTextSecondary,
                    chevron: busy ? "..." : "CHỌN",
                    onClick: { if connected && !busy { onPickBootMusicFile() } }
                )
                DashDivider()
                NavRow(
                    emoji: "↩️",
                    color: .dashAmber,
                    label: "Dùng lại kho 5 nhạc Lossless mặc định",
                    desc: "Quay về nhạc #6 / #7 / #12 trong bộ nhớ PROGMEM",
                    onClick: { if connected && !busy { onUseDefaultBootMusic() } }
                )
            }
        }
    }
}

private struct SoundTrackCard: View {
    let badge: String
    let title: String
    let subtitle: String
    let selected: Bool
    let accent: Color
    let onClick: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(badge)
                        .foregroundColor(.black)
                        .font(DashFont.shareTechMono(10))
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text(title)
                        .foregroundColor(selected ? accent : .white)
                        .font(DashFont.shareTechMono(13))
                        .fontWeight(.bold)
                }
                Text(subtitle)
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(11))
            }
            Spacer()
            Text(selected ? "▶ ĐANG CHỌN" : "▶ NGHE THỬ")
                .foregroundColor(selected ? accent : .dashTextSecondary)
                .font(DashFont.shareTechMono(11))
                .fontWeight(.bold)
                .padding(.leading, 8)
        }
        .padding(12)
        .background(selected ? accent.opacity(0.12) : Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selected ? accent : Color.dashCardBorder, lineWidth: selected ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture(perform: onClick)
    }
}

private struct VolumeChip: View {
    let label: String
    let selected: Bool
    let onClick: () -> Void

    var body: some View {
        Text(label)
            .foregroundColor(selected ? .dashCyan : .dashTextSecondary)
            .font(DashFont.shareTechMono(12))
            .fontWeight(selected ? .bold : .regular)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.dashCyan.opacity(0.14) : Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? Color.dashCyan : Color.dashCardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture(perform: onClick)
    }
}

private struct TripTab: View {
    let confirmClear: Bool
    let onNavigateTripHistory: () -> Void
    let onClearAllTrips: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            SectionTitle("HÀNH TRÌNH (TRIP TRACKER)")
            GroupCard {
                NavRow(emoji: "🗺️", color: .dashCyan, label: "Xem lịch sử hành trình", desc: "Danh sách các chuyến đi đã lưu", onClick: onNavigateTripHistory)
                DashDivider()
                NavRow(
                    emoji: "🗑️",
                    color: .dashRed,
                    label: "Xóa tất cả lịch sử",
                    desc: confirmClear ? "Chạm lần nữa để xác nhận" : "Xóa mọi dữ liệu chuyến đi vĩnh viễn",
                    labelColor: .dashRed,
                    onClick: onClearAllTrips
                )
            }
        }
    }
}

private struct MusicTab: View {
    let autoHideMusic: Bool
    let onSetAutoHideMusic: (Bool) -> Void
    let notificationAccessGranted: Bool
    let onOpenNotificationAccessSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            SectionTitle("TRÌNH PHÁT NHẠC")
            GroupCard {
                ToggleRow(emoji: "🎵", color: .dashCyan, label: "Tự động ẩn", desc: "Ẩn trình phát khi không có nhạc", checked: autoHideMusic, onCheckedChange: onSetAutoHideMusic)
                DashDivider()
                NavRow(
                    emoji: notificationAccessGranted ? "🔔" : "⚠️",
                    color: notificationAccessGranted ? .dashGreen : .dashRed,
                    label: "Quyền truy cập thư viện nhạc",
                    desc: notificationAccessGranted ? "Đã cấp quyền" : "Cần cấp để nhận diện nhạc đang phát",
                    chevron: notificationAccessGranted ? "✓" : "CẤP QUYỀN",
                    onClick: onOpenNotificationAccessSettings
                )
            }
        }
    }
}

private struct BluetoothHero: View {
    var bleName: String = "HONDA AB125 Lor"
    let statusText: String
    let statusColor: Color
    let systemImage: String
    let onReconnect: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ZStack {
                    Circle().fill(statusColor.opacity(0.12))
                    Image(systemName: systemImage).foregroundColor(statusColor)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(bleName) (ESP32-S3)")
                        .foregroundColor(.dashTextSecondary)
                        .font(DashFont.shareTechMono(11))
                    Text(statusText)
                        .foregroundColor(statusColor)
                        .font(DashFont.shareTechMono(18))
                        .fontWeight(.bold)
                        .textGlow(statusColor, radius: 10)
                }
                .padding(.leading, 12)
                Spacer()
            }
            .padding(16)

            DashDivider()

            HStack(spacing: 0) {
                HeroAction(text: "Kết nối lại", onClick: onReconnect)
                Rectangle().fill(Color.dashDivider).frame(width: 1, height: 44)
                HeroAction(text: "Ngắt kết nối", onClick: onDisconnect)
            }
        }
        .background(Color.dashCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(statusColor.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct HeroAction: View {
    let text: String
    let onClick: () -> Void

    var body: some View {
        Text(text)
            .foregroundColor(.dashCyan)
            .font(DashFont.shareTechMono(13))
            .tracking(2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
            .onTapGesture(perform: onClick)
    }
}

private struct GroupCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color.dashCardBackground)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dashCardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct DashDivider: View {
    var body: some View {
        Rectangle().fill(Color.dashDivider).frame(height: 1)
    }
}

private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .foregroundColor(.dashTextSecondary)
            .font(DashFont.shareTechMono(11))
            .tracking(3)
            .fontWeight(.bold)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .padding(.leading, 4)
    }
}

private struct EmojiBadge: View {
    let emoji: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12))
            Text(emoji).font(.system(size: 15))
        }
        .frame(width: 34, height: 34)
    }
}

private struct ToggleRow: View {
    let emoji: String
    let color: Color
    let label: String
    let desc: String?
    let checked: Bool
    let onCheckedChange: (Bool) -> Void

    var body: some View {
        HStack {
            HStack {
                EmojiBadge(emoji: emoji, color: color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).foregroundColor(.white).font(DashFont.shareTechMono(14))
                    if let desc {
                        Text(desc).foregroundColor(.dashTextSecondary).font(DashFont.shareTechMono(11))
                    }
                }
                .padding(.leading, 12)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { checked }, set: onCheckedChange))
                .labelsHidden()
                .tint(.dashCyan)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { onCheckedChange(!checked) }
    }
}

private struct NavRow: View {
    let emoji: String
    let color: Color
    let label: String
    let desc: String?
    var labelColor: Color = .white
    var chevron: String = "›"
    let onClick: () -> Void

    var body: some View {
        HStack {
            HStack {
                EmojiBadge(emoji: emoji, color: color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).foregroundColor(labelColor).font(DashFont.shareTechMono(14))
                    if let desc {
                        Text(desc).foregroundColor(.dashTextSecondary).font(DashFont.shareTechMono(11))
                    }
                }
                .padding(.leading, 12)
            }
            Spacer()
            Text(chevron).foregroundColor(.dashTextSecondary).font(DashFont.shareTechMono(13))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onClick)
    }
}

private struct ThemeChip: View {
    let label: String
    let value: String
    let current: String
    let onSelect: (String) -> Void

    private var selected: Bool { current == value }

    var body: some View {
        Text(label)
            .foregroundColor(selected ? .dashCyan : .dashTextSecondary)
            .font(DashFont.shareTechMono(12))
            .tracking(1)
            .fontWeight(selected ? .bold : .regular)
            .modifier(ConditionalTabGlow(active: selected))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.dashCyan.opacity(0.1) : Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? Color.dashCyan.opacity(0.6) : Color.dashCardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture { onSelect(value) }
    }
}

private struct BrandChip: View {
    let label: String
    let value: String
    let current: String
    let onSelect: (String) -> Void

    private var selected: Bool { current.lowercased() == value.lowercased() }

    var body: some View {
        HStack(spacing: 6) {
            Image("logo_\(value)")
                .resizable()
                .scaledToFit()
                .frame(height: 18)
            Text(label)
                .foregroundColor(selected ? .dashCyan : .dashTextSecondary)
                .font(DashFont.shareTechMono(11))
                .tracking(1)
                .fontWeight(selected ? .bold : .regular)
                .modifier(ConditionalTabGlow(active: selected))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(selected ? Color.dashCyan.opacity(0.14) : Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Color.dashCyan.opacity(0.7) : Color.dashCardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture { onSelect(value) }
    }
}

private struct StepperButton: View {
    let text: String
    let onClick: () -> Void

    var body: some View {
        ZStack {
            Circle().fill(Color.dashSurfaceRaised)
            Text(text).foregroundColor(.dashCyan).font(DashFont.shareTechMono(16)).fontWeight(.bold)
        }
        .frame(width: 30, height: 30)
        .contentShape(Circle())
        .onTapGesture(perform: onClick)
    }
}

