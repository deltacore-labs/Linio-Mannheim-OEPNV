# Dark-Mode-Überarbeitung — Design Spec

**Datum:** 2026-05-23  
**Scope:** AppTheme-Architektur + Farbpalette

---

## Ziel

Zwei Probleme gleichzeitig lösen:

1. **Boilerplate eliminieren:** Jede View deklariert heute `@Environment(\.colorScheme)` und `@Environment(\.colorSchemeContrast)` nur um sie an `AppTheme.*Adaptive(…)`-Funktionen weiterzureichen. Das ist repetitiv und fehleranfällig.

2. **Farbfehler beheben:** Mehrere AppTheme-Properties haben keine Dark-Mode-Variante und erzeugen im Dunkeln niedrigen Kontrast oder unsichtbare Elemente (z.B. `primary` = near-black auf near-black Canvas, semantische Farben unter WCAG AA).

---

## Architektur

### Vorher

```swift
// In AppTheme:
static func inkAdaptive(_ s: ColorScheme) -> Color { s == .dark ? onDark : ink }

// In jeder View:
@Environment(\.colorScheme) private var colorScheme
@Environment(\.colorSchemeContrast) private var colorSchemeContrast

.foregroundColor(AppTheme.inkAdaptive(colorScheme))
.foregroundColor(AppTheme.mutedAdaptive(colorScheme, contrast: colorSchemeContrast))
```

### Nachher

```swift
// In AppTheme:
static let ink = Color(UIColor { t in
    t.userInterfaceStyle == .dark ? UIColor(hex: "#ffffff") : UIColor(hex: "#0c0a09")
})

// In Views: keine @Environment nötig, keine Parameter
.foregroundColor(AppTheme.ink)
```

`UIColor { trait in }` nutzt UIKit's Trait-Collection-System. SwiftUI propagiert Trait-Änderungen automatisch an alle Stellen, die eine solche `Color` verwenden.

Da `UIColor` keine `init(hex:)` kennt, wird eine Erweiterung ergänzt:

```swift
private extension UIColor {
    convenience init(hex: String) { /* identische Logik wie Color(hex:) */ }
}
```

### Umbenennungen (Adaptive → Kanonisch)

Alle `*Adaptive`-Funktionen fallen weg. Der jeweilige Kurzname wird zur adaptiven Version:

| Alt (Funktion) | Neu (Property) |
|---|---|
| `canvasAdaptive(_ s)` | `canvas` |
| `surfaceCardAdaptive(_ s)` | `surfaceCard` |
| `surfaceStrongAdaptive(_ s)` | `surfaceStrong` |
| `hairlineAdaptive(_ s)` | `hairline` |
| `inkAdaptive(_ s)` | `ink` |
| `bodyTextAdaptive(_ s)` | `bodyText` |
| `mutedAdaptive(_ s, contrast: c)` | `muted` (alle 4 Kombinationen intern) |

Die alten Licht-only Properties (`canvas`, `ink`, `muted`, …) werden durch die adaptiven Versionen ersetzt.

### Inline-Dark-Mode-Checks in Views

Zwei manuelle Checks werden mitbereinigt:

- `ContentView.swift:77` — `.tint(colorScheme == .dark ? .white : AppTheme.primaryColor)` → `.tint(AppTheme.primaryColor)`
- `TripCard.swift:267` — `colorScheme == .dark ? AppTheme.surfaceDarkElevated : AppTheme.surfaceCard` → `.fill(AppTheme.surfaceCard)`

---

## Farbpalette

### Neue Dark-Mode-Werte

| Property | Hell | Dunkel | Problem (Vorher) |
|---|---|---|---|
| `primary` / `primaryColor` | `#292524` | `#e7e5e4` | Near-Black auf near-black Canvas, praktisch unsichtbar |
| `onPrimary` *(neu)* | `#ffffff` | `#1c1917` | Buttontext auf `primary`-Hintergrund |
| `muted` | `#777169` | `#a8a29e` | Direkt ohne Adaptation verwendet, zu dunkel im Dark Mode |
| `mutedSoft` | `#a8a29e` | `#78716c` | Direkt ohne Adaptation verwendet |
| `hairlineStrong` | `#d6d3d1` | `#57534e` | Zu hell (Lichtgrau) in Timeline-Dots und Borders |
| `semanticError` | `#dc2626` | `#f87171` | Kontrastverhältnis ~3.2:1 auf dark Canvas (WCAG AA erfordert 4.5:1) |
| `semanticSuccess` | `#16a34a` | `#4ade80` | Kontrastverhältnis ~2.1:1 auf dark Canvas |

### Unveränderte Werte (nur Form ändert sich)

Diese Properties existieren bereits als `*Adaptive`-Funktionen mit korrekten Werten — sie werden nur zur statischen Property:

| Property | Hell | Dunkel |
|---|---|---|
| `canvas` | `#f5f5f5` | `#1c1917` |
| `surfaceCard` | `#ffffff` | `#292524` |
| `surfaceStrong` | `#f0efed` | `#3c3836` |
| `hairline` | `#e7e5e4` | `#44403c` |
| `ink` | `#0c0a09` | `#ffffff` |
| `bodyText` | `#4e4e4e` | `#c8c2bc` |
| `muted` (Standard) | `#777169` | `#a8a29e` |
| `muted` (High Contrast) | `#565049` | `#c8c2bc` |

### `onPrimary` — neues Property

Buttons verwenden heute `.foregroundColor(.white)` hartkodiert. Das funktioniert nicht wenn `primary` im Dark Mode hell wird. **Nur** `.white`-Text der direkt auf einem `AppTheme.primary`- oder `AppTheme.primaryColor`-Hintergrund sitzt wechselt auf `.foregroundColor(AppTheme.onPrimary)`:

| Datei | Zeile | Kontext |
|---|---|---|
| `DepartureBoardView.swift` | 327 | "Haltestelle auswählen"-Button, `.background(AppTheme.primary)` |
| `StationPickerView.swift` | 689, 750 | Favoriten/Karte-Button, `.background(AppTheme.primaryColor)` |
| `ConnectionsView.swift` | ~488, ~612 | CTA-Button, `.background(AppTheme.primary)` |
| `TicketView.swift` | 538 | Ticket-Button, `.background(AppTheme.primary)` |

`.white`-Text auf Linienbadges (Transport-Linienfarbe) oder semantischen Farben (`semanticError`) bleibt unverändert — diese Hintergründe adaptieren nicht.

---

## Betroffene Dateien

### AppTheme (Definition)
- `Linio/Content/ContentView.swift` — AppTheme-Struct komplett umschreiben

### Views (Boilerplate entfernen + Callsites aktualisieren)
- `Content/DepartureBoardView.swift`
- `Content/SettingsView.swift`
- `Content/TicketView.swift`
- `Content/PlannedTripsView.swift`
- `Content/TripCard.swift`
- `Content/TripDetailView.swift`
- `Content/LegDetailCard.swift`
- `Content/StationPickerView.swift`
- `Content/ConnectionsView.swift`
- `Content/SteigSheet.swift`
- `Content/PrivacyPolicyView.swift`
- `PlannedTripCard.swift`

### Widget
- `RNVLiveActivity/StationDepartureWidget.swift` — kein AppTheme-Import, nicht betroffen

---

## Nicht im Scope

- Neue Farbthemen oder User-wählbare Themes
- Gradient-Orb-Farben (`gradientMint`, `gradientPeach`, …) — dekorativ, keine Kontrast-Anforderung
- Legacy-Aliases (`accentGradient`, `headerBackground`, `cardBackground`, `subtleBackground`, `secondaryColor`) — unverändert
