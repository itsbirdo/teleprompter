# Teleprompter

A native macOS teleprompter app that scrolls your script automatically as you speak. The floating prompter window sits right near your camera so you maintain eye contact with your audience — and it's invisible to screen sharing.

## Features

### Voice-Activated Scrolling
The app monitors your microphone and detects when you're speaking. The script scrolls forward while you talk and pauses when you stop. The detection uses smoothed audio levels with a hold timer to bridge natural pauses between words, so scrolling feels fluid rather than jittery.

### Camera-Positioned Display
The teleprompter appears as a floating panel anchored to the top-center of your screen, right where your camera is. On MacBooks with a notch, it sits just below the camera — letting you read while looking directly into the lens.

### Screen Share Invisible
The teleprompter window uses `NSWindow.SharingType.none`, making it completely invisible to screen capture, screen recording, and screen sharing. Your audience sees your slides or app, not your script.

### Customizable Appearance
- **Font size** — 16px to 80px, adjustable in Settings or with `+`/`-` keys during prompting
- **Text color** — full color picker
- **Window opacity** — 50% to 100%
- **Window size** — adjustable width (300–800px) and height (200–600px)
- **Mirror text** — horizontal flip for physical teleprompter setups (e.g. beam splitter rigs)

### Scrolling Controls
- **Scroll speed** — adjustable from slow (10) to very fast (150)
- **Microphone sensitivity** — tune the voice detection threshold to your environment
- **Manual override** — use arrow keys to nudge the scroll position up or down at any time
- **Pause/resume** — press Space to pause; the script holds position until you resume

### Countdown Timer
A configurable countdown (0–10 seconds) gives you time to get ready before scrolling begins. Set to 0 to start immediately.

### Script Editor
The main window is a full script editor. Type or paste your text, and it's auto-saved between sessions. You can also open and save `.txt` files via the File menu.

### Audio Level Indicator
A real-time audio level bar in the bottom toolbar shows your microphone input and the current detection threshold, so you can see exactly when your voice is being picked up.

## Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Start Teleprompter | `Cmd + Return` |
| Stop Teleprompter | `Escape` |
| Pause / Resume | `Space` |
| Scroll Up | `Up Arrow` |
| Scroll Down | `Down Arrow` |
| Increase Font Size | `+` |
| Decrease Font Size | `-` |
| New Script | `Cmd + N` |
| Open Script | `Cmd + O` |
| Save Script | `Cmd + S` |

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac
- Microphone access (prompted on first launch)

## Building

The project compiles from source with no dependencies beyond the macOS SDK.

```bash
# Build the app
./build.sh

# Run it
open build/Teleprompter.app
```

The build script:
1. Generates the app icon from `generate_icon.swift`
2. Compiles all Swift sources with `swiftc`
3. Assembles the `.app` bundle with Info.plist and entitlements
4. Code-signs for local use

No Xcode project is required — just the Command Line Tools (`xcode-select --install`).

## Project Structure

```
teleprompter/
├── Sources/
│   ├── TeleprompterApp.swift          # App entry point and menu commands
│   ├── AppState.swift                 # Central state management and scroll logic
│   ├── MainView.swift                 # Main window: script editor and controls
│   ├── TeleprompterView.swift         # Floating prompter content view
│   ├── SettingsView.swift             # Settings sheet
│   ├── FloatingPanel.swift            # NSPanel subclass (always-on-top, share-invisible)
│   ├── TeleprompterPanelController.swift  # Creates and manages the floating panel
│   ├── AudioMonitor.swift             # AVAudioEngine mic level monitoring
│   ├── AudioLevelIndicator.swift      # Audio level bar view
│   ├── CountdownView.swift            # Countdown overlay
│   └── Extensions.swift              # Color hex utilities
├── Resources/
│   ├── Info.plist                     # App metadata and permissions
│   └── Teleprompter.entitlements      # Microphone entitlement
├── generate_icon.swift                # Generates app icon via Core Graphics
├── build.sh                           # Build script
└── README.md
```

## How It Works

### Voice Detection
Audio monitoring uses `AVAudioEngine` with a tap on the input node. Raw RMS levels are boosted through a power curve (`raw^0.4`) to amplify quiet speech, then smoothed with an asymmetric exponential moving average — fast attack to respond instantly when you start speaking, slow release to avoid dropping between syllables. A 0.6-second hold timer keeps scrolling active through natural word gaps.

### Scroll Mechanics
A 60fps timer drives the scroll offset. Instead of snapping between moving and stopped, the scroll velocity eases in and out smoothly. The target velocity is either the configured scroll speed (when speaking) or zero (when silent), and the actual velocity interpolates toward the target each frame.

### Floating Window
The teleprompter uses `NSPanel` with `.nonactivatingPanel` style so it doesn't steal keyboard focus from your presentation app. It floats above all windows (`NSWindow.Level.floating`), shows on all Spaces, and stays visible even when the app is deactivated. Setting `sharingType = .none` makes it invisible to any screen capture API.

## Privacy

All processing happens locally. Your scripts are stored in `UserDefaults` on your machine. Audio from the microphone is analyzed in real-time for volume levels only — no audio is recorded, stored, or transmitted. No network requests are made.

## License

MIT
