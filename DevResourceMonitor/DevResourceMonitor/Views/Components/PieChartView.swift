import SwiftUI
import Charts

/// Pie chart for displaying current resource usage by category
struct ResourcePieChart: View {
    let data: [CategoryUsage]
    let title: String
    let valueType: ValueType

    @State private var hoveredItem: CategoryUsage?
    @State private var mouseLocation: CGPoint = .zero

    enum ValueType {
        case cpu
        case memory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.scaledHeadline)

            Chart(filteredData, id: \.id) { item in
                SectorMark(
                    angle: .value("Value", value(for: item)),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.0
                )
                .foregroundStyle(item.swiftUIColor)
                .cornerRadius(4)
                .opacity(hoveredItem == nil || hoveredItem?.id == item.id ? 1.0 : 0.5)
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                mouseLocation = location
                                hoveredItem = findItem(at: location, in: geometry, proxy: proxy)
                            case .ended:
                                hoveredItem = nil
                            }
                        }
                }
            }
            .overlay(alignment: .top) {
                if let item = hoveredItem {
                    TooltipView(
                        name: item.name,
                        value: formattedValue(for: item),
                        color: item.swiftUIColor,
                        processCount: item.processCount
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: hoveredItem?.id)
            .frame(height: 200)

            // Legend
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 4) {
                ForEach(filteredData) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.swiftUIColor)
                            .frame(width: 8, height: 8)
                        Text(item.name)
                            .font(.scaledCaption)
                            .lineLimit(1)
                        Spacer()
                        Text(formattedValue(for: item))
                            .font(.scaledCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }

    private var filteredData: [CategoryUsage] {
        data.filter { value(for: $0) > 0.1 }
    }

    private func value(for item: CategoryUsage) -> Double {
        switch valueType {
        case .cpu:
            return item.cpuPercent
        case .memory:
            return item.memoryMB
        }
    }

    private func formattedValue(for item: CategoryUsage) -> String {
        switch valueType {
        case .cpu:
            return Formatters.cpu(item.cpuPercent)
        case .memory:
            return Formatters.memory(item.memoryMB)
        }
    }

    private func findItem(at location: CGPoint, in geometry: GeometryProxy, proxy: ChartProxy) -> CategoryUsage? {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        let radius = min(geometry.size.width, geometry.size.height) / 2

        // Check if within the donut ring (between inner and outer radius)
        let innerRadius = radius * 0.5
        guard distance >= innerRadius && distance <= radius else {
            return nil
        }

        // Calculate angle from center (0 degrees at top, clockwise)
        var angle = atan2(dx, -dy) * 180 / .pi
        if angle < 0 {
            angle += 360
        }

        // Find which segment this angle falls into
        let total = filteredData.reduce(0.0) { $0 + value(for: $1) }
        guard total > 0 else { return nil }

        var currentAngle: Double = 0
        for item in filteredData {
            let itemValue = value(for: item)
            let sliceAngle = (itemValue / total) * 360
            if angle >= currentAngle && angle < currentAngle + sliceAngle {
                return item
            }
            currentAngle += sliceAngle
        }

        return nil
    }
}

// MARK: - Tooltip View

private struct TooltipView: View {
    let name: String
    let value: String
    let color: Color
    let processCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(name)
                .font(.scaledCaption)
                .fontWeight(.medium)
            Text(value)
                .font(.scaledCaption)
                .foregroundColor(.secondary)
            Text("(\(processCount) \(processCount == 1 ? "process" : "processes"))")
                .font(.scaledCaption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Color Extension for CategoryUsage

extension CategoryUsage {
    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }
}

// MARK: - Simple Donut Chart (alternative without Charts framework)

struct DonutChart: View {
    let data: [ChartSlice]
    let innerRadiusRatio: CGFloat = 0.6

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2
            let innerRadius = radius * innerRadiusRatio

            ZStack {
                ForEach(Array(slicesWithAngles.enumerated()), id: \.offset) { index, slice in
                    DonutSlice(
                        startAngle: slice.startAngle,
                        endAngle: slice.endAngle,
                        innerRadius: innerRadius,
                        outerRadius: radius
                    )
                    .fill(slice.color)
                }
            }
            .frame(width: size, height: size)
            .position(center)
        }
    }

    private var total: Double {
        data.reduce(0) { $0 + $1.value }
    }

    private var slicesWithAngles: [(startAngle: Angle, endAngle: Angle, color: Color)] {
        var currentAngle = Angle.degrees(-90)
        var result: [(Angle, Angle, Color)] = []

        for slice in data where slice.value > 0 {
            let sliceAngle = Angle.degrees(360 * (slice.value / total))
            result.append((currentAngle, currentAngle + sliceAngle, slice.color))
            currentAngle += sliceAngle
        }

        return result
    }
}

struct ChartSlice: Identifiable {
    let id: String
    let value: Double
    let color: Color
    let label: String
}

struct DonutSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    ResourcePieChart(
        data: [
            CategoryUsage(id: "ide", name: "IDEs", color: "#007AFF",
                         usage: ResourceUsage(cpuPercent: 45, memoryMB: 2100, processCount: 5), processes: []),
            CategoryUsage(id: "containers", name: "Containers", color: "#34C759",
                         usage: ResourceUsage(cpuPercent: 22, memoryMB: 4000, processCount: 3), processes: []),
            CategoryUsage(id: "dev-tools", name: "Dev Tools", color: "#FF9500",
                         usage: ResourceUsage(cpuPercent: 8, memoryMB: 500, processCount: 10), processes: [])
        ],
        title: "CPU Usage by Category",
        valueType: .cpu
    )
    .frame(width: 300, height: 350)
    .padding()
}
