import AppKit
import AgentUsageCore
import Foundation
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = UsageViewModel()
    private let oauthCodeBroker = OAuthCodeBroker()
    private lazy var signInController = CodexOAuthSignInController { [oauthCodeBroker] provider in
        try await oauthCodeBroker.requestCode(provider: provider)
    }
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

    private func manualRefresh() {
        viewModel.refresh(showToast: true)
    }

    private func configureOverlay() {
        overlay.show(
            rootView: NotchOverlayView(
                viewModel: viewModel,
                oauthCodeBroker: oauthCodeBroker,
                metrics: overlay.metrics,
                onRefresh: { [weak self] in self?.manualRefresh() },
                onSelectProvider: { [weak self] provider in self?.selectProvider(provider) },
                onSignIn: { [weak self] provider in self?.signIn(provider: provider) },
                onQuit: { NSApp.terminate(nil) },
                onExpansionChange: { [weak self] expanded in
                    self?.overlay.setExpanded(expanded)
                }
            )
        )
    }

    private func selectProvider(_ provider: AgentUsageProvider) {
        viewModel.selectProvider(provider)
    }

    private func signIn(provider: AgentUsageProvider) {
        viewModel.signIn(provider: provider) { [signInController] provider in
            try await signInController.signIn(provider: provider)
        }
    }

}

@MainActor
final class NotchOverlayController {
    let metrics = NotchOverlayMetrics.current()
    private var panel: NSPanel?
    private var isExpanded = false
    private var collapseWorkItem: DispatchWorkItem?

    func show<Content: View>(rootView: Content) {
        let panel = NotchPanel(
            contentRect: NSRect(origin: .zero, size: metrics.compactSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        // The panel hosts an animated, non-rectangular transparent surface.
        // AppKit caches a window-level shadow mask after resize/expand cycles,
        // which can leave a persistent gray halo around the collapsed notch.
        // Composite the black notch directly against the screen instead.
        panel.hasShadow = false
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

        panel.layoutIfNeeded()
        let fittingWidth = panel.contentView?.fittingSize.width ?? size.width
        let resolvedSize = NSSize(
            width: max(size.width, fittingWidth),
            height: size.height
        )
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: frame.midX - resolvedSize.width / 2,
            y: frame.maxY - resolvedSize.height
        )
        let target = NSRect(origin: origin, size: resolvedSize)
        panel.setFrame(target, display: true)
    }
}

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
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
        max(0, (totalWidth - notchWidth) / 2)
    }

    static func current(screen: NSScreen? = NSScreen.main ?? NSScreen.screens.first) -> NotchOverlayMetrics {
        guard let screen else {
            return NotchOverlayMetrics(totalWidth: 448, notchWidth: 188, menuBarHeight: 32, expandedHeight: 462)
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
                expandedHeight: menuBarHeight + 430
            )
        }

        return NotchOverlayMetrics(totalWidth: 448, notchWidth: 188, menuBarHeight: 32, expandedHeight: 462)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
