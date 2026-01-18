import SwiftUI

/// View for displaying resource usage trends
struct TrendsView: View {
    @ObservedObject var viewModel: MonitorViewModel
    @ObservedObject var trendsViewModel: TrendsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView

                if trendsViewModel.isLoading {
                    loadingView
                } else if trendsViewModel.categoryTrends.isEmpty {
                    emptyStateView
                } else {
                    // Category trends
                    categoryTrendsSection

                    // App trends
                    appTrendsSection
                }
            }
            .padding()
        }
        .onAppear {
            trendsViewModel.loadTrends()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Resource Trends")
                    .font(.scaledTitle2)
                    .fontWeight(.semibold)

                Text("Comparing this week vs. last week")
                    .font(.scaledSubheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { trendsViewModel.loadTrends() }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Category Trends

    private var categoryTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Trends")
                .font(.scaledHeadline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                ForEach(trendsViewModel.categoryTrends) { trend in
                    CategoryTrendCard(trend: trend)
                }
            }
        }
    }

    // MARK: - App Trends

    private var appTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Application Trends")
                .font(.scaledHeadline)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Application")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                        .frame(width: 150, alignment: .leading)

                    Spacer()

                    Text("This Week")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    Text("Last Week")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    Text("Change")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    Color.clear.frame(width: 30)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.1))

                Divider()

                ForEach(trendsViewModel.appTrends.prefix(15)) { trend in
                    AppTrendRow(trend: trend)
                    Divider()
                }
            }
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Loading/Empty States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing trends...")
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.scaledSystem(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Not Enough Data for Trends")
                .font(.scaledTitle2)
                .fontWeight(.medium)

            Text("Trends will appear once you have at least a week of usage data.\nKeep the app running to collect data over time.")
                .font(.scaledSubheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(height: 300)
    }
}

// MARK: - Category Trend Card

struct CategoryTrendCard: View {
    let trend: CategoryTrend

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color(hex: trend.categoryColor) ?? .gray)
                    .frame(width: 12, height: 12)

                Text(trend.categoryName)
                    .font(.scaledHeadline)

                Spacer()
            }

            // Metrics
            HStack(spacing: 20) {
                // CPU
                VStack(alignment: .leading, spacing: 4) {
                    Text("CPU")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: trend.cpuTrend.icon)
                            .foregroundColor(Color(hex: trend.cpuTrend.color) ?? .gray)
                            .font(.scaledCaption)

                        Text(Formatters.percentChange(trend.cpuPercentChange))
                            .font(.scaledSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: trend.cpuTrend.color) ?? .gray)
                    }

                    Text("\(Formatters.percentage(trend.currentWeekAvgCPU, decimals: 0)) avg")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                // Memory
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: trend.memoryTrend.icon)
                            .foregroundColor(Color(hex: trend.memoryTrend.color) ?? .gray)
                            .font(.scaledCaption)

                        Text(Formatters.percentChange(trend.memoryPercentChange))
                            .font(.scaledSubheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: trend.memoryTrend.color) ?? .gray)
                    }

                    Text("\(Formatters.memory(trend.currentWeekAvgMemoryMB)) avg")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Summary
            Text(trend.summary)
                .font(.scaledCaption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - App Trend Row

struct AppTrendRow: View {
    let trend: AppTrend

    var body: some View {
        HStack {
            Text(trend.appName)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)

            Spacer()

            Text(Formatters.cpu(trend.currentWeekAvgCPU))
                .monospacedDigit()
                .frame(width: 80, alignment: .trailing)

            Text(Formatters.cpu(trend.previousWeekAvgCPU))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)

            HStack(spacing: 4) {
                Image(systemName: trend.cpuTrend.icon)
                    .foregroundColor(Color(hex: trend.cpuTrend.color) ?? .gray)
                    .font(.scaledCaption)

                Text(Formatters.percentChange(trend.cpuPercentChange))
                    .foregroundColor(Color(hex: trend.cpuTrend.color) ?? .gray)
            }
            .frame(width: 80, alignment: .trailing)

            Color.clear.frame(width: 30)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview

#Preview {
    TrendsView(
        viewModel: MonitorViewModel(),
        trendsViewModel: TrendsViewModel(
            historyManager: HistoryManager(),
            categories: AppCategory.defaultCategories
        )
    )
    .frame(width: 800, height: 700)
}
