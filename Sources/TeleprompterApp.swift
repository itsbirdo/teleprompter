import SwiftUI

@main
struct TeleprompterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
        .defaultSize(width: 760, height: 560)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Script") {
                    appState.newScript()
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Open Script...") {
                    appState.openScript()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Save Script...") {
                    appState.saveScript()
                }
                .keyboardShortcut("s", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button(appState.isPrompting ? "Stop Teleprompter" : "Start Teleprompter") {
                    if appState.isPrompting {
                        appState.stopPrompting()
                    } else {
                        appState.startPrompting()
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)

                if appState.isPrompting {
                    Button(appState.isPaused ? "Resume" : "Pause") {
                        appState.togglePause()
                    }
                    .keyboardShortcut(.space, modifiers: .command)
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
