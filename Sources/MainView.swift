import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "#141416")!.ignoresSafeArea()

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
                .fill(Color(hex: "#1E1E22")!)
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

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 16) {
            // Audio level indicator
            AudioLevelIndicator(level: appState.audioLevel, threshold: appState.micSensitivity)
                .frame(width: 120, height: 6)

            if appState.isPrompting {
                // Status
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isPaused ? Color.yellow : Color.green)
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
                    .background(Color.red.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
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
                            colors: [Color(hex: "#6C5CE7")!, Color(hex: "#5B4ED4")!],
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
