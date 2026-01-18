import SwiftUI

/// The popover content shown when clicking the menu bar icon
struct MenuBarView: View {
    @ObservedObject var viewModel: MonitorViewModel
    let onOpenDetails: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Resource gauges
            resourceGaugesView

            Divider()

            // Category breakdown
            categoryBreakdownView

            Divider()

            // Threshold status
            thresholdStatusView

            Divider()

            // Actions
            actionsView
        }
        .frame(width: Constants.menuBarPopoverWidth)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("DevResourceMonitor")
                .font(.scaledHeadline)

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button(action: onOpenDetails) {
                Image(systemName: "rectangle.expand.vertical")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open Details")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Resource Gauges

    private var resourceGaugesView: some View {
        VStack(spacing: 8) {
            CompactGaugeView(
                label: "CPU",
                value: viewModel.cpuPercent,
                maxValue: 100,
                color: .blue
            )

            CompactGaugeView(
                label: "RAM",
                value: viewModel.memoryPercent,
                maxValue: 100,
                color: .green
            )

            HStack {
                Text(Formatters.memory(viewModel.totalMemoryMB))
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                Text("of")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                Text(Formatters.memory(viewModel.totalSystemMemoryMB))
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownView: some View {
        VStack(spacing: 4) {
            ForEach(viewModel.sortedCategoryUsages.prefix(5)) { category in
                CompactProcessRow(
                    name: category.name,
                    cpu: category.cpuPercent,
                    memory: category.memoryMB,
                    color: category.swiftUIColor
                )
            }

            if viewModel.categoryUsages.count > 5 {
                Text("+ \(viewModel.categoryUsages.count - 5) more categories")
                    .font(.scaledCaption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Threshold Status

    private var thresholdStatusView: some View {
        HStack {
            Image(systemName: viewModel.thresholdMonitor.isEnabled ? "bell.fill" : "bell.slash")
                .foregroundColor(viewModel.thresholdMonitor.isEnabled ? .orange : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Threshold: \(Formatters.percentage(viewModel.settings.cpuThreshold, decimals: 0)) CPU")
                    .font(.scaledCaption)

                if let timeSince = viewModel.thresholdMonitor.timeSinceLastEvent {
                    Text("Last breach: \(timeSince)")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No recent breaches")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private var actionsView: some View {
        HStack {
            Button("Open Details") {
                onOpenDetails()
            }
            .buttonStyle(.bordered)

            Spacer()

            if let lastUpdate = viewModel.lastUpdate {
                Text("Updated: \(Formatters.time(lastUpdate))")
                    .font(.scaledCaption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onQuit) {
                Text("Quit")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    MenuBarView(
        viewModel: MonitorViewModel(),
        onOpenDetails: {},
        onOpenSettings: {},
        onQuit: {}
    )
}
