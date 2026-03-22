# Whisper — A peripheral collaborative tool for Apple Vision Pro

> You are a developer in 2077. Put on Vision Pro and work in this scenario.

## What This Is

A native visionOS app walkthrough that puts you inside the Whisper experience. You choose a role (Developer or UX Designer), and the scenario plays out around you spatially: windows open, panels float to your sides, whisper cards appear, and a narrator guides you through each beat.

**This is not a demo you watch. You are the character.**

## How To Run

1. Open `WhisperOS.xcodeproj` in Xcode 15.4+
2. Select your Apple Vision Pro (or visionOS Simulator)
3. Build & Run (⌘R)
4. Choose **Developer** or **UX Designer**
5. Act it out — look around, interact with the windows

## What Happens (Developer)

| Step | What opens | Where in space | What you do |
|------|-----------|----------------|-------------|
| 1 | Code editor | Center | Look at the auth code |
| 2 | Terminal + Hive panel | Below + Right (20° off-center) | Glance right to see whisper suggestions |
| 3 | Terminal shows errors | Below | Watch tests fail |
| 4 | Struggle bar appears | Main window | See your struggle score rise |
| 5 | Whisper card floats in | Near terminal | Read the translucent hint |
| 6 | Debug constellation | Volumetric (in space) | Explore the 3D error→cause→fix graph |
| 7 | Tests pass | Terminal | You're contributor #128 |

## What Happens (Designer)

| Step | What opens | Where in space | What you do |
|------|-----------|----------------|-------------|
| 1 | Design Studio canvas | Center | See checkout flow screens |
| 2 | Hive panel + Journey panel | Right + Left | Browse pattern suggestions |
| 3 | Shipping screen glows orange | Canvas | Friction point detected |
| 4 | Whisper card appears | Floating | Address entry drop-off data |
| 5 | Journey insights expand | Left panel | Tap steps to see drop-off reasons |

## Architecture

```
WhisperOS/
├── WhisperApp.swift          # App entry: declares all windows + spaces
├── ScenarioEngine.swift       # The brain: drives the entire role-play timeline
├── MainView.swift             # Role select → narrator/controller during play
├── CodeEditorWindow.swift     # IDE with syntax highlighting + whisper glow bars
└── SpatialWindows.swift       # Terminal, Whisper Panel, Whisper, Debug, Design, Journey
```

**ScenarioEngine** is the key file. It's an `@Observable` class that runs an async timeline — each step opens windows, writes terminal output, updates the whisper panel, triggers whispers, and controls the struggle meter. The main app listens to `windowRequests` to open/close spatial windows.

## Spatial Zones

- **Zone A (Center)**: Code editor or Design canvas — where you work
- **Zone B (Peripheral)**: Whisper Intelligence panel — 20° to your right, updates passively
- **Zone C (Deep context)**: Architecture maps, debug constellations — summoned on demand
- **Whispers**: Float near your current focus, translucent, never interrupt

## Requirements

- Xcode 15.4+
- visionOS 2.0 SDK
- Apple Vision Pro or visionOS Simulator
- macOS Sonoma 14.5+

## The Rule

> The interface behaves like a quiet expert standing beside you, not a search engine shouting answers.
