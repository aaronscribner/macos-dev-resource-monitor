import SwiftUI

/// Main settings view with tabs for different settings categories
struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case thresholds = "Thresholds"
        case notifications = "Notifications"
        case categories = "Categories"

        var icon: String {
            switch self {
            case .general: return "gear"
            case .thresholds: return "gauge.with.dots.needle.50percent"
            case .notifications: return "bell"
            case .categories: return "folder"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                }
                .tag(SettingsTab.general)

            ThresholdSettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label(SettingsTab.thresholds.rawValue, systemImage: SettingsTab.thresholds.icon)
                }
                .tag(SettingsTab.thresholds)

            NotificationSettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label(SettingsTab.notifications.rawValue, systemImage: SettingsTab.notifications.icon)
                }
                .tag(SettingsTab.notifications)

            CategoriesSettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label(SettingsTab.categories.rawValue, systemImage: SettingsTab.categories.icon)
                }
                .tag(SettingsTab.categories)
        }
        .frame(width: 550, height: 450)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                // Poll interval
                HStack {
                    Text("Update Interval")
                    Spacer()
                    Picker("", selection: $viewModel.settings.pollIntervalSeconds) {
                        Text("1 second").tag(1.0)
                        Text("2 seconds").tag(2.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                        Text("60 seconds").tag(60.0)
                    }
                    .frame(width: 150)
                    .onChange(of: viewModel.settings.pollIntervalSeconds) { _, _ in
                        viewModel.saveSettings()
                    }
                }

                // Menu bar display
                Toggle("Show in Menu Bar", isOn: $viewModel.settings.showInMenuBar)
                    .onChange(of: viewModel.settings.showInMenuBar) { _, _ in
                        viewModel.saveSettings()
                    }

                Toggle("Show percentage in menu bar icon", isOn: $viewModel.settings.showPercentInMenuBar)
                    .disabled(!viewModel.settings.showInMenuBar)
                    .onChange(of: viewModel.settings.showPercentInMenuBar) { _, _ in
                        viewModel.saveSettings()
                    }

                // Default view mode
                HStack {
                    Text("Default View")
                    Spacer()
                    Picker("", selection: $viewModel.settings.defaultViewMode) {
                        Text("Grouped").tag(AppSettings.ViewMode.grouped)
                        Text("Detailed").tag(AppSettings.ViewMode.detailed)
                    }
                    .frame(width: 150)
                    .onChange(of: viewModel.settings.defaultViewMode) { _, _ in
                        viewModel.saveSettings()
                    }
                }
            } header: {
                Text("Display")
            }

            Section {
                // History retention
                HStack {
                    Text("Keep history for")
                    Spacer()
                    Picker("", selection: $viewModel.settings.historyRetentionDays) {
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                    }
                    .frame(width: 150)
                    .onChange(of: viewModel.settings.historyRetentionDays) { _, _ in
                        viewModel.saveSettings()
                    }
                }
            } header: {
                Text("Data Storage")
            }

            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.isLaunchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
            } header: {
                Text("Startup")
            }

            Section {
                Button("Reset to Defaults") {
                    viewModel.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    SettingsView(settingsViewModel: SettingsViewModel(historyManager: HistoryManager()))
}
