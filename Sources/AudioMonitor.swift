import AVFoundation
import Accelerate

/// Monitors microphone audio level using AVAudioEngine.
/// Reports a smoothed, normalized level suitable for voice detection.
class AudioMonitor {
    private let engine = AVAudioEngine()
    private var isRunning = false
    var levelCallback: ((Float) -> Void)?

    // Smoothing state
    private var smoothedLevel: Float = 0
    private let smoothUp: Float = 0.4     // Fast attack — respond quickly to speech
    private let smoothDown: Float = 0.39  // Faster release — stop prompter quickly when voice drops

    init(levelCallback: ((Float) -> Void)? = nil) {
        self.levelCallback = levelCallback
    }

    func start() {
        guard !isRunning else { return }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            print("AudioMonitor: Invalid audio format")
            return
        }

        smoothedLevel = 0

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let raw = self.calculateRMS(buffer: buffer)

            // Convert to a more perceptually useful scale:
            // Boost low-level signals so speech is clearly above threshold.
            // Power curve: lower exponent = more boost for quiet signals
            // 0.3 gives strong boost so normal speech is well above threshold
            let boosted = powf(raw, 0.3)

            // Exponential moving average with asymmetric attack/release
            let alpha = boosted > self.smoothedLevel ? self.smoothUp : self.smoothDown
            self.smoothedLevel += alpha * (boosted - self.smoothedLevel)

            self.levelCallback?(self.smoothedLevel)
        }

        do {
            try engine.start()
            isRunning = true
        } catch {
            print("AudioMonitor: Failed to start - \(error.localizedDescription)")
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        smoothedLevel = 0
    }

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelDataValue = channelData.pointee
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }

        // Use Accelerate for fast RMS
        var rms: Float = 0
        vDSP_rmsqv(channelDataValue, 1, &rms, vDSP_Length(frames))
        return rms
    }
}
