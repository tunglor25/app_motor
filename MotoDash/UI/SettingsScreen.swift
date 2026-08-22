import SwiftUI

// Structure mirrors the Kotlin source's ui/SettingsScreen.kt exactly: 3 tabs
// (CHUNG/HANH TRINH/NHAC), each row carries a colored emoji icon + label + small
// desc subtitle.
struct SettingsScreen: View {
    let settings: AppSettings
    let connectionState: BleConnectionState
    let notificationAccessGranted: Bool
    let onSetTheme: (String) -> Void
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
    let onDisconnect: () -> Void
    let onReconnect: () -> Void
    let onNavigateTripHistory: () -> Void
    let onNavigateDiagnostics: () -> Void
    var onNavigateDrag: () -> Void = {}
    let onClearAllTrips: () -> Void
    let onOpenNotificationAccessSettings: () -> Void
    let onBack: () -> Void

    @State private var confirmClear = false
    @State private var tab = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    RacingStripe()
                    ScreenHeader(title: "C\u{00C0}I \u{0110}\u{1EB6}T", onBack: onBack)
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
                        onNavigateDrag: onNavigateDrag
                    )
                case 1:
                    SoundTab(
                        settings: settings,
                        onSetSoundBootMusic: onSetSoundBootMusic,
                        onSetSoundConnection: onSetSoundConnection,
                        onSetSoundShiftWarn: onSetSoundShiftWarn,
                        onSetSoundSpeedWarn: onSetSoundSpeedWarn,
                        onSetSoundEctWarn: onSetSoundEctWarn,
                        onSetSoundIgnitionWarn: onSetSoundIgnitionWarn
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

                Text("Honda Air Blade 125 \u{00B7} ISO 9141-2 K-Line \u{00B7} v0.2.0")
                    .foregroundColor(.dashTextSecondary)
                    .font(DashFont.shareTechMono(11))
                    .tracking(1)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
            }
            .padding(16)
        }
        .dashboardBackground()
    }
}

private struct TabRow: View {
    let selected: Int
    let onSelect: (Int) -> Void

    private let labels = ["CHUNG", "\u{00C2}M THANH", "H\u{00C0}NH TR\u{00CC}NH", "NH\u{1EA0}C"]

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
    var onNavigateDrag: () -> Void = {}

    private var statusInfo: (String, Color, String) {
        switch connectionState {
        case .connected: return ("\u{0110}\u{00E3} k\u{1EBF}t n\u{1ED1}i", .dashGreen, "wifi")
        case .connecting, .scanning: return ("\u{0110}ang k\u{1EBF}t n\u{1ED1}i...", .dashAmber, "wifi.exclamationmark")
        default: return ("Ch\u{01B0}a k\u{1EBF}t n\u{1ED1}i", .dashTextSecondary, "wifi.slash")
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            SectionTitle("BLUETOOTH")
            BluetoothHero(statusText: statusInfo.0, statusColor: statusInfo.1, systemImage: statusInfo.2, onReconnect: onReconnect, onDisconnect: onDisconnect)
            GroupCard {
                ToggleRow(emoji: "\u{1F504}", color: .dashCyan, label: "T\u{1EF1} \u{0111}\u{1ED9}ng k\u{1EBF}t n\u{1ED1}i", desc: "K\u{1EBF}t n\u{1ED1}i l\u{1EA1}i khi m\u{1EDF} app", checked: settings.autoConnect, onCheckedChange: onSetAutoConnect)
            }

            SectionTitle("THEME")
            GroupCard {
                HStack(spacing: 8) {
                    ThemeChip(label: "RACE", value: "sport", current: settings.theme, onSelect: onSetTheme)
                    ThemeChip(label: "DAILY", value: "daily", current: settings.theme, onSelect: onSetTheme)
                    ThemeChip(label: "CLASSIC", value: "classic", current: settings.theme, onSelect: onSetTheme)
                }
                .padding(12)
            }

            SectionTitle("\u{0110}\u{01A0}N V\u{1ECA} \u{0110}O L\u{01AF}\u{1EDC}NG")
            GroupCard {
                HStack(spacing: 8) {
                    ThemeChip(label: "KM/H", value: "kmh", current: settings.unitSpeed, onSelect: onSetUnitSpeed)
                    ThemeChip(label: "MPH", value: "mph", current: settings.unitSpeed, onSelect: onSetUnitSpeed)
                    ThemeChip(label: "\u{00B0}C", value: "c", current: settings.unitTemp, onSelect: onSetUnitTemp)
                    ThemeChip(label: "\u{00B0}F", value: "f", current: settings.unitTemp, onSelect: onSetUnitTemp)
                }
                .padding(12)
            }

            SectionTitle("C\u{1EA2}NH B\u{00C1}O T\u{1ED0}C \u{0110}\u{1ED8}")
            GroupCard {
                ToggleRow(emoji: "\u{26A0}\u{FE0F}", color: .dashRed, label: "C\u{1EA3}nh b\u{00E1}o qu\u{00E1} t\u{1ED1}c", desc: "D\u{1EF1}a theo b\u{1EA3}n \u{0111}\u{1ED3} GPS (TomTom/OSM)", checked: settings.speedWarnEnabled, onCheckedChange: onSetSpeedWarnEnabled)
            }

            SectionTitle("C\u{1EA2}NH B\u{00C1}O V\u{00D2}NG TUA")
            GroupCard {
                ToggleRow(emoji: "\u{1F4A8}", color: .dashAmber, label: "C\u{1EA3}nh b\u{00E1}o shift (\u{0111}\u{1ED5}i s\u{1ED1})", desc: "Flash \u{0111}\u{1ECF} khi RPM cao", checked: settings.shiftWarnEnabled, onCheckedChange: onSetShiftWarnEnabled)
                if settings.shiftWarnEnabled {
                    DashDivider()
                    HStack {
                        EmojiBadge(emoji: "\u{1F525}", color: .dashAmber)
                        Text("Ng\u{01B0}\u{1EE1}ng Shift Light")
                            .foregroundColor(.white)
                            .font(DashFont.shareTechMono(14))
                            .padding(.leading, 12)
                        Spacer()
                        StepperButton(text: "\u{2212}") { onSetRpmWarnVal(min(max(settings.rpmWarnVal - 1, 4), 16)) }
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

            SectionTitle("CH\u{1EE8}C N\u{0102}NG N\u{00C2}NG CAO")
            GroupCard {
                NavRow(emoji: "\u{1F527}", color: .dashRed, label: "ECU Diagnostics", desc: "Xem IAT / c\u{1EA3}m bi\u{1EBF}n oxy", onClick: onNavigateDiagnostics)
                DashDivider()
                NavRow(emoji: "\u{1F3C1}", color: .dashCyan, label: "\u{0110}o gia t\u{1ED1}c (Drag)", desc: "B\u{1EA5}m gi\u{1EDD} 0-40, 0-60 km/h, 100m", onClick: onNavigateDrag)
                DashDivider()
                ToggleRow(emoji: "\u{1F3AE}", color: .dashAmber, label: "Demo mode", desc: "D\u{1EEF} li\u{1EC7}u gi\u{1EA3} l\u{1EAD}p, kh\u{00F4}ng c\u{1EA7}n ESP32", checked: settings.demoMode, onCheckedChange: onSetDemoMode)
                if connectionState == .connected {
                    DashDivider()
                    NavRow(emoji: "\u{1F4A3}", color: .dashRed, label: "Ch\u{1EBF} \u{0111}\u{1ED9} C4", desc: "\u{0110}\u{1EEB}ng b\u{1EA5}m. Nghi\u{00EA}m t\u{00FA}c \u{0111}\u{1EA5}y.", onClick: onTriggerC4Mode)
                }
            }

            SectionTitle("M\u{00C0}N H\u{00CC}NH")
            GroupCard {
                ToggleRow(emoji: "\u{1F506}", color: .dashCyan, label: "Gi\u{1EEF} s\u{00E1}ng m\u{00E0}n h\u{00EC}nh", desc: nil, checked: settings.wakeLock, onCheckedChange: onSetWakeLock)
                DashDivider()
                ToggleRow(emoji: "\u{26F6}", color: .dashCyan, label: "To\u{00E0}n m\u{00E0}n h\u{00EC}nh", desc: nil, checked: settings.fullscreen, onCheckedChange: onSetFullscreen)
            }
        }
    }
}

private struct SoundTab: View {
    let settings: AppSettings
    let onSetSoundBootMusic: (Bool) -> Void
    let onSetSoundConnection: (Bool) -> Void
    let onSetSoundShiftWarn: (Bool) -> Void
    let onSetSoundSpeedWarn: (Bool) -> Void
    let onSetSoundEctWarn: (Bool) -> Void
    let onSetSoundIgnitionWarn: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            SectionTitle("\u{00C2}M THANH C\u{00D2}I & LOA ESP32")
            GroupCard {
                ToggleRow(
                    emoji: "\u{1F3B5}",
                    color: .dashCyan,
                    label: "Nh\u{1EA1}c ch\u{00E0}o m\u{1EDF} m\u{00E1}y (Boot Music)",
                    desc: "Ph\u{00E1}t b\u{00E0}i nh\u{1EA1}c WAV khi b\u{1EAD}t kh\u{00F3}a xe sau 6s",
                    checked: settings.soundBootMusic,
                    onCheckedChange: onSetSoundBootMusic
                )
                DashDivider()
                ToggleRow(
                    emoji: "\u{1F4F1}",
                    color: .dashGreen,
                    label: "\u{00C2}m b\u{00E1}o k\u{1EBF}t n\u{1ED1}i Bluetooth",
                    desc: "Ti\u{1EBF}ng b\u{00ED}p ch\u{00E0}o khi \u{0111}i\u{1EC7}n tho\u{1EA1}i k\u{1EBF}t n\u{1ED1}i / ng\u{1EAF}t k\u{1EBF}t n\u{1ED1}i",
                    checked: settings.soundConnection,
                    onCheckedChange: onSetSoundConnection
                )
                DashDivider()
                ToggleRow(
                    emoji: "\u{1F3CE}\u{FE0F}",
                    color: .dashAmber,
                    label: "C\u{00F2}i / Loa b\u{00E1}o Shift-light",
                    desc: "B\u{00ED}p c\u{1EA3}nh b\u{00E1}o khi tua m\u{00E1}y \u{2265} 11.000 RPM",
                    checked: settings.soundShiftWarn,
                    onCheckedChange: onSetSoundShiftWarn
                )
                DashDivider()
                ToggleRow(
                    emoji: "\u{26A1}",
                    color: .dashRed,
                    label: "C\u{00F2}i / Loa b\u{00E1}o qu\u{00E1} t\u{1ED1}c \u{0111}\u{1ED9}",
                    desc: "B\u{00ED}p c\u{1EA3}nh b\u{00E1}o khi t\u{1ED1}c \u{0111}\u{1ED9} xe \u{2265} 80 km/h",
                    checked: settings.soundSpeedWarn,
                    onCheckedChange: onSetSoundSpeedWarn
                )
                DashDivider()
                ToggleRow(
                    emoji: "\u{1F321}\u{FE0F}",
                    color: .dashRed,
                    label: "C\u{00F2}i / Loa b\u{00E1}o qu\u{00E1} nhi\u{1EC7}t n\u{01B0}\u{1EDB}c m\u{00E1}t",
                    desc: "B\u{00ED}p c\u{1EA3}nh b\u{00E1}o khi nhi\u{1EC7}t \u{0111}\u{1ED9} n\u{01B0}\u{1EDB}c \u{2265} 105\u{00B0}C",
                    checked: settings.soundEctWarn,
                    onCheckedChange: onSetSoundEctWarn
                )
                DashDivider()
                ToggleRow(
                    emoji: "\u{1F511}",
                    color: .dashAmber,
                    label: "C\u{1EA3}nh b\u{00E1}o qu\u{00EAn t\u{1EAF}t kh\u{00F3}a \u{0111}i\u{1EC7}n",
                    desc: "H\u{00FA} c\u{00F2}i & loa sau 3 ph\u{00FA}t xe d\u{1EEB}ng ch\u{1ED1}ng c\u{1EA1}n b\u{00EC}nh",
                    checked: settings.soundIgnitionWarn,
                    onCheckedChange: onSetSoundIgnitionWarn
                )
            }
        }
    }
}

private struct TripTab: View {
    let confirmClear: Bool
    let onNavigateTripHistory: () -> Void
    let onClearAllTrips: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            SectionTitle("H\u{00C0}NH TR\u{00CC}NH (TRIP TRACKER)")
            GroupCard {
                NavRow(emoji: "\u{1F5FA}\u{FE0F}", color: .dashCyan, label: "Xem l\u{1ECB}ch s\u{1EED} h\u{00E0}nh tr\u{00EC}nh", desc: "Danh s\u{00E1}ch c\u{00E1}c chuy\u{1EBF}n \u{0111}i \u{0111}\u{00E3} l\u{01B0}u", onClick: onNavigateTripHistory)
                DashDivider()
                NavRow(
                    emoji: "\u{1F5D1}\u{FE0F}",
                    color: .dashRed,
                    label: "X\u{00F3}a t\u{1EA5}t c\u{1EA3} l\u{1ECB}ch s\u{1EED}",
                    desc: confirmClear ? "Ch\u{1EA1}m l\u{1EA7}n n\u{1EEF}a \u{0111}\u{1EC3} x\u{00E1}c nh\u{1EAD}n" : "X\u{00F3}a m\u{1ECD}i d\u{1EEF} li\u{1EC7}u chuy\u{1EBF}n \u{0111}i v\u{0129}nh vi\u{1EC5}n",
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
            SectionTitle("TR\u{00CC}NH PH\u{00C1}T NH\u{1EA0}C")
            GroupCard {
                ToggleRow(emoji: "\u{1F3B5}", color: .dashCyan, label: "T\u{1EF1} \u{0111}\u{1ED9}ng \u{1EA9}n", desc: "\u{1EA8}n tr\u{00EC}nh ph\u{00E1}t khi kh\u{00F4}ng c\u{00F3} nh\u{1EA1}c", checked: autoHideMusic, onCheckedChange: onSetAutoHideMusic)
                DashDivider()
                NavRow(
                    emoji: notificationAccessGranted ? "\u{1F514}" : "\u{26A0}\u{FE0F}",
                    color: notificationAccessGranted ? .dashGreen : .dashRed,
                    label: "Quy\u{1EC1}n truy c\u{1EAD}p th\u{01B0} vi\u{1EC7}n nh\u{1EA1}c",
                    desc: notificationAccessGranted ? "\u{0110}\u{00E3} c\u{1EA5}p quy\u{1EC1}n" : "C\u{1EA7}n c\u{1EA5}p \u{0111}\u{1EC3} nh\u{1EAD}n di\u{1EC7}n nh\u{1EA1}c đang ph\u{00E1}t",
                    chevron: notificationAccessGranted ? "\u{2713}" : "C\u{1EA4}P QUY\u{1EC0}N",
                    onClick: onOpenNotificationAccessSettings
                )
            }
        }
    }
}

private struct BluetoothHero: View {
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
                    Text("Honda_AB2025_Dash")
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
                HeroAction(text: "K\u{1EBF}t n\u{1ED1}i l\u{1EA1}i", onClick: onReconnect)
                Rectangle().fill(Color.dashDivider).frame(width: 1, height: 44)
                HeroAction(text: "Ng\u{1EAF}t k\u{1EBF}t n\u{1ED1}i", onClick: onDisconnect)
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
    var chevron: String = "\u{203A}"
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
