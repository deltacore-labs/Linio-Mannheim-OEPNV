//
//  SkeletonModifier.swift
//  Linio
//
//  Skeleton Loading für bessere UX während Ladezeiten
//  Enthält animierte Shimmer-Effekte und verschiedene Skeleton-Komponenten
//

import SwiftUI

// MARK: - Shimmer Animation Effect

/// Ein ViewModifier für den animierten Shimmer-Effekt
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let duration: Double
    let angle: Double
    
    init(duration: Double = 1.5, angle: Double = 70) {
        self.duration = duration
        self.angle = angle
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if !reduceMotion {
                        shimmerOverlay(size: geometry.size)
                    }
                }
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
    
    private func shimmerOverlay(size: CGSize) -> some View {
        let gradient = LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white.opacity(0.35), location: 0.35),
                .init(color: .white.opacity(0.5), location: 0.5),
                .init(color: .white.opacity(0.35), location: 0.65),
                .init(color: .clear, location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Breite des Shimmer-Bandes
        let shimmerWidth = size.width * 0.8
        // Gesamte Bewegungsreichweite
        let totalDistance = size.width + shimmerWidth
        // Aktuelle Position
        let currentOffset = -shimmerWidth + (totalDistance * phase)
        
        return gradient
            .frame(width: shimmerWidth, height: size.height * 2)
            .rotationEffect(.degrees(angle))
            .offset(x: currentOffset, y: 0)
            .blendMode(.softLight)
    }
}

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
            .fill(AppTheme.surfaceStrong)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .modifier(ShimmerEffect())
    }
}

// MARK: - Circle Skeleton

struct SkeletonCircle: View {
    let size: CGFloat
    
    init(size: CGFloat = 40) {
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(AppTheme.surfaceStrong)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .modifier(ShimmerEffect())
    }
}

// MARK: - Text Line Skeleton

struct SkeletonTextLine: View {
    enum LineLength {
        case full
        case long      // ~80%
        case medium    // ~60%
        case short     // ~40%
        case tiny      // ~25%
        
        var fraction: CGFloat {
            switch self {
            case .full: return 1.0
            case .long: return 0.8
            case .medium: return 0.6
            case .short: return 0.4
            case .tiny: return 0.25
            }
        }
    }
    
    let length: LineLength
    let height: CGFloat
    
    init(length: LineLength = .full, height: CGFloat = 14) {
        self.length = length
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            SkeletonShape(
                width: geometry.size.width * length.fraction,
                height: height,
                cornerRadius: height / 3
            )
        }
        .frame(height: height)
    }
}

// MARK: - TripCard Skeleton

struct TripCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.hairlineStrong)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonShape(width: 140, height: 24, cornerRadius: 6)
                        SkeletonShape(width: 80, height: 14, cornerRadius: 4)
                    }
                    Spacer()
                    SkeletonShape(width: 60, height: 28, cornerRadius: 14)
                }
                HStack(spacing: 8) {
                    SkeletonShape(width: 50, height: 12, cornerRadius: 4)
                    SkeletonShape(width: 30, height: 12, cornerRadius: 4)
                    SkeletonShape(width: 50, height: 12, cornerRadius: 4)
                }
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
        .opacity(isAnimating ? 1 : 0.7)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityLabel("Verbindung wird geladen")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Departure Row Skeleton

struct DepartureRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonShape(width: 48, height: 28, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonShape(width: 160, height: 16, cornerRadius: 4)
                SkeletonShape(width: 80, height: 12, cornerRadius: 3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                SkeletonShape(width: 50, height: 20, cornerRadius: 4)
                SkeletonShape(width: 35, height: 12, cornerRadius: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.hairline, lineWidth: 1))
        .accessibilityLabel("Abfahrt wird geladen")
    }
}

// MARK: - Departure Board Skeleton List

struct DepartureBoardSkeletonList: View {
    let count: Int
    @State private var isVisible = false
    
    init(count: Int = 5) { self.count = count }
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                DepartureRowSkeleton()
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 10)
                    .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.08), value: isVisible)
            }
        }
        .padding(.horizontal)
        .onAppear { isVisible = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Abfahrten werden geladen")
    }
}

// MARK: - Skeleton List for Connections

struct ConnectionsSkeletonList: View {
    let count: Int
    @State private var isVisible = false
    
    init(count: Int = 3) { self.count = count }
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { index in
                TripCardSkeleton()
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.1), value: isVisible)
            }
        }
        .onAppear { isVisible = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verbindungen werden geladen")
    }
}

// MARK: - Station Card Skeleton

struct StationCardSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonCircle(size: 44)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonShape(width: 180, height: 18, cornerRadius: 5)
                HStack(spacing: 8) {
                    SkeletonShape(width: 24, height: 24, cornerRadius: 6)
                    SkeletonShape(width: 24, height: 24, cornerRadius: 6)
                    SkeletonShape(width: 24, height: 24, cornerRadius: 6)
                }
            }
            Spacer()
            SkeletonShape(width: 50, height: 14, cornerRadius: 4)
        }
        .padding(14)
        .background(AppTheme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.hairline, lineWidth: 1))
        .accessibilityLabel("Haltestelle wird geladen")
    }
}

// MARK: - Station List Skeleton

struct StationListSkeleton: View {
    let count: Int
    @State private var isVisible = false
    
    init(count: Int = 4) { self.count = count }
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                StationCardSkeleton()
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 15)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.1), value: isVisible)
            }
        }
        .padding(.horizontal)
        .onAppear { isVisible = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Haltestellen werden geladen")
    }
}

// MARK: - Trip Detail Skeleton

struct TripDetailSkeleton: View {
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonShape(width: 200, height: 28, cornerRadius: 6)
                        SkeletonShape(width: 120, height: 16, cornerRadius: 4)
                    }
                    Spacer()
                    SkeletonShape(width: 70, height: 32, cornerRadius: 16)
                }
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        SkeletonShape(width: 60, height: 32, cornerRadius: 6)
                        SkeletonShape(width: 40, height: 14, cornerRadius: 4)
                    }
                    SkeletonShape(width: 100, height: 4, cornerRadius: 2)
                    VStack(spacing: 4) {
                        SkeletonShape(width: 60, height: 32, cornerRadius: 6)
                        SkeletonShape(width: 40, height: 14, cornerRadius: 4)
                    }
                }
            }
            .padding()
            .background(AppTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Journey legs
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    LegSkeleton(isLast: index == 2)
                }
            }
            .padding()
            .background(AppTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Map placeholder
            SkeletonShape(height: 180, cornerRadius: 16)
        }
        .padding(.horizontal)
        .opacity(isVisible ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { isVisible = true } }
        .accessibilityLabel("Verbindungsdetails werden geladen")
    }
}

// MARK: - Leg Skeleton

struct LegSkeleton: View {
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                SkeletonCircle(size: 12)
                if !isLast {
                    Rectangle().fill(AppTheme.hairline).frame(width: 2, height: 60)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(width: 140, height: 16, cornerRadius: 4)
                HStack(spacing: 6) {
                    SkeletonShape(width: 44, height: 22, cornerRadius: 6)
                    SkeletonShape(width: 100, height: 14, cornerRadius: 4)
                }
                if !isLast { Spacer().frame(height: 24) }
            }
            Spacer()
            SkeletonShape(width: 50, height: 18, cornerRadius: 4)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - View Extensions

extension View {
    /// Zeigt einen Skeleton-Ladeeffekt wenn isLoading true ist
    func skeleton(when isLoading: Bool, cornerRadius: CGFloat = 8) -> some View {
        Group {
            if isLoading {
                self.hidden()
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(AppTheme.surfaceStrong)
                            .modifier(ShimmerEffect())
                    )
                    .accessibilityLabel("Wird geladen")
            } else {
                self
            }
        }
    }
    
    /// Shimmer-Effekt auf beliebige View anwenden
    func shimmer(when isActive: Bool = true, duration: Double = 1.5) -> some View {
        modifier(ConditionalShimmer(isActive: isActive, duration: duration))
    }
    
    /// Animierter Übergang von Skeleton zu Content
    func skeletonTransition() -> some View {
        self.transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

/// Conditional Shimmer Modifier
struct ConditionalShimmer: ViewModifier {
    let isActive: Bool
    let duration: Double
    
    func body(content: Content) -> some View {
        if isActive {
            content.modifier(ShimmerEffect(duration: duration))
        } else {
            content
        }
    }
}

// MARK: - Loading Container

/// Container für animierten Wechsel zwischen Skeleton und Content
struct SkeletonLoadingContainer<Skeleton: View, Content: View>: View {
    let isLoading: Bool
    @ViewBuilder let skeleton: () -> Skeleton
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            if isLoading {
                skeleton()
                    .transition(.opacity)
            } else {
                content()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
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

#Preview("Connections Skeleton List") {
    ScrollView {
        ConnectionsSkeletonList(count: 5)
            .padding(.vertical)
    }
    .background(AppTheme.canvas)
}

#Preview("Departure Board Skeleton") {
    ScrollView {
        DepartureBoardSkeletonList(count: 6)
            .padding(.vertical)
    }
    .background(AppTheme.canvas)
}

#Preview("Station List Skeleton") {
    ScrollView {
        StationListSkeleton(count: 5)
            .padding(.vertical)
    }
    .background(AppTheme.canvas)
}

#Preview("Trip Detail Skeleton") {
    ScrollView {
        TripDetailSkeleton()
            .padding(.vertical)
    }
    .background(AppTheme.canvas)
}

#Preview("All Skeleton Components") {
    ScrollView {
        VStack(spacing: 32) {
            // Section Header
            Text("Skeleton Components")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Basic Shapes
            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Shapes").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    SkeletonCircle(size: 40)
                    SkeletonCircle(size: 32)
                    SkeletonCircle(size: 24)
                }
                SkeletonShape(width: 200, height: 20, cornerRadius: 6)
                SkeletonShape(width: 150, height: 14, cornerRadius: 4)
                SkeletonShape(width: 100, height: 10, cornerRadius: 3)
            }
            .padding()
            .background(AppTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            // Text Lines
            VStack(alignment: .leading, spacing: 12) {
                Text("Text Lines").font(.caption).foregroundStyle(.secondary)
                SkeletonTextLine(length: .full)
                SkeletonTextLine(length: .long)
                SkeletonTextLine(length: .medium)
                SkeletonTextLine(length: .short)
            }
            .padding()
            .background(AppTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            // Departure Row
            Text("Departure Row").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            DepartureRowSkeleton().padding(.horizontal)
            
            // Station Card
            Text("Station Card").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            StationCardSkeleton().padding(.horizontal)
            
            // Trip Card
            Text("Trip Card").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            TripCardSkeleton()
        }
        .padding(.vertical)
    }
    .background(AppTheme.canvas)
}
