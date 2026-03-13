import SwiftUI

struct TeleprompterView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(appState.windowOpacity))

            // Script content
            GeometryReader { geo in
                let viewHeight = geo.size.height

                ZStack {
                    // Scrolling text
                    scriptContent
                        .offset(y: viewHeight * 0.3 - appState.scrollOffset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    // Gradient fades
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(appState.windowOpacity),
                                Color.black.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 50)

                        Spacer()

                        LinearGradient(
                            colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(appState.windowOpacity)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                    }

                    // Reading position indicator
                    VStack {
                        Rectangle()
                            .fill(Color(hex: "#6C5CE7")!.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                            .offset(y: viewHeight * 0.3)
                        Spacer()
                    }

                    // Countdown overlay
                    if appState.isCountingDown {
                        CountdownView(value: appState.countdownValue)
                    }

                    // Paused indicator
                    if appState.isPaused && !appState.isCountingDown {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 14))
                                Text("PAUSED")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                            .padding(.bottom, 16)
                        }
                    }

                    // Audio level dot
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(appState.isSpeaking ? Color.green : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.15), value: appState.isSpeaking)
                                .padding(12)
                        }
                    }
                }
                .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var scriptContent: some View {
        Text(appState.scriptText)
            .font(.system(size: appState.fontSize, weight: .medium))
            .foregroundColor(appState.textColor)
            .lineSpacing(appState.fontSize * 0.5)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 400) // Extra space at bottom so text can scroll past
            .fixedSize(horizontal: false, vertical: true)
            .scaleEffect(x: appState.mirrorText ? -1 : 1, y: 1)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ContentHeightKey.self,
                        value: geo.size.height
                    )
                }
            )
            .onPreferenceChange(ContentHeightKey.self) { height in
                appState.totalContentHeight = height
            }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
