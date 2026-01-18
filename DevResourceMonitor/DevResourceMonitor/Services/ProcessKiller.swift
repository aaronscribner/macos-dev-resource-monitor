import Foundation
import AppKit

/// Handles safe termination of processes
class ProcessKiller {
    /// Result of a kill operation
    enum KillResult {
        case success
        case cancelled
        case failed(Error)

        var isSuccess: Bool {
            if case .success = self { return true }
            return false
        }
    }

    /// Errors that can occur during process termination
    enum ProcessError: LocalizedError {
        case systemProcessProtected
        case processNotFound
        case permissionDenied
        case unknown(Int32)

        var errorDescription: String? {
            switch self {
            case .systemProcessProtected:
                return "Cannot terminate system processes"
            case .processNotFound:
                return "Process not found"
            case .permissionDenied:
                return "Permission denied"
            case .unknown(let code):
                return "Failed with error code: \(code)"
            }
        }
    }

    /// List of process names that should not be terminated
    private static let protectedProcessNames: Set<String> = [
        "kernel_task",
        "launchd",
        "WindowServer",
        "loginwindow",
        "SystemUIServer",
        "Dock",
        "Finder",
        "cfprefsd",
        "distnoted",
        "trustd",
        "securityd"
    ]

    /// Check if a process is a system process that shouldn't be killed
    static func isSystemProcess(_ process: ProcessInfo) -> Bool {
        // Check if it's a protected process
        if protectedProcessNames.contains(process.name) {
            return true
        }

        // Check if owned by root (PID 0 or 1)
        if process.id <= 1 {
            return true
        }

        // Check if it's a system path
        if process.commandPath.hasPrefix("/System/") ||
           process.commandPath.hasPrefix("/usr/libexec/") {
            return true
        }

        return false
    }

    /// Terminate a process with user confirmation
    @MainActor
    static func terminateWithConfirmation(
        _ process: ProcessInfo,
        force: Bool = false
    ) async -> KillResult {
        // Check if it's a system process
        if isSystemProcess(process) {
            return .failed(ProcessError.systemProcessProtected)
        }

        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Terminate Process?"
        alert.informativeText = "Are you sure you want to terminate \"\(process.displayName)\" (PID: \(process.id))?\n\nThis may cause data loss if the application has unsaved work."
        alert.alertStyle = .warning
        alert.addButton(withTitle: force ? "Force Quit" : "Terminate")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            return terminate(pid: process.id, force: force)
        } else {
            return .cancelled
        }
    }

    /// Terminate a process by PID
    static func terminate(pid: Int32, force: Bool = false) -> KillResult {
        let signal = force ? SIGKILL : SIGTERM

        let result = kill(pid, signal)

        if result == 0 {
            return .success
        } else {
            let error = errno
            switch error {
            case ESRCH:
                return .failed(ProcessError.processNotFound)
            case EPERM:
                return .failed(ProcessError.permissionDenied)
            default:
                return .failed(ProcessError.unknown(error))
            }
        }
    }

    /// Terminate multiple processes (e.g., all VS Code processes)
    @MainActor
    static func terminateGroup(
        _ processes: [ProcessInfo],
        appName: String,
        force: Bool = false
    ) async -> [Int32: KillResult] {
        // Filter out system processes
        let killableProcesses = processes.filter { !isSystemProcess($0) }

        guard !killableProcesses.isEmpty else {
            return [:]
        }

        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Terminate \(appName)?"
        alert.informativeText = "This will terminate \(killableProcesses.count) process(es) associated with \(appName).\n\nThis may cause data loss if the application has unsaved work."
        alert.alertStyle = .warning
        alert.addButton(withTitle: force ? "Force Quit All" : "Terminate All")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            var results: [Int32: KillResult] = [:]
            for process in killableProcesses {
                results[process.id] = terminate(pid: process.id, force: force)
            }
            return results
        } else {
            return killableProcesses.reduce(into: [:]) { $0[$1.id] = .cancelled }
        }
    }

    /// Attempt to gracefully quit an application using AppleScript
    @MainActor
    static func quitApplication(named appName: String) async -> Bool {
        let script = """
        tell application "\(appName)"
            quit
        end tell
        """

        guard let appleScript = NSAppleScript(source: script) else {
            return false
        }

        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)

        return error == nil
    }
}
