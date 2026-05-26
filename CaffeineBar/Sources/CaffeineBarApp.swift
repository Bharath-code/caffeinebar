import SwiftUI
import Sparkle

/// CaffeineBar — macOS menu bar utility for tracking daily coffee intake.
/// LSUIElement = true: runs as a menu bar extra with no Dock icon.
/// Minimum deployment target: macOS 13.0 (Ventura).
@main
struct CaffeineBarApp: App {
    // Sparkle updater controller for in-app updates (Req 50)
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        MenuBarExtra("CaffeineBar", systemImage: "cup.and.saucer") {
            Text("CaffeineBar")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
