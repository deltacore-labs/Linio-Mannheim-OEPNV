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
    
    init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = DesignTokens.CornerRadius.small) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(SemanticColor.tertiarySystemFill)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
            .fill(SemanticColor.tertiarySystemFill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .modifier(ShimmerEffect())
    }
}

// MARK: - Inline Skeleton Loader (Ersatz für kleine ProgressView-Spinner)

/// Kleiner animierter Skeleton-Indikator für Inline-Loading in Buttons, Toolbars etc.
struct InlineSkeletonLoader: View {
    let size: CGFloat
    let tint: Color?
    
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(size: CGFloat = 16, tint: Color? = nil) {
        self.size = size
        self.tint = tint
    }
    
    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(tint ?? SemanticColor.tertiarySystemFill)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .opacity(reduceMotion ? 0.7 : (isAnimating ? 0.3 : 1.0))
                    .animation(
                        reduceMotion ? nil : Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { return }
            isAnimating = true
        }
        .accessibilityLabel("Wird geladen")
        .accessibilityHidden(true)
    }
}

/// Pulsierender Skeleton-Punkt für sehr kompakte Stellen
struct SkeletonPulse: View {
    let size: CGFloat
    let tint: Color?
    
    @State private var scale: CGFloat = 0.8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(size: CGFloat = 16, tint: Color? = nil) {
        self.size = size
        self.tint = tint
    }
    
    var body: some View {
        Circle()
            .fill(tint ?? SemanticColor.tertiarySystemFill)
            .frame(width: size, height: size)
            .scaleEffect(reduceMotion ? 1.0 : scale)
            .opacity(reduceMotion ? 0.7 : (scale < 1.0 ? 0.5 : 1.0))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    scale = 1.2
                }
            }
            .accessibilityLabel("Wird geladen")
            .accessibilityHidden(true)
    }
}

// MARK: - Toolbar Skeleton Loader

/// Skeleton-Loader für Toolbar-Positionen (ersetzt ProgressView in Navigation Bar)
struct ToolbarSkeletonLoader: View {
    var body: some View {
        InlineSkeletonLoader(size: 18, tint: SemanticColor.secondaryLabel.opacity(0.5))
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
    /// Zeigt einen Skeleton-Ladeeffekt wenn isLoading true ist (HIG)
    func skeleton(when isLoading: Bool, cornerRadius: CGFloat = DesignTokens.CornerRadius.small) -> some View {
        Group {
            if isLoading {
                self.hidden()
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(SemanticColor.tertiarySystemFill)
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

// MARK: - Preview

// MARK: - Empty State Skeleton

/// Skeleton das zum EmptyStateView passt - für initiales Laden bevor eine Suche gestartet wurde
struct EmptyStateSkeleton: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon-Platzhalter (runder Kreis wie im EmptyStateView)
            SkeletonCircle(size: 88)
            
            // Text-Platzhalter
            VStack(spacing: DesignTokens.Spacing.xs) {
                SkeletonShape(width: 200, height: 22, cornerRadius: 6)
                SkeletonShape(width: 260, height: 16, cornerRadius: 4)
                SkeletonShape(width: 180, height: 16, cornerRadius: 4)
            }
            
            // Button-Platzhalter
            SkeletonShape(width: 160, height: 44, cornerRadius: 12)
                .padding(.top, DesignTokens.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxxl)
        .accessibilityLabel("Inhalt wird geladen")
        .accessibilityHidden(true)
    }
}

/// Skeleton für Verbindungs-EmptyState ("Wohin möchtest du fahren?")
struct ConnectionsEmptyStateSkeleton: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Tram-Icon Platzhalter
            ZStack {
                SkeletonCircle(size: 88)
                Image(systemName: "tram.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(SemanticColor.tertiarySystemFill)
            }
            
            // "Wohin möchtest du fahren?" Platzhalter
            VStack(spacing: DesignTokens.Spacing.xs) {
                SkeletonShape(width: 220, height: 22, cornerRadius: 6)
                SkeletonShape(width: 280, height: 16, cornerRadius: 4)
                SkeletonShape(width: 200, height: 16, cornerRadius: 4)
            }
            
            // "Haltestelle wählen" Button-Platzhalter
            HStack(spacing: DesignTokens.Spacing.xs) {
                SkeletonCircle(size: 18)
                SkeletonShape(width: 120, height: 18, cornerRadius: 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SemanticColor.tertiarySystemFill)
                    .modifier(ShimmerEffect())
            )
            .padding(.top, DesignTokens.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxxl)
        .accessibilityLabel("Verbindungssuche wird vorbereitet")
        .accessibilityHidden(true)
    }
}

// MARK: - Map Skeleton

/// Skeleton für Kartenansichten
struct MapSkeleton: View {
    let height: CGFloat
    
    init(height: CGFloat = 200) {
        self.height = height
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                .fill(SemanticColor.tertiarySystemFill)
                .frame(height: height)
                .modifier(ShimmerEffect())
            
            VStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(SemanticColor.quaternaryLabel)
                SkeletonShape(width: 100, height: 12, cornerRadius: 6)
            }
        }
        .accessibilityLabel("Karte wird geladen")
        .accessibilityHidden(true)
    }
}

// MARK: - Service Alerts Skeleton

/// Skeleton für Störungsmeldungen - zeigt zuerst EmptyState-artiges Skeleton,
/// das dann zu Alert-Cards wechselt wenn Daten da sind
struct ServiceAlertsSkeleton: View {
    let count: Int
    
    init(count: Int = 3) {
        self.count = count
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Skeleton im Stil des "Alles läuft!" Empty States
            ZStack {
                SkeletonCircle(size: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(SemanticColor.tertiarySystemFill)
            }
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                SkeletonShape(width: 120, height: 22, cornerRadius: 6)
                SkeletonShape(width: 280, height: 16, cornerRadius: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxxl)
        .accessibilityLabel("Störungsmeldungen werden geladen")
        .accessibilityHidden(true)
    }
}

/// Skeleton für einzelne Alert-Card (wird verwendet wenn bereits Alerts da sind und mehr geladen werden)
struct ServiceAlertCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SkeletonCircle(size: 32)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(width: nil, height: 16, cornerRadius: 4)
                SkeletonShape(width: 180, height: 12, cornerRadius: 4)
                SkeletonShape(width: 100, height: 10, cornerRadius: 4)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.surfaceCard)
        )
    }
}

/// Liste von Alert-Card-Skeletons für Refresh/Folge-Laden
struct ServiceAlertCardSkeletonList: View {
    let count: Int
    
    init(count: Int = 3) {
        self.count = count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                ServiceAlertCardSkeleton()
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Ticket Skeleton

/// Skeleton für Ticket-Erkennung
struct TicketRecognitionSkeleton: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            
            // Animierte Scan-Linien
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SemanticColor.tertiarySystemFill, lineWidth: 3)
                    .frame(width: 120, height: 80)
                
                VStack(spacing: 8) {
                    SkeletonShape(width: 80, height: 10, cornerRadius: 4)
                    SkeletonShape(width: 60, height: 10, cornerRadius: 4)
                    SkeletonShape(width: 70, height: 10, cornerRadius: 4)
                }
            }
            
            VStack(spacing: 8) {
                SkeletonShape(width: 140, height: 16, cornerRadius: 6)
                SkeletonShape(width: 100, height: 12, cornerRadius: 4)
            }
            
            Spacer()
        }
        .accessibilityLabel("Ticket wird erkannt")
        .accessibilityHidden(true)
    }
}

// MARK: - Location Loading Skeleton

/// Skeleton für Standort-Ladeanzeige in Settings
struct LocationLoadingSkeleton: View {
    var body: some View {
        HStack(spacing: 8) {
            InlineSkeletonLoader(size: 18, tint: AppTheme.primaryColor.opacity(0.5))
        }
    }
}

// MARK: - Refresh Skeleton

/// Skeleton für Aktualisierungs-Anzeige
struct RefreshSkeleton: View {
    var body: some View {
        HStack(spacing: 6) {
            InlineSkeletonLoader(size: 14, tint: AppTheme.muted.opacity(0.6))
            SkeletonShape(width: 80, height: 12, cornerRadius: 4)
        }
    }
}

#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Trip Cards").font(.headline)
            TripCardSkeleton()
            DepartureRowSkeleton().padding(.horizontal)
            StationCardSkeleton().padding(.horizontal)
            
            Divider()
            
            Text("Inline Loaders").font(.headline)
            HStack(spacing: 20) {
                VStack {
                    InlineSkeletonLoader(size: 16)
                    Text("16pt").font(.caption2)
                }
                VStack {
                    InlineSkeletonLoader(size: 20)
                    Text("20pt").font(.caption2)
                }
                VStack {
                    SkeletonPulse(size: 16)
                    Text("Pulse").font(.caption2)
                }
                VStack {
                    ToolbarSkeletonLoader()
                    Text("Toolbar").font(.caption2)
                }
            }
            
            Divider()
            
            Text("Map Skeleton").font(.headline)
            MapSkeleton(height: 150)
                .padding(.horizontal)
            
            Divider()
            
            Text("Service Alert Card").font(.headline)
            ServiceAlertCardSkeleton()
                .padding(.horizontal)
            
            Divider()
            
            Text("Ticket Recognition").font(.headline)
            TicketRecognitionSkeleton()
                .frame(height: 200)
        }
        .padding(.vertical)
    }
    .background(AppTheme.canvas)
}

#Preview("Empty State Skeletons") {
    ScrollView {
        VStack(spacing: 32) {
            Text("Connections EmptyState Skeleton").font(.headline)
            ConnectionsEmptyStateSkeleton()
            
            Divider()
            
            Text("Service Alerts EmptyState Skeleton").font(.headline)
            ServiceAlertsSkeleton()
            
            Divider()
            
            Text("Generic EmptyState Skeleton").font(.headline)
            EmptyStateSkeleton()
        }
        .padding()
    }
    .background(AppTheme.canvas)
}
