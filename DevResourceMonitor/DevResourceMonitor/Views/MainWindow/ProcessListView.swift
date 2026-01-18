import SwiftUI

/// View for displaying all processes in a list
struct ProcessListView: View {
    @ObservedObject var viewModel: MonitorViewModel
    @State private var searchText = ""
    @State private var expandedGroups: Set<String> = []
    @State private var selectedCategory: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Process list
            if viewModel.viewMode == .grouped {
                groupedListView
            } else {
                detailedListView
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search processes...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)

            // Category filter
            Picker("Category", selection: $selectedCategory) {
                Text("All Categories").tag(nil as String?)
                Divider()
                ForEach(viewModel.categories) { category in
                    HStack {
                        Circle()
                            .fill(category.swiftUIColor)
                            .frame(width: 8, height: 8)
                        Text(category.name)
                    }
                    .tag(category.id as String?)
                }
            }
            .frame(width: 180)

            Spacer()

            // Sort options
            Picker("Sort", selection: $viewModel.sortBy) {
                ForEach(MonitorViewModel.SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            // View mode toggle
            Picker("View", selection: $viewModel.viewMode) {
                Image(systemName: "rectangle.grid.1x2").tag(AppSettings.ViewMode.grouped)
                Image(systemName: "list.bullet").tag(AppSettings.ViewMode.detailed)
            }
            .pickerStyle(.segmented)
            .frame(width: 80)

            // Process count
            Text("\(filteredProcessCount) processes")
                .font(.scaledCaption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Grouped List

    private var groupedListView: some View {
        List {
            ForEach(filteredGroupedProcesses) { group in
                GroupedProcessRowView(
                    group: group,
                    categoryColor: categoryColor(for: group.name),
                    isExpanded: expandedGroups.contains(group.id),
                    showKillButton: true,
                    onToggle: {
                        if expandedGroups.contains(group.id) {
                            expandedGroups.remove(group.id)
                        } else {
                            expandedGroups.insert(group.id)
                        }
                    },
                    onKill: {
                        Task {
                            _ = await ProcessKiller.terminateGroup(
                                group.processes,
                                appName: group.name
                            )
                        }
                    }
                )
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Detailed List

    private var detailedListView: some View {
        Table(filteredProcesses) {
            TableColumn("Process") { process in
                HStack(spacing: 8) {
                    if let categoryID = process.categoryID,
                       let category = viewModel.categories.first(where: { $0.id == categoryID }) {
                        Circle()
                            .fill(category.swiftUIColor)
                            .frame(width: 8, height: 8)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(process.displayName)
                            .lineLimit(1)
                        Text(process.name)
                            .font(.scaledCaption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .width(min: 150, ideal: 200)

            TableColumn("PID") { process in
                Text("\(process.id)")
                    .monospacedDigit()
            }
            .width(60)

            TableColumn("CPU") { process in
                HStack {
                    ProgressView(value: min(process.cpuPercent / 100, 1))
                        .frame(width: 40)
                    Text(Formatters.cpu(process.cpuPercent))
                        .monospacedDigit()
                }
            }
            .width(100)

            TableColumn("Memory") { process in
                Text(Formatters.memory(process.memoryMB))
                    .monospacedDigit()
            }
            .width(80)

            TableColumn("Category") { process in
                if let categoryID = process.categoryID,
                   let category = viewModel.categories.first(where: { $0.id == categoryID }) {
                    Text(category.name)
                        .foregroundColor(.secondary)
                } else {
                    Text("Other")
                        .foregroundColor(.secondary)
                }
            }
            .width(100)

            TableColumn("Actions") { process in
                if !ProcessKiller.isSystemProcess(process) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.system(size: 16))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { @MainActor in
                                _ = await ProcessKiller.terminateWithConfirmation(process)
                            }
                        }
                        .help("Terminate process")
                }
            }
            .width(50)
        }
    }

    // MARK: - Filtering

    private var filteredProcesses: [ProcessInfo] {
        var processes = viewModel.resourceAggregator.enrich(viewModel.processes)

        // Filter by search
        if !searchText.isEmpty {
            processes = processes.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by category
        if let categoryID = selectedCategory {
            processes = processes.filter { $0.categoryID == categoryID }
        }

        // Sort
        switch viewModel.sortBy {
        case .cpu:
            return processes.sorted { $0.cpuPercent > $1.cpuPercent }
        case .memory:
            return processes.sorted { $0.memoryMB > $1.memoryMB }
        case .name:
            return processes.sorted { $0.displayName < $1.displayName }
        }
    }

    private var filteredGroupedProcesses: [GroupedProcessInfo] {
        var groups = viewModel.sortedGroupedByApp

        // Filter by search
        if !searchText.isEmpty {
            groups = groups.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText) ||
                group.processes.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Filter by category
        if let categoryID = selectedCategory {
            groups = groups.filter { group in
                group.processes.contains { process in
                    viewModel.categories.first(where: { $0.id == categoryID })?.apps
                        .contains { $0.matches(processName: process.name) } ?? false
                }
            }
        }

        return groups
    }

    private var filteredProcessCount: Int {
        if viewModel.viewMode == .grouped {
            return filteredGroupedProcesses.reduce(0) { $0 + $1.processCount }
        } else {
            return filteredProcesses.count
        }
    }

    private func categoryColor(for appName: String) -> Color? {
        for category in viewModel.categories {
            if category.apps.contains(where: { $0.name == appName }) {
                return category.swiftUIColor
            }
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    ProcessListView(viewModel: MonitorViewModel())
        .frame(width: 800, height: 600)
}
