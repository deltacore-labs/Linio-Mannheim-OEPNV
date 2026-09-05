//
//  PulsingIndicator.swift
//  Linio
//
//  Animierte Indikatoren für Live-Status und Verspätungen
//

import SwiftUI

// MARK: - Pulsing Dot Indicator

struct PulsingIndicator: View {
    let color: Color
    let size: CGFloat
    let isActive: Bool
    
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(color: Color = .green, size: CGFloat = 8, isActive: Bool = true) {
        self.color = color
        self.size = size
        self.isActive = isActive
    }
    
    var body: some View {
        ZStack {
            // Äußerer pulsierender Ring
            if isActive && !reduceMotion {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * 2, height: size * 2)
                    .scaleEffect(isPulsing ? 1.8 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
            }
            
            // Innerer fester Punkt
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            guard isActive && !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
        .onChange(of: isActive) { _, newValue in
            if !newValue { isPulsing = false }
        }
        .accessibilityLabel(isActive ? "Live" : "Inaktiv")
    }
}

// MARK: - Live Status Badge

struct LiveStatusBadge: View {
    let isActive: Bool
    let label: String
    
    init(isActive: Bool = true, label: String = "Live") {
        self.isActive = isActive
        self.label = label
    }
    
    var body: some View {
        HStack(spacing: 6) {
            PulsingIndicator(
                color: isActive ? .green : AppTheme.mutedSoft,
                size: 8,
                isActive: isActive
            )
            
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isActive ? .green : AppTheme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(isActive ? Color.green.opacity(0.12) : AppTheme.surfaceStrong)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isActive ? "Live-Tracking aktiv" : "Inaktiv")
    }
}

// MARK: - Delay Indicator with Animation

struct DelayIndicator: View {
    let minutes: Int
    @State private var isHighlighted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var color: Color {
        if minutes <= 0 { return .green }
        if minutes <= 3 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 3) {
            if minutes > 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
            }
            Text(minutes > 0 ? "+\(minutes)" : "±0")
                .font(.system(size: 11, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(isHighlighted ? 0.25 : 0.12))
        )
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .onAppear {
            guard minutes > 3 && !reduceMotion else { return }
            // Kurzer Aufmerksamkeits-Puls bei großen Verspätungen
            withAnimation(.easeInOut(duration: 0.3)) {
                isHighlighted = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHighlighted = false
                }
            }
        }
        .accessibilityLabel(delayAccessibilityLabel)
    }
    
    private var delayAccessibilityLabel: String {
        if minutes <= 0 { return "Pünktlich" }
        return "\(minutes) Minuten Verspätung"
    }
}

// MARK: - Previews

#Preview("Pulsing Indicators") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            PulsingIndicator(color: .green, isActive: true)
            PulsingIndicator(color: .orange, isActive: true)
            PulsingIndicator(color: .red, isActive: true)
        }
        
        HStack(spacing: 12) {
            LiveStatusBadge(isActive: true, label: "Aktiv")
            LiveStatusBadge(isActive: false, label: "Inaktiv")
        }
        
        HStack(spacing: 12) {
            DelayIndicator(minutes: 0)
            DelayIndicator(minutes: 2)
            DelayIndicator(minutes: 5)
            DelayIndicator(minutes: 12)
        }
    }
    .padding()
    .background(AppTheme.canvas)
}
