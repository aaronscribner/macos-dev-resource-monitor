import Foundation
import UserNotifications
import AppKit

/// Handles macOS notifications for threshold alerts
class NotificationService: NSObject, ObservableObject {
    @Published var notificationsEnabled: Bool = true
    @Published var soundEnabled: Bool = false
    @Published var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        checkAuthorization()
    }

    /// Request notification permissions
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    /// Check current authorization status
    func checkAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Send a threshold alert notification
    func sendThresholdAlert(_ event: ThresholdEvent) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Resource Threshold Exceeded"
        content.body = event.description

        // Add top consumers to the notification
        let topProcesses = event.topProcessesByTrigger.prefix(3)
        let processNames = topProcesses.map { $0.displayName }.joined(separator: ", ")
        content.subtitle = "Top: \(processNames)"

        if soundEnabled {
            content.sound = .default
        }

        // Add category for actions
        content.categoryIdentifier = "THRESHOLD_ALERT"

        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// Send a custom notification
    func sendNotification(title: String, body: String, subtitle: String? = nil) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        if soundEnabled {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    /// Play alert sound without notification
    func playAlertSound() {
        NSSound.beep()
    }

    /// Register notification categories and actions
    func registerCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "THRESHOLD_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
    }

    /// Update settings
    func updateSettings(notificationsEnabled: Bool? = nil, soundEnabled: Bool? = nil) {
        if let enabled = notificationsEnabled {
            self.notificationsEnabled = enabled
        }
        if let sound = soundEnabled {
            self.soundEnabled = sound
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "VIEW_DETAILS":
            // Post notification to open main window
            NotificationCenter.default.post(name: .openMainWindow, object: nil)
        default:
            break
        }
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
}
