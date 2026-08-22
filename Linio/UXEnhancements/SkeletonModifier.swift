//
//  SkeletonModifier.swift
//  Linio
//
//  Skeleton Loading für bessere UX während Ladezeiten
//

import SwiftUI

// MARK: - Shimmer Shape

struct SkeletonShape: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = 6) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(shimmerGradient)
            .frame(width: width, height: height)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
    
    private var shimmerGradient: LinearGradient {
        let baseColor = AppTheme.surfaceStrong
        let highlightColor = AppTheme.hairline
        
        if reduceMotion {
            return LinearGradient(colors: [baseColor], startPoint: .leading, endPoint: .trailing)
        }
        
        return LinearGradient(
            stops: [
                .init(color: baseColor, location: max(0, phase - 0.3)),
                .init(color: highlightColor, location: phase),
                .init(color: baseColor, location: min(1, phase + 0.3))
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - TripCard Skeleton

struct TripCardSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.hairlineStrong)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 10) {
                // Time row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonShape(width: 140, height: 24, cornerRadius: 6)
                        SkeletonShape(width: 80, height: 14, cornerRadius: 4)
                    }
                    Spacer()
                    SkeletonShape(width: 60, height: 28, cornerRadius: 14)
                }
                
                // Meta row
                HStack(spacing: 8) {
                    SkeletonShape(width: 50, height: 12, cornerRadius: 4)
                    SkeletonShape(width: 30, height: 12, cornerRadius: 4)
                    SkeletonShape(width: 50, height: 12, cornerRadius: 4)
                }
                
                // Line badges
                HStack(spacing: 6) {
                    SkeletonShape(width: 64, height: 28, cornerRadius: 14)
                    SkeletonShape(width: 48, height: 28, cornerRadius: 14)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
        }
        .background(AppTheme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.hairline, lineWidth: 1))
        .shadow(color: AppTheme.shadowColor(), radius: 8, y: 4)
        .padding(.horizontal)
        .accessibilityLabel("Verbindung wird geladen")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Skeleton List for Connections

struct ConnectionsSkeletonList: View {
    let count: Int
    
    init(count: Int = 3) {
        self.count = count
    }
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                TripCardSkeleton()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verbindungen werden geladen")
    }
}

// MARK: - View Extension

extension View {
    /// Zeigt einen Skeleton-Ladeeffekt wenn isLoading true ist
    func skeleton(when isLoading: Bool, cornerRadius: CGFloat = 8) -> some View {
        Group {
            if isLoading {
                self.hidden()
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(AppTheme.surfaceStrong)
                    )
                    .accessibilityLabel("Wird geladen")
            } else {
                self
            }
        }
    }
}

// MARK: - Previews

#Preview("TripCard Skeleton") {
    VStack(spacing: 12) {
        TripCardSkeleton()
        TripCardSkeleton()
        TripCardSkeleton()
    }
    .padding(.vertical)
    .background(AppTheme.canvas)
}

#Preview("Skeleton List") {
    ScrollView {
        ConnectionsSkeletonList(count: 5)
            .padding(.vertical)
    }
    .background(AppTheme.canvas)
}
