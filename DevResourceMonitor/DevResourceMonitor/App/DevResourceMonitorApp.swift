import SwiftUI
import AppKit

@main
struct DevResourceMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = MonitorViewModel()

    var body: some Scene {
        // Menu bar
        MenuBarExtra {
            MenuBarView(
                viewModel: viewModel,
                onOpenDetails: { appDelegate.openMainWindow() },
                onOpenSettings: { appDelegate.openSettings() },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Main window
        Window("DevResourceMonitor", id: "main") {
            MainWindowView(viewModel: viewModel)
                .frame(minWidth: Constants.mainWindowMinWidth, minHeight: Constants.mainWindowMinHeight)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 650)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appDelegate.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                Button("Refresh") {
                    Task {
                        await viewModel.refresh()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        // Settings window
        Settings {
            SettingsView(settingsViewModel: SettingsViewModel(
                historyManager: viewModel.historyManager,
                monitorViewModel: viewModel
            ))
        }
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if viewModel.settings.showPercentInMenuBar {
            HStack(spacing: 4) {
                Image(systemName: "gauge.with.dots.needle.33percent")
                Text("\(Int(viewModel.totalCPU))%")
                    .monospacedDigit()
            }
        } else {
            Image(systemName: "gauge.with.dots.needle.33percent")
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: NSWindowController?
    var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        NotificationService().requestAuthorization()

        // Listen for notification to open main window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenMainWindow),
            name: .openMainWindow,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when closing windows - we're a menu bar app
        return false
    }

    @objc func handleOpenMainWindow() {
        openMainWindow()
    }

    func openMainWindow() {
        // Find and activate the main window
        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else {
            // Open via WindowGroup
            if let url = URL(string: "devresourcemonitor://main") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func openSettings() {
        // Open settings window
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
