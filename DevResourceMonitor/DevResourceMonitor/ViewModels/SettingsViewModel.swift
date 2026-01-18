import Foundation
import ServiceManagement

/// View model for settings management
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var settings: AppSettings
    @Published var categories: [AppCategory]

    // MARK: - Services

    private let historyManager: HistoryManager
    private weak var monitorViewModel: MonitorViewModel?

    // MARK: - Initialization

    init(historyManager: HistoryManager, monitorViewModel: MonitorViewModel? = nil) {
        self.historyManager = historyManager
        self.monitorViewModel = monitorViewModel
        self.settings = historyManager.loadSettings()
        self.categories = historyManager.loadCategories() ?? AppCategory.defaultCategories
    }

    // MARK: - Settings Updates

    func saveSettings() {
        historyManager.saveSettings(settings)
        monitorViewModel?.updateSettings(settings)
    }

    func resetToDefaults() {
        settings = AppSettings.default
        saveSettings()
    }

    // MARK: - Category Management

    func addCategory(_ category: AppCategory) {
        categories.append(category)
        saveCategories()
    }

    func updateCategory(_ category: AppCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    func deleteCategory(at indexSet: IndexSet) {
        // Don't delete built-in categories
        let toDelete = indexSet.filter { !categories[$0].isBuiltIn }
        categories.remove(atOffsets: IndexSet(toDelete))
        saveCategories()
    }

    func moveCategory(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        saveCategories()
    }

    func resetCategoriesToDefaults() {
        categories = AppCategory.defaultCategories
        saveCategories()
    }

    func toggleCategory(_ categoryID: String) {
        if let index = categories.firstIndex(where: { $0.id == categoryID }) {
            categories[index].isEnabled.toggle()
            saveCategories()
        }
    }

    private func saveCategories() {
        historyManager.saveCategories(categories)
        monitorViewModel?.updateCategories(categories)
    }

    // MARK: - App Management in Category

    func addApp(to categoryID: String, app: AppDefinition) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        categories[index].apps.append(app)
        saveCategories()
    }

    func updateApp(in categoryID: String, app: AppDefinition) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryID }),
              let appIndex = categories[categoryIndex].apps.firstIndex(where: { $0.id == app.id }) else {
            return
        }
        categories[categoryIndex].apps[appIndex] = app
        saveCategories()
    }

    func deleteApp(from categoryID: String, at indexSet: IndexSet) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        categories[index].apps.remove(atOffsets: indexSet)
        saveCategories()
    }

    // MARK: - Launch at Login

    func setLaunchAtLogin(_ enabled: Bool) {
        settings.launchAtLogin = enabled

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            // Revert setting on failure
            settings.launchAtLogin = !enabled
        }

        saveSettings()
    }

    var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: - Validation

    func validatePollInterval(_ interval: Double) -> Bool {
        interval >= 1.0 && interval <= 60.0
    }

    func validateThreshold(_ threshold: Double) -> Bool {
        threshold >= 1.0 && threshold <= 100.0
    }

    func validateRetentionDays(_ days: Int) -> Bool {
        days >= 1 && days <= 365
    }
}
