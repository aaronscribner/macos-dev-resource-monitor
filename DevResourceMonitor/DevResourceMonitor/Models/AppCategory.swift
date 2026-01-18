import Foundation
import SwiftUI

/// Represents a category of applications (e.g., "IDEs & Editors")
struct AppCategory: Identifiable, Codable, Hashable {
    static func == (lhs: AppCategory, rhs: AppCategory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String
    var name: String
    var color: String  // Hex color string
    var apps: [AppDefinition]
    var isBuiltIn: Bool
    var isEnabled: Bool

    init(id: String, name: String, color: String, apps: [AppDefinition], isBuiltIn: Bool = false, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.color = color
        self.apps = apps
        self.isBuiltIn = isBuiltIn
        self.isEnabled = isEnabled
    }

    /// SwiftUI Color from hex string
    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }
}

/// Defines an application and its associated process names
struct AppDefinition: Identifiable, Codable {
    let id: UUID
    var name: String
    var processNames: [String]  // Process names to match against
    var useRegex: Bool

    init(id: UUID = UUID(), name: String, processNames: [String], useRegex: Bool = false) {
        self.id = id
        self.name = name
        self.processNames = processNames
        self.useRegex = useRegex
    }

    /// Check if a process name matches this app definition
    func matches(processName: String) -> Bool {
        for pattern in processNames {
            if useRegex {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(processName.startIndex..., in: processName)
                    if regex.firstMatch(in: processName, range: range) != nil {
                        return true
                    }
                }
            } else {
                // Case-insensitive contains match
                if processName.localizedCaseInsensitiveContains(pattern) {
                    return true
                }
            }
        }
        return false
    }
}

/// Container for all categories (used for JSON serialization)
struct CategoriesContainer: Codable {
    var categories: [AppCategory]
}

// MARK: - Default Categories

extension AppCategory {
    static let defaultCategories: [AppCategory] = [
        AppCategory(
            id: "ide",
            name: "IDEs & Editors",
            color: "#007AFF",
            apps: [
                AppDefinition(name: "Visual Studio Code", processNames: ["Electron", "Code Helper", "Code"]),
                AppDefinition(name: "JetBrains Rider", processNames: ["rider", "fsnotifier"]),
                AppDefinition(name: "JetBrains WebStorm", processNames: ["webstorm"]),
                AppDefinition(name: "JetBrains IntelliJ", processNames: ["idea"]),
                AppDefinition(name: "JetBrains PyCharm", processNames: ["pycharm"]),
                AppDefinition(name: "JetBrains GoLand", processNames: ["goland"]),
                AppDefinition(name: "JetBrains CLion", processNames: ["clion"]),
                AppDefinition(name: "JetBrains DataGrip", processNames: ["datagrip"]),
                AppDefinition(name: "Xcode", processNames: ["Xcode", "XCBBuildService", "SourceKitService", "IBDesignablesAgent"]),
                AppDefinition(name: "Sublime Text", processNames: ["Sublime Text", "sublime_text"]),
                AppDefinition(name: "Neovim", processNames: ["nvim"]),
                AppDefinition(name: "Vim", processNames: ["vim"]),
                AppDefinition(name: "Cursor", processNames: ["Cursor", "Cursor Helper"]),
                AppDefinition(name: "Zed", processNames: ["Zed", "zed"])
            ],
            isBuiltIn: true
        ),
        AppCategory(
            id: "containers",
            name: "Containers & VMs",
            color: "#34C759",
            apps: [
                AppDefinition(name: "Docker", processNames: ["Docker", "com.docker", "docker-proxy", "vpnkit", "Docker Desktop"]),
                AppDefinition(name: "Podman", processNames: ["podman", "gvproxy"]),
                AppDefinition(name: "Colima", processNames: ["colima", "limactl", "lima"]),
                AppDefinition(name: "OrbStack", processNames: ["OrbStack", "orbstack"]),
                AppDefinition(name: "UTM", processNames: ["UTM", "QEMU"]),
                AppDefinition(name: "Parallels", processNames: ["prl_client_app", "prl_vm_app", "Parallels"]),
                AppDefinition(name: "VMware Fusion", processNames: ["vmware", "VMware Fusion"])
            ],
            isBuiltIn: true
        ),
        AppCategory(
            id: "dev-tools",
            name: "Dev Tools",
            color: "#FF9500",
            apps: [
                AppDefinition(name: "Terminal", processNames: ["Terminal"]),
                AppDefinition(name: "iTerm2", processNames: ["iTerm2", "iTerm"]),
                AppDefinition(name: "Warp", processNames: ["Warp"]),
                AppDefinition(name: "Alacritty", processNames: ["alacritty"]),
                AppDefinition(name: "Kitty", processNames: ["kitty"]),
                AppDefinition(name: "Git", processNames: ["git", "git-remote-https", "git-credential"]),
                AppDefinition(name: "Node.js", processNames: ["node"]),
                AppDefinition(name: "Python", processNames: ["python", "python3", "Python"]),
                AppDefinition(name: "Ruby", processNames: ["ruby"]),
                AppDefinition(name: "Go", processNames: ["go"]),
                AppDefinition(name: "Rust", processNames: ["rustc", "cargo", "rust-analyzer"]),
                AppDefinition(name: "Java", processNames: ["java"]),
                AppDefinition(name: "Kotlin", processNames: ["kotlin", "kotlinc"])
            ],
            isBuiltIn: true
        ),
        AppCategory(
            id: "databases",
            name: "Databases",
            color: "#AF52DE",
            apps: [
                AppDefinition(name: "PostgreSQL", processNames: ["postgres", "psql", "pg_"]),
                AppDefinition(name: "MySQL", processNames: ["mysqld", "mysql"]),
                AppDefinition(name: "MongoDB", processNames: ["mongod", "mongo", "mongos"]),
                AppDefinition(name: "Redis", processNames: ["redis-server", "redis-cli"]),
                AppDefinition(name: "SQLite", processNames: ["sqlite3"]),
                AppDefinition(name: "TablePlus", processNames: ["TablePlus"]),
                AppDefinition(name: "DBeaver", processNames: ["dbeaver"]),
                AppDefinition(name: "Sequel Pro", processNames: ["Sequel Pro"]),
                AppDefinition(name: "Postico", processNames: ["Postico"])
            ],
            isBuiltIn: true
        ),
        AppCategory(
            id: "browsers",
            name: "Browsers (Dev)",
            color: "#5856D6",
            apps: [
                AppDefinition(name: "Chrome", processNames: ["Google Chrome", "Google Chrome Helper", "Chrome"]),
                AppDefinition(name: "Firefox", processNames: ["firefox", "Firefox"]),
                AppDefinition(name: "Safari", processNames: ["Safari", "com.apple.WebKit"]),
                AppDefinition(name: "Arc", processNames: ["Arc", "Arc Helper"]),
                AppDefinition(name: "Brave", processNames: ["Brave Browser", "Brave"]),
                AppDefinition(name: "Edge", processNames: ["Microsoft Edge", "Edge"])
            ],
            isBuiltIn: true
        ),
        AppCategory(
            id: "build-tools",
            name: "Build & CI",
            color: "#FF3B30",
            apps: [
                AppDefinition(name: "Gradle", processNames: ["gradle", "GradleDaemon"]),
                AppDefinition(name: "Maven", processNames: ["mvn"]),
                AppDefinition(name: "Webpack", processNames: ["webpack"]),
                AppDefinition(name: "Vite", processNames: ["vite"]),
                AppDefinition(name: "esbuild", processNames: ["esbuild"]),
                AppDefinition(name: "Turbopack", processNames: ["turbopack"]),
                AppDefinition(name: "SWC", processNames: ["swc"]),
                AppDefinition(name: "Bun", processNames: ["bun"]),
                AppDefinition(name: "npm", processNames: ["npm"]),
                AppDefinition(name: "yarn", processNames: ["yarn"]),
                AppDefinition(name: "pnpm", processNames: ["pnpm"])
            ],
            isBuiltIn: true
        ),
        AppCategory(
            id: "communication",
            name: "Communication",
            color: "#00C7BE",
            apps: [
                AppDefinition(name: "Slack", processNames: ["Slack", "Slack Helper"]),
                AppDefinition(name: "Discord", processNames: ["Discord", "Discord Helper"]),
                AppDefinition(name: "Zoom", processNames: ["zoom.us", "Zoom"]),
                AppDefinition(name: "Microsoft Teams", processNames: ["Microsoft Teams", "Teams"]),
                AppDefinition(name: "Messages", processNames: ["Messages"]),
                AppDefinition(name: "Mail", processNames: ["Mail"])
            ],
            isBuiltIn: true
        ),
        AppCategory(
            id: "other",
            name: "Other/Uncategorized",
            color: "#8E8E93",
            apps: [],
            isBuiltIn: true
        )
    ]
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#8E8E93"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
