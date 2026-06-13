import AppKit
import CodexUsageCore
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let reader = CodexUsageReader()
    private var timer: Timer?
    private var latestSnapshot: CodexUsageSnapshot = .empty

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let button = statusItem.button {
            button.title = "Codex ..."
            button.toolTip = "Codex usage near the notch"
        }

        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        do {
            latestSnapshot = try reader.todaySnapshot()
            statusItem.button?.title = statusTitle(for: latestSnapshot)
            statusItem.menu = menu(for: latestSnapshot)
        } catch {
            statusItem.button?.title = "Codex --"
            statusItem.menu = errorMenu(error)
        }
    }

    private func statusTitle(for snapshot: CodexUsageSnapshot) -> String {
        if let primary = snapshot.rateLimits?.primary {
            return "Codex \(Int(primary.usedPercent.rounded()))%"
        }

        if snapshot.totalUsage.totalTokens > 0 {
            return "Codex \(Self.compact(snapshot.totalUsage.totalTokens))"
        }

        return "Codex idle"
    }

    private func menu(for snapshot: CodexUsageSnapshot) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(.sectionHeader(title: "Codex Usage Today"))
        menu.addItem(NSMenuItem(title: "Total tokens: \(Self.decimal(snapshot.totalUsage.totalTokens))", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Input: \(Self.decimal(snapshot.totalUsage.inputTokens))", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Output: \(Self.decimal(snapshot.totalUsage.outputTokens))", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reasoning: \(Self.decimal(snapshot.totalUsage.reasoningOutputTokens))", action: nil, keyEquivalent: ""))

        if let primary = snapshot.rateLimits?.primary {
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "5h window: \(Self.percent(primary.usedPercent))", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Resets: \(Self.relative(primary.resetsAt))", action: nil, keyEquivalent: ""))
        }

        if let secondary = snapshot.rateLimits?.secondary {
            menu.addItem(NSMenuItem(title: "Weekly: \(Self.percent(secondary.usedPercent))", action: nil, keyEquivalent: ""))
        }

        if let plan = snapshot.rateLimits?.planType {
            menu.addItem(NSMenuItem(title: "Plan: \(plan)", action: nil, keyEquivalent: ""))
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Sessions scanned: \(snapshot.scannedFiles)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Last update: \(Self.relative(snapshot.newestEventDate))", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshFromMenu), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        return menu
    }

    private func errorMenu(_ error: Error) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(.sectionHeader(title: "Codex Usage"))
        menu.addItem(NSMenuItem(title: "Unable to read usage", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "\(error)", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshFromMenu), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        return menu
    }

    @objc private func refreshFromMenu() {
        refresh()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private static func compact(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }

    private static func decimal(_ value: Int) -> String {
        value.formatted(.number)
    }

    private static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private static func relative(_ date: Date?) -> String {
        guard let date else {
            return "unknown"
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
