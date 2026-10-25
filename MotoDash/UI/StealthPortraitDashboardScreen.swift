import SwiftUI
import WebKit

struct StealthPortraitDashboardScreen: View {
    let state: DashboardUiState
    var initialMode: String = "portrait"
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    var onLogsClick: () -> Void = {}
    var onDiagnosticsClick: () -> Void = {}
    var onTripHistoryClick: () -> Void = {}
    var onDragClick: () -> Void = {}
    var onTripShortClick: () -> Void = {}
    var onTripLongPress: () -> Void = {}
    var onSetDemoMode: (Bool) -> Void = { _ in }
    var onClearDtc: () -> Void = {}
    var onTriggerC4: () -> Void = {}
    var onSetUnitSpeed: (String) -> Void = { _ in }
    var onSetUnitTemp: (String) -> Void = { _ in }
    let onTripSaved: (String) -> Void

    var body: some View {
        ZStack {
            Color(red: 7.0 / 255.0, green: 8.0 / 255.0, blue: 11.0 / 255.0)
                .ignoresSafeArea()

            StealthPortraitWebView(
                state: state,
                initialMode: initialMode,
                onConnectClick: onConnectClick,
                onGearClick: onGearClick,
                onLogsClick: onLogsClick,
                onDiagnosticsClick: onDiagnosticsClick,
                onTripHistoryClick: onTripHistoryClick,
                onDragClick: onDragClick,
                onTripShortClick: onTripShortClick,
                onTripLongPress: onTripLongPress,
                onSetDemoMode: onSetDemoMode,
                onClearDtc: onClearDtc,
                onTriggerC4: onTriggerC4,
                onSetUnitSpeed: onSetUnitSpeed,
                onSetUnitTemp: onSetUnitTemp
            )
            .ignoresSafeArea()

            ShiftFlashOverlay(rpm: state.reading.rpm, threshold: state.settings.shiftRpmThreshold)
        }
        .onChange(of: state.savedTripId) { newId in
            if let id = newId {
                onTripSaved(id)
            }
        }
    }
}

private struct StealthPortraitWebView: UIViewRepresentable {
    let state: DashboardUiState
    let initialMode: String
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onLogsClick: () -> Void
    let onDiagnosticsClick: () -> Void
    let onTripHistoryClick: () -> Void
    let onDragClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onSetDemoMode: (Bool) -> Void
    let onClearDtc: () -> Void
    let onTriggerC4: () -> Void
    let onSetUnitSpeed: (String) -> Void
    let onSetUnitTemp: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let bridgeJs = """
        window.AndroidDash = {
          connectBle: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'connectBle' });
          },
          openSettings: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'openSettings' });
          },
          openLogs: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'openLogs' });
          },
          openDiagnostics: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'openDiagnostics' });
          },
          openTripHistory: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'openTripHistory' });
          },
          openDrag: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'openDrag' });
          },
          toggleTrip: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'toggleTrip' });
          },
          setDemoMode: function(enabled) {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'setDemoMode', value: Boolean(enabled) });
          },
          clearDtc: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'clearDtc' });
          },
          triggerC4: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'triggerC4' });
          },
          setUnitSpeed: function(unit) {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'setUnitSpeed', value: String(unit) });
          },
          setUnitTemp: function(unit) {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'setUnitTemp', value: String(unit) });
          },
          setOrientationMode: function(mode) {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'setOrientationMode', value: String(mode) });
          }
        };
        """
        let userScript = WKUserScript(source: bridgeJs, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(context.coordinator, name: "iosDash")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 7.0 / 255.0, green: 8.0 / 255.0, blue: 11.0 / 255.0, alpha: 1.0)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.navigationDelegate = context.coordinator

        let resName = (initialMode == "landscape") ? "landscape" : "portrait"
        if let htmlUrl = Bundle.main.url(forResource: resName, withExtension: "html") {
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
        } else if let fallbackUrl = Bundle.main.url(forResource: "portrait", withExtension: "html") {
            webView.loadFileURL(fallbackUrl, allowingReadAccessTo: fallbackUrl.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let modeChanged = (context.coordinator.lastOrientMode != initialMode)
        context.coordinator.parent = self
        guard context.coordinator.pageLoaded else { return }
        if modeChanged {
            context.coordinator.lastOrientMode = initialMode
            webView.evaluateJavaScript("window.setOrientPreference && window.setOrientPreference('\(initialMode)');", completionHandler: nil)
        }
        context.coordinator.pushTelemetry(to: webView, state: state)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: StealthPortraitWebView
        var pageLoaded = false
        var lastOrientMode = ""

        init(parent: StealthPortraitWebView) {
            self.parent = parent
            self.lastOrientMode = parent.initialMode
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pageLoaded = true
            webView.evaluateJavaScript("window.setOrientPreference && window.setOrientPreference('\(parent.initialMode)');", completionHandler: nil)
            pushTelemetry(to: webView, state: parent.state)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any],
                  let action = dict["action"] as? String else { return }
            DispatchQueue.main.async {
                switch action {
                case "connectBle":
                    self.parent.onConnectClick()
                case "openSettings":
                    self.parent.onGearClick()
                case "openLogs":
                    self.parent.onLogsClick()
                case "openDiagnostics":
                    self.parent.onDiagnosticsClick()
                case "openTripHistory":
                    self.parent.onTripHistoryClick()
                case "openDrag":
                    self.parent.onDragClick()
                case "toggleTrip":
                    if self.parent.state.isTripRecording {
                        self.parent.onTripLongPress()
                    } else {
                        self.parent.onTripShortClick()
                    }
                case "setDemoMode":
                    if let val = dict["value"] as? Bool {
                        self.parent.onSetDemoMode(val)
                    }
                case "clearDtc":
                    self.parent.onClearDtc()
                case "triggerC4":
                    self.parent.onTriggerC4()
                case "setUnitSpeed":
                    if let val = dict["value"] as? String {
                        self.parent.onSetUnitSpeed(val)
                    }
                case "setUnitTemp":
                    if let val = dict["value"] as? String {
                        self.parent.onSetUnitTemp(val)
                    }
                default:
                    break
                }
            }
        }

        func pushTelemetry(to webView: WKWebView, state: DashboardUiState) {
            let r = state.reading
            let bleConnected = (state.connectionState == .connected)
            let bleStateStr: String = {
                switch state.connectionState {
                case .connected: return "ONLINE"
                case .scanning: return "SCANNING"
                case .connecting: return "CONNECTING"
                default: return "OFFLINE"
                }
            }()
            let hasReading = r.rpm != nil || r.speed != nil || r.battery != nil || r.ect != nil

            let payload: [String: Any] = [
                "bleConnected": bleConnected,
                "bleState": bleStateStr,
                "ecuConnected": r.ecuConnected,
                "hasReading": hasReading,
                "demoMode": state.settings.demoMode,
                "isTripRecording": state.isTripRecording,
                "bleDeviceName": state.settings.bleDeviceName,
                "unitSpeed": state.settings.unitSpeed,
                "unitTemp": state.settings.unitTemp,
                "tripKm": state.tripKm,
                "sideStandDown": r.sideStandDown,
                "idlingStopActive": (r.switches & 0x10) != 0,
                "dtcPresent": !r.dtcCodes.isEmpty,
                "dtcCount": r.dtcCodes.count,
                "packetCount": r.packetCount,
                "packetHz": r.packetHz,
                "rpm": r.rpm ?? NSNull(),
                "speed": r.speed ?? NSNull(),
                "ect": r.ect ?? NSNull(),
                "tps": r.tps ?? NSNull(),
                "volt": r.battery ?? NSNull(),
                "iat": r.iat ?? NSNull(),
                "o2": r.o2Voltage ?? NSNull(),
                "engineLoad": r.engineLoad ?? NSNull(),
                "ignitionTiming": r.ignitionTiming ?? NSNull(),
                "injectorTi": r.injectorTi ?? NSNull(),
                "runTime": r.runTimeSec ?? NSNull()
            ]

            guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                  let jsonStr = String(data: data, encoding: .utf8) else { return }

            webView.evaluateJavaScript("window.updateFromNative && window.updateFromNative(\(jsonStr));", completionHandler: nil)
        }
    }
}
