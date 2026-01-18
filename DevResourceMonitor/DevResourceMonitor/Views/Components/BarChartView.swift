import SwiftUI
import Charts

/// Bar chart for displaying historical resource usage
struct HistoryBarChart: View {
    let snapshots: [AggregatedSnapshot]
    let categories: [AppCategory]
    let valueType: ValueType

    enum ValueType {
        case cpu
        case memory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.scaledHeadline)

            if snapshots.isEmpty {
                emptyState
            } else {
                chartView
            }

            legendView
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        Chart {
            ForEach(snapshots) { snapshot in
                ForEach(Array(snapshot.categoryBreakdown.keys.sorted()), id: \.self) { categoryID in
                    if let usage = snapshot.categoryBreakdown[categoryID] {
                        BarMark(
                            x: .value("Time", snapshot.timestamp),
                            y: .value(valueLabel, value(from: usage))
                        )
                        .foregroundStyle(colorFor(categoryID: categoryID))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(Formatters.chartDate(date))
                            .font(.scaledCaption2)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatYAxisValue(doubleValue))
                            .font(.scaledCaption2)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 250)
    }

    // MARK: - Computed Properties

    private var title: String {
        switch valueType {
        case .cpu:
            return "CPU Usage Over Time"
        case .memory:
            return "Memory Usage Over Time"
        }
    }

    private var valueLabel: String {
        switch valueType {
        case .cpu:
            return "CPU %"
        case .memory:
            return "Memory"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.scaledSystem(size: 40))
                .foregroundColor(.secondary)
            Text("No historical data yet")
                .font(.scaledSubheadline)
                .foregroundColor(.secondary)
            Text("Data will appear as the app collects usage information")
                .font(.scaledCaption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    private var legendView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 4) {
            ForEach(categories.filter { $0.id != "other" }) { category in
                HStack(spacing: 4) {
                    Circle()
                        .fill(category.swiftUIColor)
                        .frame(width: 8, height: 8)
                    Text(category.name)
                        .font(.scaledCaption)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func value(from usage: ResourceUsage) -> Double {
        switch valueType {
        case .cpu:
            return usage.cpuPercent
        case .memory:
            return usage.memoryMB
        }
    }

    private func formatYAxisValue(_ value: Double) -> String {
        switch valueType {
        case .cpu:
            return Formatters.percentage(value, decimals: 0)
        case .memory:
            return Formatters.memory(value)
        }
    }

    private func colorFor(categoryID: String) -> Color {
        categories.first { $0.id == categoryID }?.swiftUIColor ?? .gray
    }
}

// MARK: - Line Chart for Trends

struct TrendLineChart: View {
    let dataPoints: [TrendDataPoint]
    let color: Color
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.scaledHeadline)

            if dataPoints.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)

                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color.opacity(0.1))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(Formatters.chartDate(date))
                                    .font(.scaledCaption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// MARK: - Preview

#Preview {
    let categories = AppCategory.defaultCategories

    let snapshots = (0..<10).map { i in
        AggregatedSnapshot(
            timestamp: Date().addingTimeInterval(Double(i) * -3600),
            avgCPU: Double.random(in: 20...80),
            avgMemoryMB: Double.random(in: 4000...12000),
            categoryBreakdown: [
                "ide": ResourceUsage(cpuPercent: Double.random(in: 10...40), memoryMB: Double.random(in: 1000...3000), processCount: 5),
                "containers": ResourceUsage(cpuPercent: Double.random(in: 5...25), memoryMB: Double.random(in: 2000...5000), processCount: 3)
            ],
            snapshotCount: 12
        )
    }

    return VStack {
        HistoryBarChart(snapshots: snapshots, categories: categories, valueType: .cpu)
        HistoryBarChart(snapshots: snapshots, categories: categories, valueType: .memory)
    }
    .frame(width: 600)
    .padding()
}
