import SwiftUI

/// The main detailed window view with tabs
struct MainWindowView: View {
    @ObservedObject var viewModel: MonitorViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var trendsViewModel: TrendsViewModel
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case history = "History"
        case processes = "Processes"
        case events = "Events"
        case trends = "Trends"

        var icon: String {
            switch self {
            case .dashboard: return "gauge.with.dots.needle.33percent"
            case .history: return "chart.bar.fill"
            case .processes: return "list.bullet"
            case .events: return "exclamationmark.triangle.fill"
            case .trends: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    init(viewModel: MonitorViewModel) {
        self.viewModel = viewModel
        self._historyViewModel = StateObject(wrappedValue: HistoryViewModel(historyManager: viewModel.historyManager))
        self._trendsViewModel = StateObject(wrappedValue: TrendsViewModel(historyManager: viewModel.historyManager, categories: viewModel.categories))
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar with tabs
            List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)
        } detail: {
            // Content area
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(viewModel: viewModel)
                case .history:
                    HistoryView(viewModel: viewModel, historyViewModel: historyViewModel)
                case .processes:
                    ProcessListView(viewModel: viewModel)
                case .events:
                    ThresholdEventsView(viewModel: viewModel)
                case .trends:
                    TrendsView(viewModel: viewModel, trendsViewModel: trendsViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // View mode toggle
                Picker("View", selection: $viewModel.viewMode) {
                    Text("Grouped").tag(AppSettings.ViewMode.grouped)
                    Text("Detailed").tag(AppSettings.ViewMode.detailed)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)

                // Refresh button
                Button(action: {
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh (⌘R)")
                .keyboardShortcut("r", modifiers: .command)

                // Settings button
                Button(action: {
                    openSettings()
                }) {
                    Image(systemName: "gear")
                }
                .help("Settings (⌘,)")
                .keyboardShortcut(",", modifiers: .command)
            }

            ToolbarItem(placement: .status) {
                if let lastUpdate = viewModel.lastUpdate {
                    Text("Updated: \(Formatters.relativeTime(lastUpdate))")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("DevResourceMonitor")
        .onAppear {
            historyViewModel.loadData()
            trendsViewModel.loadTrends()
        }
    }

    private func openSettings() {
        // Open settings window
        if let url = URL(string: "devresourcemonitor://settings") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    MainWindowView(viewModel: MonitorViewModel())
        .frame(width: 900, height: 600)
}
