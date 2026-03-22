// SpatialWindows.swift — Whisper
// Whisper Panel, Debug Constellation, Design Studio, Journey Panel, Digital Twin

import SwiftUI

// ══════════════════════════════════════
// MARK: - Whisper Panel (was Peripheral Intelligence)
// ══════════════════════════════════════

struct WhisperPanelWindow: View {
    @Environment(ScenarioEngine.self) private var engine
    @State private var expandedId: UUID? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            whisperHeader
            Divider().opacity(0.15)
            whisperBody
            if let reasoning = engine.whisperReasoning {
                Divider().opacity(0.15)
                reasoningView(reasoning)
            }
            if engine.expandedSolution != nil {
                Divider().opacity(0.15)
                expandedSolutionView
            }
            if !engine.whisperActions.isEmpty {
                Divider().opacity(0.15)
                whisperActionButtons
            }
        }
        .background(Color(red: 0.03, green: 0.05, blue: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // ── Why This? Reasoning ──
    private func reasoningView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "questionmark.circle.fill").font(.system(size: 10)).foregroundStyle(.purple)
                Text("WHY THIS SOLUTION").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.purple)
            }
            Text(text)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(12)
        .background(Color.purple.opacity(0.04))
    }
    
    // ── Header ──
    private var whisperHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 14)).foregroundStyle(.cyan)
                .symbolEffect(.breathe, options: .repeating)
            VStack(alignment: .leading, spacing: 1) {
                Text("Whisper")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                Text(engine.whisperContext)
                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            if !engine.whisperSuggestions.isEmpty {
                liveBadge
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color(red: 0.02, green: 0.04, blue: 0.08))
    }
    
    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle().fill(.green).frame(width: 5, height: 5).shadow(color: .green, radius: 3)
            Text("ACTIVE").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.green)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(.green.opacity(0.1), in: Capsule())
    }
    
    // ── Suggestions list (dynamic — appears/disappears) ──
    private var whisperBody: some View {
        ScrollView {
            if engine.whisperSuggestions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(engine.whisperSuggestions) { s in
                        suggestionCard(s)
                    }
                }
                .padding(10)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle").font(.system(size: 24)).foregroundStyle(Color(white: 0.2))
            Text("Listening...").font(.system(size: 11, design: .monospaced)).foregroundStyle(Color(white: 0.25))
            Text("Suggestions appear when relevant").font(.system(size: 9, design: .monospaced)).foregroundStyle(Color(white: 0.18))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
    
    // ── Suggestion Card ──
    private func suggestionCard(_ s: WhisperSugg) -> some View {
        let isExp = expandedId == s.id
        return Button {
            withAnimation(.spring(response: 0.25)) { expandedId = isExp ? nil : s.id }
        } label: {
            cardContent(s, isExp: isExp)
        }
        .buttonStyle(.plain)
    }
    
    private func cardContent(_ s: WhisperSugg, isExp: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            cardHeader(s)
            Text(s.detail)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(isExp ? nil : 2)
            if isExp {
                cardActions(s)
            }
        }
        .padding(10)
        .background(isExp ? s.color.opacity(0.08) : Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isExp ? s.color.opacity(0.3) : .clear, lineWidth: 1))
    }
    
    private func cardHeader(_ s: WhisperSugg) -> some View {
        HStack(spacing: 6) {
            Image(systemName: s.icon).font(.system(size: 10)).foregroundStyle(s.color).frame(width: 16)
            Text(s.title).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(.primary)
            if s.isNew {
                Text("NEW").font(.system(size: 7, weight: .black)).foregroundStyle(.black)
                    .padding(.horizontal, 5).padding(.vertical, 1).background(.cyan, in: Capsule())
            }
            Spacer()
        }
    }
    
    private func cardActions(_ s: WhisperSugg) -> some View {
        HStack(spacing: 8) {
            Button {
                engine.whisperExpand()
            } label: {
                Label("Expand", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(s.color)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(s.color.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
            
            Button {
                engine.whisperApply()
            } label: {
                Label("Apply", systemImage: "plus.circle")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(.green)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.green.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
    
    // ── Expanded Solution (with people + contact) ──
    private var expandedSolutionView: some View {
        let sol = engine.expandedSolution!
        return VStack(alignment: .leading, spacing: 8) {
            Text(sol.title).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.cyan)
            Text(sol.description).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).lineSpacing(2)
            
            Divider().opacity(0.15)
            Text("SOLVED BY").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(Color(white: 0.35))
            
            ForEach(sol.solvers) { solver in
                solverRow(solver)
            }
        }
        .padding(12)
        .background(Color(red: 0.02, green: 0.06, blue: 0.1))
    }
    
    // ── Whisper Action Buttons ──
    private var whisperActionButtons: some View {
        VStack(spacing: 6) {
            ForEach(engine.whisperActions) { action in
                Button {
                    engine.runWhisperAction(action.action)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: action.label.contains("Apply") ? "checkmark.circle" :
                              action.label.contains("Back") ? "arrow.uturn.backward" :
                              "square.on.square")
                            .font(.system(size: 11))
                            .foregroundStyle(action.label.contains("Apply") ? .green :
                                           action.label.contains("Back") ? .secondary : .cyan)
                        Text(action.label)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(action.label.contains("Apply") ? .green : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8)).foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(
                        action.label.contains("Apply") ? Color.green.opacity(0.08) : Color.white.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 9)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(action.label.contains("Apply") ? .green.opacity(0.3) : Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 9))
                .hoverEffect(.highlight)
            }
        }
        .padding(10)
        .background(Color(red: 0.02, green: 0.04, blue: 0.08))
    }
    
    private func solverRow(_ solver: ScenarioEngine.Solver) -> some View {
        HStack(spacing: 8) {
            // Profile image or initial
            solverAvatar(solver)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(solver.name)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    if solver.isBusy {
                        Text("BUSY")
                            .font(.system(size: 6, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange, in: Capsule())
                    }
                }
                Text(solver.role)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(solver.successRate)%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.green)
            
            // Contact button
            Button {
                engine.contactSolver(solver)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: solver.isBusy ? "person.wave.2" : "envelope.circle.fill")
                        .font(.system(size: 12))
                    Text(solver.isBusy ? "Twin" : "Contact")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.cyan.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(.cyan.opacity(0.2)))
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func solverAvatar(_ solver: ScenarioEngine.Solver) -> some View {
        Group {
            if let imgName = solver.imageName {
                Image(imgName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.cyan.opacity(0.4), lineWidth: 1.5))
            } else {
                Circle()
                    .fill(.cyan.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(solver.name.prefix(1)))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.cyan)
                    )
            }
        }
    }
}

// ══════════════════════════════════════
// MARK: - Architecture Explorer
// ══════════════════════════════════════

struct ArchitectureWindow: View {
    @Environment(ScenarioEngine.self) private var engine
    @State private var selected: Int? = nil
    
    private let patterns: [(name: String, icon: String, color: Color, projects: Int, desc: String, details: String)] = [
        ("Monolith Auth", "server.rack", .blue, 156,
         "Single auth service handles all authentication",
         "All auth logic in one service. Simple to deploy, hard to scale. Session stored in-memory or single DB. Works for small teams. Becomes bottleneck at 10K+ concurrent users."),
        ("Microservice Auth", "square.grid.3x3", .cyan, 234,
         "Dedicated auth microservice with token-based flow",
         "Separate auth service issues JWTs. Other services validate tokens independently. Scales horizontally. Requires token rotation strategy. 234 projects in the collective use this — most common for APIs."),
        ("Edge Auth", "network", .green, 89,
         "Authentication at CDN/edge layer before requests reach backend",
         "Auth handled at edge nodes (Cloudflare Workers, Lambda@Edge). Zero-latency token validation. Backend never sees unauthenticated requests. Complex to debug. Best for global apps with strict latency needs."),
    ]
    
    var body: some View {
        if engine.archOpen {
            VStack(spacing: 0) {
                archHeader
                Divider().opacity(0.15)
                archBody
            }
            .background(Color(red: 0.03, green: 0.04, blue: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Color.clear.frame(width: 1, height: 1)
        }
    }
    
    private var archHeader: some View {
        HStack {
            Image(systemName: "building.2").foregroundStyle(.blue)
            Text("Architecture Explorer").font(.system(size: 14, weight: .bold, design: .monospaced))
            Text("· Auth Patterns").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.02, green: 0.03, blue: 0.07))
    }
    
    private var archBody: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(patterns.enumerated()), id: \.offset) { i, p in
                    archCard(p, index: i)
                }
            }
            .padding(16)
        }
    }
    
    private func archCard(_ p: (name: String, icon: String, color: Color, projects: Int, desc: String, details: String), index: Int) -> some View {
        let isExp = selected == index
        return Button {
            withAnimation(.spring(response: 0.3)) { selected = isExp ? nil : index }
        } label: {
            archCardContent(p, isExp: isExp)
        }
        .buttonStyle(.plain)
    }
    
    private func archCardContent(_ p: (name: String, icon: String, color: Color, projects: Int, desc: String, details: String), isExp: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(p.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: p.icon).font(.system(size: 16)).foregroundStyle(p.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name).font(.system(size: 13, weight: .bold, design: .monospaced))
                    Text(p.desc).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(p.projects)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(p.color)
                Text("projects").font(.system(size: 8, design: .monospaced)).foregroundStyle(Color(white: 0.35))
            }
            
            if isExp {
                Divider().opacity(0.15)
                Text(p.details)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(white: 0.7))
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .background(isExp ? p.color.opacity(0.06) : Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isExp ? p.color.opacity(0.3) : Color.white.opacity(0.04)))
    }
}

// ══════════════════════════════════════
// MARK: - Debug Constellation
// ══════════════════════════════════════

struct DebugConstellationWindow: View {
    @Environment(ScenarioEngine.self) private var engine
    
    var body: some View {
        if engine.debugOpen {
            VStack(spacing: 0) {
                debugHeader
                Divider().opacity(0.15)
                debugBody
            }
            .background(Color(red: 0.03, green: 0.04, blue: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Color.clear.frame(width: 1, height: 1)
        }
    }
    
    private var debugHeader: some View {
        HStack {
            Image(systemName: "point.3.connected.trianglepath.dotted").foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text("Debug Constellation").font(.system(size: 14, weight: .bold, design: .monospaced))
                Text("Choose a cause to investigate").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                withAnimation { engine.debugOpen = false }
                engine.requestClose("debug")
            } label: {
                Label("Close", systemImage: "xmark.circle").font(.system(size: 11))
            }.buttonStyle(.bordered)
        }
        .padding(16)
        .background(Color(red: 0.02, green: 0.03, blue: 0.07))
    }
    
    private var debugBody: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                errorNode
                connector(.red)
                HStack(alignment: .top, spacing: 16) {
                    causeBranch("Refresh token not rotated", fix: "Add rotation middleware", devs: 89, rate: 94, color: .orange, isRecommended: true)
                    causeBranch("Cookie path mismatch", fix: "Fix cookie path config", devs: 45, rate: 78, color: .orange, isRecommended: false)
                    causeBranch("Refresh endpoint not called", fix: "Add HTTP interceptor", devs: 32, rate: 72, color: .orange, isRecommended: false)
                }
            }
            .padding(32)
        }
    }
    
    private var errorNode: some View {
        nodeBox("401 Token Expired", icon: "xmark.octagon", color: .red, meta: nil, recommended: false)
    }
    
    private func causeBranch(_ cause: String, fix: String, devs: Int, rate: Int, color: Color, isRecommended: Bool) -> some View {
        VStack(spacing: 0) {
            connector(color)
            nodeBox(cause, icon: "exclamationmark.triangle", color: color, meta: nil, recommended: false)
            connector(.green)
            nodeBox(fix, icon: "wrench.and.screwdriver", color: .green, meta: "\(devs) devs · \(rate)% success", recommended: isRecommended)
        }
    }
    
    private func nodeBox(_ label: String, icon: String, color: Color, meta: String?, recommended: Bool) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 26, height: 26)
                Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(label).font(.system(size: 11, weight: .semibold, design: .monospaced))
                    if recommended {
                        Text("RECOMMENDED").font(.system(size: 7, weight: .black)).foregroundStyle(.black)
                            .padding(.horizontal, 5).padding(.vertical, 1).background(.green, in: Capsule())
                    }
                }
                if let meta {
                    Text(meta).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(color.opacity(recommended ? 0.1 : 0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(recommended ? 0.5 : 0.2), lineWidth: recommended ? 2 : 1))
        .shadow(color: recommended ? .green.opacity(0.2) : .clear, radius: 8)
    }
    
    private func connector(_ color: Color) -> some View {
        Rectangle().fill(color.opacity(0.3)).frame(width: 2, height: 18)
    }
}

// ══════════════════════════════════════
// MARK: - Design Studio Window
// ══════════════════════════════════════

struct DesignStudioWindow: View {
    @Environment(ScenarioEngine.self) private var engine
    
    // Interactive dashboard state
    @State private var selectedKPI: String? = nil
    @State private var selectedChartBar: (chart: String, index: Int)? = nil
    @State private var selectedTableRow: Int? = nil
    
    // Crowded dashboard filter state
    @State private var selectedFilters: Set<String> = []
    
    // Two-level dashboard state
    @State private var twoLevelActive: Set<String> = ["Date Range"]
    @State private var twoLevelDrawerOpen = false
    @State private var twoLevelPinned: Set<String> = []
    
    // Progressive dashboard state
    @State private var progressiveAdded: [String] = []
    @State private var progressivePickerOpen = false
    
    // Export feedback
    @State private var exportTapped = false
    
    var body: some View {
        VStack(spacing: 0) {
            designHeader
            Divider().opacity(0.15)
            if engine.designScenario == 2 {
                dashboardCanvas
            } else {
                checkoutCanvas
            }
        }
        .background(Color(red: 0.04, green: 0.03, blue: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var designHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "paintpalette").foregroundStyle(.indigo)
            Text("Design Studio").font(.system(size: 12, weight: .bold, design: .monospaced))
            Text("· \(engine.designScenario == 2 ? "Dashboard" : "Checkout Flow")")
                .font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color(red: 0.03, green: 0.02, blue: 0.06))
    }
    
    // ═══ USE CASE 1: Checkout payment screen ═══
    
    private var checkoutCanvas: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Checkout flow
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        miniScreen("Cart", icon: "cart", active: false)
                        Image(systemName: "arrow.right").foregroundStyle(Color(white: 0.15))
                        miniScreen("Shipping", icon: "shippingbox", active: false)
                        Image(systemName: "arrow.right").foregroundStyle(Color(white: 0.15))
                        miniScreen("Payment", icon: "creditcard", active: true)
                        Image(systemName: "arrow.right").foregroundStyle(Color(white: 0.15))
                        miniScreen("Confirm", icon: "checkmark.circle", active: false)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 12)
                
                Divider().opacity(0.1).padding(.horizontal, 16)
                
                // Payment screen detail
                if engine.designFixed {
                    fixedPaymentScreen
                } else {
                    ZStack {
                        crowdedPaymentScreen
                        if engine.showDesignOverlay {
                            patternOverlay
                        }
                    }
                }
            }
        }
    }
    
    private var crowdedPaymentScreen: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAYMENT").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color(white: 0.4))
            
            formField("Card Number", required: true)
            formField("Expiry / CVV", required: true)
            formField("Billing Address", required: false)
            formField("Coupon Code", required: false)
            formField("Delivery Note", required: false)
            formField("Billing Options", required: false)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(.indigo.opacity(0.3))
                .frame(height: 36)
                .overlay(Text("Confirm Payment").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.white))
        }
        .padding(16)
    }
    
    private var fixedPaymentScreen: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAYMENT").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color(white: 0.4))
            
            formField("Card Number", required: true)
            formField("Expiry / CVV", required: true)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(.indigo.opacity(0.4))
                .frame(height: 36)
                .overlay(Text("Pay Now").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.white))
            
            HStack(spacing: 6) {
                Image(systemName: "chevron.right").font(.system(size: 8))
                Text("More details (coupon, billing, delivery note)")
                    .font(.system(size: 10, design: .monospaced))
            }
            .foregroundStyle(Color(white: 0.4))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
    }
    
    // ═══ Pattern Overlay (transparent guide) ═══
    
    private var patternOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PATTERN OVERLAY")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(.cyan)
            
            // Show what should stay
            HStack(spacing: 6) {
                Image(systemName: "eye.fill").font(.system(size: 8)).foregroundStyle(.green)
                Text("KEEP VISIBLE").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.green)
            }
            overlayField("Card Number", keep: true)
            overlayField("Expiry / CVV", keep: true)
            
            // Show primary action position
            RoundedRectangle(cornerRadius: 6)
                .stroke(.green, style: StrokeStyle(lineWidth: 2, dash: [4]))
                .frame(height: 30)
                .overlay(Text("← Primary action here").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.green))
            
            // Show what to collapse
            HStack(spacing: 6) {
                Image(systemName: "eye.slash.fill").font(.system(size: 8)).foregroundStyle(.orange)
                Text("COLLAPSE THESE").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.orange)
            }
            overlayField("Billing Address", keep: false)
            overlayField("Coupon Code", keep: false)
            overlayField("Delivery Note", keep: false)
        }
        .padding(14)
        .background(Color(red: 0, green: 0.1, blue: 0.15).opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.cyan.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
        )
        .padding(8)
    }
    
    private func overlayField(_ label: String, keep: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: keep ? "checkmark.circle" : "minus.circle")
                .font(.system(size: 8))
                .foregroundStyle(keep ? .green : .orange)
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(keep ? .green.opacity(0.8) : .orange.opacity(0.6))
                .strikethrough(!keep, color: .orange.opacity(0.4))
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
    }
    
    // ═══ USE CASE 2: Dashboard filter bar ═══
    
    private var dashboardCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch engine.designAppliedOption {
                case "twolevel": twoLevelDashboard
                case "progressive": progressiveDashboard
                default: crowdedDashboard // "keepall" or not yet applied
                }
                
                // KPI cards row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        kpiCard("Revenue", value: "$1.2M", change: "+12%", color: .cyan)
                        kpiCard("Users", value: "48.3K", change: "+8%", color: .indigo)
                        kpiCard("Sessions", value: "126K", change: "-3%", color: .orange)
                        kpiCard("Conversion", value: "3.2%", change: "+0.4%", color: .green)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                
                // Charts
                HStack(spacing: 12) {
                    mockChart("Revenue Trend", color: .cyan)
                    mockChart("Active Users", color: .indigo)
                }
                .padding(.horizontal, 16)
                
                // Table preview
                tablePreview
                    .padding(16)
            }
        }
    }
    
    private var crowdedDashboard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FILTERS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.4))
                .padding(.horizontal, 16).padding(.top, 12)
            
            // All filters jammed together, no hierarchy
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    interactiveFilter("Date Range", icon: "calendar")
                    interactiveFilter("Region", icon: "globe")
                    interactiveFilter("Product", icon: "shippingbox")
                    interactiveFilter("Team", icon: "person.3")
                    interactiveFilter("Segment", icon: "chart.pie")
                    interactiveFilter("Compare", icon: "arrow.left.arrow.right")
                    interactiveFilter("YoY", icon: "arrow.up.arrow.down")
                    interactiveFilter("Export", icon: "square.and.arrow.up")
                    interactiveFilter("Share", icon: "paperplane")
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func interactiveFilter(_ label: String, icon: String) -> some View {
        let isSelected = selectedFilters.contains(label)
        return Button {
            if isSelected { _ = selectedFilters.remove(label) }
            else { _ = selectedFilters.insert(label) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 8))
                Text(label).font(.system(size: 9, design: .monospaced))
                if isSelected {
                    Image(systemName: "xmark").font(.system(size: 6))
                }
            }
            .foregroundStyle(isSelected ? .cyan : Color(white: 0.6))
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(
                isSelected ? Color.cyan.opacity(0.1) : Color.white.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(
                    isSelected ? .cyan.opacity(0.3) : Color.white.opacity(0.05)
                )
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private let advancedFilterDefs: [(String, String)] = [
        ("Team", "person.3"), ("Segment", "chart.pie"),
        ("Compare", "arrow.left.arrow.right"), ("YoY", "arrow.up.arrow.down"),
        ("Share", "paperplane"), ("Custom", "slider.horizontal.3"),
    ]
    
    private var twoLevelDashboard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FILTERS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.4))
                .padding(.horizontal, 16).padding(.top, 12)
            
            twoLevelPrimaryRow
            
            if twoLevelDrawerOpen {
                twoLevelDrawerContent
            }
        }
    }
    
    private var twoLevelPrimaryRow: some View {
        HStack(spacing: 6) {
            twoLevelToggle("Date Range", icon: "calendar")
            twoLevelToggle("Region", icon: "globe")
            twoLevelToggle("Product", icon: "shippingbox")
            
            ForEach(Array(twoLevelPinned).sorted(), id: \.self) { name in
                if let f = advancedFilterDefs.first(where: { $0.0 == name }) {
                    twoLevelToggle(f.0, icon: f.1)
                }
            }
            
            Spacer()
            twoLevelDrawerButton
            exportButton
        }
        .padding(.horizontal, 16)
    }
    
    private var twoLevelDrawerButton: some View {
        let count = advancedFilterDefs.count - twoLevelPinned.count
        return Button {
            withAnimation(.spring(response: 0.25)) { twoLevelDrawerOpen.toggle() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease").font(.system(size: 9))
                Text("All Filters").font(.system(size: 9, design: .monospaced))
                Text("\(count)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Color.white.opacity(0.15), in: Capsule())
                Image(systemName: twoLevelDrawerOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 7))
            }
            .foregroundStyle(twoLevelDrawerOpen ? .cyan : Color(white: 0.5))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(
                twoLevelDrawerOpen ? Color.cyan.opacity(0.08) : Color.white.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(
                twoLevelDrawerOpen ? .cyan.opacity(0.3) : Color.white.opacity(0.05)
            ))
        }
        .buttonStyle(.plain)
    }
    
    private var exportButton: some View {
        Button {
            withAnimation { exportTapped = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { exportTapped = false }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: exportTapped ? "checkmark" : "square.and.arrow.up").font(.system(size: 9))
                Text(exportTapped ? "Exported!" : "Export").font(.system(size: 9, design: .monospaced))
            }
            .foregroundStyle(exportTapped ? .green : .blue)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background((exportTapped ? Color.green : .blue).opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private var twoLevelDrawerContent: some View {
        let unpinned = advancedFilterDefs.filter { !twoLevelPinned.contains($0.0) }
        return VStack(alignment: .leading, spacing: 6) {
            Text("ADVANCED FILTERS")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.35))
            
            ForEach(unpinned, id: \.0) { name, icon in
                drawerFilterRow(name: name, icon: icon)
            }
            
            if unpinned.isEmpty {
                Text("All filters pinned to primary row")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(white: 0.3))
            }
        }
        .padding(12)
        .background(Color.cyan.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.cyan.opacity(0.08)))
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func drawerFilterRow(name: String, icon: String) -> some View {
        let rowBg = Color.white.opacity(0.02)
        let pinBg = Color.cyan.opacity(0.06)
        return HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 9)).foregroundStyle(.cyan).frame(width: 14)
            Text(name).font(.system(size: 10, design: .monospaced)).foregroundStyle(Color(white: 0.7))
            Spacer()
            Button {
                withAnimation(.spring(response: 0.2)) {
                    _ = twoLevelPinned.insert(name)
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "pin").font(.system(size: 8))
                    Text("Pin").font(.system(size: 8, design: .monospaced))
                }
                .foregroundStyle(Color.cyan.opacity(0.6))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(pinBg, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(rowBg, in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func twoLevelToggle(_ label: String, icon: String) -> some View {
        let isActive = twoLevelActive.contains(label)
        let isPinned = twoLevelPinned.contains(label)
        return HStack(spacing: 4) {
            Button {
                withAnimation(.spring(response: 0.2)) {
                    if isActive { _ = twoLevelActive.remove(label) }
                    else { _ = twoLevelActive.insert(label) }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 8))
                    Text(label).font(.system(size: 9, design: .monospaced))
                    if isActive {
                        Image(systemName: "xmark").font(.system(size: 6))
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isPinned {
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        _ = twoLevelPinned.remove(label)
                        _ = twoLevelActive.remove(label)
                    }
                } label: {
                    Image(systemName: "pin.slash").font(.system(size: 7)).foregroundStyle(.orange.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(isActive ? .cyan : Color(white: 0.6))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(
            isActive ? Color.cyan.opacity(0.1) : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(
            isActive ? .cyan.opacity(0.3) : Color.white.opacity(0.04)
        ))
    }
    
    // ═══ Progressive Disclosure Dashboard ═══
    
    private let allProgressiveFilters: [(String, String)] = [
        ("Date Range", "calendar"), ("Region", "globe"), ("Product", "shippingbox"),
        ("Team", "person.3"), ("Segment", "chart.pie"), ("Compare", "arrow.left.arrow.right"),
        ("YoY", "arrow.up.arrow.down"),
    ]
    
    private var progressiveDashboard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FILTERS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.4))
                .padding(.horizontal, 16).padding(.top, 12)
            
            progressiveFilterBar
            
            if progressivePickerOpen {
                progressivePickerDropdown
            }
            
            if progressiveAdded.isEmpty {
                Text("Filters appear as you interact with the data")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(white: 0.3))
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var progressiveFilterBar: some View {
        HStack(spacing: 6) {
            ForEach(progressiveAdded, id: \.self) { name in
                progressiveChip(name: name)
            }
            
            Button {
                withAnimation(.spring(response: 0.25)) { progressivePickerOpen.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle").font(.system(size: 9))
                    Text("Add Filter").font(.system(size: 9, design: .monospaced))
                }
                .foregroundStyle(progressivePickerOpen ? .white : .cyan)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(
                    progressivePickerOpen ? Color.cyan.opacity(0.2) : .cyan.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.cyan.opacity(0.2)))
            }
            .buttonStyle(.plain)
            
            Spacer()
            exportButton
        }
        .padding(.horizontal, 16)
    }
    
    private func progressiveChip(name: String) -> some View {
        let icon = allProgressiveFilters.first(where: { $0.0 == name })?.1 ?? "circle"
        return HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8))
            Text(name).font(.system(size: 9, design: .monospaced))
            Button {
                withAnimation(.spring(response: 0.2)) {
                    progressiveAdded.removeAll { $0 == name }
                }
            } label: {
                Image(systemName: "xmark").font(.system(size: 7)).foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.cyan)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.cyan.opacity(0.25)))
        .transition(.scale.combined(with: .opacity))
    }
    
    private var progressivePickerDropdown: some View {
        let available = allProgressiveFilters.filter { f in !progressiveAdded.contains(f.0) }
        return VStack(alignment: .leading, spacing: 4) {
            if available.isEmpty {
                Text("All filters added")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(white: 0.3))
                    .padding(8)
            } else {
                ForEach(available, id: \.0) { name, icon in
                    pickerRow(name: name, icon: icon, remainingCount: available.count)
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.03, green: 0.06, blue: 0.1), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.cyan.opacity(0.1)))
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func pickerRow(name: String, icon: String, remainingCount: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.2)) {
                progressiveAdded.append(name)
                if remainingCount <= 1 { progressivePickerOpen = false }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 9)).foregroundStyle(.cyan).frame(width: 14)
                Text(name).font(.system(size: 10, design: .monospaced)).foregroundStyle(Color(white: 0.7))
                Spacer()
                Image(systemName: "plus").font(.system(size: 9)).foregroundStyle(.cyan.opacity(0.5))
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    // ═══ Dashboard Components ═══
    
    private func kpiCard(_ title: String, value: String, change: String, color: Color) -> some View {
        let isSelected = selectedKPI == title
        let detailMap: [String: String] = [
            "Revenue": "↑ 12% vs last month\nTop region: US West",
            "Users": "↑ 8% week over week\nNew signups: 3.2K",
            "Sessions": "↓ 3% from peak\nAvg duration: 4m 12s",
            "Conversion": "↑ 0.4pp improvement\nBest funnel: organic"
        ]
        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedKPI = isSelected ? nil : title
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(Color(white: 0.4))
                Text(value).font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundStyle(color)
                Text(change)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(change.hasPrefix("-") ? .red : .green)
                if isSelected, let detail = detailMap[title] {
                    Divider().opacity(0.15)
                    Text(detail)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(white: 0.5))
                        .lineSpacing(2)
                }
            }
            .padding(12)
            .frame(width: isSelected ? 150 : 120)
            .background(color.opacity(isSelected ? 0.1 : 0.04), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(isSelected ? 0.4 : 0.1)))
        }
        .buttonStyle(.plain)
    }
    
    private let tableData: [(String, String, String, String, String)] = [
        ("Alice K.", "US West", "$4,200", "142", "Top converter · 3.8% rate"),
        ("Bob M.", "EU", "$3,100", "98", "Highest avg order value"),
        ("Chen W.", "APAC", "$5,800", "203", "Most sessions this month"),
        ("Dana R.", "US East", "$2,900", "76", "New user · first 30 days"),
    ]
    
    private var tablePreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DATA TABLE").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(Color(white: 0.3))
                .padding(.bottom, 6)
            
            HStack(spacing: 0) {
                tableCell("User", width: 100, header: true)
                tableCell("Region", width: 80, header: true)
                tableCell("Revenue", width: 80, header: true)
                tableCell("Sessions", width: 70, header: true)
            }
            .background(Color.white.opacity(0.04))
            
            ForEach(0..<4, id: \.self) { i in
                tableRow(index: i)
            }
        }
    }
    
    private func tableRow(index i: Int) -> some View {
        let isSel = selectedTableRow == i
        let row = tableData[i]
        return Button {
            withAnimation(.spring(response: 0.2)) {
                selectedTableRow = isSel ? nil : i
            }
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    tableCell(row.0, width: 100, header: false)
                    tableCell(row.1, width: 80, header: false)
                    tableCell(row.2, width: 80, header: false)
                    tableCell(row.3, width: 70, header: false)
                }
                if isSel {
                    tableRowDetail(row.4)
                }
            }
            .background(isSel ? Color.cyan.opacity(0.06) : i % 2 == 0 ? Color.white.opacity(0.01) : .clear)
            .overlay(alignment: .leading) {
                if isSel { Rectangle().fill(.cyan).frame(width: 2) }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func tableRowDetail(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle").font(.system(size: 8)).foregroundStyle(.cyan)
            Text(text)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.cyan.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func tableCell(_ text: String, width: CGFloat, header: Bool) -> some View {
        Text(text)
            .font(.system(size: header ? 8 : 9, weight: header ? .bold : .regular, design: .monospaced))
            .foregroundStyle(header ? Color(white: 0.4) : Color(white: 0.6))
            .frame(width: width, alignment: .leading)
            .padding(.vertical, 5).padding(.horizontal, 6)
    }
    
    // ═══ Helpers ═══
    
    private func miniScreen(_ name: String, icon: String, active: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(active ? .indigo : Color(white: 0.25))
            Text(name).font(.system(size: 9, design: .monospaced)).foregroundStyle(active ? .primary : Color(white: 0.3))
        }
        .padding(8)
        .background(active ? Color.indigo.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? .indigo.opacity(0.3) : .clear))
    }
    
    private func formField(_ label: String, required: Bool) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 10, design: .monospaced)).foregroundStyle(Color(white: 0.6))
            if !required {
                Text("optional").font(.system(size: 7, design: .monospaced)).foregroundStyle(Color(white: 0.25))
            }
            Spacer()
        }
        .padding(8)
        .background(Color.white.opacity(required ? 0.04 : 0.02), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(required ? 0.06 : 0.03)))
    }
    
    private func filterPill(_ label: String, icon: String, highlight: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8))
            Text(label).font(.system(size: 9, design: .monospaced))
        }
        .foregroundStyle(highlight ? .orange : Color(white: 0.6))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(highlight ? Color.orange.opacity(0.08) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(highlight ? .orange.opacity(0.3) : Color.white.opacity(0.04)))
    }
    
    private func mockChart(_ title: String, color: Color) -> some View {
        let heights: [CGFloat] = [35, 48, 28, 55, 42, 60, 32, 50]
        let labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug"]
        let isRevenue = title.contains("Revenue")
        let values: [String] = isRevenue ?
            ["$98K", "$134K", "$78K", "$153K", "$117K", "$167K", "$89K", "$139K"] :
            ["5.2K", "7.1K", "4.1K", "8.1K", "6.2K", "8.8K", "4.7K", "7.4K"]
        
        return VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(color)
            
            chartTooltip(title: title, labels: labels, values: values, color: color)
            
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(heights.enumerated()), id: \.offset) { i, h in
                    chartBar(chartTitle: title, index: i, height: h, label: labels[i], color: color)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
    }
    
    @ViewBuilder
    private func chartTooltip(title: String, labels: [String], values: [String], color: Color) -> some View {
        if let sel = selectedChartBar, sel.chart == title {
            HStack(spacing: 4) {
                Text(labels[sel.index]).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(color)
                Text(values[sel.index]).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.white)
            }
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.2), in: Capsule())
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private func chartBar(chartTitle: String, index i: Int, height h: CGFloat, label: String, color: Color) -> some View {
        let isSel = selectedChartBar?.chart == chartTitle && selectedChartBar?.index == i
        return Button {
            withAnimation(.spring(response: 0.2)) {
                if isSel { selectedChartBar = nil }
                else { selectedChartBar = (chart: chartTitle, index: i) }
            }
        } label: {
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSel ? color.opacity(0.8) : color.opacity(0.3))
                    .frame(width: 12, height: isSel ? h + 4 : h)
                Text(label)
                    .font(.system(size: 6, design: .monospaced))
                    .foregroundStyle(isSel ? color : Color(white: 0.25))
            }
        }
        .buttonStyle(.plain)
    }
}

// ══════════════════════════════════════
// MARK: - Journey Panel Window
// ══════════════════════════════════════

struct JourneyPanelWindow: View {
    @Environment(ScenarioEngine.self) private var engine
    @State private var expandedStep: Int? = nil
    
    private let steps: [(name: String, drop: Int, friction: Bool, insights: [String])] = [
        ("Cart", 12, false, ["Most users spend < 30s here"]),
        ("Shipping", 28, true, ["Address entry is #1 friction", "Autofill reduces drop-off 40%"]),
        ("Payment", 8, false, ["Forced signup = 60% abandon"]),
        ("Confirm", 3, false, ["Clear summary cuts support tickets"]),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            journeyHeader
            Divider().opacity(0.15)
            journeyBody
        }
        .background(Color(red: 0.03, green: 0.03, blue: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var journeyHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "point.3.connected.trianglepath.dotted").foregroundStyle(.indigo)
            Text("Journey Intelligence").font(.system(size: 12, weight: .bold, design: .monospaced))
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color(red: 0.02, green: 0.02, blue: 0.06))
    }
    
    private var journeyBody: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    stepRow(step, index: i)
                    if i < steps.count - 1 {
                        stepConnector(step)
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func stepRow(_ step: (name: String, drop: Int, friction: Bool, insights: [String]), index: Int) -> some View {
        let c: Color = step.friction ? .orange : .indigo
        return Button {
            withAnimation(.spring(response: 0.25)) { expandedStep = expandedStep == index ? nil : index }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(c.opacity(0.2)).frame(width: 28, height: 28)
                        Text("\(index + 1)").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(c)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.name).font(.system(size: 12, weight: .bold))
                        Text("Drop-off: \(step.drop)%").font(.system(size: 10, design: .monospaced)).foregroundStyle(step.friction ? c : .secondary)
                    }
                    Spacer()
                    if step.friction {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    }
                }
                if expandedStep == index {
                    ForEach(step.insights, id: \.self) { ins in
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "lightbulb.fill").font(.system(size: 8)).foregroundStyle(.yellow)
                            Text(ins).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                        }.padding(.leading, 36)
                    }
                }
            }
            .padding(10)
            .background(step.friction ? Color.orange.opacity(0.04) : .clear)
        }
        .buttonStyle(.plain)
    }
    
    private func stepConnector(_ step: (name: String, drop: Int, friction: Bool, insights: [String])) -> some View {
        let c: Color = step.friction ? .orange : Color(white: 0.1)
        return VStack(spacing: 3) {
            Rectangle().fill(c.opacity(0.5)).frame(width: 2, height: 12)
            Text("-\(step.drop)%").font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(step.friction ? .orange : .secondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(step.friction ? Color.orange.opacity(0.1) : Color.white.opacity(0.04), in: Capsule())
            Rectangle().fill(c.opacity(0.5)).frame(width: 2, height: 12)
        }.frame(maxWidth: .infinity)
    }
}

// ══════════════════════════════════════
// MARK: - Digital Twin — Holographic Interface
// ══════════════════════════════════════

struct DigitalTwinWindow: View {
    @Environment(ScenarioEngine.self) private var engine
    
    var body: some View {
        if engine.twinActive {
            VStack(spacing: 0) {
                twinIdentity
                Divider().opacity(0.1)
                twinConversation
                if !engine.twinChoices.isEmpty {
                    Divider().opacity(0.1)
                    twinActionBar
                }
            }
            .background(
                ZStack {
                    Color(red: 0.02, green: 0.03, blue: 0.08)
                    // Holographic scan lines
                    LinearGradient(colors: [.cyan.opacity(0.02), .clear, .cyan.opacity(0.01)],
                                   startPoint: .top, endPoint: .bottom)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.cyan.opacity(0.15), lineWidth: 1)
            )
        } else {
            Color.clear.frame(width: 1, height: 1)
        }
    }
    
    // ── Borderless banner image + identity overlay ──
    private var twinIdentity: some View {
        ZStack(alignment: .bottom) {
            // Large banner image, borderless, top half of window
            Image(engine.twinImage)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
                .opacity(0.7)
                .overlay(
                    // Gradient fade at bottom
                    LinearGradient(
                        colors: [.clear, .clear, Color(red: 0.02, green: 0.03, blue: 0.08)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    // Scan line effect
                    VStack(spacing: 3) {
                        ForEach(0..<30, id: \.self) { _ in
                            Rectangle().fill(.cyan.opacity(0.03)).frame(height: 1)
                            Spacer().frame(height: 5)
                        }
                    }
                )
            
            // Identity info overlaid at bottom of banner
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Spacer()
                    Button {
                        engine.twinActive = false
                        engine.requestClose("digital-twin")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text(engine.twinName)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("DIGITAL TWIN")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.cyan, in: Capsule())
                }
                
                Text(engine.twinRole)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(white: 0.6))
                
                HStack(spacing: 8) {
                    statusPill("CONNECTED", color: .green)
                    statusPill("HIGH MATCH", color: .cyan)
                    if engine.twinBusy {
                        statusPill("PERSON BUSY", color: .orange)
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 180)
        .background(Color(red: 0.02, green: 0.03, blue: 0.06))
    }
    
    private func statusPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 7, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.1), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.2)))
    }
    
    // ── Conversation as holographic text panels ──
    private var twinConversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Connection beacon
                    connectionBeacon
                    
                    ForEach(engine.twinMessages) { msg in
                        messagePanel(msg).id(msg.id)
                    }
                }
                .padding(14)
            }
            .onChange(of: engine.twinMessages.count) { _, _ in
                if let last = engine.twinMessages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
    
    private var connectionBeacon: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(.cyan.opacity(0.1)).frame(width: 32, height: 32)
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 14)).foregroundStyle(.cyan)
                    .symbolEffect(.breathe, options: .repeating)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Twin link established")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                Text("AI trained on \(engine.twinName)'s solutions and reasoning patterns")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color(white: 0.4))
            }
        }
        .padding(10)
        .background(.cyan.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.cyan.opacity(0.1)))
    }
    
    private func messagePanel(_ msg: ScenarioEngine.TwinMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Sender label
            HStack(spacing: 6) {
                if !msg.isUser {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan.opacity(0.6))
                }
                Text(msg.isUser ? "YOU" : engine.twinName.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(msg.isUser ? .cyan : .orange)
                
                if !msg.isUser {
                    Text("· TWIN").font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(white: 0.3))
                }
            }
            
            // Message content — holographic panel style
            Text(msg.text)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(msg.isUser ? Color(white: 0.9) : .white)
                .lineSpacing(4)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    msg.isUser ?
                        Color.cyan.opacity(0.06) :
                        Color(red: 0.04, green: 0.06, blue: 0.12),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(msg.isUser ? .cyan.opacity(0.15) : Color.white.opacity(0.04))
                )
        }
    }
    
    // ── Action buttons INSIDE twin window ──
    private var twinActionBar: some View {
        VStack(spacing: 6) {
            Text("ASK THE TWIN")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.35))
            
            ForEach(engine.twinChoices) { choice in
                Button {
                    engine.runTwinChoice(choice.action)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path")
                            .font(.system(size: 9))
                            .foregroundStyle(.cyan)
                        Text(choice.label)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color(white: 0.8))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(white: 0.3))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Color.cyan.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.cyan.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(red: 0.02, green: 0.03, blue: 0.06))
    }
}
