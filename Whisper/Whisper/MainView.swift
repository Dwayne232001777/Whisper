// MainView.swift — Narrator Window
// Shows the story feed with choices. User picks actions here.

import SwiftUI

struct MainView: View {
    @Environment(ScenarioEngine.self) private var engine
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        Group {
            if !engine.started { roleSelectView }
            else { narratorFeed }
        }
        .glassBackgroundEffect()
        .onChange(of: engine.pendingOpens) { _, ids in
            for id in ids { openWindow(id: id) }
            engine.clearPending()
        }
        .onChange(of: engine.pendingCloses) { _, ids in
            for id in ids { dismissWindow(id: id) }
            engine.clearPending()
        }
    }
    
    // ═══ Role Select ═══
    
    private var roleSelectView: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48)).foregroundStyle(.cyan)
                .symbolEffect(.breathe, options: .repeating)
            VStack(spacing: 4) {
                Text("WHISPER")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                Text("2077 · SPATIAL INTELLIGENCE")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text("Choose your role. You are the character.")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                roleCard("laptopcomputer", "Developer", "JWT auth · Debug · Whisper-assisted fixes", .developer)
                roleCard("paintpalette", "UX Designer", "Checkout flow · Friction · Pattern whispers", .designer)
            }
        }
        .padding(32)
    }
    
    private func roleCard(_ icon: String, _ title: String, _ desc: String, _ role: ScenarioEngine.Role) -> some View {
        Button { engine.selectRole(role) } label: {
            VStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 28)).foregroundStyle(.cyan)
                Text(title).font(.system(size: 15, weight: .bold))
                Text(desc).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .frame(width: 180).padding(18)
            .background(.cyan.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.cyan.opacity(0.2)))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .hoverEffect(.lift)
    }
    
    // ═══ Narrator Feed ═══
    
    private var narratorFeed: some View {
        VStack(spacing: 0) {
            narratorHeader
            Divider().opacity(0.2)
            messageList
            Divider().opacity(0.2)
            choiceButtons
        }
        .animation(.easeInOut(duration: 0.2), value: engine.choices.count)
        .animation(.easeInOut(duration: 0.2), value: engine.messages.count)
    }
    
    private var narratorHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill").foregroundStyle(.cyan)
            Text("NARRATOR").font(.system(size: 12, weight: .bold, design: .monospaced))
            Text("· Whisper").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            Spacer()
            if let role = engine.role {
                Text(role.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.cyan.opacity(0.1), in: Capsule())
            }
            if engine.struggleScore > 0.1 { struggleChip }
            Button { engine.reset() } label: {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 10))
            }.buttonStyle(.bordered)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(engine.messages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                }
                .padding(12)
            }
            .onChange(of: engine.messages.count) { _, _ in
                if let last = engine.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
    
    private var choiceButtons: some View {
        Group {
            if !engine.choices.isEmpty {
                VStack(spacing: 5) {
                    Text("YOUR ACTION")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                        .padding(.top, 8)
                    ForEach(engine.choices) { choice in
                        choiceButton(choice)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func choiceButton(_ choice: ScenarioEngine.Choice) -> some View {
        Button { engine.pick(choice.action) } label: {
            HStack(spacing: 8) {
                Image(systemName: choice.icon)
                    .font(.system(size: 11)).foregroundStyle(.cyan).frame(width: 20)
                Text(choice.label)
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 9))
        .hoverEffect(.highlight)
        .disabled(!engine.choicesEnabled)
        .opacity(engine.choicesEnabled ? 1 : 0.4)
    }
    
    // ═══ Message Bubble ═══
    
    private func messageBubble(_ msg: ScenarioEngine.NarratorMessage) -> some View {
        let s = msgStyle(msg.type)
        return HStack(alignment: .top, spacing: 8) {
            if let icon = s.icon {
                Image(systemName: icon).font(.system(size: 9)).foregroundStyle(s.color)
                    .frame(width: 14).padding(.top, 3)
            }
            Text(msg.text)
                .font(.system(size: 12.5, weight: s.weight, design: .monospaced))
                .foregroundStyle(s.color).lineSpacing(3)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(s.bg, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private struct MStyle { let color: Color; let bg: Color; let icon: String?; let weight: Font.Weight }
    private func msgStyle(_ t: ScenarioEngine.NarratorMessage.MsgType) -> MStyle {
        switch t {
        case .narrator: return MStyle(color: .primary.opacity(0.85), bg: .clear, icon: nil, weight: .regular)
        case .action:   return MStyle(color: .primary.opacity(0.9), bg: .white.opacity(0.04), icon: "arrow.right", weight: .medium)
        case .hint:     return MStyle(color: .cyan.opacity(0.8), bg: .cyan.opacity(0.06), icon: "hand.tap", weight: .regular)
        case .whisper:  return MStyle(color: .cyan, bg: .cyan.opacity(0.08), icon: "waveform.circle.fill", weight: .medium)
        case .success:  return MStyle(color: .green, bg: .green.opacity(0.06), icon: "checkmark.circle", weight: .semibold)
        case .error:    return MStyle(color: .red.opacity(0.9), bg: .red.opacity(0.06), icon: "xmark.octagon", weight: .medium)
        }
    }
    
    private var struggleChip: some View {
        let c: Color = engine.struggleScore > 0.7 ? .red : engine.struggleScore > 0.4 ? .orange : .yellow
        return HStack(spacing: 4) {
            Circle().fill(c).frame(width: 5, height: 5).shadow(color: c, radius: 3)
            Text("\(Int(engine.struggleScore * 100))%").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(c)
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(c.opacity(0.1), in: Capsule())
    }
}
