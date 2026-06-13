import AppKit
import CodexUsageCore
import Foundation
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let viewModel = UsageViewModel()
    private let popover = NSPopover()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let button = statusItem.button {
            button.title = "Codex ..."
            button.toolTip = "Codex usage near the notch"
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        configurePopover()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        viewModel.refresh()
        statusItem.button?.title = statusTitle(for: viewModel.snapshot, error: viewModel.errorMessage)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 348)
        popover.contentViewController = NSHostingController(
            rootView: PixelUsagePanel(
                viewModel: viewModel,
                onRefresh: { [weak self] in self?.refresh() },
                onQuit: { NSApp.terminate(nil) }
            )
        )
    }

    private func statusTitle(for snapshot: CodexUsageSnapshot, error: String?) -> String {
        if error != nil {
            return "Codex --"
        }

        if let primary = snapshot.rateLimits?.primary {
            return "Codex \(Int(primary.usedPercent.rounded()))%"
        }

        if snapshot.totalUsage.totalTokens > 0 {
            return "Codex \(Self.compact(snapshot.totalUsage.totalTokens))"
        }

        return "Codex idle"
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

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            viewModel.bump()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
