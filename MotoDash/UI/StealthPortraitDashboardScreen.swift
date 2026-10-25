import SwiftUI
import WebKit

struct StealthPortraitDashboardScreen: View {
    let state: DashboardUiState
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    var onLogsClick: () -> Void = {}
    var onDiagnosticsClick: () -> Void = {}
    var onTripHistoryClick: () -> Void = {}
    var onTripShortClick: () -> Void = {}
    var onTripLongPress: () -> Void = {}
    var onSetDemoMode: (Bool) -> Void = { _ in }
    let onTripSaved: (String) -> Void

    var body: some View {
        ZStack {
            Color(red: 2.0 / 255.0, green: 3.0 / 255.0, blue: 6.0 / 255.0)
                .ignoresSafeArea()

            StealthPortraitWebView(
                state: state,
                onConnectClick: onConnectClick,
                onGearClick: onGearClick,
                onLogsClick: onLogsClick,
                onDiagnosticsClick: onDiagnosticsClick,
                onTripHistoryClick: onTripHistoryClick,
                onTripShortClick: onTripShortClick,
                onTripLongPress: onTripLongPress,
                onSetDemoMode: onSetDemoMode
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
    let onConnectClick: () -> Void
    let onGearClick: () -> Void
    let onLogsClick: () -> Void
    let onDiagnosticsClick: () -> Void
    let onTripHistoryClick: () -> Void
    let onTripShortClick: () -> Void
    let onTripLongPress: () -> Void
    let onSetDemoMode: (Bool) -> Void

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
          toggleTrip: function() {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'toggleTrip' });
          },
          setDemoMode: function(enabled) {
            window.webkit.messageHandlers.iosDash.postMessage({ action: 'setDemoMode', value: Boolean(enabled) });
          }
        };
        """
        let userScript = WKUserScript(source: bridgeJs, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(context.coordinator, name: "iosDash")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 2.0 / 255.0, green: 3.0 / 255.0, blue: 6.0 / 255.0, alpha: 1.0)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.navigationDelegate = context.coordinator

        if let htmlUrl = Bundle.main.url(forResource: "portrait", withExtension: "html") {
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        guard context.coordinator.pageLoaded else { return }
        context.coordinator.pushTelemetry(to: webView, state: state)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: StealthPortraitWebView
        var pageLoaded = false

        init(parent: StealthPortraitWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pageLoaded = true
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
