import SwiftUI

/// A row displaying process information in a list
struct ProcessRowView: View {
    let process: ProcessInfo
    let showKillButton: Bool
    let onKill: (() -> Void)?

    init(process: ProcessInfo, showKillButton: Bool = true, onKill: (() -> Void)? = nil) {
        self.process = process
        self.showKillButton = showKillButton
        self.onKill = onKill
    }

    var body: some View {
        HStack(spacing: 12) {
            // Process name
            VStack(alignment: .leading, spacing: 2) {
                Text(process.displayName)
                    .font(.scaledBody)
                    .lineLimit(1)
                Text("PID: \(process.id)")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 150, alignment: .leading)

            Spacer()

            // CPU usage
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.cpu(process.cpuPercent))
                    .font(.scaledBody)
                    .monospacedDigit()
                Text("CPU")
                    .font(.scaledCaption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)

            // Memory usage
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.memory(process.memoryMB))
                    .font(.scaledBody)
                    .monospacedDigit()
                Text("Memory")
                    .font(.scaledCaption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)

            // Kill button
            if showKillButton && !ProcessKiller.isSystemProcess(process) {
                Button(action: { onKill?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Terminate process")
            } else {
                Color.clear
                    .frame(width: 20)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A row for grouped processes (app-level)
struct GroupedProcessRowView: View {
    let group: GroupedProcessInfo
    let categoryColor: Color?
    let isExpanded: Bool
    let showKillButton: Bool
    let onToggle: () -> Void
    let onKill: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Expand/collapse indicator
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 16)

                // Category color indicator
                if let color = categoryColor {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }

                // App name
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.scaledBody)
                        .fontWeight(.medium)
                    Text("\(group.processCount) process\(group.processCount == 1 ? "" : "es")")
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Total CPU
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.cpu(group.totalCPU))
                        .font(.scaledBody)
                        .monospacedDigit()
                    Text("CPU")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 60)

                // Total Memory
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.memory(group.totalMemoryMB))
                        .font(.scaledBody)
                        .monospacedDigit()
                    Text("Memory")
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 70)

                // Kill button
                if showKillButton {
                    Button(action: { onKill?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Terminate all processes")
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)

            // Expanded process list
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(group.processes.sorted { $0.cpuPercent > $1.cpuPercent }) { process in
                        HStack(spacing: 12) {
                            Color.clear.frame(width: 24)  // Indent

                            Text(process.name)
                                .font(.scaledCaption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            Spacer()

                            Text(Formatters.cpu(process.cpuPercent))
                                .font(.scaledCaption)
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)

                            Text(Formatters.memory(process.memoryMB))
                                .font(.scaledCaption)
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)

                            Text("PID: \(process.id)")
                                .font(.scaledCaption2)
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                        .padding(.leading, 8)
                    }
                }
                .padding(.bottom, 4)
                .background(Color.secondary.opacity(0.05))
            }
        }
    }
}

/// Compact process row for menu bar popover
struct CompactProcessRow: View {
    let name: String
    let cpu: Double
    let memory: Double
    let color: Color?

    var body: some View {
        HStack(spacing: 8) {
            if let color = color {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }

            Text(name)
                .font(.scaledCaption)
                .lineLimit(1)

            Spacer()

            Text(Formatters.cpu(cpu))
                .font(.scaledCaption)
                .monospacedDigit()
                .foregroundColor(.secondary)

            Text(Formatters.memory(memory))
                .font(.scaledCaption)
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ProcessRowView(
            process: ProcessInfo(
                id: 1234,
                name: "Code Helper",
                cpuPercent: 12.5,
                memoryMB: 450,
                appName: "VS Code"
            )
        )

        Divider()

        GroupedProcessRowView(
            group: GroupedProcessInfo(
                id: "vscode",
                name: "Visual Studio Code",
                processes: [
                    ProcessInfo(id: 1234, name: "Electron", cpuPercent: 8.2, memoryMB: 320),
                    ProcessInfo(id: 1235, name: "Code Helper", cpuPercent: 4.3, memoryMB: 180),
                    ProcessInfo(id: 1236, name: "Code Helper (GPU)", cpuPercent: 2.1, memoryMB: 95)
                ]
            ),
            categoryColor: .blue,
            isExpanded: true,
            showKillButton: true,
            onToggle: {},
            onKill: {}
        )

        Divider()

        CompactProcessRow(
            name: "Docker",
            cpu: 18.5,
            memory: 3200,
            color: .green
        )
    }
    .padding()
    .frame(width: 400)
}
