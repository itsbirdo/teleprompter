import SwiftUI
import Combine
import AppKit

class AppState: ObservableObject {
    // MARK: - Script
    @Published var scriptText: String {
        didSet { UserDefaults.standard.set(scriptText, forKey: "scriptText") }
    }

    // MARK: - Teleprompter State
    @Published var isPrompting = false
    @Published var isLoading = false
    @Published var scrollOffset: CGFloat = 0
    @Published var totalContentHeight: CGFloat = 0
    @Published var isSpeaking = false
    @Published var audioLevel: Float = 0
    @Published var isPaused = false

    // Speech hold: keeps scrolling during natural pauses between words
    private var speechHoldTimer: Timer?
    private let speechHoldDuration: TimeInterval = 0.1 // seconds to keep scrolling after voice drops

    // Smooth scroll velocity (eases in/out instead of instant start/stop)
    @Published var scrollVelocity: CGFloat = 0

    // MARK: - Countdown
    @Published var isCountingDown = false
    @Published var countdownValue = 3

    // MARK: - Settings
    @Published var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(fontSize), forKey: "fontSize") }
    }
    @Published var textColorHex: String {
        didSet { UserDefaults.standard.set(textColorHex, forKey: "textColorHex") }
    }
    @Published var scrollSpeed: CGFloat {
        didSet { UserDefaults.standard.set(Double(scrollSpeed), forKey: "scrollSpeed") }
    }
    @Published var micSensitivity: Float {
        didSet { UserDefaults.standard.set(Double(micSensitivity), forKey: "micSensitivity") }
    }
    @Published var windowOpacity: CGFloat {
        didSet { UserDefaults.standard.set(Double(windowOpacity), forKey: "windowOpacity") }
    }
    @Published var countdownDuration: Int {
        didSet { UserDefaults.standard.set(countdownDuration, forKey: "countdownDuration") }
    }
    @Published var teleprompterWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(teleprompterWidth), forKey: "teleprompterWidth") }
    }
    @Published var teleprompterHeight: CGFloat {
        didSet { UserDefaults.standard.set(Double(teleprompterHeight), forKey: "teleprompterHeight") }
    }
    @Published var mirrorText: Bool {
        didSet { UserDefaults.standard.set(mirrorText, forKey: "mirrorText") }
    }

    var textColor: Color {
        Color(hex: textColorHex) ?? .white
    }

    // MARK: - Services
    private var audioMonitor: AudioMonitor?
    private var scrollTimer: Timer?
    private var countdownTimer: Timer?
    var panelController: TeleprompterPanelController?

    // MARK: - Init
    init() {
        let defaults = UserDefaults.standard
        self.scriptText = defaults.string(forKey: "scriptText")
            ?? "Welcome to Teleprompter.\n\nPaste or type your script here. When you start the teleprompter, this text will appear in a floating window near your camera.\n\nThe text scrolls automatically when it detects your voice through the microphone. Pause speaking and the scroll pauses too.\n\nYou can adjust the font size, scroll speed, colors, and microphone sensitivity at the bottom of the window. Check the settings for more customisation.\n\nPress Command+Return to start, and Escape to stop."
        self.fontSize = CGFloat(defaults.double(forKey: "fontSize").nonZero ?? 36)
        self.textColorHex = defaults.string(forKey: "textColorHex") ?? "#FFFFFF"
        self.scrollSpeed = CGFloat(defaults.double(forKey: "scrollSpeed").nonZero ?? 55)
        self.micSensitivity = Float(defaults.double(forKey: "micSensitivity").nonZero ?? 0.28)
        self.windowOpacity = CGFloat(defaults.double(forKey: "windowOpacity").nonZero ?? 0.92)
        self.countdownDuration = defaults.object(forKey: "countdownDuration") as? Int ?? 3
        self.teleprompterWidth = CGFloat(defaults.double(forKey: "teleprompterWidth").nonZero ?? 480)
        self.teleprompterHeight = CGFloat(defaults.double(forKey: "teleprompterHeight").nonZero ?? 320)
        self.mirrorText = defaults.bool(forKey: "mirrorText")
    }

    // MARK: - Teleprompter Control

    func startPrompting() {
        guard !isPrompting, !isCountingDown, !isLoading else { return }

        isLoading = true
        scrollOffset = 0
        isPaused = false

        // Brief minimum loading time, then proceed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }

            if self.countdownDuration == 0 {
                self.beginScrolling()
                return
            }

            self.isCountingDown = true
            self.countdownValue = self.countdownDuration

            self.countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                DispatchQueue.main.async {
                    self.countdownValue -= 1
                    if self.countdownValue <= 0 {
                        timer.invalidate()
                        self.countdownTimer = nil
                        self.isCountingDown = false
                        self.beginScrolling()
                    }
                }
            }
        }
    }

    private func beginScrolling() {
        isPrompting = true
        scrollVelocity = 0

        // Show the floating panel
        if panelController == nil {
            panelController = TeleprompterPanelController(appState: self)
        }
        panelController?.showPanel()

        // Clear loading now that the panel is visible
        isLoading = false

        // Start audio monitoring
        audioMonitor = AudioMonitor { [weak self] level in
            guard let self else { return }
            DispatchQueue.main.async {
                self.audioLevel = level

                let voiceDetected = level > self.micSensitivity

                if voiceDetected {
                    // Voice detected: mark speaking and reset hold timer
                    self.isSpeaking = true
                    self.speechHoldTimer?.invalidate()
                    self.speechHoldTimer = nil
                } else if self.isSpeaking && self.speechHoldTimer == nil {
                    // Voice dropped but we're still in "speaking" state:
                    // Start a hold timer to bridge natural word gaps
                    self.speechHoldTimer = Timer.scheduledTimer(withTimeInterval: self.speechHoldDuration, repeats: false) { [weak self] _ in
                        guard let self else { return }
                        DispatchQueue.main.async {
                            self.isSpeaking = false
                            self.speechHoldTimer = nil
                        }
                    }
                }
            }
        }
        audioMonitor?.start()

        // Start scroll timer at 60fps with smooth velocity easing
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                let targetVelocity: CGFloat = (self.isSpeaking && !self.isPaused) ? self.scrollSpeed : 0
                // Ease toward target velocity for smooth start/stop
                let easeSpeed: CGFloat = 0.49
                self.scrollVelocity += (targetVelocity - self.scrollVelocity) * easeSpeed

                if self.scrollVelocity > 0.1 {
                    self.scrollOffset += self.scrollVelocity / 60.0
                }
            }
        }
    }

    func stopPrompting() {
        isPrompting = false
        isCountingDown = false
        isLoading = false
        isPaused = false

        countdownTimer?.invalidate()
        countdownTimer = nil
        scrollTimer?.invalidate()
        scrollTimer = nil
        speechHoldTimer?.invalidate()
        speechHoldTimer = nil
        audioMonitor?.stop()
        audioMonitor = nil

        panelController?.hidePanel()
        scrollOffset = 0
        scrollVelocity = 0
    }

    func togglePause() {
        isPaused.toggle()
    }

    func adjustScroll(by delta: CGFloat) {
        scrollOffset = max(0, scrollOffset + delta)
    }

    // MARK: - Script Management

    func newScript() {
        scriptText = ""
    }

    func openScript() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                scriptText = text
            }
        }
    }

    func saveScript() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "script.txt"
        if panel.runModal() == .OK, let url = panel.url {
            try? scriptText.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Helpers

extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }
}
