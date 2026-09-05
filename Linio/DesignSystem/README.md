# Linio Design System

## Apple HIG-konformes Design

Dieses Design-System basiert auf den [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/).

## Schriftart: San Francisco (SF Pro)

Die gesamte App verwendet **San Francisco** (SF Pro) als Systemschrift – Apples Standard-Font für iOS, watchOS und macOS. Die verschiedenen SF-Varianten werden wie folgt eingesetzt:

- **SF Pro** – Standard-Text für alle UI-Elemente
- **SF Pro mit Monospaced Digits** – Für Zeitanzeigen und numerische Werte (`.monospacedDigit()`)
- **SF Pro Rounded** – Für Countdowns und hervorgehobene Zahlen in Widgets (`design: .rounded`)

Die Verwendung von `design: .serif` oder `design: .monospaced` wurde entfernt, um eine konsistente Typografie zu gewährleisten.

## Migration Status ✅ ABGESCHLOSSEN

Das Design-System wurde vollständig implementiert. `AppTheme` referenziert jetzt automatisch die HIG-konformen SemanticColors, sodass alle bestehenden Views von den Verbesserungen profitieren.

### Core Design System
- ✅ `AppTheme` → Verweist auf `SemanticColor`, `Typography`, `DesignTokens`
- ✅ Automatische Light/Dark Mode Unterstützung
- ✅ Dynamic Type Support für alle Texte
- ✅ 8pt Grid Spacing System
- ✅ 44pt Minimum Touch Targets

### Aktualisierte Views
- ✅ Alle Main Views nutzen jetzt das Design-System
- ✅ TripCard, TripDetailView, ConnectionsView
- ✅ SettingsView, DepartureBoardView
- ✅ EmptyStateView, ErrorView, SkeletonModifier

## Struktur

```
DesignSystem/
├── DesignTokens.swift        # Spacing, CornerRadius, TouchTargets, Animations, Shadows
├── SemanticColors.swift      # Systemfarben (adaptiv für Light/Dark Mode)
├── LineColors.swift          # Brand-Farben: RNV-Linien, D-Ticket, Ticket-Status
├── Typography.swift          # Dynamic Type Text-Styles
├── HIGComponents.swift       # Wiederverwendbare UI-Komponenten
├── LiquidGlass.swift         # iOS 26 Liquid Glass Effekte
├── AppTheme+HIG.swift        # Brücke zum bestehenden AppTheme
└── AccessibilityModifiers.swift  # Accessibility View-Modifier
```

## Verwendung

### Spacing (8pt Grid)
```swift
VStack(spacing: DesignTokens.Spacing.md) { ... }  // 16pt
.padding(DesignTokens.Spacing.xl)                  // 24pt
```

### Farben
```swift
// Semantische Farben für automatische Dark Mode Unterstützung
Text("Titel").foregroundStyle(SemanticColor.label)
Text("Untertitel").foregroundStyle(SemanticColor.secondaryLabel)
.background(SemanticColor.systemGroupedBackground)

// Brand-Farben für Transportlinien
LineColors.tram4       // Tram 4 - Rot
LineColors.sBahn       // S-Bahn - Grün
LineColors.busDefault  // Bus - Blau

// Ticket-Status-Farben
TicketStatusColors.valid    // Gültig - Grün
TicketStatusColors.expired  // Abgelaufen - Rot
TicketStatusColors.warning  // Warnung - Orange

// Deutschlandticket-Logo
GermanyFlagColors.black
GermanyFlagColors.red
GermanyFlagColors.gold
```

### Typografie
```swift
Text("Überschrift").font(Typography.title2)
Text("Body Text").font(Typography.body)
Text("12:45").font(Typography.monospacedDigit(size: 24))
```

### Komponenten
```swift
// HIG Card
HIGCard {
    Text("Inhalt")
}

// HIG Icon Badge
HIGIconBadge(systemName: "tram.fill", color: .red)

// HIG Button Styles
Button("Primär") { }
    .buttonStyle(.higPrimary)
```

### Accessibility
```swift
Button("Action") { }
    .accessibleButton(label: "Aktion ausführen", hint: "Doppeltippen")

Text("Section")
    .accessibleHeading()
```

### Liquid Glass (iOS 26)
```swift
// Liquid Glass Card
LiquidGlassCard {
    Text("Glassmorphismus Inhalt")
}

// Liquid Glass Modifier
Text("Content")
    .padding()
    .liquidGlass(cornerRadius: 16, intensity: .standard)

// Liquid Glass Button
Button("Aktion") { }
    .buttonStyle(.liquidGlass)

// Intensitätsstufen: .subtle, .standard, .prominent
LiquidGlassCard(intensity: .prominent) {
    Text("Stärkerer Glaseffekt")
}
```

## Design Prinzipien

1. **Semantische Farben**: Verwende `SemanticColor` statt hardcoded Hex-Werte
2. **Dynamic Type**: Verwende `Typography` für automatische Schriftgrößen-Skalierung  
3. **Touch Targets**: Mindestens 44pt für interaktive Elemente
4. **Konsistentes Spacing**: 8pt Grid-System mit `DesignTokens.Spacing`
5. **Continuous Corners**: `.continuous` Style für RoundedRectangles
6. **SF Symbols**: Mit `.symbolRenderingMode(.hierarchical)` für bessere Darstellung
