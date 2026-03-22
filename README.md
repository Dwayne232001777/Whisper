# Whisper: Spatial peripheral collaborative tool for Apple Vision Pro
 
> You are a developer in 2077. Put on Vision Pro and work in this scenario.
 
## What This Is
 
A native visionOS app that puts you inside the Whisper experience. You choose a role (Developer or UX Designer), and the scenario plays out around you spatially: windows open, panels float to your sides, whisper suggestions appear, and a narrator guides you through each step.
 
**This is not a demo you watch. You are the character.**
 
## How To Run
 
1. Open `Whisper.xcodeproj` in Xcode 15.4+
2. Select your Apple Vision Pro (or visionOS Simulator)
3. Build & Run (⌘R)
4. Choose **Developer** or **UX Designer**
5. Act it out — look around, interact with the windows
 
## What Happens (Developer)
 
Two scenarios available: **JWT Auth Debug** and **Race Condition + Digital Twin**.
 
### Scenario 1: JWT Auth Debug
 
| Step | What opens | Where in space | What you do |
|------|-----------|----------------|-------------|
| 1 | CodeForge IDE | Center | Browse auth code files |
| 2 | Terminal inside IDE | Below editor | Run builds and tests |
| 3 | Tests fail (401 error) | Terminal | Watch struggle score rise |
| 4 | Whisper panel lights up | Right | Suggestion appears after repeated failures |
| 5 | Expand suggestion | Whisper panel | See fix details, solver names, success rates |
| 6 | Debug Constellation | Spatial | Explore error→cause→fix graph with 3 branches |
| 7 | Apply fix + tests pass | IDE + Terminal | Code animates in, you're contributor #128 |
 
### Scenario 2: Race Condition + Digital Twin
 
| Step | What opens | Where in space | What you do |
|------|-----------|----------------|-------------|
| 1 | CodeForge IDE | Center | Node.js request handler |
| 2 | Run concurrent requests | Terminal | See stale data from race condition |
| 3 | Whisper detects pattern | Right | Suggestion after repeated failures |
| 4 | You're skeptical | Narrator | Challenge the suggestion as too generic |
| 5 | Contact solver (busy) | Whisper panel | Digital Twin activates |
| 6 | Twin conversation | Spatial panel | Ask questions, get contextual answers |
| 7 | Choose fix (3 options) | Twin panel | Mutex, queue, or stateless redesign |
| 8 | Verify fix | Terminal | Both responses consistent |
 
## What Happens (Designer)
 
Two use cases available: **Crowded Payment Screen** and **Dashboard Filters + Digital Twin**.
 
### Use Case 1: Crowded Payment Screen
 
| Step | What opens | Where in space | What you do |
|------|-----------|----------------|-------------|
| 1 | Design Studio canvas | Center | See checkout flow (Cart → Shipping → Payment → Confirm) |
| 2 | Place form elements | Canvas | Payment screen gets crowded |
| 3 | Whisper panel lights up | Right | Crowded layout pattern detected |
| 4 | Expand suggestion | Whisper panel | See fix: collapse optional fields behind "More details" |
| 5 | Pattern overlay | Canvas | Transparent guide shows what to keep vs collapse |
| 6 | Apply fix | Canvas | Clean layout: card + pay button visible, rest collapsed |
 
### Use Case 2: Dashboard Filters + Digital Twin
 
| Step | What opens | Where in space | What you do |
|------|-----------|----------------|-------------|
| 1 | Design Studio canvas | Center | Dashboard with KPI cards, charts, data table |
| 2 | Build filter area | Canvas | 9 filters crammed together, no hierarchy |
| 3 | Whisper detects overload | Right | Filter overload pattern flagged |
| 4 | You disagree | Narrator | "My users are power users who need speed" |
| 5 | Expand for reasoning | Whisper panel | Contact Maya's Digital Twin |
| 6 | Twin conversation | Spatial panel | Ask about expert users, pinning, what changed |
| 7 | Choose layout (3 options) | Twin panel | Two-level filters, progressive disclosure, or keep all |
| 8 | Dashboard updates | Canvas | Interactive filters with unique behaviour per option |
 
## Architecture
 
```
Whisper/
├── WhisperApp.swift           # App entry — declares all windows
├── ScenarioEngine.swift       # The brain — drives the entire role-play timeline
├── MainView.swift             # Role select → narrator/controller during play
├── CodeEditorWindow.swift     # IDE with syntax highlighting + whisper glow bars
└── SpatialWindows.swift       # Whisper Panel, Debug Constellation, Design Studio,
                               # Architecture Explorer, Journey Panel, Digital Twin
```
 
**ScenarioEngine** is the key file. It's an `@Observable` class that manages the full state machine — each choice opens windows, writes terminal output, updates the Whisper panel, triggers suggestions, manages Digital Twin conversations, and controls the struggle meter. The main app listens to `pendingOpens` / `pendingCloses` to open/close spatial windows.
 
## Spatial Zones
 
- **Zone A (Center)**: CodeForge IDE or Design Studio canvas — where you work
- **Zone B (Peripheral)**: Whisper panel — 20° to your right, updates passively
- **Zone C (Deep context)**: Debug Constellation, Architecture Explorer — summoned on demand
- **Digital Twin**: Appears as a separate spatial panel with holographic conversation interface
 
## Requirements
 
- Xcode 15.4+
- visionOS 2.0 SDK
- Apple Vision Pro or visionOS Simulator
- macOS Sonoma 14.5+
 
## The Rule
 
> The interface behaves like a quiet expert standing beside you, not a search engine shouting answers.
