import CodexUsageCore
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var snapshot: CodexUsageSnapshot = .empty
    @Published var errorMessage: String?
    @Published var refreshPulse = false

    private let reader = CodexUsageReader()

    func refresh() {
        withAnimation(.snappy(duration: 0.28)) {
            refreshPulse.toggle()
        }

        do {
            snapshot = try reader.todaySnapshot()
            errorMessage = nil
        } catch {
            snapshot = .empty
            errorMessage = "\(error)"
        }
    }

    func bump() {
        withAnimation(.bouncy(duration: 0.34)) {
            refreshPulse.toggle()
        }
    }
}

struct PixelUsagePanel: View {
    @ObservedObject var viewModel: UsageViewModel
    let onRefresh: () -> Void
    let onQuit: () -> Void

    @State private var appear = false
    @State private var scanlineOffset: CGFloat = -36

    var body: some View {
        ZStack {
            PixelBackdrop(scanlineOffset: scanlineOffset)

            VStack(alignment: .leading, spacing: 14) {
                header

                if let error = viewModel.errorMessage {
                    ErrorTile(message: error)
                } else {
                    usageContent
                }

                footer
            }
            .padding(18)
            .scaleEffect(appear ? 1 : 0.96)
            .opacity(appear ? 1 : 0)
        }
        .frame(width: 360, height: 348)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PixelPalette.edge, lineWidth: 2)
        )
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                appear = true
            }
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                scanlineOffset = 360
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    PixelStatusDot(isActive: viewModel.errorMessage == nil)
                    Text("NOTCH CODEX")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundStyle(PixelPalette.ink)
                }

                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(PixelPalette.muted)
            }

            Spacer()

            PixelButton(title: "SYNC", accent: PixelPalette.cyan, action: onRefresh)
        }
    }

    private var usageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            PixelProgressBar(
                title: "5H LIMIT",
                value: viewModel.snapshot.rateLimits?.primary?.usedPercent ?? 0,
                pulse: viewModel.refreshPulse
            )

            HStack(spacing: 10) {
                PixelMetricCard(
                    label: "TOTAL",
                    value: compact(viewModel.snapshot.totalUsage.totalTokens),
                    tint: PixelPalette.lime
                )
                PixelMetricCard(
                    label: "OUT",
                    value: compact(viewModel.snapshot.totalUsage.outputTokens),
                    tint: PixelPalette.cyan
                )
                PixelMetricCard(
                    label: "THINK",
                    value: compact(viewModel.snapshot.totalUsage.reasoningOutputTokens),
                    tint: PixelPalette.gold
                )
            }

            HStack(spacing: 10) {
                PixelInfoRow(label: "WINDOW", value: percent(viewModel.snapshot.rateLimits?.secondary?.usedPercent))
                PixelInfoRow(label: "PLAN", value: viewModel.snapshot.rateLimits?.planType?.uppercased() ?? "LOCAL")
            }

            HStack(spacing: 10) {
                PixelInfoRow(label: "FILES", value: "\(viewModel.snapshot.scannedFiles)")
                PixelInfoRow(label: "LAST", value: relative(viewModel.snapshot.newestEventDate))
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("LOCAL JSONL ONLY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(PixelPalette.muted)

            Spacer()

            PixelButton(title: "QUIT", accent: PixelPalette.pink, action: onQuit)
        }
    }

    private var subtitle: String {
        if viewModel.errorMessage != nil {
            return "scanner offline"
        }
        if let primary = viewModel.snapshot.rateLimits?.primary {
            return "\(Int(primary.usedPercent.rounded()))% used - resets \(relative(primary.resetsAt))"
        }
        return "watching local codex usage"
    }

    private func compact(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }

    private func percent(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }
        return "\(Int(value.rounded()))%"
    }

    private func relative(_ date: Date?) -> String {
        guard let date else {
            return "unknown"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct PixelBackdrop: View {
    var scanlineOffset: CGFloat

    var body: some View {
        ZStack {
            PixelPalette.background

            Canvas { context, size in
                let cell: CGFloat = 12
                var path = Path()

                stride(from: CGFloat(0), through: size.width, by: cell).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }

                stride(from: CGFloat(0), through: size.height, by: cell).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }

                context.stroke(path, with: .color(PixelPalette.grid), lineWidth: 1)
            }

            Rectangle()
                .fill(PixelPalette.cyan.opacity(0.16))
                .frame(height: 22)
                .offset(y: scanlineOffset)
                .blur(radius: 0.2)
        }
    }
}

private struct PixelProgressBar: View {
    let title: String
    let value: Double
    let pulse: Bool

    @State private var animatedValue = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.rounded()))%")
            }
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .foregroundStyle(PixelPalette.ink)

            GeometryReader { proxy in
                let width = max(0, proxy.size.width * min(animatedValue, 100) / 100)

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(PixelPalette.panel)
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: width)
                    PixelTicks()
                }
                .overlay(Rectangle().stroke(PixelPalette.edge, lineWidth: 2))
            }
            .frame(height: 22)
            .scaleEffect(y: pulse ? 1.08 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeOut(duration: 0.55)) {
                animatedValue = newValue
            }
        }
    }

    private var progressColor: Color {
        if value >= 80 {
            return PixelPalette.pink
        }
        if value >= 50 {
            return PixelPalette.gold
        }
        return PixelPalette.lime
    }
}

private struct PixelTicks: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<32, id: \.self) { _ in
                Rectangle()
                    .fill(Color.black.opacity(0.22))
                    .frame(width: 2)
            }
        }
        .padding(.horizontal, 6)
    }
}

private struct PixelMetricCard: View {
    let label: String
    let value: String
    let tint: Color

    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(PixelPalette.muted)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(PixelPalette.panel)
        .overlay(Rectangle().stroke(hover ? tint : PixelPalette.edge, lineWidth: 2))
        .offset(y: hover ? -2 : 0)
        .onHover { inside in
            withAnimation(.snappy(duration: 0.16)) {
                hover = inside
            }
        }
    }
}

private struct PixelInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(PixelPalette.muted)
            Spacer()
            Text(value)
                .foregroundStyle(PixelPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .font(.system(size: 11, weight: .black, design: .monospaced))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(PixelPalette.panel.opacity(0.92))
        .overlay(Rectangle().stroke(PixelPalette.edge.opacity(0.75), lineWidth: 2))
    }
}

private struct PixelButton: View {
    let title: String
    let accent: Color
    let action: () -> Void

    @State private var hover = false
    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.12)) {
                pressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.snappy(duration: 0.12)) {
                    pressed = false
                }
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(PixelPalette.background)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(hover ? PixelPalette.ink : accent)
                .overlay(Rectangle().stroke(PixelPalette.edge, lineWidth: 2))
                .offset(x: pressed ? 2 : 0, y: pressed ? 2 : 0)
                .shadow(color: PixelPalette.edge, radius: 0, x: pressed ? 0 : 3, y: pressed ? 0 : 3)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            withAnimation(.snappy(duration: 0.14)) {
                hover = inside
            }
        }
    }
}

private struct PixelStatusDot: View {
    let isActive: Bool
    @State private var blink = false

    var body: some View {
        Rectangle()
            .fill(isActive ? PixelPalette.lime : PixelPalette.pink)
            .frame(width: 10, height: 10)
            .opacity(blink ? 0.42 : 1)
            .overlay(Rectangle().stroke(PixelPalette.edge, lineWidth: 1))
            .onAppear {
                withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: true)) {
                    blink = true
                }
            }
    }
}

private struct ErrorTile: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("READ ERROR")
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(PixelPalette.pink)
            Text(message)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(PixelPalette.ink)
                .lineLimit(5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(PixelPalette.panel)
        .overlay(Rectangle().stroke(PixelPalette.pink, lineWidth: 2))
    }
}

private enum PixelPalette {
    static let background = Color(red: 0.07, green: 0.08, blue: 0.09)
    static let panel = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let grid = Color(red: 0.22, green: 0.24, blue: 0.27).opacity(0.42)
    static let edge = Color(red: 0.02, green: 0.02, blue: 0.025)
    static let ink = Color(red: 0.93, green: 0.96, blue: 0.88)
    static let muted = Color(red: 0.55, green: 0.62, blue: 0.63)
    static let lime = Color(red: 0.58, green: 0.95, blue: 0.28)
    static let cyan = Color(red: 0.24, green: 0.84, blue: 0.92)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.27)
    static let pink = Color(red: 0.98, green: 0.33, blue: 0.48)
}
