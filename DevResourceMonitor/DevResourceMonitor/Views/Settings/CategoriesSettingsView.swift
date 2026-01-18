import SwiftUI

/// Settings view for managing categories
struct CategoriesSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedCategory: AppCategory?
    @State private var showingAddCategory = false
    @State private var showingAddApp = false
    @State private var editingCategory: AppCategory?
    @State private var editingApp: AppDefinition?

    var body: some View {
        HSplitView {
            // Categories list
            categoriesList
                .frame(minWidth: 200, maxWidth: 250)

            // Category detail / Apps list
            if let category = selectedCategory {
                categoryDetail(category)
            } else {
                emptySelection
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditorSheet(
                category: nil,
                onSave: { newCategory in
                    viewModel.addCategory(newCategory)
                    selectedCategory = newCategory
                }
            )
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(
                category: category,
                onSave: { updatedCategory in
                    viewModel.updateCategory(updatedCategory)
                    selectedCategory = updatedCategory
                }
            )
        }
        .sheet(isPresented: $showingAddApp) {
            if let categoryID = selectedCategory?.id {
                AppEditorSheet(
                    app: nil,
                    onSave: { newApp in
                        viewModel.addApp(to: categoryID, app: newApp)
                    }
                )
            }
        }
        .sheet(item: $editingApp) { app in
            if let categoryID = selectedCategory?.id {
                AppEditorSheet(
                    app: app,
                    onSave: { updatedApp in
                        viewModel.updateApp(in: categoryID, app: updatedApp)
                    }
                )
            }
        }
    }

    // MARK: - Categories List

    private var categoriesList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Categories")
                    .font(.scaledHeadline)
                Spacer()
                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // List
            List(viewModel.categories, selection: $selectedCategory) { category in
                HStack(spacing: 8) {
                    Toggle("", isOn: Binding(
                        get: { category.isEnabled },
                        set: { _ in viewModel.toggleCategory(category.id) }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                    Circle()
                        .fill(category.swiftUIColor)
                        .frame(width: 10, height: 10)
                        .opacity(category.isEnabled ? 1.0 : 0.4)

                    Text(category.name)
                        .lineLimit(1)
                        .foregroundColor(category.isEnabled ? .primary : .secondary)

                    Spacer()

                    if category.isBuiltIn {
                        Text("Built-in")
                            .font(.scaledCaption2)
                            .foregroundColor(.secondary)
                    }
                }
                .tag(category)
            }
            .listStyle(.inset)

            Divider()

            // Footer actions
            HStack {
                Button("Reset to Defaults") {
                    viewModel.resetCategoriesToDefaults()
                    selectedCategory = nil
                }
                .font(.scaledCaption)
            }
            .padding()
        }
    }

    // MARK: - Category Detail

    private func categoryDetail(_ category: AppCategory) -> some View {
        VStack(spacing: 0) {
            // Category header
            HStack {
                Circle()
                    .fill(category.swiftUIColor)
                    .frame(width: 16, height: 16)

                Text(category.name)
                    .font(.scaledHeadline)

                if category.isBuiltIn {
                    Text("Built-in")
                        .font(.scaledCaption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()

                Button(action: { editingCategory = category }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .disabled(category.isBuiltIn)
            }
            .padding()

            Divider()

            // Apps header
            HStack {
                Text("Applications")
                    .font(.scaledSubheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { showingAddApp = true }) {
                    Label("Add App", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .font(.scaledCaption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Apps list
            if category.apps.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "app.dashed")
                        .font(.scaledTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No applications defined")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                    Text("Add apps to track their processes in this category")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(category.apps) { app in
                        AppRow(app: app, onEdit: { editingApp = app })
                    }
                    .onDelete { indexSet in
                        viewModel.deleteApp(from: category.id, at: indexSet)
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private var emptySelection: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.scaledSystem(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Select a Category")
                .font(.scaledHeadline)
                .foregroundColor(.secondary)

            Text("Choose a category to view and edit its applications")
                .font(.scaledCaption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - App Row

struct AppRow: View {
    let app: AppDefinition
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .fontWeight(.medium)

                Text(app.processNames.joined(separator: ", "))
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if app.useRegex {
                    Label("Regex", systemImage: "curlybraces")
                        .font(.scaledCaption2)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Editor Sheet

struct CategoryEditorSheet: View {
    let category: AppCategory?
    let onSave: (AppCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var colorHex: String = "#007AFF"

    private var isEditing: Bool { category != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text(isEditing ? "Edit Category" : "New Category")
                    .fontWeight(.semibold)
                Spacer()
                Button("Save") { save() }
                    .disabled(name.isEmpty)
            }
            .padding()

            Divider()

            // Form
            Form {
                TextField("Name", text: $name)

                HStack {
                    Text("Color")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: colorHex) ?? .blue },
                        set: { colorHex = $0.hexString }
                    ))
                    .labelsHidden()
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 350, height: 250)
        .onAppear {
            if let category = category {
                name = category.name
                colorHex = category.color
            }
        }
    }

    private func save() {
        let newCategory = AppCategory(
            id: category?.id ?? UUID().uuidString,
            name: name,
            color: colorHex,
            apps: category?.apps ?? [],
            isBuiltIn: false
        )
        onSave(newCategory)
        dismiss()
    }
}

// MARK: - App Editor Sheet

struct AppEditorSheet: View {
    let app: AppDefinition?
    let onSave: (AppDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var processNamesText: String = ""
    @State private var useRegex: Bool = false

    private var isEditing: Bool { app != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text(isEditing ? "Edit Application" : "New Application")
                    .fontWeight(.semibold)
                Spacer()
                Button("Save") { save() }
                    .disabled(name.isEmpty || processNamesText.isEmpty)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section {
                    TextField("Application Name", text: $name)
                        .help("Friendly name shown in the UI (e.g., 'Visual Studio Code')")
                }

                Section {
                    TextEditor(text: $processNamesText)
                        .frame(height: 100)
                        .font(.scaledMonospacedBody)
                } header: {
                    Text("Process Names (one per line)")
                } footer: {
                    Text("Enter the process names that belong to this app. Check Activity Monitor for exact names.")
                }

                Section {
                    Toggle("Use Regular Expressions", isOn: $useRegex)
                } footer: {
                    Text("When enabled, process names are matched using regex patterns.")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 400)
        .onAppear {
            if let app = app {
                name = app.name
                processNamesText = app.processNames.joined(separator: "\n")
                useRegex = app.useRegex
            }
        }
    }

    private func save() {
        let processNames = processNamesText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let newApp = AppDefinition(
            id: app?.id ?? UUID(),
            name: name,
            processNames: processNames,
            useRegex: useRegex
        )
        onSave(newApp)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    CategoriesSettingsView(viewModel: SettingsViewModel(historyManager: HistoryManager()))
        .frame(width: 600, height: 500)
}
