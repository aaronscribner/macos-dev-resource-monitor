import SwiftUI

/// A gauge view showing resource usage percentage
struct ResourceGaugeView: View {
    let title: String
    let value: Double
    let maxValue: Double
    let unit: String
    let color: Color

    init(title: String, value: Double, maxValue: Double = 100, unit: String = "%", color: Color = .blue) {
        self.title = title
        self.value = value
        self.maxValue = maxValue
        self.unit = unit
        self.color = color
    }

    private var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return (value / maxValue).clamped(to: 0...1)
    }

    private var displayValue: String {
        if unit == "%" {
            return Formatters.percentage(value, decimals: 0)
        } else {
            return "\(Formatters.memory(value))"
        }
    }

    private var gaugeColor: Color {
        if percentage > 0.9 {
            return .red
        } else if percentage > 0.75 {
            return .orange
        } else {
            return color
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.scaledSubheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(displayValue)
                    .font(.scaledSubheadline)
                    .fontWeight(.medium)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(gaugeColor)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

/// Compact gauge for menu bar
struct CompactGaugeView: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color

    private var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return (value / maxValue).clamped(to: 0...1)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.scaledCaption)
                .frame(width: 35, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 6)

            Text(Formatters.percentage(value, decimals: 0))
                .font(.scaledCaption)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}

/// Circular gauge view
struct CircularGaugeView: View {
    let value: Double
    let maxValue: Double
    let title: String
    let subtitle: String
    let color: Color

    private var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return (value / maxValue).clamped(to: 0...1)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)

                // Progress arc
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    Text(Formatters.percentage(value, decimals: 0))
                        .font(.scaledTitle2)
                        .fontWeight(.semibold)
                    Text(title)
                        .font(.scaledCaption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)

            Text(subtitle)
                .font(.scaledCaption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ResourceGaugeView(
            title: "CPU",
            value: 75,
            color: .blue
        )
        .frame(width: 200)

        ResourceGaugeView(
            title: "Memory",
            value: 8500,
            maxValue: 16000,
            unit: "MB",
            color: .green
        )
        .frame(width: 200)

        CompactGaugeView(
            label: "CPU",
            value: 65,
            maxValue: 100,
            color: .blue
        )
        .frame(width: 200)

        HStack(spacing: 20) {
            CircularGaugeView(
                value: 78,
                maxValue: 100,
                title: "CPU",
                subtitle: "78% used",
                color: .blue
            )

            CircularGaugeView(
                value: 52,
                maxValue: 100,
                title: "RAM",
                subtitle: "8.3 GB",
                color: .green
            )
        }
    }
    .padding()
}
