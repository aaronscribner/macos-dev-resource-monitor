import SwiftUI
import UserNotifications

/// Settings view for notification configuration
struct NotificationSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section {
                // Notification permission status
                HStack {
                    Text("System Permission")
                    Spacer()
                    statusBadge
                }

                if notificationStatus != .authorized {
                    Button("Request Permission") {
                        requestPermission()
                    }
                }
            } header: {
                Text("Permission")
            } footer: {
                if notificationStatus == .denied {
                    Text("Notifications are disabled in System Settings. Click 'Open System Settings' to enable them.")
                }
            }

            Section {
                Toggle("Enable Notifications", isOn: $viewModel.settings.notificationsEnabled)
                    .onChange(of: viewModel.settings.notificationsEnabled) { _, _ in
                        viewModel.saveSettings()
                    }
                    .disabled(notificationStatus != .authorized)

                Toggle("Play Sound", isOn: $viewModel.settings.soundEnabled)
                    .onChange(of: viewModel.settings.soundEnabled) { _, _ in
                        viewModel.saveSettings()
                    }
                    .disabled(!viewModel.settings.notificationsEnabled || notificationStatus != .authorized)

                Toggle("Silent Logging Only", isOn: $viewModel.settings.silentLogging)
                    .onChange(of: viewModel.settings.silentLogging) { _, _ in
                        viewModel.saveSettings()
                    }
            } header: {
                Text("Alert Settings")
            } footer: {
                Text("When 'Silent Logging Only' is enabled, threshold events are recorded but no notifications are shown.")
            }

            Section {
                NotificationPreview(
                    notificationsEnabled: viewModel.settings.notificationsEnabled,
                    soundEnabled: viewModel.settings.soundEnabled,
                    silentLogging: viewModel.settings.silentLogging
                )
            } header: {
                Text("Preview")
            }

            if notificationStatus == .denied {
                Section {
                    Button("Open System Settings") {
                        openNotificationSettings()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            checkNotificationStatus()
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        switch notificationStatus {
        case .authorized:
            Label("Enabled", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.scaledCaption)

        case .denied:
            Label("Disabled", systemImage: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.scaledCaption)

        case .provisional:
            Label("Provisional", systemImage: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
                .font(.scaledCaption)

        case .notDetermined:
            Label("Not Set", systemImage: "questionmark.circle.fill")
                .foregroundColor(.secondary)
                .font(.scaledCaption)

        case .ephemeral:
            Label("Ephemeral", systemImage: "clock.circle.fill")
                .foregroundColor(.orange)
                .font(.scaledCaption)

        @unknown default:
            Label("Unknown", systemImage: "questionmark.circle")
                .foregroundColor(.secondary)
                .font(.scaledCaption)
        }
    }

    // MARK: - Actions

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                checkNotificationStatus()
            }
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Notification Preview

struct NotificationPreview: View {
    let notificationsEnabled: Bool
    let soundEnabled: Bool
    let silentLogging: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When a threshold is exceeded:")
                .font(.scaledCaption)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                PreviewItem(
                    icon: "bell.badge.fill",
                    label: "Notification",
                    enabled: notificationsEnabled && !silentLogging
                )

                PreviewItem(
                    icon: "speaker.wave.2.fill",
                    label: "Sound",
                    enabled: notificationsEnabled && soundEnabled && !silentLogging
                )

                PreviewItem(
                    icon: "doc.text.fill",
                    label: "Log Event",
                    enabled: true
                )
            }
            .frame(maxWidth: .infinity)

            if silentLogging {
                Text("Silent logging mode: events are recorded without notifications")
                    .font(.scaledCaption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

struct PreviewItem: View {
    let icon: String
    let label: String
    let enabled: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.scaledTitle2)
                .foregroundColor(enabled ? .accentColor : .secondary.opacity(0.5))

            Text(label)
                .font(.scaledCaption)
                .foregroundColor(enabled ? .primary : .secondary.opacity(0.5))

            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .font(.scaledCaption)
                .foregroundColor(enabled ? .green : .secondary.opacity(0.5))
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView(viewModel: SettingsViewModel(historyManager: HistoryManager()))
}
