import AppKit
import CodexUsageCore
import Foundation
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = UsageViewModel()
    private let overlay = NotchOverlayController()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configureOverlay()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        viewModel.refresh()
    }

    private func configureOverlay() {
        overlay.show(
            rootView: NotchOverlayView(
                viewModel: viewModel,
                onRefresh: { [weak self] in self?.refresh() },
                onQuit: { NSApp.terminate(nil) },
                onExpansionChange: { [weak self] expanded in
                    self?.overlay.setExpanded(expanded)
                }
            )
        )
    }

}

@MainActor
final class NotchOverlayController {
    private let compactSize = NSSize(width: 286, height: 72)
    private let expandedSize = NSSize(width: 420, height: 356)
    private var panel: NSPanel?
    private var isExpanded = false

    func show<Content: View>(rootView: Content) {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: compactSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.contentViewController = NSHostingController(rootView: rootView)

        self.panel = panel
        position(size: compactSize, animated: false)
        panel.orderFrontRegardless()
    }

    func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        position(size: expanded ? expandedSize : compactSize, animated: true)
    }

    private func position(size: NSSize, animated: Bool) {
        guard let panel else {
            return
        }

        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height + 1
        )
        let target = NSRect(origin: origin, size: size)

        if animated {
            panel.animator().setFrame(target, display: true)
        } else {
            panel.setFrame(target, display: true)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
