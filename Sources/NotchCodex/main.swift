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
                metrics: overlay.metrics,
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
    let metrics = NotchOverlayMetrics.current()
    private var panel: NSPanel?
    private var isExpanded = false
    private var collapseWorkItem: DispatchWorkItem?

    func show<Content: View>(rootView: Content) {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: metrics.compactSize),
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
        position(size: metrics.compactSize)
        panel.orderFrontRegardless()
    }

    func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        collapseWorkItem?.cancel()

        if expanded {
            position(size: metrics.expandedSize)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, !self.isExpanded else {
                    return
                }
                self.position(size: self.metrics.compactSize)
            }
        }
        collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    private func position(size: NSSize) {
        guard let panel else {
            return
        }

        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height
        )
        let target = NSRect(origin: origin, size: size)
        panel.setFrame(target, display: true)
    }
}

struct NotchOverlayMetrics {
    var totalWidth: CGFloat
    var notchWidth: CGFloat
    var menuBarHeight: CGFloat
    var expandedHeight: CGFloat

    var compactSize: NSSize {
        NSSize(width: totalWidth, height: menuBarHeight)
    }

    var expandedSize: NSSize {
        NSSize(width: totalWidth, height: expandedHeight)
    }

    var earWidth: CGFloat {
        max(104, (totalWidth - notchWidth) / 2)
    }

    static func current(screen: NSScreen? = NSScreen.main ?? NSScreen.screens.first) -> NotchOverlayMetrics {
        guard let screen else {
            return NotchOverlayMetrics(totalWidth: 448, notchWidth: 188, menuBarHeight: 32, expandedHeight: 330)
        }

        if #available(macOS 12.0, *),
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let notchWidth = max(140, right.minX - left.maxX)
            let menuBarHeight = max(28, screen.safeAreaInsets.top)
            let earWidth: CGFloat = 84
            return NotchOverlayMetrics(
                totalWidth: notchWidth + earWidth * 2,
                notchWidth: notchWidth,
                menuBarHeight: menuBarHeight,
                expandedHeight: menuBarHeight + 304
            )
        }

        return NotchOverlayMetrics(totalWidth: 448, notchWidth: 188, menuBarHeight: 32, expandedHeight: 330)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
