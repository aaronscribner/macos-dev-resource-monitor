import SwiftUI
import Charts

/// Dashboard view with pie charts and top consumers
struct DashboardView: View {
    @ObservedObject var viewModel: MonitorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Resource overview gauges
                resourceOverview

                // Per-core CPU chart
                perCoreCPUChart

                // Pie charts
                pieChartsRow

                // Top consumers
                topConsumersSection
            }
            .padding()
        }
    }

    // MARK: - Resource Overview

    private var resourceOverview: some View {
        HStack(spacing: 40) {
            CircularGaugeView(
                value: viewModel.cpuPercent,
                maxValue: 100,
                title: "CPU",
                subtitle: "\(viewModel.cpuCoreCount) cores",
                color: .blue
            )

            CircularGaugeView(
                value: viewModel.memoryPercent,
                maxValue: 100,
                title: "RAM",
                subtitle: Formatters.memory(viewModel.totalMemoryMB),
                color: .green
            )

            // System info
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Total Processes", value: "\(viewModel.processes.count)")
                InfoRow(label: "CPU Cores", value: "\(viewModel.cpuCoreCount)")
                InfoRow(label: "System Memory", value: Formatters.memory(viewModel.totalSystemMemoryMB))
                InfoRow(label: "Categories Tracked", value: "\(viewModel.categories.count)")

                if viewModel.isMonitoring {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Monitoring active")
                            .font(.scaledCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.3))
        .cornerRadius(16)
    }

    // MARK: - Per-Core CPU Chart

    private var perCoreCPUChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Usage Per Core")
                .font(.scaledHeadline)

            if viewModel.perCoreUsage.isEmpty {
                Text("Loading CPU data...")
                    .foregroundColor(.secondary)
                    .frame(height: 120)
            } else {
                Chart(viewModel.perCoreUsage) { core in
                    BarMark(
                        x: .value("Core", "Core \(core.id)"),
                        y: .value("Usage", core.usage)
                    )
                    .foregroundStyle(colorForUsage(core.usage))
                    .annotation(position: .top) {
                        Text("\(Int(core.usage))%")
                            .font(.scaledCaption2)
                            .foregroundColor(.secondary)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.scaledCaption2)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }

    private func colorForUsage(_ usage: Double) -> Color {
        if usage < 50 {
            return .green
        } else if usage < 80 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Pie Charts

    private var pieChartsRow: some View {
        HStack(spacing: 20) {
            ResourcePieChart(
                data: viewModel.sortedCategoryUsages,
                title: "Current CPU Usage",
                valueType: .cpu
            )

            ResourcePieChart(
                data: viewModel.sortedCategoryUsages,
                title: "Current Memory Usage",
                valueType: .memory
            )
        }
    }

    // MARK: - Top Consumers

    private var topConsumersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Consumers")
                    .font(.scaledHeadline)

                Spacer()

                Picker("Sort by", selection: $viewModel.sortBy) {
                    ForEach(MonitorViewModel.SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Picker("View", selection: $viewModel.viewMode) {
                    Text("Grouped").tag(AppSettings.ViewMode.grouped)
                    Text("Detailed").tag(AppSettings.ViewMode.detailed)
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }

            if viewModel.viewMode == .grouped {
                groupedConsumersView
            } else {
                detailedConsumersView
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }

    private var groupedConsumersView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Application")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 200, alignment: .leading)

                Spacer()

                Text("CPU")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)

                Text("Memory")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)

                Text("Processes")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)

                Color.clear.frame(width: 30)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.secondary.opacity(0.1))

            Divider()

            // Rows
            ForEach(viewModel.sortedGroupedByApp.prefix(10)) { group in
                GroupedConsumerRow(group: group, viewModel: viewModel)
                Divider()
            }
        }
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }

    private var detailedConsumersView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Process")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 200, alignment: .leading)

                Spacer()

                Text("CPU")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)

                Text("Memory")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)

                Text("PID")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)

                Color.clear.frame(width: 30)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.secondary.opacity(0.1))

            Divider()

            // Rows
            let sortedProcesses: [ProcessInfo] = {
                switch viewModel.sortBy {
                case .cpu:
                    return viewModel.processes.sorted { $0.cpuPercent > $1.cpuPercent }
                case .memory:
                    return viewModel.processes.sorted { $0.memoryMB > $1.memoryMB }
                case .name:
                    return viewModel.processes.sorted { $0.displayName < $1.displayName }
                }
            }()

            ForEach(sortedProcesses.prefix(20)) { process in
                ProcessConsumerRow(process: process, viewModel: viewModel)
                Divider()
            }
        }
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.scaledCaption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.scaledCaption)
                .fontWeight(.medium)
        }
    }
}

struct GroupedConsumerRow: View {
    let group: GroupedProcessInfo
    @ObservedObject var viewModel: MonitorViewModel

    var body: some View {
        HStack {
            // Category color dot
            if let category = viewModel.categories.first(where: { cat in
                cat.apps.contains { $0.name == group.name }
            }) {
                Circle()
                    .fill(category.swiftUIColor)
                    .frame(width: 8, height: 8)
            }

            Text(group.name)
                .lineLimit(1)
                .frame(width: 180, alignment: .leading)

            Spacer()

            Text(Formatters.cpu(group.totalCPU))
                .monospacedDigit()
                .frame(width: 80, alignment: .trailing)

            Text(Formatters.memory(group.totalMemoryMB))
                .monospacedDigit()
                .frame(width: 80, alignment: .trailing)

            Text("\(group.processCount)")
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)

            Button(action: {
                Task {
                    _ = await ProcessKiller.terminateGroup(
                        group.processes,
                        appName: group.name
                    )
                }
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .frame(width: 30)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }
}

struct ProcessConsumerRow: View {
    let process: ProcessInfo
    @ObservedObject var viewModel: MonitorViewModel

    var body: some View {
        HStack {
            Text(process.displayName)
                .lineLimit(1)
                .frame(width: 200, alignment: .leading)

            Spacer()

            Text(Formatters.cpu(process.cpuPercent))
                .monospacedDigit()
                .frame(width: 80, alignment: .trailing)

            Text(Formatters.memory(process.memoryMB))
                .monospacedDigit()
                .frame(width: 80, alignment: .trailing)

            Text("\(process.id)")
                .font(.scaledCaption)
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)

            if !ProcessKiller.isSystemProcess(process) {
                Button(action: {
                    Task {
                        _ = await ProcessKiller.terminateWithConfirmation(process)
                    }
                }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .frame(width: 30)
            } else {
                Color.clear.frame(width: 30)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview

#Preview {
    DashboardView(viewModel: MonitorViewModel())
        .frame(width: 800, height: 700)
}
