// CodeEditorWindow.swift — CodeForge IDE + Embedded Terminal
// Terminal is at the bottom. Command buttons IN the terminal.
// Code animates line-by-line when updated.

import SwiftUI

struct CodeEditorWindow: View {
    @Environment(ScenarioEngine.self) private var engine
    @State private var termExpanded = true
    
    private let fileOrder = ["auth", "token", "user", "routes", "authtest", "handler", "server", "state"]
    private let fileColors: [String: Color] = [
        "auth": .cyan, "token": .blue, "user": .pink, "routes": .green,
        "authtest": .purple, "handler": .orange, "server": .yellow, "state": .mint
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider().opacity(0.15)
            HStack(spacing: 0) {
                fileTree
                Divider().opacity(0.1)
                VStack(spacing: 0) {
                    editorArea
                    Divider().opacity(0.15)
                    embeddedTerminal
                }
            }
        }
        .background(Color(red: 0.04, green: 0.06, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // ═══ Title Bar ═══
    private var titleBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 12)).foregroundStyle(.cyan)
            Text("CodeForge").font(.system(size: 12, weight: .bold, design: .monospaced))
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "waveform.circle.fill").font(.system(size: 8)).foregroundStyle(.cyan)
                Text("Whisper active").font(.system(size: 9, design: .monospaced)).foregroundStyle(.cyan)
            }
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(.cyan.opacity(0.08), in: Capsule())
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color(red: 0.03, green: 0.05, blue: 0.1))
    }
    
    // ═══ File Tree ═══
    private var fileTree: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EXPLORER")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 8)
            ForEach(fileOrder, id: \.self) { key in
                if let file = engine.codeFiles[key] {
                    fileRow(key: key, label: file.label)
                }
            }
            Spacer()
        }
        .frame(width: 170)
        .background(Color(red: 0.03, green: 0.04, blue: 0.09))
    }
    
    private func fileRow(key: String, label: String) -> some View {
        Button { engine.currentFile = key } label: {
            HStack(spacing: 6) {
                Circle().fill(fileColors[key] ?? .gray).frame(width: 6, height: 6)
                Text(label).font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(engine.currentFile == key ? .white : Color(white: 0.45))
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(engine.currentFile == key ? Color.cyan.opacity(0.1) : .clear)
            .overlay(alignment: .leading) {
                if engine.currentFile == key {
                    Rectangle().fill(.cyan).frame(width: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // ═══ Editor Area ═══
    private var editorArea: some View {
        VStack(spacing: 0) {
            tabBar
            breadcrumb
            codeScroll
            statusBar
        }
    }
    
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(fileOrder, id: \.self) { key in
                    if let file = engine.codeFiles[key] {
                        Button { engine.currentFile = key } label: {
                            Text(file.label)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(engine.currentFile == key ? .white : Color(white: 0.3))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(engine.currentFile == key ? Color(white: 0.08) : .clear)
                                .overlay(alignment: .top) {
                                    if engine.currentFile == key {
                                        Rectangle().fill(.cyan).frame(height: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .background(Color(red: 0.03, green: 0.04, blue: 0.09))
    }
    
    private var breadcrumb: some View {
        HStack {
            if let file = engine.codeFiles[engine.currentFile] {
                Text(file.path).font(.system(size: 10, design: .monospaced)).foregroundStyle(Color(white: 0.3))
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 4)
        .background(Color(red: 0.03, green: 0.05, blue: 0.1))
    }
    
    private var codeScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if let file = engine.codeFiles[engine.currentFile] {
                    codeContent(file.code)
                }
            }
            .background(Color(red: 0.04, green: 0.06, blue: 0.12))
            .id(engine.currentFile)
            .onChange(of: engine.codeFiles[engine.currentFile]?.code) { _, _ in
                // Scroll to bottom of changed code to show the fix
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    proxy.scrollTo("code-end", anchor: .bottom)
                }
            }
        }
    }
    
    private var statusBar: some View {
        HStack(spacing: 14) {
            Label("auth-refactor", systemImage: "arrow.triangle.branch")
                .font(.system(size: 9, design: .monospaced)).foregroundStyle(.green)
            Spacer()
            Text("UTF-8 · \(engine.currentFile.hasSuffix("js") || engine.codeFiles[engine.currentFile]?.label.hasSuffix(".js") == true ? "JavaScript" : "Swift")")
                .font(.system(size: 9, design: .monospaced)).foregroundStyle(Color(white: 0.3))
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(Color(red: 0.03, green: 0.04, blue: 0.09))
    }
    
    // ═══ Embedded Terminal ═══
    private var embeddedTerminal: some View {
        VStack(spacing: 0) {
            // Terminal header with toggle
            HStack(spacing: 6) {
                Image(systemName: "terminal").font(.system(size: 10)).foregroundStyle(.green)
                Text("Terminal").font(.system(size: 11, weight: .semibold, design: .monospaced))
                Spacer()
                Circle().fill(.green).frame(width: 5, height: 5).shadow(color: .green, radius: 3)
                Button { withAnimation { termExpanded.toggle() } } label: {
                    Image(systemName: termExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(red: 0.02, green: 0.02, blue: 0.05))
            
            if termExpanded {
                // Terminal output
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(engine.terminalLines) { line in
                                Text(line.text)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(line.type.color)
                                    .id(line.id)
                            }
                        }
                        .padding(10)
                    }
                    .frame(height: 140)
                    .onChange(of: engine.terminalLines.count) { _, _ in
                        if let last = engine.terminalLines.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                .background(Color(red: 0.02, green: 0.02, blue: 0.04))
                
                // Command buttons — large and noticeable
                if !engine.terminalCommands.isEmpty {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Circle().fill(.green).frame(width: 6, height: 6)
                                .shadow(color: .green, radius: 4)
                            Text("READY TO RUN")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                        
                        ForEach(engine.terminalCommands) { cmd in
                            Button {
                                engine.runTerminalCommand(cmd.action)
                            } label: {
                                HStack(spacing: 8) {
                                    Text("▶").font(.system(size: 12))
                                    Text("$ \(cmd.label)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    Spacer()
                                    Text("tap to run")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.green.opacity(0.6))
                                }
                                .foregroundStyle(.green)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.green.opacity(0.4), lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                            .hoverEffect(.highlight)
                        }
                    }
                    .padding(10)
                    .background(Color.green.opacity(0.03))
                }
            }
        }
    }
    
    // ═══ Code Rendering ═══
    private func codeContent(_ code: String) -> some View {
        let lines = code.components(separatedBy: "\n")
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                codeLine(i + 1, line)
            }
            // Typing cursor
            if engine.isTyping {
                HStack(spacing: 0) {
                    Spacer().frame(width: 50)
                    Rectangle()
                        .fill(.cyan)
                        .frame(width: 2, height: 14)
                        .opacity(1)
                        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: engine.isTyping)
                }
                .padding(.vertical, 2)
            }
            Color.clear.frame(height: 1).id("code-end")
        }
        .padding(.vertical, 8)
    }
    
    private func codeLine(_ num: Int, _ line: String) -> some View {
        let rel = hiveRelevance(line)
        let isNew = line.contains("✅")
        return HStack(alignment: .top, spacing: 0) {
            Text("\(num)").font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color(white: 0.18))
                .frame(width: 36, alignment: .trailing).padding(.trailing, 8)
            
            if rel > 0 {
                RoundedRectangle(cornerRadius: 1.5).fill(.cyan.opacity(rel * 0.6))
                    .frame(width: 3)
                    .shadow(color: .cyan.opacity(rel * 0.3), radius: rel > 0.7 ? 4 : 0)
                    .padding(.trailing, 6)
            } else {
                Color.clear.frame(width: 3).padding(.trailing, 6)
            }
            
            Text(line).font(.system(size: 12, design: .monospaced))
                .foregroundStyle(syntaxColor(line))
            
            Spacer()
            
            if line.contains("TODO") {
                hiveHint
            }
        }
        .padding(.vertical, 0.5)
        .background(
            line.contains("TODO") ? Color.orange.opacity(0.05) :
            isNew ? Color.green.opacity(0.04) : .clear
        )
    }
    
    private var hiveHint: some View {
        HStack(spacing: 3) {
            Image(systemName: "waveform.circle.fill").font(.system(size: 6))
            Text("127 devs solved this").font(.system(size: 8, design: .monospaced))
        }
        .foregroundStyle(.cyan.opacity(0.6))
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(.cyan.opacity(0.06), in: Capsule())
        .padding(.trailing, 8)
    }
    
    private func hiveRelevance(_ line: String) -> Double {
        if line.contains("TODO") { return 1.0 }
        if line.contains("✅") { return 0.8 }
        if line.contains("⚠️") { return 0.9 }
        if line.contains("refreshAccessToken") || line.contains("updateUserState") { return 0.6 }
        return 0
    }
    
    private func syntaxColor(_ line: String) -> Color {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("//") && t.contains("✅") { return .green }
        if t.hasPrefix("//") { return Color(red: 0.3, green: 0.55, blue: 0.35) }
        let kw = ["import", "func ", "let ", "var ", "guard", "return", "throw", "final",
                   "class ", "struct ", "try", "else", "defer", "@", "const ", "async ",
                   "await ", "require(", "module."]
        if kw.contains(where: { t.hasPrefix($0) }) { return Color(red: 0.85, green: 0.5, blue: 0.7) }
        return Color(white: 0.82)
    }
}
