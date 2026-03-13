import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "#1A1D22")!.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top toolbar
                toolbar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Divider()
                    .background(Color.white.opacity(0.06))

                // Script editor
                scriptEditor
                    .padding(16)

                Divider()
                    .background(Color.white.opacity(0.06))

                // Quick controls: font size, scroll speed, sensitivity
                quickControls

                Divider()
                    .background(Color.white.opacity(0.06))

                // Bottom bar
                bottomBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Teleprompter")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.white)
                Text("Smart prompter for your camera")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            // Word count
            let wordCount = appState.scriptText
                .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
                .count
            Text("\(wordCount) words")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Script Editor

    private var scriptEditor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#22252B")!)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )

            TextEditor(text: $appState.scriptText)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .padding(16)
                .focused($editorFocused)

            if appState.scriptText.isEmpty {
                Text("Paste or type your script here...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(20)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Quick Controls

    private var quickControls: some View {
        HStack(spacing: 20) {
            controlSlider(
                icon: "textformat.size",
                title: "Font Size",
                label: "\(Int(appState.fontSize))px",
                value: $appState.fontSize,
                range: 16...80,
                step: 1
            )

            dividerLine

            controlSlider(
                icon: "arrow.up.arrow.down",
                title: "Speed",
                label: speedLabel,
                value: $appState.scrollSpeed,
                range: 10...150,
                step: 5
            )

            dividerLine

            controlSlider(
                icon: "mic.fill",
                title: "Sensitivity",
                label: sensitivityLabel,
                value: Binding(
                    get: { CGFloat(appState.micSensitivity) },
                    set: { appState.micSensitivity = Float($0) }
                ),
                range: 0.05...0.5,
                step: 0.01
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func controlSlider(icon: String, title: String, label: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "#B2884F")!.opacity(0.7))
                .frame(width: 14)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize()

            Slider(value: value, in: range, step: step)
                .frame(minWidth: 80)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 52, alignment: .trailing)
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(width: 1, height: 20)
    }

    private var speedLabel: String {
        if appState.scrollSpeed < 30 { return "Slow" }
        if appState.scrollSpeed < 70 { return "Med" }
        if appState.scrollSpeed < 110 { return "Fast" }
        return "V.Fast"
    }

    private var sensitivityLabel: String {
        if appState.micSensitivity < 0.1 { return "V.High" }
        if appState.micSensitivity < 0.18 { return "High" }
        if appState.micSensitivity < 0.3 { return "Med" }
        return "Low"
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 16) {
            // Audio level indicator
            AudioLevelIndicator(level: appState.audioLevel, threshold: appState.micSensitivity)
                .frame(width: 120, height: 6)

            if appState.isPrompting {
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isPaused ? Color(hex: "#D7B58E")! : Color(hex: "#B2884F")!)
                        .frame(width: 8, height: 8)
                    Text(appState.isPaused ? "Paused" : "Live")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            if appState.isPrompting {
                Button(action: { appState.togglePause() }) {
                    HStack(spacing: 6) {
                        Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 11))
                        Text(appState.isPaused ? "Resume" : "Pause")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: { appState.stopPrompting() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                        Text("Stop")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#8B3A3A")!.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else if appState.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                    Text("Starting...")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Button(action: { appState.startPrompting() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Start Teleprompter")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#B2884F")!, Color(hex: "#96703F")!],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
