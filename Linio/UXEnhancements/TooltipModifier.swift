//
//  TooltipModifier.swift
//  Linio
//
//  First-Use Tooltips für Feature-Entdeckung
//

import SwiftUI

// MARK: - Tooltip View

struct TooltipView: View {
    let text: String
    let arrowEdge: Edge
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.85))
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - First-Use Tooltip Modifier

struct FirstUseTooltipModifier: ViewModifier {
    let key: String
    let text: String
    let edge: Edge
    
    @AppStorage private var hasShown: Bool
    @State private var isVisible = false
    
    init(key: String, text: String, edge: Edge) {
        self.key = key
        self.text = text
        self.edge = edge
        self._hasShown = AppStorage(wrappedValue: false, "tooltip_\(key)")
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                if isVisible {
                    TooltipView(text: text, arrowEdge: oppositeEdge)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .onTapGesture { dismissTooltip() }
                        .padding(8)
                }
            }
            .onAppear {
                guard !hasShown else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isVisible = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.8) {
                    dismissTooltip()
                }
            }
    }
    
    private func dismissTooltip() {
        withAnimation(.easeOut(duration: 0.2)) { isVisible = false }
        hasShown = true
    }
    
    private var alignment: Alignment {
        switch edge {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
    
    private var oppositeEdge: Edge {
        switch edge {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
}

extension View {
    /// Zeigt einen Tooltip beim ersten Verwenden an
    func firstUseTooltip(key: String, text: String, edge: Edge = .bottom) -> some View {
        modifier(FirstUseTooltipModifier(key: key, text: text, edge: edge))
    }
}

// MARK: - Tooltip Keys

enum TooltipKey {
    static let swipeForLiveActivity = "swipe_live_activity"
}

#Preview("Tooltip") {
    Text("Beispiel")
        .padding()
        .background(Color.blue)
        .firstUseTooltip(key: "preview", text: "Wische für Optionen")
}
