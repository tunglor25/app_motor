import Foundation

/// NavigationStack path element -- mirrors the Kotlin source's ui/Screen.kt route graph.
enum Route: Hashable {
    case settings
    case diagnostics
    case tripHistory
    case tripResult(String)
}
