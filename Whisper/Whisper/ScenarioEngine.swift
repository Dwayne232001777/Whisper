// ScenarioEngine.swift - Whisper
// Interactive choice-driven. Narrator guides you step by step.
// YOU perform every action. Code updates live when you apply fixes.

import SwiftUI
import Observation

@Observable @MainActor
final class ScenarioEngine {
    
    enum Role: String, CaseIterable {
        case developer = "Developer"
        case designer = "UX Designer"
    }
    
    struct NarratorMessage: Identifiable {
        let id = UUID()
        let text: String
        let type: MsgType
        enum MsgType { case narrator, action, hint, whisper, success, error }
    }
    
    struct Choice: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        let action: String
    }
    
    // Terminal command buttons (shown inside CodeForge terminal)
    struct TermCmd: Identifiable {
        let id = UUID()
        let label: String
        let action: String
    }
    
    // Twin conversation choices (shown inside Twin window, NOT narrator)
    struct TwinChoice: Identifiable {
        let id = UUID()
        let label: String
        let action: String
    }
    
    // Solver info for expanded whisper
    struct Solver: Identifiable {
        let id = UUID()
        let name: String
        let role: String
        let successRate: Int
        let imageName: String?   // asset image name, nil = use initial
        let isBusy: Bool         // if true, contact goes to digital twin
    }
    
    // Digital twin conversation
    struct TwinMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    // ═══ State ═══
    var role: Role? = nil
    var scenario = 0   // 1 = JWT auth, 2 = race condition, etc.
    var started = false
    var messages: [NarratorMessage] = []
    var choices: [Choice] = []
    var choicesEnabled = true
    
    // IDE
    var ideOpen = false
    var currentFile = "auth"
    var terminalLines: [TermLine] = []
    var terminalCommands: [TermCmd] = []   // clickable buttons in terminal
    var codeFiles: [String: CodeFile] = [:]
    
    // Whisper panel (left) - suggestions appear/disappear dynamically
    var whisperPanelOpen = false
    var whisperContext = ""
    var whisperSuggestions: [WhisperSugg] = []
    var whisperReasoning: String? = nil  // "Why this?" breakdown text
    var whisperActions: [TermCmd] = []   // action buttons shown inside Whisper panel
    
    // Expanded solution detail (inside whisper panel)
    var expandedSolution: ExpandedSolution? = nil
    
    // Design overlay
    var showDesignOverlay = false
    
    // Digital twin
    var twinActive = false
    var twinName = ""
    var twinRole = ""
    var twinImage = "AlexChen"  // asset name for banner
    var twinMessages: [TwinMessage] = []
    var twinBusy = false
    var twinChoices: [TwinChoice] = []   // buttons inside twin window
    
    // Debug constellation
    var debugOpen = false
    var debugRecommendation: String? = nil
    
    // Architecture explorer
    // Architecture explorer
    var archOpen = false
    
    // Struggle
    var struggleScore: Double = 0
    var testFailCount = 0
    
    // Designer
    var designOpen = false
    var designScenario = 0   // 1 = checkout payment, 2 = dashboard filters
    var designFixed = false  // whether the fix has been applied
    var designAppliedOption = ""  // "twolevel", "progressive", "keepall"
    var journeyOpen = false
    var frictionHighlight = false
    
    // Window tracking
    var pendingOpens: Set<String> = []
    var pendingCloses: Set<String> = []
    var openWindows: Set<String> = []
    
    func requestOpen(_ id: String) {
        guard !openWindows.contains(id) else { return }
        openWindows.insert(id)
        pendingOpens.insert(id)
    }
    func requestClose(_ id: String) {
        openWindows.remove(id)
        pendingCloses.insert(id)
    }
    func clearPending() {
        pendingOpens.removeAll()
        pendingCloses.removeAll()
    }
    
    func selectRole(_ r: Role) {
        role = r; started = true
        switch r {
        case .developer: showDevScenarioPicker()
        case .designer: beginDesignerScenario()
        }
    }
    
    func selectScenario(_ num: Int) {
        scenario = num
        clearChoices()
        switch num {
        case 1: beginDevScenario()
        case 2: beginDevScenario2()
        default: break
        }
    }
    
    func reset() {
        role = nil; scenario = 0; started = false; messages = []; choices = []
        ideOpen = false; currentFile = "auth"; terminalLines = []; terminalCommands = []; codeFiles = [:]
        whisperPanelOpen = false; whisperSuggestions = []; expandedSolution = nil; whisperReasoning = nil; whisperActions = []; showDesignOverlay = false
        debugOpen = false; debugRecommendation = nil; archOpen = false; struggleScore = 0; testFailCount = 0
        designOpen = false; designScenario = 0; designFixed = false; designAppliedOption = ""; journeyOpen = false; frictionHighlight = false
        twinActive = false; twinMessages = []; twinBusy = false; twinChoices = []
        pendingCloses = openWindows; pendingOpens = []; openWindows = []
    }
    
    // ═══ Helpers ═══
    
    private func say(_ text: String, type: NarratorMessage.MsgType = .narrator) {
        withAnimation(.easeInOut(duration: 0.2)) {
            messages.append(NarratorMessage(text: text, type: type))
        }
    }
    private func setChoices(_ opts: [(String, String, String)]) {
        withAnimation(.easeInOut(duration: 0.2)) {
            choices = opts.map { Choice(label: $0.0, icon: $0.1, action: $0.2) }
            choicesEnabled = true
        }
    }
    private func clearChoices() { withAnimation { choices = [] } }
    
    private func termWrite(_ text: String, type: TermLine.LineType = .normal) {
        withAnimation(.easeInOut(duration: 0.15)) {
            terminalLines.append(TermLine(text, type: type))
        }
    }
    
    // Clear whisper suggestions when no longer relevant
    private func clearWhisperSuggestions() {
        withAnimation { whisperSuggestions = []; expandedSolution = nil; whisperActions = []; showDesignOverlay = false }
    }
    
    // Update code with typing animation - reveals line by line
    var isTyping = false
    
    func updateCode(file: String, newCode: String) {
        guard let f = codeFiles[file] else { return }
        currentFile = file
        isTyping = true
        
        let lines = newCode.components(separatedBy: "\n")
        // Start empty, build up line by line
        codeFiles[file] = CodeFile(label: f.label, path: f.path, code: "")
        
        Task {
            for i in 0..<lines.count {
                let partial = lines[0...i].joined(separator: "\n")
                try? await Task.sleep(for: .milliseconds(35))
                codeFiles[file] = CodeFile(label: f.label, path: f.path, code: partial)
            }
            isTyping = false
        }
    }
    
    // ═══ Called by Whisper panel Expand button ═══
    func whisperExpand() {
        if role == .developer && scenario == 2 { whisperExpandS2(); return }
        if role == .developer {
            expandedSolution = ExpandedSolution(
                title: "Refresh Token Rotation Middleware",
                description: "The refresh token must be invalidated and re-issued on every refresh call. Without rotation, the old token remains valid and causes a 401 loop when the access token expires.",
                solvers: [
                    Solver(name: "Anika Patel", role: "Backend Lead @ Meridian", successRate: 94, imageName: nil, isBusy: false),
                    Solver(name: "Jonas Eriksson", role: "Auth Engineer @ Novacloud", successRate: 91, imageName: nil, isBusy: false),
                    Solver(name: "Mei Chen", role: "Security Architect @ Lattice", successRate: 88, imageName: nil, isBusy: false),
                ],
                fixSnippet: authFixedCode
            )
            say("Expanded! The Whisper interface now shows the full solution description, who solved it, and their success rates. You can contact any solver. Click 'Apply' in the Whisper interface to apply the fix to your code.", type: .whisper)
            clearChoices()
            setChoices([
                ("Open Debug Constellation to see all causes", "point.3.connected.trianglepath.dotted", "dev-expand-debug"),
            ])
        } else {
            // Designer use cases
            if whisperContext.contains("Payment") {
                // Use Case 1: Crowded payment screen
                expandedSolution = ExpandedSolution(
                    title: "Cleaner Payment Layout",
                    description: "Users scan payment screens quickly. Too many visible choices slow them down. Optional fields compete with the main action.\n\nFix: Show only card info and pay button first. Move coupon, billing, delivery note behind 'More details' expandable section.",
                    solvers: [
                        Solver(name: "Priya Sharma", role: "UX Lead @ CartFlow", successRate: 92, imageName: nil, isBusy: false),
                        Solver(name: "Leo Tanaka", role: "Design Director @ ShopOS", successRate: 88, imageName: nil, isBusy: false),
                    ],
                    fixSnippet: nil
                )
                say("Expanded! See the fix logic in the Whisper interface. Use the buttons there to preview the overlay or apply the fix.", type: .whisper)
                whisperActions = [
                    TermCmd(label: "Show Pattern Overlay", action: "d1-show-overlay"),
                ]
                clearChoices()
            } else {
                // Use Case 2: Dashboard filters
                expandedSolution = ExpandedSolution(
                    title: "Two-Level Filter Model",
                    description: "Problems with the current layout:\n\n• 9 controls sit at the same visual weight, so the eye has no starting point\n• Export and Share are actions, not filters, but they look identical to everything else\n• Advanced filters (Segment, Compare, YoY) compete with the ones users reach for first\n• Users in testing spent 3x longer locating their first action\n\nWhat the fix solves:\n\n• Creates a clear visual hierarchy: 3 primary filters always visible\n• Moves 6 advanced filters behind an 'All Filters' drawer, still one tap away\n• Separates Export/Share as actions so users know what filters vs what does something\n• Adds a pin option so power users can pull any filter back into the top row\n• Reduces average time-to-first-action from 8s to under 3s",
                    solvers: [
                        Solver(name: "Maya", role: "Senior UX Designer @ DataViz Corp", successRate: 91, imageName: "Maya", isBusy: true),
                        Solver(name: "Raj Kapoor", role: "Product Designer @ Analytics Hub", successRate: 85, imageName: nil, isBusy: false),
                    ],
                    fixSnippet: nil
                )
                say("Expanded! Full recommendation with solver names. Maya is busy. tap 'Twin' to talk to her Digital Twin about why this works for expert users.", type: .whisper)
                clearChoices()
            }
        }
    }
    
    // ═══ Called by Whisper panel Apply button ═══
    func whisperApply() {
        if role == .developer && scenario == 2 { whisperApplyS2(); return }
        if role == .developer {
            say("Applying fix to AuthService.swift. watch the code update in CodeForge.", type: .action)
            updateCode(file: "auth", newCode: authFixedCode)
            clearWhisperSuggestions()
            if debugOpen { debugOpen = false; requestClose("debug") }
            
            say("Done! The TODO is resolved. Token rotation middleware is now in your code. The refreshAccessToken function now invalidates the old token and issues a new pair. look at the green ✅ lines.", type: .success)
            say("Next: run the tests again to verify the fix works.", type: .hint)
            clearChoices()
            setChoices([
                ("Run tests", "play", "dev-run-tests"),
            ])
        } else {
            // Designer use cases
            if whisperContext.contains("Payment") {
                say("Layout restructured: card info and pay button visible first, coupon and billing behind 'More details'. Screen is calmer.", type: .success)
                designFixed = true
                clearWhisperSuggestions()
                withAnimation { frictionHighlight = false }
                say("Whisper confirms: this structure matches solutions that reduced hesitation in similar checkout flows.", type: .whisper)
                clearChoices()
                setChoices([("Finish Use Case 1", "checkmark.circle", "d1-complete")])
            } else if whisperContext.contains("Dashboard") {
                say("Applied: most-used filters visible, advanced filters in drawer, export separated, pin option for power users.", type: .success)
                designFixed = true; designAppliedOption = "twolevel"
                clearWhisperSuggestions(); whisperReasoning = nil
                say("Whisper confirms: this revised structure matches successful solutions in similar analytics dashboards.", type: .whisper)
                clearChoices()
                setChoices([("Finish Use Case 2", "checkmark.circle", "d2-complete")])
            }
        }
    }
    
    func pick(_ action: String) {
        choicesEnabled = false; clearChoices()
        if action == "scenario-1" || action == "scenario-2" { selectScenario(action == "scenario-1" ? 1 : 2); return }
        if role == .developer {
            if scenario == 2 { handleDev2Choice(action) }
            else { handleDevChoice(action) }
        }
        else { handleDesignerChoice(action) }
    }
    
    // Called by terminal command buttons inside CodeForge
    func runTerminalCommand(_ action: String) {
        terminalCommands = []  // clear after running
        pick(action)
    }
    
    // Called by whisper panel action buttons
    func runWhisperAction(_ action: String) {
        whisperActions = []
        pick(action)
    }
    
    // Called by twin conversation buttons. Does NOT clear choices or go through pick().
    func runTwinChoice(_ action: String) {
        // Route directly to the handler without clearing twin choices
        if role == .developer {
            if scenario == 2 { handleDev2Choice(action) }
            else { handleDevChoice(action) }
        } else {
            handleDesignerChoice(action)
        }
    }
    
    // ═══ Dev scenario picker ═══
    
    private func showDevScenarioPicker() {
        say("Welcome to Whisper. Choose your developer scenario.")
        say("Scenario 1: JWT refresh token authentication. debugging token expiry.", type: .action)
        say("Scenario 2: Async race condition. escalation to a digital twin when you challenge Whisper's suggestion.", type: .action)
        setChoices([
            ("Scenario 1: JWT Auth Debug", "lock.shield", "scenario-1"),
            ("Scenario 2: Race Condition + Digital Twin", "person.wave.2", "scenario-2"),
        ])
    }
    
    // ════════════════════════════════════════
    // MARK: - DEVELOPER SCENARIO
    // ════════════════════════════════════════
    
    private func beginDevScenario() {
        codeFiles = devCodeFiles
        say("Welcome to Whisper. It's 2077. You're wearing Apple Vision Pro.")
        say("Your task today: implement JWT refresh token authentication for a backend API.", type: .action)
        say("First, let's set up your workspace. Open CodeForge to start coding.", type: .hint)
        setChoices([
            ("Open CodeForge IDE", "laptopcomputer", "dev-open-ide"),
        ])
    }
    
    private func handleDevChoice(_ action: String) {
        switch action {
            
        // ── Workspace setup ──
        case "dev-open-ide":
            say("CodeForge is open. AuthService.swift is loaded with the refresh token skeleton.", type: .action)
            say("Next: open your Terminal so you can build and test later.", type: .hint)
            ideOpen = true; currentFile = "auth"; requestOpen("ide")
            setChoices([
                ("Open Terminal", "terminal", "dev-open-term"),
            ])
            
        case "dev-open-term":
            say("Terminal is ready inside CodeForge.", type: .action)
            terminalLines = [TermLine("$ ", type: .command)]
            say("Your workspace is set up. Run a build from the terminal, or start coding.", type: .hint)
            terminalCommands = [
                TermCmd(label: "swift build", action: "dev-run-build"),
            ]
            setChoices([
                ("Start writing auth code", "pencil.line", "dev-start-coding"),
            ])
            
        case "dev-run-build":
            say("Building project.", type: .action)
            termWrite("$ swift build", type: .command)
            termWrite("Compiling AuthService.swift...", type: .normal)
            termWrite("Compiling TokenMiddleware.swift...", type: .normal)
            termWrite("Build complete. 0 errors.", type: .success)
            say("Build clean. Now start writing the auth code.", type: .hint)
            setChoices([
                ("Start writing auth code", "pencil.line", "dev-start-coding"),
            ])
            
        // ── Coding phase ──
        case "dev-start-coding":
            say("You begin implementing refreshAccessToken(). Whisper detects: authentication module, JWT, token refresh logic, Swift + Vapor.", type: .action)
            currentFile = "auth"
            
            // Whisper panel lights up with relevant suggestions
            say("The Whisper interface lights up. It detected your coding context and found related patterns from 142 projects.", type: .whisper)
            whisperPanelOpen = true
            whisperContext = "Authentication · JWT · Token Refresh"
            whisperSuggestions = [
                WhisperSugg(title: "JWT Refresh Middleware", detail: "Token rotation pattern used in 142 projects. Most common approach.", icon: "chevron.left.forwardslash.chevron.right", color: .cyan, isNew: false),
                WhisperSugg(title: "Sliding Session Tokens", detail: "Auto-extend session with activity window. Used by 67 projects.", icon: "arrow.triangle.2.circlepath", color: .purple, isNew: true),
            ]
            requestOpen("whisper-panel")
            
            say("Check the Whisper interface. it has suggestions related to what you're building. You can expand any suggestion for details, or ignore it and keep coding.", type: .hint)
            setChoices([
                ("Keep coding (ignore suggestions)", "keyboard", "dev-keep-coding"),
                ("Run tests to check progress", "play", "dev-run-tests"),
            ])
            
        case "dev-keep-coding":
            say("You continue implementing the refresh logic. Look at the code. notice the TODO on line 43: 'Rotate refresh token'. This will matter later.", type: .action)
            say("Run your tests from the terminal to check the implementation.", type: .hint)
            terminalCommands = [
                TermCmd(label: "swift test", action: "dev-run-tests"),
            ]
            setChoices([
                ("Switch to AuthTests.swift to review", "checkmark.circle", "dev-switch-tests"),
            ])
            
        case "dev-switch-token":
            say("Go to CodeForge and click TokenMiddleware.swift in the file tree. It handles bearer token verification on protected routes.", type: .action)
            currentFile = "token"
            setChoices([
                ("Switch back to AuthService.swift", "doc.text", "dev-switch-auth"),
                ("Run tests", "play", "dev-run-tests"),
            ])
            
        case "dev-switch-tests":
            say("Go to CodeForge and click AuthTests.swift. The test logs in, waits for token expiry, then attempts a refresh.", type: .action)
            currentFile = "authtest"
            setChoices([
                ("Run tests", "play", "dev-run-tests"),
                ("Switch back to AuthService.swift", "doc.text", "dev-switch-auth"),
            ])
            
        case "dev-switch-auth":
            currentFile = "auth"
            say("Back to AuthService.swift in CodeForge.", type: .action)
            setChoices([
                ("Run tests", "play", "dev-run-tests"),
            ])
            
        // ── Testing / struggle ──
        case "dev-run-tests":
            testFailCount += 1
            termWrite(""); termWrite("$ swift test", type: .command)
            termWrite("Running AuthTests.testTokenRefresh...", type: .normal)
            
            if testFailCount <= 3 {
                termWrite("✗ FAILED: 401 token expired", type: .error)
                termWrite("  at AuthService.swift:47", type: .normal)
                withAnimation { struggleScore = min(Double(testFailCount) * 0.25, 0.85) }
                
                if testFailCount == 1 {
                    say("Test failed. 401 token expired at line 47. The refresh token isn't being rotated.", type: .error)
                    say("You can retry, inspect the error more closely, or switch to TokenMiddleware.swift to check if the issue is there.", type: .hint)
                    setChoices([
                        ("Retry the test", "arrow.counterclockwise", "dev-run-tests"),
                        ("Inspect error at line 47", "magnifyingglass", "dev-inspect-error"),
                        ("Check TokenMiddleware.swift", "doc.text", "dev-switch-token"),
                    ])
                } else if testFailCount == 2 {
                    say("Same error again. 401 token expired. You've spent a few minutes on this. Whisper is tracking your struggle.", type: .error)
                    say("Try once more. If it fails again, Whisper will offer help.", type: .hint)
                    setChoices([
                        ("Try once more", "arrow.counterclockwise", "dev-run-tests"),
                        ("Switch between files to debug", "doc.text", "dev-switch-token"),
                    ])
                } else {
                    // Third failure - whisper activates
                    say("Third consecutive failure. Struggle score crossed the threshold.", type: .error)
                    say("Whisper detected a pattern. 127 other developers hit this exact error. A new suggestion appeared in the Whisper interface.", type: .whisper)
                    
                    // Clear old suggestions, show the relevant one
                    clearWhisperSuggestions()
                    whisperSuggestions = [
                        WhisperSugg(title: "JWT Token Refresh Loop. Fix Available", detail: "127 developers encountered this. 63% solved it with refresh token rotation. Tap Expand for details and who solved it.", icon: "ant", color: .orange, isNew: true),
                    ]
                    
                    say("Go to the Whisper interface. Tap the suggestion to expand it, then tap 'Expand' for the full solution with solver names, or 'Apply' to fix your code directly.", type: .hint)
                    setChoices([
                        ("Dismiss Whisper, I'll debug it myself", "xmark", "dev-dismiss-whisper"),
                    ])
                }
            } else {
                // After fix applied - tests pass
                termWrite("✓ All tests passed (12/12)", type: .success)
                termWrite("  Time: 2.34s", type: .normal)
                termWrite("")
                termWrite("📡 Whisper: Solution recorded. You are contributor #128.", type: .whisperLog)
                withAnimation { struggleScore = 0 }
                clearWhisperSuggestions()
                
                say("All tests pass! Whisper recorded your solution. you're contributor #128. The collective knowledge grows stronger.", type: .success)
                say("You can explore auth architecture patterns from the collective, or finish the scenario.", type: .hint)
                setChoices([
                    ("Explore auth architecture patterns", "building.2", "dev-explore-arch"),
                    ("Finish the scenario", "checkmark.circle", "dev-complete"),
                ])
            }
            
        case "dev-inspect-error":
            say("Looking at line 47 in AuthService.swift. the refresh token is returned but never rotated. The old token stays valid, which causes the 401 loop on retry.", type: .action)
            say("Now you understand the bug. Run the test again to trigger Whisper's help, or try fixing it yourself by switching files.", type: .hint)
            currentFile = "auth"
            setChoices([
                ("Run test again", "arrow.counterclockwise", "dev-run-tests"),
                ("Check TokenMiddleware.swift", "doc.text", "dev-switch-token"),
            ])
            
        // ── Whisper-assisted fix ──
        // (Expand and Apply are handled by whisperExpand() and whisperApply()
        //  called from the Whisper panel buttons, not from narrator)
        
        case "dev-dismiss-whisper":
            clearWhisperSuggestions()
            say("Dismissed. You're debugging it yourself.", type: .action)
            say("Keep running tests or switching files to find the issue.", type: .hint)
            testFailCount = 2  // allow re-triggering
            setChoices([
                ("Run tests", "play", "dev-run-tests"),
                ("Check TokenMiddleware.swift", "doc.text", "dev-switch-token"),
            ])
            
        // ── Debug constellation ──
        case "dev-expand-debug":
            say("The Debug Constellation opens. a spatial graph showing the error tree.", type: .action)
            debugOpen = true
            debugRecommendation = "rotation"
            requestOpen("debug")
            
            say("You can see 3 causes: 'Refresh token not rotated' (89 devs, 94% success. RECOMMENDED), 'Cookie path mismatch' (45 devs), 'Refresh endpoint not called' (32 devs).", type: .whisper)
            say("Investigate any cause below, or go to the Whisper interface and click 'Apply' to apply the recommended fix.", type: .hint)
            setChoices([
                ("Investigate: Cookie path mismatch", "magnifyingglass", "dev-investigate-cookie"),
                ("Investigate: Refresh endpoint not called", "magnifyingglass", "dev-investigate-endpoint"),
                ("Close constellation", "xmark", "dev-close-debug"),
            ])
            
        case "dev-investigate-cookie":
            say("Cookie path mismatch. 45 developers hit this. The refresh token cookie path doesn't match the endpoint path. 78% success rate. Less likely to be your issue since you're not using cookies.", type: .action)
            say("The recommended fix is still token rotation (94% success). Go to the Whisper interface and click 'Apply', or check the third cause.", type: .hint)
            setChoices([
                ("Investigate: Refresh endpoint not called", "magnifyingglass", "dev-investigate-endpoint"),
                ("Close constellation", "xmark", "dev-close-debug"),
            ])
            
        case "dev-investigate-endpoint":
            say("Refresh endpoint not called. 32 developers hit this. The client never calls /auth/refresh before the access token expires. 72% success rate.", type: .action)
            say("Your routes.swift already has the refresh endpoint defined, so this isn't the cause. Go to the Whisper interface and click 'Apply' to apply the token rotation fix.", type: .hint)
            setChoices([
                ("Close constellation", "xmark", "dev-close-debug"),
            ])
            
        case "dev-close-debug":
            debugOpen = false; requestClose("debug"); debugRecommendation = nil
            say("Constellation closed. Back to coding.", type: .action)
            testFailCount = 2
            setChoices([
                ("Run tests", "play", "dev-run-tests"),
                ("Switch to AuthService.swift", "doc.text", "dev-switch-auth"),
            ])
            
        // ── Post-fix ──
        case "dev-explore-arch":
            say("Whisper loads the Architecture Explorer with auth patterns from the collective.", type: .action)
            archOpen = true
            requestOpen("architecture")
            say("Three architecture patterns are shown: Monolith, Microservice, and Edge Auth. Explore them in the Architecture window.", type: .hint)
            setChoices([
                ("Close architecture, finish scenario", "checkmark.circle", "dev-close-arch"),
            ])
            
        case "dev-close-arch":
            archOpen = false
            requestClose("architecture")
            say("Scenario complete.", type: .success)
            say("You experienced Whisper as a quiet expert: subtle hints, a debug constellation when stuck, code applied directly to your editor, and architecture exploration. No popups. No interruptions.", type: .narrator)
            clearChoices()
            
        default: break
        }
    }
    
    // ════════════════════════════════════════
    // MARK: - DEV SCENARIO 2: Race Condition + Digital Twin
    // ════════════════════════════════════════
    
    private func beginDevScenario2() {
        codeFiles = nodeCodeFiles
        say("It's 2077. You're debugging an async Node.js backend. Users report intermittent stale data.")
        say("Your task: find and fix a race condition in concurrent request handling.", type: .action)
        say("Open CodeForge to start.", type: .hint)
        setChoices([
            ("Open CodeForge IDE", "laptopcomputer", "r-open-ide"),
        ])
    }
    
    private func handleDev2Choice(_ action: String) {
        switch action {
            
        case "r-open-ide":
            say("CodeForge opens. requestHandler.js is loaded. the async request handler.", type: .action)
            ideOpen = true; currentFile = "handler"; requestOpen("ide")
            say("Open the Terminal so you can run the server.", type: .hint)
            setChoices([("Open Terminal", "terminal", "r-open-term")])
            
        case "r-open-term":
            terminalLines = [TermLine("$ ", type: .command)]
            say("Terminal ready inside CodeForge. Run the server from the terminal.", type: .hint)
            terminalCommands = [TermCmd(label: "node server.js", action: "r-run-server")]
            clearChoices()
            
        case "r-run-server":
            say("Starting the server and sending concurrent requests.", type: .action)
            termWrite("$ node server.js", type: .command)
            termWrite("Server running on :3000", type: .normal)
            termWrite("")
            termWrite("$ curl -X POST /api/update & curl -X POST /api/update", type: .command)
            termWrite("Response 1: { status: 'ok', value: 42 }", type: .normal)
            termWrite("Response 2: { status: 'ok', value: 41 }  ← STALE", type: .error)
            testFailCount = 1
            withAnimation { struggleScore = 0.2 }
            say("Inconsistent results. one returns stale data. Both should show 42 but one shows 41.", type: .error)
            say("Run the concurrent requests again from the terminal, or look at the code.", type: .hint)
            terminalCommands = [TermCmd(label: "curl (concurrent)", action: "r-run-again")]
            setChoices([("Look at requestHandler.js", "doc.text", "r-look-code")])
            
        case "r-run-again":
            testFailCount += 1
            terminalCommands = []
            termWrite("")
            termWrite("$ curl -X POST /api/update & curl -X POST /api/update", type: .command)
            termWrite("Response 1: { status: 'ok', value: 43 }", type: .normal)
            termWrite("Response 2: { status: 'ok', value: 42 }  ← STALE AGAIN", type: .error)
            withAnimation { struggleScore = min(Double(testFailCount) * 0.2, 0.85) }
            
            if testFailCount >= 3 {
                say("Non-deterministic error confirmed. Happening on concurrent requests.", type: .error)
                say("Whisper has detected a pattern. A suggestion appeared in the Whisper interface.", type: .whisper)
                
                whisperPanelOpen = true; whisperContext = "Async · Race Condition · Node.js"
                clearWhisperSuggestions()
                whisperSuggestions = [
                    WhisperSugg(title: "Async Race Condition Detected", detail: "78 developers hit this pattern. Avg solve time: 12 min. Tap to expand.", icon: "bolt.trianglebadge.exclamationmark", color: .orange, isNew: true),
                ]
                requestOpen("whisper-panel")
                
                say("Go to the Whisper interface. Tap the suggestion and hit 'Expand' for details.", type: .hint)
                setChoices([
                    ("Dismiss Whisper, debug myself", "xmark", "r-dismiss-whisper"),
                ])
            } else {
                say("Same issue. Run from the terminal again, or check the code.", type: .hint)
                terminalCommands = [TermCmd(label: "curl (concurrent)", action: "r-run-again")]
                setChoices([("Look at requestHandler.js", "doc.text", "r-look-code")])
            }
            
        case "r-look-code":
            currentFile = "handler"
            say("requestHandler.js. look at updateUserState(). Reads state, async work, writes back. No locking.", type: .action)
            say("Run concurrent requests from the terminal to trigger the issue.", type: .hint)
            terminalCommands = [TermCmd(label: "curl (concurrent)", action: "r-run-again")]
            clearChoices()
            
        case "r-dismiss-whisper":
            clearWhisperSuggestions(); whisperReasoning = nil
            say("Dismissed. Debugging yourself.", type: .action)
            testFailCount = 2
            terminalCommands = [TermCmd(label: "curl (concurrent)", action: "r-run-again")]
            setChoices([("Look at code", "doc.text", "r-look-code")])
            
        // ── Whisper expand for scenario 2 triggers this via whisperExpand() ──
        // (handled in whisperExpand())
        
        case "r-skeptical":
            say("You're not convinced. 'That's too generic. My issue isn't that simple.'", type: .action)
            say("The Whisper interface has a 'Why this?' reasoning breakdown. You can also escalate: 'Ask developer who solved this' is at the bottom.", type: .hint)
            setChoices([
                ("View reasoning: Why this solution?", "questionmark.circle", "r-why-this"),
                ("Escalate: Talk to the developer who solved it", "person.wave.2", "r-contact-solver"),
            ])
            
        case "r-why-this":
            say("You're skeptical. The suggestion feels too generic for your specific case.", type: .action)
            say("You can expand the suggestion in Whisper for the full reasoning, or escalate to talk to the developer who solved it.", type: .hint)
            setChoices([
                ("Talk to the developer who solved it", "person.wave.2", "r-contact-solver"),
            ])
            
        case "r-contact-solver":
            say("Connecting to Alex Chen...", type: .whisper)
            twinBusy = true
            twinName = "Alex Chen"
            twinRole = "Senior Backend Engineer @ NovaSys"
            twinImage = "AlexChen"
            say("Alex Chen is in a meeting. Connecting to Digital Twin.", type: .action)
            say("Use the Digital Twin panel to ask questions. The conversation happens there.", type: .hint)
            
            twinActive = true
            twinMessages = []
            requestOpen("digital-twin")
            
            // Buttons in twin window, NOT narrator
            twinChoices = [
                TwinChoice(label: "Why mutex instead of caching?", action: "r-twin-q1"),
                TwinChoice(label: "Where does the race happen in my code?", action: "r-twin-q2"),
                TwinChoice(label: "Would a queue be better?", action: "r-twin-q3"),
                TwinChoice(label: "Show me the fix options", action: "r-show-options"),
            ]
            clearChoices()
            
        case "r-twin-q1":
            withAnimation {
                twinMessages.append(TwinMessage(text: "Why did you use a mutex instead of just caching?", isUser: true))
            }
            Task { try? await Task.sleep(for: .seconds(0.8))
                withAnimation {
                    twinMessages.append(TwinMessage(text: "In my case, caching didn't work because the issue wasn't read performance. It was concurrent writes overwriting each other. The mutex ensures only one request updates the shared state at a time.", isUser: false))
                }
                twinChoices = [
                    TwinChoice(label: "Why mutex instead of caching?", action: "r-twin-q1"),
                    TwinChoice(label: "Where does the race happen in my code?", action: "r-twin-q2"),
                    TwinChoice(label: "Would a queue be better?", action: "r-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "r-show-options"),
                ]
            }
            say("The Twin explains: concurrent writes, not reads. Mutex prevents write conflicts.", type: .action)
            
        case "r-twin-q2":
            withAnimation {
                twinMessages.append(TwinMessage(text: "Show me where exactly the race condition happens in my code.", isUser: true))
            }
            Task { try? await Task.sleep(for: .seconds(0.8))
                withAnimation {
                    twinMessages.append(TwinMessage(text: "Look at updateUserState(). it reads state, does async work, then writes back. When triggered in parallel, both reads happen before either write. That's your race condition. Lines 8-14 in requestHandler.js.", isUser: false))
                }
                twinChoices = [
                    TwinChoice(label: "Why mutex instead of caching?", action: "r-twin-q1"),
                    TwinChoice(label: "Where does the race happen in my code?", action: "r-twin-q2"),
                    TwinChoice(label: "Would a queue be better?", action: "r-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "r-show-options"),
                ]
            }
            currentFile = "handler"
            say("Twin identified the location: updateUserState() lines 8-14. Look at CodeForge.", type: .whisper)
            
        case "r-twin-q3":
            withAnimation {
                twinMessages.append(TwinMessage(text: "Would a queue be better here?", isUser: true))
            }
            Task { try? await Task.sleep(for: .seconds(0.8))
                withAnimation {
                    twinMessages.append(TwinMessage(text: "A queue works if you can tolerate delay. If this is real-time user data, a mutex is safer and simpler. Queue adds latency and complexity you don't need here.", isUser: false))
                }
                twinChoices = [
                    TwinChoice(label: "Why mutex instead of caching?", action: "r-twin-q1"),
                    TwinChoice(label: "Where does the race happen in my code?", action: "r-twin-q2"),
                    TwinChoice(label: "Would a queue be better?", action: "r-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "r-show-options"),
                ]
            }
            say("Twin recommends mutex for real-time data. Queue adds unnecessary latency.", type: .action)
            
        case "r-show-options":
            withAnimation {
                twinMessages.append(TwinMessage(text: "What are my options?", isUser: true))
                twinMessages.append(TwinMessage(text: "You have three paths. Choose one below.", isUser: false))
            }
            twinChoices = [
                TwinChoice(label: "Apply Mutex Lock (simple, safe)", action: "r-apply-mutex"),
                TwinChoice(label: "Apply Request Queue (scalable, slower)", action: "r-apply-queue"),
                TwinChoice(label: "Apply Stateless Redesign (robust, complex)", action: "r-apply-stateless"),
            ]
            
        case "r-apply-mutex":
            withAnimation { twinMessages.append(TwinMessage(text: "Apply the mutex lock.", isUser: true)) }
            say("Applying mutex lock to requestHandler.js.", type: .action)
            updateCode(file: "handler", newCode: handlerFixedMutex)
            twinActive = false; requestClose("digital-twin"); twinChoices = []
            clearWhisperSuggestions()
            say("Mutex applied. updateUserState() now acquires a lock before read/write.", type: .success)
            say("Run concurrent requests from the terminal to verify.", type: .hint)
            terminalCommands = [TermCmd(label: "curl (verify)", action: "r-verify")]
            clearChoices()
            
        case "r-apply-queue":
            withAnimation { twinMessages.append(TwinMessage(text: "Apply the request queue.", isUser: true)) }
            say("Applying request queue to requestHandler.js.", type: .action)
            updateCode(file: "handler", newCode: handlerFixedQueue)
            twinActive = false; requestClose("digital-twin"); twinChoices = []
            clearWhisperSuggestions()
            say("Queue applied. All writes now go through a serial async queue.", type: .success)
            say("Run concurrent requests from the terminal to verify.", type: .hint)
            terminalCommands = [TermCmd(label: "curl (verify)", action: "r-verify")]
            clearChoices()
            
        case "r-apply-stateless":
            withAnimation { twinMessages.append(TwinMessage(text: "Apply the stateless redesign.", isUser: true)) }
            say("Applying stateless redesign to requestHandler.js.", type: .action)
            updateCode(file: "handler", newCode: handlerFixedStateless)
            twinActive = false; requestClose("digital-twin"); twinChoices = []
            clearWhisperSuggestions()
            say("Stateless redesign applied. Shared state replaced with atomic database operations.", type: .success)
            say("Run concurrent requests from the terminal to verify.", type: .hint)
            terminalCommands = [TermCmd(label: "curl (verify)", action: "r-verify")]
            clearChoices()
            
        case "r-close-twin":
            twinActive = false; requestClose("digital-twin")
            say("Digital Twin dismissed. Choose your fix from the Whisper interface. tap a suggestion, then 'Expand' for details or 'Apply' to fix the code.", type: .hint)
            clearChoices()
            // User uses Whisper Apply button from here
            
        case "r-apply-direct":
            say("Applying mutex fix to requestHandler.js.", type: .action)
            updateCode(file: "handler", newCode: handlerFixedMutex)
            clearWhisperSuggestions(); whisperReasoning = nil
            twinActive = false; requestClose("digital-twin")
            say("Done! updateUserState() now acquires a mutex. Look at the green ✅ lines in CodeForge.", type: .success)
            say("Run concurrent requests from the terminal to verify the fix.", type: .hint)
            terminalCommands = [TermCmd(label: "curl (verify)", action: "r-verify")]
            clearChoices()
            
        case "r-verify":
            terminalCommands = []
            termWrite("")
            termWrite("$ curl -X POST /api/update & curl -X POST /api/update", type: .command)
            termWrite("Response 1: { status: 'ok', value: 44 }", type: .success)
            termWrite("Response 2: { status: 'ok', value: 45 }", type: .success)
            termWrite("")
            termWrite("📡 Whisper: Fix verified. Solution recorded. Escalation successful.", type: .whisperLog)
            withAnimation { struggleScore = 0 }
            
            say("Both responses are consistent! The race condition is fixed.", type: .success)
            say("Whisper logged: escalation successful, understanding improved, solution reused. The collective grows stronger.", type: .whisper)
            setChoices([("Finish the scenario", "checkmark.circle", "r-complete")])
            
        case "r-complete":
            say("Scenario complete.", type: .success)
            say("You experienced Whisper's escalation path: suggestion → skepticism → reasoning breakdown → digital twin conversation → targeted fix. The system earned your trust through explanation, not authority.", type: .narrator)
            clearChoices()
            
        default: break
        }
    }
    
    // ═══ Whisper Expand/Apply for Scenario 2 ═══
    
    func whisperExpandS2() {
        expandedSolution = ExpandedSolution(
            title: "Mutex Lock for Async Race Condition",
            description: "Problem pattern:\nConcurrent requests modifying shared state. Request A reads, request B reads, B writes, A overwrites B's result.\n\nWhy this fix works:\nA mutex serializes access so only one request touches shared state at a time. Prevents the read-modify-write race in updateUserState().\n\nWhat it solves:\n• Eliminates non-deterministic stale data responses\n• No architectural change needed, just a lock wrapper\n• 94% success rate across 89 developers with this pattern",
            solvers: [
                Solver(name: "Alex Chen", role: "Senior Backend Engineer @ NovaSys", successRate: 94, imageName: "AlexChen", isBusy: true),
                Solver(name: "Rita Nowak", role: "Distributed Systems @ Helix", successRate: 89, imageName: nil, isBusy: false),
            ],
            fixSnippet: handlerFixedMutex
        )
        say("Expanded! Full description and solvers visible. Alex Chen (94%, busy. digital twin available) and Rita Nowak (89%). You can contact Alex's digital twin, or click 'Apply'.", type: .whisper)
        clearChoices()
        setChoices([
            ("I'm not convinced. this is too generic", "hand.raised", "r-skeptical"),
            ("Contact Alex Chen", "person.wave.2", "r-contact-solver"),
        ])
    }
    
    func whisperApplyS2() {
        say("Applying mutex fix to requestHandler.js.", type: .action)
        updateCode(file: "handler", newCode: handlerFixedMutex)
        clearWhisperSuggestions(); whisperReasoning = nil
        if twinActive { twinActive = false; requestClose("digital-twin") }
        say("Done! The race condition fix is applied. Look at the green ✅ lines in CodeForge.", type: .success)
        say("Run concurrent requests from the terminal to verify.", type: .hint)
        clearChoices()
        terminalCommands = [TermCmd(label: "curl (verify)", action: "r-verify")]
    }
    
    // Contact solver (from whisper panel button). Handles twin directly, no pick() re-entry.
    func contactSolver(_ solver: Solver) {
        if solver.isBusy {
            say("\(solver.name) is currently busy. Connecting to their Digital Twin instead.", type: .whisper)
            
            twinBusy = true
            twinName = solver.name
            twinRole = solver.role
            twinImage = solver.imageName ?? "AlexChen"
            twinActive = true
            twinMessages = []
            requestOpen("digital-twin")
            
            say("The Digital Twin panel opened. Ask your questions there.", type: .hint)
            
            // Set appropriate twin choices based on role
            if role == .designer {
                twinChoices = [
                    TwinChoice(label: "Why hide filters if expert users need speed?", action: "d2-twin-q1"),
                    TwinChoice(label: "Show me what you changed", action: "d2-twin-q2"),
                    TwinChoice(label: "What about pinning advanced filters?", action: "d2-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "d2-show-options"),
                ]
            } else {
                twinChoices = [
                    TwinChoice(label: "Why mutex instead of caching?", action: "r-twin-q1"),
                    TwinChoice(label: "Where does the race happen in my code?", action: "r-twin-q2"),
                    TwinChoice(label: "Would a queue be better?", action: "r-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "r-show-options"),
                ]
            }
        } else {
            say("Connecting to \(solver.name)...", type: .action)
            say("\(solver.name) is available. In a full system, a direct conversation would start here.", type: .hint)
        }
    }
    
    // ════════════════════════════════════════
    // MARK: - DESIGNER SCENARIOS
    // ════════════════════════════════════════
    
    private func beginDesignerScenario() {
        say("Welcome to Whisper. Choose your design scenario.")
        say("Use Case 1: Mobile checkout. payment screen is getting crowded. Whisper acts as a pattern coach.", type: .action)
        say("Use Case 2: Analytics dashboard. you disagree with Whisper's recommendation and escalate to a digital twin.", type: .action)
        setChoices([
            ("Use Case 1: Crowded Payment Screen", "creditcard", "scenario-d1"),
            ("Use Case 2: Dashboard Filters + Digital Twin", "chart.bar", "scenario-d2"),
        ])
    }
    
    private func handleDesignerChoice(_ action: String) {
        switch action {
            
        // ═══ USE CASE 1: CROWDED PAYMENT SCREEN ═══
            
        case "scenario-d1":
            say("You're designing the payment step of a mobile checkout flow. Open the Design Studio to start.", type: .action)
            setChoices([("Open Design Studio", "paintpalette", "d1-open-studio")])
            
        case "d1-open-studio":
            designOpen = true; designScenario = 1; requestOpen("design-studio")
            say("Figma canvas is floating in front of you. You can see: Cart, Shipping, Payment, Confirmation. Focus on the Payment screen.", type: .action)
            say("Start placing elements on the payment screen.", type: .hint)
            setChoices([("Place payment form elements", "square.and.pencil", "d1-place-elements")])
            
        case "d1-place-elements":
            say("You place: card number field, address fields, coupon field, delivery note, billing options, confirm button. The screen starts to look crowded.", type: .action)
            withAnimation { frictionHighlight = true }
            
            say("Whisper notices a pattern. this layout is similar to flows that caused user hesitation.", type: .whisper)
            whisperPanelOpen = true; whisperContext = "Payment Screen · Checkout"
            whisperSuggestions = [
                WhisperSugg(title: "Crowded Payment Layout", detail: "Similar layouts caused hesitation. Too many visible inputs. Users unsure what's required vs optional. Tap Expand.", icon: "exclamationmark.triangle", color: .orange, isNew: true),
            ]
            requestOpen("whisper-panel")
            
            say("A Whisper suggestion appeared. You can look at it or keep working.", type: .hint)
            setChoices([
                ("Keep working. rearrange the elements", "arrow.up.arrow.down", "d1-rearrange"),
                ("Dismiss Whisper", "xmark", "d1-dismiss"),
            ])
            
        case "d1-rearrange":
            say("You drag things around: coupon field goes higher, billing address stays visible, confirm button at the bottom. The screen still feels messy.", type: .action)
            say("You pause and look at the Whisper suggestion. Tap it and press 'Expand' in the Whisper interface to see what the fix is.", type: .hint)
            setChoices([
                ("Dismiss, keep my layout", "xmark", "d1-dismiss"),
            ])
            
        case "d1-dismiss":
            clearWhisperSuggestions(); withAnimation { frictionHighlight = false }
            say("Dismissed. You continue with your layout.", type: .action)
            say("Finish the scenario.", type: .hint)
            setChoices([("Finish", "checkmark.circle", "d1-complete")])
            
        // whisperExpand() for designer use case 1 shows the fix
        // whisperApply() applies the cleaner layout
            
        case "d1-show-overlay":
            showDesignOverlay = true
            say("A transparent overlay now appears on the Design Studio canvas showing the recommended layout structure.", type: .action)
            say("Compare your layout with the suggestion. Use the Whisper buttons to apply the fix or go back.", type: .hint)
            whisperActions = [
                TermCmd(label: "Apply This Layout", action: "d1-apply-from-overlay"),
                TermCmd(label: "Back. Remove Overlay", action: "d1-remove-overlay"),
            ]
            clearChoices()
            
        case "d1-apply-from-overlay":
            showDesignOverlay = false
            whisperActions = []
            whisperApply()
            
        case "d1-remove-overlay":
            showDesignOverlay = false
            say("Overlay removed. The suggestion is still in the Whisper interface if you want to revisit it.", type: .action)
            whisperActions = [
                TermCmd(label: "Show Pattern Overlay", action: "d1-show-overlay"),
            ]
            clearChoices()
            
        case "d1-complete":
            clearWhisperSuggestions()
            withAnimation { frictionHighlight = false }
            say("Use Case 1 complete.", type: .success)
            say("Whisper acted as: a gentle warning, a pattern guide, a layout coach. No digital twin was needed. prior design patterns, visual overlays, and clear examples were enough.", type: .narrator)
            clearChoices()
            
        // ═══ USE CASE 2: DASHBOARD FILTERS + DIGITAL TWIN ═══
            
        case "scenario-d2":
            say("You're building an analytics dashboard with charts, KPI cards, filters, date ranges, and export actions. Open Design Studio.", type: .action)
            setChoices([("Open Design Studio", "paintpalette", "d2-open-studio")])
            
        case "d2-open-studio":
            designOpen = true; designScenario = 2; requestOpen("design-studio")
            say("Dashboard canvas is floating in front. You need to improve the filter bar at the top.", type: .action)
            say("Start building the filter area.", type: .hint)
            setChoices([("Build the filter area", "line.3.horizontal.decrease", "d2-build-filters")])
            
        case "d2-build-filters":
            say("You place: date range, region filter, product filter, team filter, segment filter, compare toggle, export button. The top area feels overloaded. too many controls competing for attention.", type: .action)
            
            whisperPanelOpen = true; whisperContext = "Dashboard · Filter Bar"
            whisperSuggestions = [
                WhisperSugg(title: "Filter Overload Detected", detail: "Similar dashboards had trouble with all filters at the same level. Users didn't know where to start. Tap Expand.", icon: "slider.horizontal.3", color: .orange, isNew: true),
            ]
            requestOpen("whisper-panel")
            
            say("Whisper detected a familiar issue. A suggestion appeared in the Whisper interface.", type: .whisper)
            say("You read it and frown. You think: 'No, in this tool people need ALL filters visible. Hiding them might slow expert users down.'", type: .hint)
            setChoices([
                ("I'm not convinced. ask for more detail", "questionmark.circle", "d2-why-this"),
                ("Dismiss, keep all filters visible", "xmark", "d2-dismiss"),
            ])
            
        case "d2-why-this":
            say("You're not convinced. 'That's too generic. My users are power users who need speed.'", type: .action)
            say("Expand the suggestion in the Whisper panel for more detail. You can contact a solver from there.", type: .hint)
            clearChoices()
            
        case "d2-contact-maya":
            say("Connecting to Maya...", type: .whisper)
            twinBusy = true
            twinName = "Maya"
            twinRole = "Senior UX Designer @ DataViz Corp"
            twinImage = "Maya"
            say("Maya is currently in a design review. Connecting to Maya's Digital Twin.", type: .action)
            
            twinActive = true; twinMessages = []
            requestOpen("digital-twin")
            
            say("The Digital Twin panel opened. Ask your questions there.", type: .hint)
            twinChoices = [
                TwinChoice(label: "Why hide filters if expert users need speed?", action: "d2-twin-q1"),
                TwinChoice(label: "Show me what you changed", action: "d2-twin-q2"),
                TwinChoice(label: "What about pinning advanced filters?", action: "d2-twin-q3"),
                TwinChoice(label: "Show me the fix options", action: "d2-show-options"),
            ]
            clearChoices()
            
        case "d2-twin-q1":
            withAnimation {
                twinMessages.append(TwinMessage(text: "Why did you hide some filters if expert users needed speed?", isUser: true))
            }
            Task { try? await Task.sleep(for: .seconds(0.8))
                withAnimation {
                    twinMessages.append(TwinMessage(text: "I thought the same thing at first. But the problem was not that users needed fewer controls. The problem was that they needed a clearer starting point.\n\nWe kept the most frequent filters visible, and placed the less common ones one step away. Expert users still had access, but the interface became easier to read.", isUser: false))
                }
                twinChoices = [
                    TwinChoice(label: "Why hide filters if expert users need speed?", action: "d2-twin-q1"),
                    TwinChoice(label: "Show me what you changed", action: "d2-twin-q2"),
                    TwinChoice(label: "What about pinning advanced filters?", action: "d2-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "d2-show-options"),
                ]
            }
            say("The Twin explains: the issue isn't fewer controls, it's a clearer starting point.", type: .action)
            
        case "d2-twin-q2":
            withAnimation {
                twinMessages.append(TwinMessage(text: "Show me what you changed in your dashboard.", isUser: true))
            }
            Task { try? await Task.sleep(for: .seconds(0.8))
                withAnimation {
                    twinMessages.append(TwinMessage(text: "Here's what I did:\n\nPrimary row: date range, region, product\nSecondary area: advanced filters, compare options\nSeparate action area: export\n\nThe key insight: export is not a filter. it's an action. Mixing it with filters confused users about what they were doing.", isUser: false))
                }
                twinChoices = [
                    TwinChoice(label: "Why hide filters if expert users need speed?", action: "d2-twin-q1"),
                    TwinChoice(label: "Show me what you changed", action: "d2-twin-q2"),
                    TwinChoice(label: "What about pinning advanced filters?", action: "d2-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "d2-show-options"),
                ]
            }
            say("The Twin shows the restructured layout: primary filters visible, advanced behind a drawer, export separated.", type: .action)
            
        case "d2-twin-q3":
            withAnimation {
                twinMessages.append(TwinMessage(text: "But what if advanced users use those hidden filters every single day?", isUser: true))
            }
            Task { try? await Task.sleep(for: .seconds(0.8))
                withAnimation {
                    twinMessages.append(TwinMessage(text: "Then the interface can remember them.\n\nIn my case, we let users pin advanced filters back into the top row. So the default view stayed clean, but heavy users could personalize it.\n\nThe solution isn't 'hide things'. It's 'create a cleaner default, then let experts adapt it'.", isUser: false))
                }
                twinChoices = [
                    TwinChoice(label: "Why hide filters if expert users need speed?", action: "d2-twin-q1"),
                    TwinChoice(label: "Show me what you changed", action: "d2-twin-q2"),
                    TwinChoice(label: "What about pinning advanced filters?", action: "d2-twin-q3"),
                    TwinChoice(label: "Show me the fix options", action: "d2-show-options"),
                ]
            }
            say("Key insight: 'Create a cleaner default, then let experts adapt it.' Users can pin frequently used filters.", type: .whisper)
            
        case "d2-show-options":
            withAnimation {
                twinMessages.append(TwinMessage(text: "What are my options?", isUser: true))
                twinMessages.append(TwinMessage(text: "You have three approaches. Choose one below.", isUser: false))
            }
            twinChoices = [
                TwinChoice(label: "Apply Two-Level Filter (recommended)", action: "d2-apply-twolevel"),
                TwinChoice(label: "Apply Progressive Disclosure (minimalist)", action: "d2-apply-progressive"),
                TwinChoice(label: "Keep All Visible (no change)", action: "d2-apply-keepall"),
            ]
            
        case "d2-apply-twolevel":
            withAnimation { twinMessages.append(TwinMessage(text: "Apply the two-level filter model.", isUser: true)) }
            designFixed = true; designAppliedOption = "twolevel"
            twinActive = false; requestClose("digital-twin"); twinChoices = []
            clearWhisperSuggestions(); whisperReasoning = nil
            say("Two-level filter applied. Look at the Design Studio.", type: .success)
            setChoices([("Finish", "checkmark.circle", "d2-complete")])
            
        case "d2-apply-progressive":
            withAnimation { twinMessages.append(TwinMessage(text: "Apply progressive disclosure.", isUser: true)) }
            designFixed = true; designAppliedOption = "progressive"
            twinActive = false; requestClose("digital-twin"); twinChoices = []
            clearWhisperSuggestions(); whisperReasoning = nil
            say("Progressive disclosure applied. Look at the Design Studio.", type: .success)
            setChoices([("Finish", "checkmark.circle", "d2-complete")])
            
        case "d2-apply-keepall":
            withAnimation { twinMessages.append(TwinMessage(text: "Keep all filters visible.", isUser: true)) }
            designFixed = true; designAppliedOption = "keepall"
            twinActive = false; requestClose("digital-twin"); twinChoices = []
            clearWhisperSuggestions(); whisperReasoning = nil
            say("No changes made. Look at the Design Studio.", type: .action)
            setChoices([("Finish", "checkmark.circle", "d2-complete")])
            
        case "d2-dismiss":
            clearWhisperSuggestions(); whisperReasoning = nil
            say("Dismissed. Keeping your current layout.", type: .action)
            setChoices([("Finish", "checkmark.circle", "d2-complete")])
            
        case "d2-complete":
            clearWhisperSuggestions(); whisperReasoning = nil
            twinActive = false; twinChoices = []
            say("Use Case 2 complete.", type: .success)
            say("The issue was a tension between clarity for most users and speed for expert users. Whisper gave a general recommendation, you resisted (reasonably), then the Digital Twin added the missing part: the reasoning and tradeoff behind the recommendation. That made it usable.", type: .narrator)
            clearChoices()
            
        default: break
        }
    }
    
    // ════════════════════════════════════════
    // MARK: - Code Content
    // ════════════════════════════════════════
    
    // Original code (with TODO)
    private var devCodeFiles: [String: CodeFile] {[
        "auth": CodeFile(label: "AuthService.swift", path: "src/auth/AuthService.swift", code: "import Vapor\nimport JWT\n\n// MARK: Auth Service\n\nfinal class AuthService {\n\n    let app: Application\n\n    init(app: Application) {\n        self.app = app\n    }\n\n    /// Refresh an expired access token\n    func refreshAccessToken(\n        refreshToken: String\n    ) async throws -> TokenPair {\n\n        // Verify refresh token\n        let payload = try app.jwt.signers\n            .verify(refreshToken, as: RefreshPayload.self)\n\n        // Check if token is revoked\n        guard let stored = try await RefreshToken\n            .query(on: app.db)\n            .filter(\\.$token == refreshToken)\n            .first()\n        else {\n            throw AuthError.invalidRefreshToken\n        }\n\n        guard !stored.isRevoked else {\n            throw AuthError.tokenRevoked\n        }\n\n        let user = try await User.find(\n            payload.userId, on: app.db\n        )\n\n        let newAccess = try generateAccessToken(for: user)\n        let newRefresh = try generateRefreshToken(for: user)\n\n        // TODO: Rotate refresh token ←\n\n        return TokenPair(\n            accessToken: newAccess,\n            refreshToken: newRefresh,\n            expiresIn: 3600\n        )\n    }\n}"),
        "token": CodeFile(label: "TokenMiddleware.swift", path: "src/auth/TokenMiddleware.swift", code: "import Vapor\n\nstruct TokenMiddleware: AsyncMiddleware {\n\n    func respond(\n        to request: Request,\n        chainingTo next: AsyncResponder\n    ) async throws -> Response {\n\n        guard let token = request.headers\n            .bearerAuthorization?.token\n        else {\n            throw Abort(.unauthorized)\n        }\n\n        let payload = try request.jwt\n            .verify(token, as: AccessPayload.self)\n\n        request.auth.login(payload)\n        return try await next.respond(to: request)\n    }\n}"),
        "user": CodeFile(label: "User.swift", path: "src/models/User.swift", code: "import Fluent\nimport Vapor\n\nfinal class User: Model, Content {\n    static let schema = \"users\"\n\n    @ID(key: .id) var id: UUID?\n    @Field(key: \"email\") var email: String\n    @Field(key: \"password_hash\") var passwordHash: String\n\n    init() { }\n}"),
        "routes": CodeFile(label: "routes.swift", path: "src/api/routes.swift", code: "import Vapor\n\nfunc routes(_ app: Application) throws {\n    let auth = app.grouped(\"api\", \"auth\")\n    auth.post(\"login\", use: loginHandler)\n    auth.post(\"refresh\", use: refreshHandler)\n    auth.post(\"logout\", use: logoutHandler)\n\n    let protected = auth.grouped(TokenMiddleware())\n    protected.get(\"me\", use: meHandler)\n}"),
        "authtest": CodeFile(label: "AuthTests.swift", path: "tests/AuthTests.swift", code: "import XCTVapor\n@testable import App\n\nfinal class AuthTests: XCTestCase {\n    func testTokenRefresh() async throws {\n        let app = Application(.testing)\n        defer { app.shutdown() }\n        try configure(app)\n\n        let loginRes = try app.sendRequest(\n            .POST, \"api/auth/login\",\n            body: [\"email\": \"test@whisper.dev\"]\n        )\n\n        try await Task.sleep(for: .seconds(2))\n\n        let refreshRes = try app.sendRequest(\n            .POST, \"api/auth/refresh\"\n        )\n        XCTAssertEqual(refreshRes.status, .ok)\n    }\n}"),
    ]}
    
    // Fixed code (after applying rotation fix)
    private var authFixedCode: String {
        "import Vapor\nimport JWT\n\n// MARK: Auth Service\n\nfinal class AuthService {\n\n    let app: Application\n\n    init(app: Application) {\n        self.app = app\n    }\n\n    /// Refresh an expired access token\n    func refreshAccessToken(\n        refreshToken: String\n    ) async throws -> TokenPair {\n\n        // Verify refresh token\n        let payload = try app.jwt.signers\n            .verify(refreshToken, as: RefreshPayload.self)\n\n        // Check if token is revoked\n        guard let stored = try await RefreshToken\n            .query(on: app.db)\n            .filter(\\.$token == refreshToken)\n            .first()\n        else {\n            throw AuthError.invalidRefreshToken\n        }\n\n        guard !stored.isRevoked else {\n            throw AuthError.tokenRevoked\n        }\n\n        let user = try await User.find(\n            payload.userId, on: app.db\n        )\n\n        // ✅ Rotate: invalidate old refresh token\n        stored.isRevoked = true\n        try await stored.save(on: app.db)\n\n        // ✅ Generate new token pair\n        let newAccess = try generateAccessToken(for: user)\n        let newRefresh = try generateRefreshToken(for: user)\n\n        // ✅ Store new refresh token\n        let newToken = RefreshToken(\n            token: newRefresh,\n            userId: user.id!\n        )\n        try await newToken.save(on: app.db)\n\n        return TokenPair(\n            accessToken: newAccess,\n            refreshToken: newRefresh,\n            expiresIn: 3600\n        )\n    }\n}"
    }
    
    // ═══ Scenario 2: Node.js Code Files ═══
    
    private var nodeCodeFiles: [String: CodeFile] {[
        "handler": CodeFile(label: "requestHandler.js", path: "src/handlers/requestHandler.js", code: "const express = require('express');\nconst app = express();\n\nlet sharedState = { counter: 40, lastUpdated: null };\n\n// ⚠️ Race condition: concurrent calls can read stale state\nasync function updateUserState(req, res) {\n    // Read current state\n    const current = sharedState.counter;\n    \n    // Simulate async work (DB call, external API)\n    await new Promise(r => setTimeout(r, 50));\n    \n    // Write back, another request may have already\n    // changed sharedState.counter between read and write\n    sharedState.counter = current + 1;\n    sharedState.lastUpdated = new Date();\n    \n    res.json({ status: 'ok', value: sharedState.counter });\n}\n\napp.post('/api/update', updateUserState);\napp.listen(3000, () => console.log('Server on :3000'));"),
        "server": CodeFile(label: "server.js", path: "server.js", code: "const app = require('./src/handlers/requestHandler');\n\nconst PORT = process.env.PORT || 3000;\nconsole.log(`Starting server on :${PORT}`);\nconsole.log('Endpoints: POST /api/update');"),
        "state": CodeFile(label: "stateManager.js", path: "src/state/stateManager.js", code: "// State management module\n// Currently in-memory shared state\n// TODO: Consider Redis or DB-backed state\n\nclass StateManager {\n    constructor() {\n        this.state = {};\n    }\n    get(key) { return this.state[key]; }\n    set(key, value) { this.state[key] = value; }\n}\n\nmodule.exports = new StateManager();"),
    ]}
    
    private var handlerFixedMutex: String {
        "const express = require('express');\nconst { Mutex } = require('async-mutex');\nconst app = express();\n\nlet sharedState = { counter: 40, lastUpdated: null };\n\n// ✅ Mutex prevents concurrent access to shared state\nconst mutex = new Mutex();\n\nasync function updateUserState(req, res) {\n    // ✅ Acquire lock before reading/writing\n    const release = await mutex.acquire();\n    try {\n        const current = sharedState.counter;\n        \n        // Simulate async work\n        await new Promise(r => setTimeout(r, 50));\n        \n        // ✅ Write back safely. lock held\n        sharedState.counter = current + 1;\n        sharedState.lastUpdated = new Date();\n        \n        res.json({ status: 'ok', value: sharedState.counter });\n    } finally {\n        // ✅ Always release the lock\n        release();\n    }\n}\n\napp.post('/api/update', updateUserState);\napp.listen(3000, () => console.log('Server on :3000'));"
    }
    
    private var handlerFixedQueue: String {
        "const express = require('express');\nconst app = express();\n\nlet sharedState = { counter: 40, lastUpdated: null };\n\n// ✅ Serial queue ensures writes happen one at a time\nconst writeQueue = [];\nlet processing = false;\n\nfunction enqueue(task) {\n    return new Promise((resolve) => {\n        writeQueue.push({ task, resolve });\n        processQueue();\n    });\n}\n\nasync function processQueue() {\n    if (processing) return;\n    processing = true;\n    while (writeQueue.length > 0) {\n        const { task, resolve } = writeQueue.shift();\n        const result = await task();\n        resolve(result);\n    }\n    processing = false;\n}\n\nasync function updateUserState(req, res) {\n    // ✅ All writes go through the serial queue\n    const result = await enqueue(async () => {\n        const current = sharedState.counter;\n        await new Promise(r => setTimeout(r, 50));\n        sharedState.counter = current + 1;\n        sharedState.lastUpdated = new Date();\n        return sharedState.counter;\n    });\n    \n    res.json({ status: 'ok', value: result });\n}\n\napp.post('/api/update', updateUserState);\napp.listen(3000, () => console.log('Server on :3000'));"
    }
    
    private var handlerFixedStateless: String {
        "const express = require('express');\nconst { Pool } = require('pg');\nconst app = express();\n\n// ✅ No shared mutable state. Database handles concurrency.\nconst pool = new Pool({ connectionString: process.env.DB_URL });\n\nasync function updateUserState(req, res) {\n    // ✅ Atomic database operation. no shared memory.\n    const result = await pool.query(\n        'UPDATE state SET counter = counter + 1, ' +\n        'last_updated = NOW() ' +\n        'WHERE id = 1 ' +\n        'RETURNING counter'\n    );\n    \n    // ✅ Database guarantees atomicity.\n    // No race condition possible.\n    res.json({\n        status: 'ok',\n        value: result.rows[0].counter\n    });\n}\n\napp.post('/api/update', updateUserState);\napp.listen(3000, () => console.log('Server on :3000'));"
    }
}

struct TermLine: Identifiable {
    let id = UUID(); let text: String; let type: LineType
    init(_ text: String, type: LineType = .normal) { self.text = text; self.type = type }
    enum LineType { case command, normal, error, success, whisperLog
        var color: Color { switch self {
            case .command: return .white; case .normal: return .secondary
            case .error: return .red; case .success: return .green; case .whisperLog: return .cyan
        }}
    }
}

struct WhisperSugg: Identifiable {
    let id = UUID()
    let title: String; let detail: String; let icon: String
    let color: Color; let isNew: Bool
}


struct ExpandedSolution {
    let title: String
    let description: String
    let solvers: [ScenarioEngine.Solver]
    let fixSnippet: String?  // if non-nil, can be applied to code
}

struct CodeFile {
    let label: String; let path: String; let code: String
}
