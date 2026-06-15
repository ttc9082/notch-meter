import AgentUsageCore
import SwiftUI

private enum NotchTheme: CaseIterable {
    case pixel
    case bauhaus
    case swiss
    case artDeco
    case cobalt
    case longTable

    var next: NotchTheme {
        let themes = Self.allCases
        guard let index = themes.firstIndex(of: self) else {
            return .pixel
        }
        return themes[(index + 1) % themes.count]
    }

    var buttonTitle: String {
        switch self {
        case .pixel:
            return "PIX"
        case .bauhaus:
            return "BAU"
        case .swiss:
            return "SWI"
        case .artDeco:
            return "DEC"
        case .cobalt:
            return "COB"
        case .longTable:
            return "TBL"
        }
    }

    var panel: Color {
        switch self {
        case .pixel:
            return PixelPalette.panel
        case .bauhaus:
            return Color(red: 0.92, green: 0.86, blue: 0.68)
        case .swiss:
            return Color(red: 0.93, green: 0.95, blue: 0.96)
        case .artDeco:
            return Color(red: 0.055, green: 0.045, blue: 0.03)
        case .cobalt:
            return Color(red: 0.035, green: 0.075, blue: 0.16)
        case .longTable:
            return Color(red: 0.18, green: 0.105, blue: 0.075)
        }
    }

    var edge: Color {
        switch self {
        case .pixel:
            return PixelPalette.edge
        case .bauhaus:
            return Color(red: 0.02, green: 0.025, blue: 0.03)
        case .swiss:
            return Color(red: 0.05, green: 0.12, blue: 0.22)
        case .artDeco:
            return Color(red: 0.86, green: 0.65, blue: 0.28)
        case .cobalt:
            return Color(red: 0.18, green: 0.42, blue: 0.82)
        case .longTable:
            return Color(red: 0.58, green: 0.18, blue: 0.1)
        }
    }

    var ink: Color {
        switch self {
        case .pixel:
            return PixelPalette.ink
        case .bauhaus:
            return Color(red: 0.03, green: 0.035, blue: 0.04)
        case .swiss:
            return Color(red: 0.03, green: 0.06, blue: 0.1)
        case .artDeco:
            return Color(red: 1, green: 0.91, blue: 0.58)
        case .cobalt:
            return Color(red: 0.88, green: 0.95, blue: 1)
        case .longTable:
            return Color(red: 1, green: 0.91, blue: 0.72)
        }
    }

    var muted: Color {
        switch self {
        case .pixel:
            return PixelPalette.muted
        case .bauhaus:
            return Color(red: 0.18, green: 0.18, blue: 0.16)
        case .swiss:
            return Color(red: 0.35, green: 0.42, blue: 0.48)
        case .artDeco:
            return Color(red: 0.7, green: 0.58, blue: 0.38)
        case .cobalt:
            return Color(red: 0.58, green: 0.72, blue: 0.9)
        case .longTable:
            return Color(red: 0.72, green: 0.54, blue: 0.44)
        }
    }

    var track: Color {
        panel.opacity(0.72)
    }

    var hudInk: Color {
        switch self {
        case .bauhaus:
            return Color(red: 0.96, green: 0.78, blue: 0.05)
        case .swiss:
            return Color(red: 0.86, green: 0.93, blue: 1)
        case .artDeco:
            return Color(red: 1, green: 0.91, blue: 0.58)
        default:
            return ink
        }
    }

    var hudMuted: Color {
        switch self {
        case .bauhaus:
            return Color(red: 0.92, green: 0.86, blue: 0.68)
        case .swiss:
            return Color(red: 0.58, green: 0.72, blue: 0.9)
        case .artDeco:
            return Color(red: 0.7, green: 0.58, blue: 0.38)
        default:
            return muted
        }
    }

    var actionAccent: Color {
        switch self {
        case .bauhaus:
            return Color(red: 0.96, green: 0.78, blue: 0.05)
        case .swiss:
            return Color(red: 0.9, green: 0.05, blue: 0.08)
        default:
            return accentD
        }
    }

    var accentA: Color {
        switch self {
        case .pixel:
            return PixelPalette.lime
        case .bauhaus:
            return Color(red: 0.9, green: 0.12, blue: 0.1)
        case .swiss:
            return Color(red: 0.02, green: 0.26, blue: 0.72)
        case .artDeco:
            return Color(red: 0.94, green: 0.72, blue: 0.28)
        case .cobalt:
            return Color(red: 0.35, green: 0.76, blue: 1)
        case .longTable:
            return Color(red: 0.95, green: 0.74, blue: 0.38)
        }
    }

    var accentB: Color {
        switch self {
        case .pixel:
            return PixelPalette.cyan
        case .bauhaus:
            return Color(red: 0.0, green: 0.22, blue: 0.68)
        case .swiss:
            return Color(red: 0.9, green: 0.05, blue: 0.08)
        case .artDeco:
            return Color(red: 0.22, green: 0.74, blue: 0.72)
        case .cobalt:
            return Color(red: 0.72, green: 0.9, blue: 1)
        case .longTable:
            return Color(red: 0.94, green: 0.38, blue: 0.22)
        }
    }

    var accentC: Color {
        switch self {
        case .pixel:
            return PixelPalette.gold
        case .bauhaus:
            return Color(red: 0.96, green: 0.78, blue: 0.05)
        case .swiss:
            return Color(red: 0.03, green: 0.08, blue: 0.13)
        case .artDeco:
            return Color(red: 0.95, green: 0.86, blue: 0.56)
        case .cobalt:
            return Color(red: 0.48, green: 0.58, blue: 1)
        case .longTable:
            return Color(red: 1, green: 0.84, blue: 0.58)
        }
    }

    var accentD: Color {
        switch self {
        case .pixel:
            return PixelPalette.pink
        case .bauhaus:
            return Color(red: 0.02, green: 0.02, blue: 0.02)
        case .swiss:
            return Color(red: 0.95, green: 0.2, blue: 0.14)
        case .artDeco:
            return Color(red: 0.62, green: 0.44, blue: 0.16)
        case .cobalt:
            return Color(red: 0.92, green: 0.44, blue: 0.82)
        case .longTable:
            return Color(red: 0.78, green: 0.24, blue: 0.14)
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .pixel, .cobalt:
            return .monospaced
        case .bauhaus, .swiss:
            return .default
        case .artDeco, .longTable:
            return .serif
        }
    }

    var labelWeight: Font.Weight {
        switch self {
        case .pixel, .bauhaus:
            return .black
        case .swiss, .cobalt:
            return .semibold
        case .artDeco, .longTable:
            return .bold
        }
    }

    var valueWeight: Font.Weight {
        switch self {
        case .pixel, .bauhaus:
            return .black
        case .swiss, .cobalt:
            return .heavy
        case .artDeco, .longTable:
            return .bold
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .pixel:
            return 12
        case .bauhaus:
            return 10
        case .swiss:
            return 8
        case .artDeco:
            return 15
        case .cobalt:
            return 10
        case .longTable:
            return 13
        }
    }

    var topPadding: CGFloat {
        switch self {
        case .bauhaus:
            return 14
        case .swiss:
            return 12
        case .artDeco:
            return 18
        case .cobalt:
            return 14
        default:
            return 16
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .cobalt:
            return 16
        case .bauhaus:
            return 14
        case .swiss:
            return 16
        case .artDeco:
            return 20
        default:
            return 18
        }
    }

    var bottomPadding: CGFloat {
        16
    }

    var gridSpacing: CGFloat {
        switch self {
        case .swiss:
            return 8
        case .artDeco:
            return 14
        case .cobalt:
            return 8
        case .bauhaus:
            return 12
        default:
            return 10
        }
    }

    var cardHeight: CGFloat {
        switch self {
        case .pixel:
            return 68
        case .bauhaus:
            return 62
        case .swiss:
            return 58
        case .artDeco:
            return 78
        case .cobalt:
            return 64
        case .longTable:
            return 72
        }
    }

    var cardCorner: CGFloat {
        switch self {
        case .pixel, .bauhaus, .swiss, .cobalt:
            return 0
        case .artDeco:
            return 8
        case .longTable:
            return 3
        }
    }

    var cardBorderWidth: CGFloat {
        switch self {
        case .pixel:
            return 2
        case .bauhaus:
            return 3
        case .swiss, .cobalt:
            return 1
        case .artDeco:
            return 2.2
        case .longTable:
            return 1.5
        }
    }

    var progressHeight: CGFloat {
        switch self {
        case .pixel:
            return 20
        case .bauhaus:
            return 24
        case .swiss:
            return 10
        case .artDeco:
            return 18
        case .cobalt:
            return 14
        case .longTable:
            return 22
        }
    }

    var progressCorner: CGFloat {
        switch self {
        case .pixel:
            return 0
        case .bauhaus, .swiss:
            return 0
        case .artDeco:
            return 9
        case .cobalt:
            return 2
        case .longTable:
            return 11
        }
    }

    var valueFontSize: CGFloat {
        switch self {
        case .pixel:
            return 28
        case .bauhaus:
            return 30
        case .swiss:
            return 25
        case .artDeco:
            return 29
        case .cobalt:
            return 26
        case .longTable:
            return 27
        }
    }

    var labelFontSize: CGFloat {
        switch self {
        case .swiss:
            return 9
        case .artDeco, .longTable:
            return 11
        default:
            return 10
        }
    }

    var expandedDeckHeight: CGFloat {
        switch self {
        case .pixel:
            return 276
        case .bauhaus:
            return 260
        case .swiss:
            return 228
        case .artDeco:
            return 304
        case .cobalt:
            return 244
        case .longTable:
            return 288
        }
    }
}

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var snapshot: CodexUsageSnapshot = .empty
    @Published var errorMessage: String?
    @Published var refreshPulse = false
    @Published var authMessage: String?
    @Published var isRefreshing = false
    @Published var toastMessage: String?
    @Published var selectedProvider: AgentUsageProvider = UserDefaults.standard.string(forKey: "selectedProvider")
        .flatMap(AgentUsageProvider.init(rawValue:)) ?? .codex

    private let usageService = CodexUsageService()
    private var refreshTask: Task<Void, Never>?
    private var signInTask: Task<Void, Never>?

    func refresh(showToast: Bool = false) {
        withAnimation(.easeInOut(duration: 0.18)) {
            refreshPulse.toggle()
        }
        if showToast {
            toastMessage = nil
        }
        isRefreshing = true

        refreshTask?.cancel()
        let provider = selectedProvider
        refreshTask = Task { [usageService] in
            do {
                let nextSnapshot = try await usageService.todaySnapshot(provider: provider)
                guard !Task.isCancelled else {
                    return
                }

                snapshot = nextSnapshot
                errorMessage = nil
                isRefreshing = false
                if showToast {
                    presentToast("Synced \(nextSnapshot.source?.label ?? provider.compactName)")
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                snapshot = .empty
                errorMessage = error.localizedDescription
                isRefreshing = false
                if showToast {
                    presentToast("Sync failed: \(Self.shortError(error))")
                }
            }
        }
    }

    func bump() {
        withAnimation(.easeOut(duration: 0.18)) {
            refreshPulse.toggle()
        }
    }

    func selectProvider(_ provider: AgentUsageProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: "selectedProvider")
        authMessage = "Using \(provider.displayName)"
        refresh()
    }

    func signIn(
        provider: AgentUsageProvider,
        _ action: @escaping (AgentUsageProvider) async throws -> CodexOAuthCredentials
    ) {
        authMessage = "Opening \(provider.displayName) sign-in..."
        signInTask?.cancel()
        signInTask = Task {
            do {
                _ = try await action(provider)
                guard !Task.isCancelled else {
                    return
                }
                selectedProvider = provider
                UserDefaults.standard.set(provider.rawValue, forKey: "selectedProvider")
                authMessage = "\(provider.displayName) sign-in complete"
                presentToast("\(provider.displayName) signed in")
                refresh(showToast: true)
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                authMessage = error.localizedDescription
                presentToast("Sign-in failed")
            }
        }
    }

    private func presentToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            toastMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard !Task.isCancelled else {
                return
            }
            withAnimation(.easeIn(duration: 0.18)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }

    private static func shortError(_ error: Error) -> String {
        if let remoteError = error as? CodexRemoteUsageError {
            switch remoteError {
            case .missingCredentials:
                return "not signed in"
            case .invalidURL:
                return "bad URL"
            case .requestFailed(let status):
                return "HTTP \(status)"
            case .refreshFailed(let status):
                return "refresh HTTP \(status)"
            case .unrecoverableRefresh:
                return "sign in again"
            case .emptyResponse:
                return "empty usage"
            }
        }

        let message = error.localizedDescription
        return message.count > 30 ? String(message.prefix(27)) + "..." : message
    }
}

struct NotchOverlayView: View {
    @ObservedObject var viewModel: UsageViewModel
    let metrics: NotchOverlayMetrics
    let onRefresh: () -> Void
    let onSelectProvider: (AgentUsageProvider) -> Void
    let onSignIn: (AgentUsageProvider) -> Void
    let onSignOut: (AgentUsageProvider) -> Void
    let onConfigureProxy: () -> Void
    let onClearProxy: () -> Void
    let onQuit: () -> Void
    let onExpansionChange: (Bool) -> Void

    @State private var expanded = false
    @State private var hover = false
    @State private var scanlineOffset: CGFloat = -42
    @State private var theme: NotchTheme = .pixel

    private var expansionAnimation: Animation {
        .easeInOut(duration: expanded ? 0.24 : 0.18)
    }

    private var expansionProgress: CGFloat {
        expanded ? 1 : 0
    }

    private var visibleHeight: CGFloat {
        metrics.menuBarHeight + theme.expandedDeckHeight * expansionProgress
    }

    var body: some View {
        ZStack(alignment: .top) {
            UnifiedNotchShape()
                .fill(PixelPalette.notch)
                .shadow(color: Color.black.opacity(0.34), radius: 12, x: 0, y: 6)
                .frame(height: visibleHeight)
                .animation(expansionAnimation, value: expanded)
                .animation(expansionAnimation, value: theme)

            VStack(spacing: 0) {
                notchCap

                expandedDeck
                    .opacity(expanded ? 1 : 0)
                    .frame(height: theme.expandedDeckHeight * expansionProgress, alignment: .top)
                    .clipped()
                    .allowsHitTesting(expanded)
                    .animation(expansionAnimation, value: expanded)
                    .animation(expansionAnimation, value: theme)

                Spacer(minLength: 0)
            }
        }
        .frame(
            width: metrics.totalWidth,
            height: metrics.expandedHeight,
            alignment: .top
        )
        .clipShape(TopAnchoredNotchMask(height: visibleHeight))
        .contentShape(TopAnchoredNotchMask(height: visibleHeight))
        .animation(expansionAnimation, value: theme)
        .background(Color.clear)
        .onHover { inside in
            guard !inside else {
                return
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                hover = false
                expanded = false
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                scanlineOffset = 420
            }
        }
        .onChange(of: expanded) { _, newValue in
            onExpansionChange(newValue)
        }
        .contextMenu {
            ForEach(AgentUsageProvider.allCases, id: \.self) { provider in
                Button("Use \(provider.displayName)\(provider == viewModel.selectedProvider ? " (current)" : "")") {
                    onSelectProvider(provider)
                }
            }
            Divider()
            ForEach(AgentUsageProvider.allCases, id: \.self) { provider in
                Button("Sign in with \(provider.displayName)") {
                    onSignIn(provider)
                }
            }
            Button("Clear \(viewModel.selectedProvider.displayName) Sign-In") {
                onSignOut(viewModel.selectedProvider)
            }
            Divider()
            Button("Configure Proxy...") {
                onConfigureProxy()
            }
            Button("Clear Proxy") {
                onClearProxy()
            }
            Divider()
            Button("Quit NotchMeter", action: onQuit)
        }
    }

    private var notchCap: some View {
        ZStack {
            PixelPalette.notch

            HStack(spacing: 0) {
                Button {
                    if expanded {
                        onRefresh()
                    } else {
                        toggleExpanded()
                    }
                } label: {
                    Group {
                        if expanded {
                            NotchActionLabel(title: viewModel.isRefreshing ? "SYNC..." : "SYNC", tint: theme.accentB)
                        } else {
                            CompactRemainingLabel(
                                label: "5H",
                                value: remainingText(for: viewModel.snapshot.rateLimits?.primary),
                                tint: remainingColor(for: viewModel.snapshot.rateLimits?.primary),
                                theme: theme
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: metrics.earWidth, height: metrics.menuBarHeight)

                Color.clear
                    .frame(width: metrics.notchWidth, height: metrics.menuBarHeight)
                    .allowsHitTesting(false)

                Button {
                    if expanded {
                        cycleTheme()
                    } else {
                        toggleExpanded()
                    }
                } label: {
                    Group {
                        if expanded {
                            NotchActionLabel(title: theme.buttonTitle, tint: theme.actionAccent)
                        } else {
                            CompactRemainingLabel(
                                label: "WK",
                                value: remainingText(for: viewModel.snapshot.rateLimits?.secondary),
                                tint: remainingColor(for: viewModel.snapshot.rateLimits?.secondary),
                                theme: theme
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: metrics.earWidth, height: metrics.menuBarHeight)
            }
        }
        .frame(width: metrics.totalWidth, height: metrics.menuBarHeight)
        .contentShape(Rectangle())
        .onHover { inside in
            guard inside else {
                return
            }
            withAnimation(.easeInOut(duration: 0.24)) {
                hover = true
                expanded = true
                viewModel.bump()
            }
        }
    }

    private var expandedDeck: some View {
        ZStack(alignment: .top) {
            PixelPalette.notch

            VStack(alignment: .leading, spacing: theme.contentSpacing) {
                DualLimitProgress(
                    primary: viewModel.snapshot.rateLimits?.primary,
                    secondary: viewModel.snapshot.rateLimits?.secondary,
                    primaryReset: relative(viewModel.snapshot.rateLimits?.primary?.resetsAt),
                    secondaryReset: relative(viewModel.snapshot.rateLimits?.secondary?.resetsAt),
                    pulse: viewModel.refreshPulse,
                    theme: theme
                )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: theme.gridSpacing), count: 2), spacing: theme.gridSpacing) {
                    PixelMetricCard(label: "TOTAL", value: compact(viewModel.snapshot.totalUsage.totalTokens), tint: theme.accentA, theme: theme)
                    PixelMetricCard(label: "OUT", value: compact(viewModel.snapshot.totalUsage.outputTokens), tint: theme.accentB, theme: theme)
                    PixelMetricCard(label: "THINK", value: compact(viewModel.snapshot.totalUsage.reasoningOutputTokens), tint: theme.accentC, theme: theme)
                    PixelMetricCard(label: "CACHED", value: compact(viewModel.snapshot.totalUsage.cachedInputTokens), tint: theme.accentD, theme: theme)
                }
            }
            .padding(.horizontal, theme.horizontalPadding)
            .padding(.top, theme.topPadding)
            .padding(.bottom, theme.bottomPadding)

            VStack {
                Spacer()
                HStack {
                    SourceBadge(text: viewModel.snapshot.source?.label ?? "\(viewModel.selectedProvider.compactName) --", theme: theme)
                    Spacer()
                }
            }
            .padding(.horizontal, theme.horizontalPadding)
            .padding(.bottom, 2)

            if let toastMessage = viewModel.toastMessage {
                VStack {
                    Spacer()
                    ToastPill(text: toastMessage, theme: theme)
                        .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .frame(width: metrics.totalWidth, height: theme.expandedDeckHeight)
    }

    private func toggleExpanded() {
        withAnimation(.easeInOut(duration: expanded ? 0.18 : 0.24)) {
            expanded.toggle()
            viewModel.bump()
        }
    }

    private func cycleTheme() {
        withAnimation(.easeInOut(duration: 0.18)) {
            theme = theme.next
        }
    }

    private func remainingText(for window: RateLimitWindow?) -> String {
        guard viewModel.errorMessage == nil, let window else {
            return "--"
        }
        let remaining = max(0, min(100, 100 - window.usedPercent))
        return "\(Int(remaining.rounded()))%"
    }

    private func remainingColor(for window: RateLimitWindow?) -> Color {
        guard viewModel.errorMessage == nil, let window else {
            return theme.muted
        }
        let remaining = max(0, min(100, 100 - window.usedPercent))
        if remaining <= 15 {
            return theme.accentD
        }
        if remaining <= 40 {
            return theme.accentC
        }
        return theme.accentA
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

private struct MiniUsageStrip: View {
    let value: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                Rectangle()
                    .fill(Double(index) < value / 10 ? PixelPalette.lime : PixelPalette.panel)
                    .frame(width: 7, height: 5)
                    .overlay(Rectangle().stroke(PixelPalette.edge.opacity(0.65), lineWidth: 1))
            }
        }
    }
}

private struct CompactRemainingLabel: View {
    let label: String
    let value: String
    let tint: Color
    let theme: NotchTheme

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(theme.muted)
            Text(value)
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .font(.system(size: compactFontSize, weight: theme.labelWeight, design: theme.fontDesign))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, 6)
    }

    private var compactFontSize: CGFloat {
        switch theme {
        case .longTable:
            return 12
        case .cobalt:
            return 11
        default:
            return 12
        }
    }
}

private struct NotchActionLabel: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 6)
    }
}

private struct SourceBadge: View {
    let text: String
    let theme: NotchTheme

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: theme.labelWeight, design: theme.fontDesign))
            .foregroundStyle(theme.hudMuted.opacity(0.58))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(theme.hudMuted.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .allowsHitTesting(false)
    }
}

private struct ToastPill: View {
    let text: String
    let theme: NotchTheme

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: theme.labelWeight, design: theme.fontDesign))
            .foregroundStyle(theme.hudInk)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(theme.accentB.opacity(0.42), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 3)
            .allowsHitTesting(false)
    }
}

private struct MiniUsagePip: View {
    let value: Double

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 6, height: 10)
            .overlay(Rectangle().stroke(PixelPalette.edge.opacity(0.7), lineWidth: 1))
    }

    private var color: Color {
        if value >= 80 {
            return PixelPalette.pink
        }
        if value >= 50 {
            return PixelPalette.gold
        }
        return PixelPalette.lime
    }
}

private struct DualLimitProgress: View {
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
    let primaryReset: String
    let secondaryReset: String
    let pulse: Bool
    let theme: NotchTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            limitRow(title: "5H", window: primary, reset: primaryReset, accent: color(for: primary))
            limitRow(title: "WK", window: secondary, reset: secondaryReset, accent: color(for: secondary))
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(y: pulse ? 1.035 : 1)
    }

    private func limitRow(title: String, window: RateLimitWindow?, reset: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(title)
                    .foregroundStyle(theme.hudMuted)
                Text("\(remainingPercent(for: window)) LEFT")
                    .foregroundStyle(accent)
                Spacer()
                Text("\(usedPercent(for: window)) USED")
                    .foregroundStyle(theme.hudInk)
                Text("RESET \(reset)")
                    .foregroundStyle(theme.hudMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.system(size: 11, weight: theme.labelWeight, design: theme.fontDesign))

            GeometryReader { proxy in
                let remaining = max(0, min(100, 100 - (window?.usedPercent ?? 100)))
                let width = proxy.size.width * remaining / 100

                ZStack(alignment: .leading) {
                    progressShape
                        .fill(theme.track)
                    progressShape
                        .fill(accent)
                        .frame(width: width)
                    if theme == .pixel {
                        PixelTicks()
                    } else if theme == .bauhaus {
                        BauhausDividers()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: theme.progressCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.progressCorner, style: .continuous)
                        .stroke(theme.edge, lineWidth: theme.cardBorderWidth)
                )
            }
            .frame(height: theme.progressHeight)
        }
    }

    private var progressShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.progressCorner, style: .continuous)
    }

    private func usedPercent(for window: RateLimitWindow?) -> String {
        guard let window else {
            return "--"
        }
        return "\(Int(window.usedPercent.rounded()))%"
    }

    private func remainingPercent(for window: RateLimitWindow?) -> String {
        guard let window else {
            return "--"
        }
        let remaining = max(0, min(100, 100 - window.usedPercent))
        return "\(Int(remaining.rounded()))%"
    }

    private func color(for window: RateLimitWindow?) -> Color {
        guard let window else {
            return theme.muted
        }
        let remaining = max(0, min(100, 100 - window.usedPercent))
        if remaining <= 15 {
            return theme.accentD
        }
        if remaining <= 40 {
            return theme.accentC
        }
        return theme.accentA
    }
}

private struct QuotaDetailStrip: View {
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
    let primaryReset: String
    let secondaryReset: String

    var body: some View {
        HStack(spacing: 10) {
            quotaPanel(title: "5H", window: primary, reset: primaryReset)
            quotaPanel(title: "WEEK", window: secondary, reset: secondaryReset)
        }
    }

    private func quotaPanel(title: String, window: RateLimitWindow?, reset: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundStyle(color(for: window))
                Spacer()
                Text(windowSpan(for: window))
                    .foregroundStyle(PixelPalette.muted)
            }

            HStack(spacing: 8) {
                quotaStat("LEFT", remainingPercent(for: window), color(for: window))
                quotaStat("USED", usedPercent(for: window), PixelPalette.ink)
                quotaStat("RESET", reset, PixelPalette.ink)
            }
        }
        .font(.system(size: 10, weight: .black, design: .monospaced))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PixelPalette.panel.opacity(0.78))
        .overlay(Rectangle().stroke(PixelPalette.edge.opacity(0.75), lineWidth: 2))
    }

    private func quotaStat(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundStyle(PixelPalette.muted)
            Text(value)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func usedPercent(for window: RateLimitWindow?) -> String {
        guard let window else {
            return "--"
        }
        return "\(Int(window.usedPercent.rounded()))%"
    }

    private func remainingPercent(for window: RateLimitWindow?) -> String {
        guard let window else {
            return "--"
        }
        let remaining = max(0, min(100, 100 - window.usedPercent))
        return "\(Int(remaining.rounded()))%"
    }

    private func color(for window: RateLimitWindow?) -> Color {
        guard let window else {
            return PixelPalette.muted
        }
        let remaining = max(0, min(100, 100 - window.usedPercent))
        if remaining <= 15 {
            return PixelPalette.pink
        }
        if remaining <= 40 {
            return PixelPalette.gold
        }
        return PixelPalette.lime
    }

    private func windowSpan(for window: RateLimitWindow?) -> String {
        guard let minutes = window?.windowMinutes else {
            return "--"
        }
        if minutes >= 60 * 24 {
            return "\(minutes / (60 * 24))D"
        }
        if minutes >= 60 {
            return "\(minutes / 60)H"
        }
        return "\(minutes)M"
    }
}

private struct WeakStatusBar: View {
    let plan: String

    var body: some View {
        HStack {
            Text("LOCAL JSONL")
            Spacer()
            Text(plan)
        }
        .font(.system(size: 9, weight: .black, design: .monospaced))
        .foregroundStyle(PixelPalette.muted.opacity(0.62))
        .padding(.top, 1)
    }
}

private struct PixelChevron: View {
    let expanded: Bool

    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .frame(width: 8, height: 2)
                .offset(x: expanded ? -2 : 0, y: expanded ? 1 : 0)
            Rectangle()
                .frame(width: 8, height: 2)
                .offset(x: expanded ? 2 : 0, y: expanded ? -1 : 0)
        }
        .foregroundStyle(PixelPalette.cyan)
        .rotationEffect(.degrees(expanded ? 0 : 90))
        .animation(.snappy(duration: 0.18), value: expanded)
    }
}

private struct NotchCapShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - radius),
            control: CGPoint(x: 0, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct UnifiedNotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = min(22, rect.width / 10, rect.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct TopAnchoredNotchMask: Shape {
    var height: CGFloat

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func path(in rect: CGRect) -> Path {
        UnifiedNotchShape().path(in: CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: min(max(0, height), rect.height)
        ))
    }
}

private struct NotchDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 22
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - radius),
            control: CGPoint(x: 0, y: rect.maxY)
        )
        path.closeSubpath()
        return path
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
                    Text("NOTCH METER")
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

private struct BauhausDividers: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.34))
                .frame(width: 5)
            Spacer()
            Rectangle()
                .fill(Color.black.opacity(0.34))
                .frame(width: 5)
            Spacer()
            Rectangle()
                .fill(Color.black.opacity(0.34))
                .frame(width: 5)
        }
    }
}

private struct PixelMetricCard: View {
    let label: String
    let value: String
    let tint: Color
    var theme: NotchTheme = .pixel

    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: theme.labelFontSize, weight: theme.labelWeight, design: theme.fontDesign))
                .foregroundStyle(theme.muted)
            Text(value)
                .font(.system(size: theme.valueFontSize, weight: theme.valueWeight, design: theme.fontDesign))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, theme == .cobalt ? 12 : 10)
        .padding(.vertical, theme == .cobalt ? 8 : 10)
        .frame(height: theme.cardHeight, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCorner, style: .continuous)
                .fill(theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCorner, style: .continuous)
                .stroke(hover ? tint : theme.edge, lineWidth: theme.cardBorderWidth)
        )
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
    static let notch = Color.black
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
