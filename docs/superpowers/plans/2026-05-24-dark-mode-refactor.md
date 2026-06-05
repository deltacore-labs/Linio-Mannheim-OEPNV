# Dark Mode Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all `@Environment(\.colorScheme)` boilerplate and `*Adaptive(colorScheme)` calls with UIKit-trait-based adaptive `Color` properties, and fix Dark Mode contrast failures for semantic colors, `primary`, and `muted`.

**Architecture:** `AppTheme` properties become `Color(UIColor { trait in … })` — SwiftUI propagates trait changes automatically, so no view needs to observe `colorScheme` for theme purposes. All `*Adaptive` functions are first converted to forwarding stubs (so every view compiles immediately after Task 1), then their call sites are cleaned up file-by-file, and finally the stubs are removed.

**Tech Stack:** SwiftUI, UIKit (`UIColor` dynamic provider), UITraitCollection

---

## File Map

| File | Changes |
|---|---|
| `Linio/Content/ContentView.swift` | AppTheme rewrite + UIColor ext + *Adaptive stubs |
| `Linio/Content/DepartureBoardView.swift` | Remove @Environment ×3, callsites, onPrimary |
| `Linio/Content/SettingsView.swift` | Remove @Environment ×2, computed vars, callsites |
| `Linio/Content/TicketView.swift` | Remove @Environment ×2, computed var, callsites, onPrimary |
| `Linio/Content/PlannedTripsView.swift` | Remove @Environment, callsites |
| `Linio/Content/TripCard.swift` | Remove @Environment, callsites, inline check |
| `Linio/Content/TripDetailView.swift` | Remove @Environment, callsites |
| `Linio/Content/LegDetailCard.swift` | Callsites only — @Environment stays in one struct |
| `Linio/Content/StationPickerView.swift` | Remove @Environment, callsites, onPrimary ×3 |
| `Linio/Content/ConnectionsView.swift` | Remove @Environment ×2, callsites, onPrimary ×2 |
| `Linio/Content/SteigSheet.swift` | Remove @Environment, callsites |
| `Linio/Content/PrivacyPolicyView.swift` | Remove @Environment, callsites |
| `Linio/Content/PlannedTripDetailSheet.swift` | Remove @Environment, callsites |
| `Linio/PlannedTripCard.swift` | Remove @Environment, callsites |
| `Linio/Content/ContentView.swift` | Remove *Adaptive stubs (final cleanup) |

---

## Task 1: AppTheme — Adaptive Properties + UIColor-Extension

**File:** `Linio/Content/ContentView.swift`

- [ ] **Step 1: UIColor(hex:) extension ergänzen**

Add this directly below the existing `Color(hex:)` extension at the bottom of ContentView.swift:

```swift
private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: Double(a) / 255)
    }
}
```

- [ ] **Step 2: AppTheme-Struct vollständig ersetzen**

Replace the entire `struct AppTheme { … }` block (lines ~110–171) with:

```swift
struct AppTheme {
    // Canvas & Surfaces (adaptive)
    static let canvas = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#1c1917") : UIColor(hex: "#f5f5f5")
    })
    static let canvasSoft     = Color(hex: "#fafafa")
    static let surfaceCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#292524") : .white
    })
    static let surfaceStrong = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#3c3836") : UIColor(hex: "#f0efed")
    })
    static let hairline = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#44403c") : UIColor(hex: "#e7e5e4")
    })
    static let hairlineStrong = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#57534e") : UIColor(hex: "#d6d3d1")
    })

    // Text (adaptive)
    static let ink = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? .white : UIColor(hex: "#0c0a09")
    })
    static let bodyText = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#c8c2bc") : UIColor(hex: "#4e4e4e")
    })
    static let muted = Color(UIColor { t in
        if t.accessibilityContrast == .high {
            return t.userInterfaceStyle == .dark ? UIColor(hex: "#c8c2bc") : UIColor(hex: "#565049")
        }
        return t.userInterfaceStyle == .dark ? UIColor(hex: "#a8a29e") : UIColor(hex: "#777169")
    })
    static let mutedSoft = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#78716c") : UIColor(hex: "#a8a29e")
    })

    // Actions (adaptive)
    static let primary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#e7e5e4") : UIColor(hex: "#292524")
    })
    static let primaryActive = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? .white : UIColor(hex: "#0c0a09")
    })
    static let primaryColor = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#e7e5e4") : UIColor(hex: "#292524")
    })
    static let onPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#1c1917") : .white
    })

    // Dark hero surfaces (always dark — not adaptive)
    static let surfaceDark         = Color(hex: "#0c0a09")
    static let surfaceDarkElevated = Color(hex: "#1c1917")
    static let onDark              = Color.white
    static let onDarkSoft          = Color(hex: "#a8a29e")

    // Atmospheric gradient orbs (decoration — no contrast requirement)
    static let gradientMint     = Color(hex: "#a7e5d3")
    static let gradientPeach    = Color(hex: "#f4c5a8")
    static let gradientLavender = Color(hex: "#c8b8e0")
    static let gradientSky      = Color(hex: "#a8c8e8")
    static let gradientRose     = Color(hex: "#e8b8c4")

    // Semantic (adaptive — WCAG AA compliant in both modes)
    static let semanticError = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#f87171") : UIColor(hex: "#dc2626")
    })
    static let semanticSuccess = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#4ade80") : UIColor(hex: "#16a34a")
    })

    // Legacy aliases
    static let accentGradient   = LinearGradient(colors: [primary, primary], startPoint: .leading, endPoint: .trailing)
    static let headerBackground = LinearGradient(colors: [surfaceDark, surfaceDarkElevated], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardBackground   = surfaceCard
    static let subtleBackground = surfaceStrong
    static let secondaryColor   = primary

    // Shadow
    static func shadowColor(isPast: Bool = false) -> Color {
        Color.black.opacity(isPast ? 0.03 : 0.05)
    }

    // Typography
    static func displayFont(size: CGFloat) -> Font { .system(size: size, weight: .light, design: .serif) }
    static let buttonFont = Font.system(size: 15, weight: .medium)
    static func monoFont(size: CGFloat, weight: Font.Weight = .bold) -> Font { .system(size: size, weight: weight, design: .monospaced) }

    // *Adaptive stubs — forward to new properties (colorScheme param ignored).
    // Call sites are cleaned up in Tasks 2–15. Stubs removed in Task 16.
    static func canvasAdaptive(_ s: ColorScheme) -> Color { canvas }
    static func surfaceCardAdaptive(_ s: ColorScheme) -> Color { surfaceCard }
    static func surfaceStrongAdaptive(_ s: ColorScheme) -> Color { surfaceStrong }
    static func hairlineAdaptive(_ s: ColorScheme) -> Color { hairline }
    static func inkAdaptive(_ s: ColorScheme) -> Color { ink }
    static func mutedAdaptive(_ s: ColorScheme, contrast: ColorSchemeContrast = .standard) -> Color { muted }
    static func bodyTextAdaptive(_ s: ColorScheme) -> Color { bodyText }
}
```

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

Dark Mode ist ab jetzt funktional (alle *Adaptive-Stubs leiten an die neuen adaptiven Properties weiter).

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/ContentView.swift
git commit -m "refactor: AppTheme — UIColor-adaptive properties, onPrimary, WCAG semantic colors"
```

---

## Task 2: ContentView — @Environment entfernen + tint-Fix

**File:** `Linio/Content/ContentView.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 19:
```swift
@Environment(\.colorScheme) private var colorScheme
```

- [ ] **Step 2: Inline colorScheme-Check fixen**

Find and replace (around line 77):
```swift
// Vorher:
.tint(colorScheme == .dark ? .white : AppTheme.primaryColor)
// Nachher:
.tint(AppTheme.primaryColor)
```

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/ContentView.swift
git commit -m "refactor: ContentView — @Environment(colorScheme) und inline tint-Check entfernt"
```

---

## Task 3: DepartureBoardView — 3 Structs bereinigen

**File:** `Linio/Content/DepartureBoardView.swift`

Drei Structs in dieser Datei haben @Environment: `DepartureBoardView`, `DepartureRowView`, `DepartureTripDetailView`.

- [ ] **Step 1: DepartureBoardView — @Environment entfernen**

Delete lines 31–32:
```swift
@Environment(\.colorScheme) private var colorScheme
@Environment(\.colorSchemeContrast) private var colorSchemeContrast
```

- [ ] **Step 2: DepartureBoardView — *Adaptive-Aufrufe ersetzen**

Use find-replace (all occurrences in the DepartureBoardView struct body):
- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`
- `AppTheme.mutedAdaptive(colorScheme, contrast: colorSchemeContrast)` → `AppTheme.muted`
- `AppTheme.surfaceStrongAdaptive(colorScheme)` → `AppTheme.surfaceStrong`

- [ ] **Step 3: onPrimary für "Haltestelle auswählen"-Button (promptView)**

Find (around line 327–333):
```swift
Button(action: { showStationPicker = true }) {
    Text("Haltestelle auswählen")
        .font(AppTheme.buttonFont)
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppTheme.primary)
```
Replace `.foregroundColor(.white)` with `.foregroundColor(AppTheme.onPrimary)`.

- [ ] **Step 4: DepartureRowView — @Environment entfernen**

Delete lines 474–475:
```swift
@Environment(\.colorScheme) private var colorScheme
@Environment(\.colorSchemeContrast) private var colorSchemeContrast
```

- [ ] **Step 5: DepartureRowView — *Adaptive-Aufrufe ersetzen**

- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`
- `AppTheme.mutedAdaptive(colorScheme, contrast: colorSchemeContrast)` → `AppTheme.muted` (appears in `mutedAdaptive(colorScheme, contrast: colorSchemeContrast)`)
- `AppTheme.mutedAdaptive(colorScheme)` → `AppTheme.muted`

- [ ] **Step 6: DepartureTripDetailView — @Environment entfernen**

Delete lines 637–638:
```swift
@Environment(\.colorScheme) private var colorScheme
@Environment(\.colorSchemeContrast) private var colorSchemeContrast
```

- [ ] **Step 7: DepartureTripDetailView — *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`
- `AppTheme.mutedAdaptive(colorScheme, contrast: colorSchemeContrast)` → `AppTheme.muted`

- [ ] **Step 8: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 9: Commit**

```bash
git add Linio/Content/DepartureBoardView.swift
git commit -m "refactor: DepartureBoardView — @Environment und *Adaptive-Boilerplate entfernt, onPrimary"
```

---

## Task 4: SettingsView — @Environment + computed vars entfernen

**File:** `Linio/Content/SettingsView.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 15:
```swift
@Environment(\.colorScheme) private var colorScheme
```

- [ ] **Step 2: Computed vars entfernen**

Delete lines 32–34:
```swift
private var cardBg: Color { AppTheme.surfaceCardAdaptive(colorScheme) }
private var canvasBg: Color { AppTheme.canvasAdaptive(colorScheme) }
private var dividerColor: Color { AppTheme.hairlineAdaptive(colorScheme) }
```

- [ ] **Step 3: Computed-var-Verwendungen inline ersetzen**

- `canvasBg` → `AppTheme.canvas` (1 occurrence: `.background(canvasBg.ignoresSafeArea())`)
- `cardBg` → `AppTheme.surfaceCard` (all occurrences: `.background(cardBg)`, all `SettingsCard(…, cardBg: cardBg, …)` calls)
- `dividerColor` → `AppTheme.hairline` (all occurrences: `RowDivider(color: dividerColor)`, all `SettingsCard(…, dividerColor: dividerColor)` calls)

- [ ] **Step 4: *Adaptive-Aufrufe im main struct ersetzen**

- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink` (all occurrences in SettingsView body)

- [ ] **Step 5: ActionRow-Struct @Environment entfernen**

Delete line 493 (inside `ActionRow` struct):
```swift
@Environment(\.colorScheme) private var colorScheme
```
Replace line 501:
```swift
// Vorher:
.foregroundColor(AppTheme.inkAdaptive(colorScheme))
// Nachher:
.foregroundColor(AppTheme.ink)
```

- [ ] **Step 6: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 7: Commit**

```bash
git add Linio/Content/SettingsView.swift
git commit -m "refactor: SettingsView — @Environment, computed vars und *Adaptive-Boilerplate entfernt"
```

---

## Task 5: TicketView — @Environment + computed var + onPrimary

**File:** `Linio/Content/TicketView.swift`

- [ ] **Step 1: @Environment entfernen (2 Stellen)**

Delete line 410: `@Environment(\.colorScheme) private var colorScheme`
Delete line 731: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: Computed var `canvas` entfernen**

Delete line ~433:
```swift
private var canvas: Color { AppTheme.canvasAdaptive(colorScheme) }
```
Replace all usages of `canvas` (where used as `AppTheme.canvas`) with `AppTheme.canvas`.

- [ ] **Step 3: *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`
- `AppTheme.mutedAdaptive(colorScheme)` → `AppTheme.muted`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`

- [ ] **Step 4: onPrimary für Import-Button**

Find (around line 535–542):
```swift
Button { showImportOptions = true } label: {
    Label("Aus Screenshot importieren", systemImage: "photo.badge.plus")
        .font(AppTheme.buttonFont)
        .foregroundStyle(.white)
        .frame(maxWidth: 280)
        .padding(.vertical, 15)
        .background(AppTheme.primary)
```
Replace `.foregroundStyle(.white)` with `.foregroundStyle(AppTheme.onPrimary)`.

- [ ] **Step 5: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 6: Commit**

```bash
git add Linio/Content/TicketView.swift
git commit -m "refactor: TicketView — @Environment, computed var und *Adaptive-Boilerplate entfernt, onPrimary"
```

---

## Task 6: PlannedTripsView — @Environment entfernen

**File:** `Linio/Content/PlannedTripsView.swift`

- [ ] **Step 1: @Environment entfernen (2 Stellen)**

Delete line 16: `@Environment(\.colorScheme) private var colorScheme`
Delete line 216: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`
- `AppTheme.bodyTextAdaptive(colorScheme)` → `AppTheme.bodyText`
- `AppTheme.surfaceStrongAdaptive(colorScheme)` → `AppTheme.surfaceStrong`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/PlannedTripsView.swift
git commit -m "refactor: PlannedTripsView — @Environment und *Adaptive-Boilerplate entfernt"
```

---

## Task 7: TripCard — @Environment + inline check

**File:** `Linio/Content/TripCard.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 13: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.surfaceStrongAdaptive(colorScheme)` → `AppTheme.surfaceStrong`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`

- [ ] **Step 3: Inline colorScheme-Check fixen**

Find (around line 267):
```swift
.fill(colorScheme == .dark ? AppTheme.surfaceDarkElevated : AppTheme.surfaceCard)
```
Replace with:
```swift
.fill(AppTheme.surfaceCard)
```

- [ ] **Step 4: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 5: Commit**

```bash
git add Linio/Content/TripCard.swift
git commit -m "refactor: TripCard — @Environment, *Adaptive-Boilerplate und inline Dark-Mode-Check entfernt"
```

---

## Task 8: TripDetailView — @Environment entfernen

**File:** `Linio/Content/TripDetailView.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 25: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.surfaceStrongAdaptive(colorScheme)` → `AppTheme.surfaceStrong`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/TripDetailView.swift
git commit -m "refactor: TripDetailView — @Environment und *Adaptive-Boilerplate entfernt"
```

---

## Task 9: LegDetailCard — *Adaptive-Aufrufe ersetzen (selektiv)

**File:** `Linio/Content/LegDetailCard.swift`

> **Hinweis:** Diese Datei enthält 3 Structs mit `@Environment(\.colorScheme)`. Nur der zweite Struct (ab Zeile ~365) behält das @Environment, weil er inline Dark-Mode-Opacity-Checks verwendet (`Color.orange.opacity(colorScheme == .dark ? 0.06 : 0.04)`), die nicht in den Scope dieser Refactoring-Spec fallen.

- [ ] **Step 1: Struct 1 (Zeile 19) — *Adaptive ersetzen, @Environment entfernen**

Ersatz-Aufrufe im ersten Struct:
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard` (Zeilen 70, 136)
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline` (Zeile 72)

Prüfe: Nutzt Struct 1 noch `colorScheme` nach diesen Ersetzungen? Wenn nein, lösche das `@Environment` auf Zeile 19.

- [ ] **Step 2: Struct 2 (Zeile ~365) — @Environment BEHALTEN**

Dieser Struct nutzt `colorScheme` für `Color.orange.opacity(colorScheme == .dark ? 0.06 : 0.04)` (Zeilen 462–463). Keine Änderung in diesem Struct.

- [ ] **Step 3: Struct 3 (Zeile ~541) — *Adaptive ersetzen, @Environment entfernen**

Ersatz-Aufrufe im dritten Struct:
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard` (Zeile 606)

Prüfe: Nutzt Struct 3 noch `colorScheme` nach dieser Ersetzung? Wenn nein, lösche das `@Environment` auf Zeile 541.

- [ ] **Step 4: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 5: Commit**

```bash
git add Linio/Content/LegDetailCard.swift
git commit -m "refactor: LegDetailCard — *Adaptive-Aufrufe ersetzt (inline opacity-checks bleiben)"
```

---

## Task 10: StationPickerView — @Environment + onPrimary (3 Stellen)

**File:** `Linio/Content/StationPickerView.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 25: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.surfaceStrongAdaptive(colorScheme)` → `AppTheme.surfaceStrong`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`

- [ ] **Step 3: onPrimary — Karten-Bubble (stationPin)**

Find in `stationPin` function (around line 688–695):
```swift
Text(name)
    .font(.system(size: 11, weight: .semibold))
    .foregroundColor(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Capsule().fill(AppTheme.primaryColor))
```
Replace `.foregroundColor(.white)` with `.foregroundColor(AppTheme.onPrimary)`.

- [ ] **Step 4: onPrimary — Karten-Icon (stationPin)**

Find in `stationPin` function (around line 704):
```swift
.foregroundColor(isSelected ? .white : AppTheme.primaryColor)
```
Replace with:
```swift
.foregroundColor(isSelected ? AppTheme.onPrimary : AppTheme.primaryColor)
```

- [ ] **Step 5: onPrimary — "Auswählen"-Button (selectionCard)**

Find in `selectionCard` function (around line 750–755):
```swift
Text("Auswählen")
    .font(.system(size: 14, weight: .semibold))
    .foregroundColor(.white)
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(Capsule().fill(AppTheme.primaryColor))
```
Replace `.foregroundColor(.white)` with `.foregroundColor(AppTheme.onPrimary)`.

- [ ] **Step 6: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 7: Commit**

```bash
git add Linio/Content/StationPickerView.swift
git commit -m "refactor: StationPickerView — @Environment, *Adaptive-Boilerplate entfernt, onPrimary"
```

---

## Task 11: ConnectionsView — @Environment + onPrimary (2 Stellen)

**File:** `Linio/Content/ConnectionsView.swift`

Diese Datei hat die meisten *Adaptive-Aufrufe (24 Stellen). Systematisch mit Find-Replace arbeiten.

- [ ] **Step 1: @Environment entfernen (2 Deklarationen)**

Delete line 39: `@Environment(\.colorScheme) private var colorScheme`
Delete line 41: `@Environment(\.colorSchemeContrast) private var colorSchemeContrast`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen (alle 24)**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.surfaceStrongAdaptive(colorScheme)` → `AppTheme.surfaceStrong`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`
- `AppTheme.mutedAdaptive(colorScheme, contrast: colorSchemeContrast)` → `AppTheme.muted`

- [ ] **Step 3: onPrimary — "Erneut verbinden"-Button**

Find (around line 481–488):
```swift
.foregroundColor(.white)
.frame(maxWidth: .infinity)
.padding(.vertical, 14)
.background(Capsule().fill(AppTheme.primary))
```
Replace `.foregroundColor(.white)` with `.foregroundColor(AppTheme.onPrimary)`.

- [ ] **Step 4: onPrimary — "Verbindungen suchen"-Button**

Find (around line 604–612):
```swift
.foregroundColor(.white)
.frame(maxWidth: .infinity)
.padding(.vertical, 14)
.background(
    Capsule()
        .fill(AppTheme.primary)
)
```
Replace `.foregroundColor(.white)` with `.foregroundColor(AppTheme.onPrimary)`.

- [ ] **Step 5: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 6: Commit**

```bash
git add Linio/Content/ConnectionsView.swift
git commit -m "refactor: ConnectionsView — @Environment, *Adaptive-Boilerplate entfernt, onPrimary"
```

---

## Task 12: SteigSheet — @Environment entfernen

**File:** `Linio/Content/SteigSheet.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 22: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/SteigSheet.swift
git commit -m "refactor: SteigSheet — @Environment und *Adaptive-Boilerplate entfernt"
```

---

## Task 13: PrivacyPolicyView — @Environment entfernen

**File:** `Linio/Content/PrivacyPolicyView.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 10: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`
- `AppTheme.bodyTextAdaptive(colorScheme)` → `AppTheme.bodyText`

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/PrivacyPolicyView.swift
git commit -m "refactor: PrivacyPolicyView — @Environment und *Adaptive-Boilerplate entfernt"
```

---

## Task 14: PlannedTripDetailSheet — @Environment entfernen

**File:** `Linio/Content/PlannedTripDetailSheet.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 15: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.canvasAdaptive(colorScheme)` → `AppTheme.canvas`
- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard`
- `AppTheme.surfaceStrongAdaptive(colorScheme)` → `AppTheme.surfaceStrong`
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline`
- `AppTheme.inkAdaptive(colorScheme)` → `AppTheme.ink`

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/PlannedTripDetailSheet.swift
git commit -m "refactor: PlannedTripDetailSheet — @Environment und *Adaptive-Boilerplate entfernt"
```

---

## Task 15: PlannedTripCard — @Environment entfernen

**File:** `Linio/PlannedTripCard.swift`

- [ ] **Step 1: @Environment entfernen**

Delete line 19: `@Environment(\.colorScheme) private var colorScheme`

- [ ] **Step 2: *Adaptive-Aufrufe ersetzen**

- `AppTheme.surfaceCardAdaptive(colorScheme)` → `AppTheme.surfaceCard` (Zeile 79)
- `AppTheme.hairlineAdaptive(colorScheme)` → `AppTheme.hairline` (Zeile 81)

- [ ] **Step 3: Build — ⌘B, 0 Fehler erwartet**

- [ ] **Step 4: Commit**

```bash
git add Linio/PlannedTripCard.swift
git commit -m "refactor: PlannedTripCard — @Environment und *Adaptive-Boilerplate entfernt"
```

---

## Task 16: *Adaptive-Stubs aus AppTheme entfernen

**File:** `Linio/Content/ContentView.swift`

- [ ] **Step 1: Stubs löschen**

In `struct AppTheme`, den gesamten `// *Adaptive stubs`-Block am Ende löschen:

```swift
// *Adaptive stubs — forward to new properties (colorScheme param ignored).
// Call sites are cleaned up in Tasks 2–15. Stubs removed in Task 16.
static func canvasAdaptive(_ s: ColorScheme) -> Color { canvas }
static func surfaceCardAdaptive(_ s: ColorScheme) -> Color { surfaceCard }
static func surfaceStrongAdaptive(_ s: ColorScheme) -> Color { surfaceStrong }
static func hairlineAdaptive(_ s: ColorScheme) -> Color { hairline }
static func inkAdaptive(_ s: ColorScheme) -> Color { ink }
static func mutedAdaptive(_ s: ColorScheme, contrast: ColorSchemeContrast = .standard) -> Color { muted }
static func bodyTextAdaptive(_ s: ColorScheme) -> Color { bodyText }
```

- [ ] **Step 2: Build — ⌘B, 0 Fehler erwartet**

Wenn Fehler auftreten: Die entsprechende Datei hat noch *Adaptive-Aufrufe. Die Fehlermeldungen zeigen die genaue Stelle — gleiche Ersatz-Muster wie in den vorherigen Tasks anwenden.

- [ ] **Step 3: Visuell im Simulator prüfen**

- App im Dark Mode öffnen (Einstellungen → Entwickler → Dark Appearance oder ⌘+Shift+A im Simulator)
- Prüfe: Abfahrtstafel, Verbindungen, Ticket-View, Einstellungen — alle Views sollen lesbaren Text haben
- Prüfe: Rote Fehlermeldungen ("+2 min") und grüne Pünktlichkeits-Anzeigen sollen im Dark Mode klar sichtbar sein
- Prüfe: "Haltestelle auswählen"-, "Auswählen"-, "Verbindungen suchen"-, Import-Buttons sollen im Dark Mode lesbaren (dunklen) Text haben

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/ContentView.swift
git commit -m "refactor: AppTheme *Adaptive-Stubs entfernt — Refactoring abgeschlossen"
```
