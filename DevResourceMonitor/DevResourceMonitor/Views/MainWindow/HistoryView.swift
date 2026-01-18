import SwiftUI

/// View for displaying historical resource usage
struct HistoryView: View {
    @ObservedObject var viewModel: MonitorViewModel
    @ObservedObject var historyViewModel: HistoryViewModel
    @State private var chartMode: AppSettings.HistoryChartMode = .bar

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range selector
                timeRangeSelector

                // Stats summary
                statsSummary

                // Charts
                if historyViewModel.isLoading {
                    loadingView
                } else if historyViewModel.snapshots.isEmpty {
                    emptyStateView
                } else {
                    chartsSection
                }
            }
            .padding()
        }
        .onAppear {
            chartMode = viewModel.settings.defaultHistoryChartMode
            historyViewModel.loadData()
        }
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack {
            Text("Time Range:")
                .font(.scaledSubheadline)
                .foregroundColor(.secondary)

            ForEach(HistoryViewModel.TimeRange.allCases, id: \.self) { range in
                Button(action: { historyViewModel.setTimeRange(range) }) {
                    Text(range.rawValue)
                        .font(.scaledSubheadline)
                        .fontWeight(historyViewModel.timeRange == range ? .semibold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(historyViewModel.timeRange == range ? Color.accentColor : Color.clear)
                        )
                        .foregroundColor(historyViewModel.timeRange == range ? .white : .primary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            HStack(spacing: 4) {
                Button(action: { chartMode = .bar }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18))
                        .frame(width: 36, height: 28)
                        .background(chartMode == .bar ? Color.accentColor : Color.clear)
                        .foregroundColor(chartMode == .bar ? .white : .primary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { chartMode = .line }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18))
                        .frame(width: 36, height: 28)
                        .background(chartMode == .line ? Color.accentColor : Color.clear)
                        .foregroundColor(chartMode == .line ? .white : .primary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(Color(.separatorColor).opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Peak CPU",
                value: Formatters.percentage(historyViewModel.peakCPU, decimals: 0),
                icon: "cpu",
                color: .blue
            )

            StatCard(
                title: "Avg CPU",
                value: Formatters.percentage(historyViewModel.avgCPU, decimals: 0),
                icon: "chart.bar",
                color: .blue
            )

            StatCard(
                title: "Peak Memory",
                value: Formatters.memory(historyViewModel.peakMemoryMB),
                icon: "memorychip",
                color: .green
            )

            StatCard(
                title: "Avg Memory",
                value: Formatters.memory(historyViewModel.avgMemoryMB),
                icon: "chart.bar",
                color: .green
            )

            StatCard(
                title: "Data Points",
                value: "\(historyViewModel.snapshots.count)",
                icon: "chart.dots.scatter",
                color: .purple
            )
        }
    }

    // MARK: - Charts

    @ViewBuilder
    private var chartsSection: some View {
        VStack(spacing: 20) {
            switch chartMode {
            case .bar:
                HistoryBarChart(
                    snapshots: historyViewModel.aggregatedSnapshots(),
                    categories: viewModel.categories,
                    valueType: .cpu
                )

                HistoryBarChart(
                    snapshots: historyViewModel.aggregatedSnapshots(),
                    categories: viewModel.categories,
                    valueType: .memory
                )
            case .line:
                HistoryLineChart(
                    snapshots: historyViewModel.aggregatedSnapshots(),
                    categories: viewModel.categories,
                    valueType: .cpu
                )

                HistoryLineChart(
                    snapshots: historyViewModel.aggregatedSnapshots(),
                    categories: viewModel.categories,
                    valueType: .memory
                )
            }
        }
    }

    // MARK: - Loading/Empty States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading historical data...")
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.scaledSystem(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Historical Data")
                .font(.scaledTitle2)
                .fontWeight(.medium)

            Text("Historical data will appear here as the app monitors your system.\nSnapshots are saved every minute.")
                .font(.scaledSubheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(height: 300)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.scaledTitle2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    HistoryView(
        viewModel: MonitorViewModel(),
        historyViewModel: HistoryViewModel(historyManager: HistoryManager())
    )
    .frame(width: 800, height: 600)
}
