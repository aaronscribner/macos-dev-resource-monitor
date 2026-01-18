import SwiftUI

/// Settings view for threshold configuration
struct ThresholdSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Enable Threshold Monitoring", isOn: $viewModel.settings.thresholdsEnabled)
                    .onChange(of: viewModel.settings.thresholdsEnabled) { _, _ in
                        viewModel.saveSettings()
                    }
            } header: {
                Text("Monitoring")
            } footer: {
                Text("When enabled, the app will record all running processes whenever usage exceeds the thresholds below.")
            }

            Section {
                // CPU threshold
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CPU Threshold")
                        Spacer()
                        Text("\(Int(viewModel.settings.cpuThreshold))%")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: $viewModel.settings.cpuThreshold,
                        in: 10...100,
                        step: 5
                    ) {
                        Text("CPU Threshold")
                    }
                    .onChange(of: viewModel.settings.cpuThreshold) { _, _ in
                        viewModel.saveSettings()
                    }

                    Text("Alert when total CPU usage exceeds this percentage")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                }

                // Memory threshold
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Memory Threshold")
                        Spacer()
                        Text("\(Int(viewModel.settings.memoryThreshold))%")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: $viewModel.settings.memoryThreshold,
                        in: 10...100,
                        step: 5
                    ) {
                        Text("Memory Threshold")
                    }
                    .onChange(of: viewModel.settings.memoryThreshold) { _, _ in
                        viewModel.saveSettings()
                    }

                    Text("Alert when memory usage exceeds this percentage of total system RAM")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Thresholds")
            }

            Section {
                HStack {
                    Text("Alert Cooldown")
                    Spacer()
                    Picker("", selection: $viewModel.settings.thresholdCooldownSeconds) {
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                        Text("2 minutes").tag(120.0)
                        Text("5 minutes").tag(300.0)
                        Text("10 minutes").tag(600.0)
                    }
                    .frame(width: 150)
                    .onChange(of: viewModel.settings.thresholdCooldownSeconds) { _, _ in
                        viewModel.saveSettings()
                    }
                }
            } header: {
                Text("Rate Limiting")
            } footer: {
                Text("Minimum time between threshold alerts to avoid notification spam.")
            }

            Section {
                ThresholdPreview(
                    cpuThreshold: viewModel.settings.cpuThreshold,
                    memoryThreshold: viewModel.settings.memoryThreshold
                )
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
        .padding()
        .disabled(!viewModel.settings.thresholdsEnabled)
    }
}

// MARK: - Threshold Preview

struct ThresholdPreview: View {
    let cpuThreshold: Double
    let memoryThreshold: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thresholds visualized:")
                .font(.scaledCaption)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                // CPU gauge
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: cpuThreshold / 100)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(Int(cpuThreshold))%")
                                .font(.scaledTitle3)
                                .fontWeight(.semibold)
                            Text("CPU")
                                .font(.scaledCaption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 80, height: 80)

                    Text("Alert above \(Int(cpuThreshold))%")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }

                // Memory gauge
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: memoryThreshold / 100)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(Int(memoryThreshold))%")
                                .font(.scaledTitle3)
                                .fontWeight(.semibold)
                            Text("RAM")
                                .font(.scaledCaption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 80, height: 80)

                    Text("Alert above \(Int(memoryThreshold))%")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    ThresholdSettingsView(viewModel: SettingsViewModel(historyManager: HistoryManager()))
}
