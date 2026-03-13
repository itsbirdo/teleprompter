import AppKit

/// A floating, non-activating panel that stays above all windows
/// and is invisible to screen sharing / screen capture.
class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Float above everything
        level = .floating
        isFloatingPanel = true

        // Don't steal focus from main app or other apps
        becomesKeyOnlyIfNeeded = true

        // Allow dragging by background
        isMovableByWindowBackground = true

        // Invisible to screen sharing
        sharingType = .none

        // Appearance
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // Show on all spaces
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Keep visible
        hidesOnDeactivate = false
    }
}
