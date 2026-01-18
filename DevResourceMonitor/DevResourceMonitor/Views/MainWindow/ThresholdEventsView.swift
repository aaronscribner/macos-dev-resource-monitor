import SwiftUI

/// View for displaying threshold breach events
struct ThresholdEventsView: View {
    @ObservedObject var viewModel: MonitorViewModel
    @State private var events: [ThresholdEvent] = []
    @State private var selectedEvent: ThresholdEvent?
    @State private var isLoading = false

    var body: some View {
        HSplitView {
            // Events list
            eventsListView
                .frame(minWidth: 300, maxWidth: 400)

            // Event detail
            if let event = selectedEvent {
                eventDetailView(event)
            } else {
                emptyDetailView
            }
        }
        .onAppear {
            loadEvents()
        }
    }

    // MARK: - Events List

    private var eventsListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Threshold Events")
                    .font(.scaledHeadline)
                Spacer()
                Button(action: loadEvents) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView()
                    .padding()
            } else if events.isEmpty {
                emptyEventsView
            } else {
                List(events, selection: $selectedEvent) { event in
                    EventRowView(event: event, isSelected: selectedEvent?.id == event.id)
                        .tag(event)
                }
                .listStyle(.inset)
            }
        }
    }

    private var emptyEventsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.scaledSystem(size: 40))
                .foregroundColor(.green)

            Text("No Threshold Breaches")
                .font(.scaledHeadline)

            Text("Events will appear here when CPU or memory thresholds are exceeded")
                .font(.scaledCaption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Event Detail

    private func eventDetailView(_ event: ThresholdEvent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: event.triggerType.icon)
                            .font(.scaledTitle)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading) {
                            Text("\(event.triggerType.displayName) Threshold Exceeded")
                                .font(.scaledTitle2)
                                .fontWeight(.semibold)

                            Text(Formatters.dateTime(event.timestamp))
                                .font(.scaledSubheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    HStack(spacing: 40) {
                        VStack(alignment: .leading) {
                            Text("Trigger Value")
                                .font(.scaledCaption)
                                .foregroundColor(.secondary)
                            Text(Formatters.percentage(event.triggerValue, decimals: 1))
                                .font(.scaledTitle3)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }

                        VStack(alignment: .leading) {
                            Text("Threshold")
                                .font(.scaledCaption)
                                .foregroundColor(.secondary)
                            Text(Formatters.percentage(event.threshold, decimals: 1))
                                .font(.scaledTitle3)
                                .fontWeight(.medium)
                        }

                        VStack(alignment: .leading) {
                            Text("Processes Captured")
                                .font(.scaledCaption)
                                .foregroundColor(.secondary)
                            Text("\(event.allProcesses.count)")
                                .font(.scaledTitle3)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .cornerRadius(12)

                // Process snapshot
                VStack(alignment: .leading, spacing: 12) {
                    Text("Process Snapshot at Time of Breach")
                        .font(.scaledHeadline)

                    // Top consumers
                    VStack(spacing: 0) {
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
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.secondary.opacity(0.1))

                        ForEach(event.topProcessesByTrigger.prefix(20)) { process in
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
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            Divider()
                        }
                    }
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    private var emptyDetailView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cursorarrow.click")
                .font(.scaledSystem(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Select an Event")
                .font(.scaledHeadline)
                .foregroundColor(.secondary)

            Text("Click on an event to see the process snapshot")
                .font(.scaledCaption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadEvents() {
        isLoading = true
        let manager = viewModel.historyManager
        Task {
            let loaded = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let events = manager.loadEvents(lastDays: 30)
                    continuation.resume(returning: events)
                }
            }
            await MainActor.run {
                self.events = loaded
                self.isLoading = false
            }
        }
    }
}

// MARK: - Event Row

struct EventRowView: View {
    let event: ThresholdEvent
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: event.triggerType.icon)
                .foregroundColor(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.description)
                    .font(.scaledSubheadline)
                    .lineLimit(1)

                Text(Formatters.relativeTime(event.timestamp))
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(event.allProcesses.count)")
                .font(.scaledCaption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    ThresholdEventsView(viewModel: MonitorViewModel())
        .frame(width: 900, height: 600)
}
