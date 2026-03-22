// WhisperApp.swift — Whisper
// Each WindowGroup is a separate spatial panel the user positions freely.

import SwiftUI

@main
struct WhisperApp: App {
    
    @State private var engine = ScenarioEngine()
    
    var body: some Scene {
        
        // Narrator (main window — always open)
        WindowGroup(id: "main") {
            MainView()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 480, height: 560)
        
        // CodeForge IDE + Terminal (center)
        WindowGroup(id: "ide") {
            CodeEditorWindow()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 900, height: 740)
        
        // Whisper Interface (suggestions panel)
        WindowGroup(id: "whisper-panel") {
            WhisperPanelWindow()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 380, height: 560)
        
        // Debug Constellation
        WindowGroup(id: "debug") {
            DebugConstellationWindow()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 900, height: 600)
        
        // Architecture Explorer
        WindowGroup(id: "architecture") {
            ArchitectureWindow()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 800, height: 500)
        
        // Design Studio (designer scenario)
        WindowGroup(id: "design-studio") {
            DesignStudioWindow()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 860, height: 520)
        
        // Journey Panel (designer scenario)
        WindowGroup(id: "journey") {
            JourneyPanelWindow()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 320, height: 520)
        
        // Digital Twin Conversation
        WindowGroup(id: "digital-twin") {
            DigitalTwinWindow()
                .environment(engine)
        }
        .windowStyle(.plain)
        .defaultSize(width: 440, height: 560)
    }
}
