import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider().background(Color.white.opacity(0.06))

            ScrollView {
                VStack(spacing: 24) {
                    // Text Appearance
                    settingsSection("Text Appearance") {
                        settingsRow("Font Size", subtitle: "\(Int(appState.fontSize))px") {
                            Slider(value: $appState.fontSize, in: 16...80, step: 1)
                                .frame(width: 180)
                        }

                        settingsRow("Text Color") {
                            ColorPicker("", selection: textColorBinding)
                                .labelsHidden()
                        }

                        settingsRow("Mirror Text", subtitle: "Flip horizontally") {
                            Toggle("", isOn: $appState.mirrorText)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                    }

                    // Scrolling
                    settingsSection("Scrolling") {
                        settingsRow("Scroll Speed", subtitle: speedLabel) {
                            Slider(value: $appState.scrollSpeed, in: 10...150, step: 5)
                                .frame(width: 180)
                        }
                    }

                    // Microphone
                    settingsSection("Microphone") {
                        settingsRow("Sensitivity", subtitle: sensitivityLabel) {
                            Slider(value: Binding(
                                get: { appState.micSensitivity },
                                set: { appState.micSensitivity = $0 }
                            ), in: 0.05...0.5, step: 0.01)
                                .frame(width: 180)
                        }
                    }

                    // Window
                    settingsSection("Teleprompter Window") {
                        settingsRow("Opacity", subtitle: "\(Int(appState.windowOpacity * 100))%") {
                            Slider(value: $appState.windowOpacity, in: 0.5...1.0, step: 0.05)
                                .frame(width: 180)
                        }

                        settingsRow("Width", subtitle: "\(Int(appState.teleprompterWidth))px") {
                            Slider(value: $appState.teleprompterWidth, in: 300...800, step: 10)
                                .frame(width: 180)
                        }

                        settingsRow("Height", subtitle: "\(Int(appState.teleprompterHeight))px") {
                            Slider(value: $appState.teleprompterHeight, in: 200...600, step: 10)
                                .frame(width: 180)
                        }
                    }

                    // Countdown
                    settingsSection("Countdown") {
                        settingsRow("Duration", subtitle: appState.countdownDuration == 0 ? "Off" : "\(appState.countdownDuration)s") {
                            Stepper("", value: $appState.countdownDuration, in: 0...10)
                                .labelsHidden()
                        }
                    }

                    // Keyboard Shortcuts
                    settingsSection("Keyboard Shortcuts") {
                        shortcutRow("Start / Stop", keys: "\u{2318} Return")
                        shortcutRow("Pause / Resume", keys: "Space")
                        shortcutRow("Stop", keys: "Esc")
                        shortcutRow("Scroll Up", keys: "\u{2191}")
                        shortcutRow("Scroll Down", keys: "\u{2193}")
                        shortcutRow("Increase Font", keys: "+")
                        shortcutRow("Decrease Font", keys: "-")
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 500, height: 580)
        .background(Color(hex: "#1A1A1E")!)
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private var speedLabel: String {
        if appState.scrollSpeed < 30 { return "Slow" }
        if appState.scrollSpeed < 70 { return "Medium" }
        if appState.scrollSpeed < 110 { return "Fast" }
        return "Very Fast"
    }

    private var sensitivityLabel: String {
        if appState.micSensitivity < 0.1 { return "Very Sensitive" }
        if appState.micSensitivity < 0.18 { return "Sensitive" }
        if appState.micSensitivity < 0.3 { return "Normal" }
        return "Low Sensitivity"
    }

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { appState.textColor },
            set: { newColor in
                if let hex = newColor.toHex() {
                    appState.textColorHex = hex
                }
            }
        )
    }

    // MARK: - Section Builders

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.white.opacity(0.35))
                .tracking(0.8)

            VStack(spacing: 1) {
                content()
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func settingsRow<Trailing: View>(_ label: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func shortcutRow(_ action: String, keys: String) -> some View {
        HStack {
            Text(action)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
