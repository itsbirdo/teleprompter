import AppKit
import SwiftUI

/// Manages the floating teleprompter panel window.
class TeleprompterPanelController {
    private var panel: FloatingPanel?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    func showPanel() {
        guard let appState else { return }

        let width = appState.teleprompterWidth
        let height = appState.teleprompterHeight

        // Position: centered horizontally, at the very top of the screen (below menu bar)
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.midX - width / 2
        let y = visibleFrame.maxY - height
        let frame = NSRect(x: x, y: y, width: width, height: height)

        let panel = FloatingPanel(contentRect: frame)
        self.panel = panel

        let teleprompterView = TeleprompterView()
            .environmentObject(appState)

        let hostingView = NSHostingView(rootView: teleprompterView)
        hostingView.frame = panel.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hostingView)

        // Handle keyboard events in the panel
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let appState = self.appState, appState.isPrompting else { return event }
            return self.handleKeyEvent(event) ? nil : event
        }
        self._eventMonitor = monitor

        panel.orderFrontRegardless()
    }

    func hidePanel() {
        panel?.orderOut(nil)
        panel = nil
        if let monitor = _eventMonitor {
            NSEvent.removeMonitor(monitor)
            _eventMonitor = nil
        }
    }

    func updateSize(width: CGFloat, height: CGFloat) {
        guard let panel else { return }
        var frame = panel.frame
        let centerX = frame.midX
        let topY = frame.maxY
        frame.size.width = width
        frame.size.height = height
        frame.origin.x = centerX - width / 2
        frame.origin.y = topY - height
        panel.setFrame(frame, display: true, animate: true)
    }

    private var _eventMonitor: Any?

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let appState else { return false }

        switch event.keyCode {
        case 53: // Escape
            appState.stopPrompting()
            return true
        case 49: // Space
            appState.togglePause()
            return true
        case 126: // Up arrow
            appState.adjustScroll(by: -30)
            return true
        case 125: // Down arrow
            appState.adjustScroll(by: 30)
            return true
        case 24: // + (equals/plus)
            appState.fontSize = min(80, appState.fontSize + 2)
            return true
        case 27: // - (minus)
            appState.fontSize = max(16, appState.fontSize - 2)
            return true
        default:
            return false
        }
    }
}
