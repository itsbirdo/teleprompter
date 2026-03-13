import SwiftUI

struct AudioLevelIndicator: View {
    let level: Float
    let threshold: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.08))

                // Level bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: max(0, geo.size.width * CGFloat(normalizedLevel)))
                    .animation(.linear(duration: 0.05), value: level)

                // Threshold marker
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1)
                    .offset(x: geo.size.width * CGFloat(min(threshold, 1.0)))
            }
        }
    }

    private var normalizedLevel: Float {
        min(level, 1.0)
    }

    private var barColor: Color {
        if level > threshold {
            return Color.green
        }
        return Color.white.opacity(0.3)
    }
}
