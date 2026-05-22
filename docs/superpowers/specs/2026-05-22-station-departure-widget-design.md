# Station Departure Widget

**Datum:** 2026-05-22  
**Status:** Bereit zur Implementierung

## Ziel

Ein neues konfigurierbares Home Screen Widget, das die nächsten Abfahrten einer frei wählbaren Haltestelle anzeigt. Der Nutzer legt die Station einmalig per Widget-Konfiguration fest (langes Drücken → „Widget bearbeiten") und sieht ab sofort immer aktuelle Abfahrtszeiten direkt auf dem Home Screen — ohne die App öffnen zu müssen.

---

## Unterstützte Größen

| Größe | Abfahrten |
|-------|-----------|
| Small (2×2) | 1 nächste Abfahrt |
| Medium (4×2) | 3 Abfahrten |
| Large (4×4) | 6 Abfahrten |

---

## Architektur

### Neuer Ansatz: Widget fetcht direkt (Ansatz A)

Das Widget-Extension-Target ruft die GraphQL-API selbst auf. Der Auth-Token wird von der Haupt-App in die App Group UserDefaults geschrieben und vom Widget dort gelesen. Die Netzwerk-Logik ist minimal und eigenständig im Widget-Target implementiert (kein geteiltes Framework nötig).

### Neue Dateien

- `RNVLiveActivity/StationDepartureWidget.swift` — Gesamtes Widget in einer Datei

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `AuthService.swift` | Token bei Login/Refresh in `AppGroup["widgetAccessToken"]` schreiben |
| `DepartureBoardView.swift` oder `StationPickerView.swift` | Gewählte Station in `AppGroup["recentWidgetStations"]` speichern (max. 10) |
| `LiveActivityState.swift` | `WidgetCenter.reloadTimelines("StationDepartureWidget")` bei App-Öffnung |
| `RNVLiveActivityBundle.swift` | `StationDepartureWidget()` zum Bundle hinzufügen |
| `Mannheim ÖPNV.xcodeproj` | Neue Datei zum Widget-Target hinzufügen |

---

## Datenmodell

### `WidgetDeparture`

```swift
struct WidgetDeparture: Codable {
    let serviceName: String       // "Linie 5"
    let serviceType: String       // "STRASSENBAHN", "BUS", "S_BAHN", etc.
    let destination: String       // "Heidelberg Hbf"
    let plannedTimeISO: String    // ISO8601
    let delayMinutes: Int?        // nil = kein Info, 0 = pünktlich
    let quayText: String?         // "Steig A", nil = ausblenden
}
```

### `StationEntity`

```swift
struct StationEntity: AppEntity {
    let id: String      // globalID (z.B. "de:08222:2505")
    let name: String    // "Mannheim Hbf"
    let hafasID: String // für API-Abfragen
}
```

### `StationDepartureEntry`

```swift
struct StationDepartureEntry: TimelineEntry {
    let date: Date
    let stationName: String
    let departures: [WidgetDeparture]
    let isPlaceholder: Bool
    let errorState: ErrorState?

    enum ErrorState {
        case noToken, noStation, networkError, noDepartures
    }
}
```

---

## Stationsauswahl via AppIntent

### `StationSelectionIntent`

```swift
struct StationSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Station wählen"
    @Parameter(title: "Haltestelle") var station: StationEntity?
}
```

### `StationEntityQuery`

Liefert Vorschläge aus `AppGroup["recentWidgetStations"]` — eine Liste der zuletzt in der App genutzten Stationen (bis zu 10 Einträge, als JSON in UserDefaults gespeichert). Keine Echtzeit-Suche im Intent nötig.

---

## Datenfluss

```
Haupt-App:
  Login / Token-Refresh  →  AppGroup["widgetAccessToken"] = accessToken
  Stationsauswahl        →  AppGroup["recentWidgetStations"] = [StationEntity, ...]  (max. 10)
  App wird geöffnet      →  WidgetCenter.reloadTimelines("StationDepartureWidget")

Widget-Extension (getTimeline):
  1. Token aus AppGroup lesen
     → fehlt: Entry mit .noToken zurückgeben
  2. Station aus Intent lesen
     → fehlt: Entry mit .noStation zurückgeben
  3. GET getDeparturesViaJourneys(hafasID:) per URLSession
     → Fehler: letzte bekannte Daten + .networkError
  4. JSON → [WidgetDeparture] parsen
  5. Timeline mit 15-min-Policy zurückgeben
```

---

## Netzwerkaufruf im Widget

Eigenständiger, schlanker GraphQL-Fetch (~80–100 Zeilen) direkt in `StationDepartureWidget.swift`:
- Verwendet `URLSession.shared` mit async/await
- Gleiche Journeys-Query wie `GraphQLService.getDeparturesViaJourneys()`
- Parst nur die für das Widget nötigen Felder: `serviceName`, `serviceType`, `destination`, `plannedTime`, `delay`, `quayText`
- Kein Import von `GraphQLService` oder anderen App-Targets

---

## Refresh-Strategie

| Trigger | Aktion |
|---------|--------|
| Timeline läuft ab | Automatisch alle 15 Minuten (`.after(now + 15 min)`) |
| App wird geöffnet | `WidgetCenter.reloadTimelines("StationDepartureWidget")` |
| Token wird erneuert | `WidgetCenter.reloadTimelines("StationDepartureWidget")` |

---

## Views

### Small View

```
┌─────────────────┐
│ 📍 Mannheim Hbf │   ← klein, grau
│                 │
│ [T] 5           │   ← Line-Badge (Farbe aus WidgetTheme.lineColor)
│ Heidelberg      │   ← Richtung, 1 Zeile
│                 │
│ 14:35      3'   │   ← Uhrzeit links, Countdown rechts
└─────────────────┘
```

### Medium View

```
┌──────────────────────────────────┐
│ 📍 Mannheim Hbf          14:32  │
├──────────────────────────────────┤
│ [T] 5   Heidelberg Hbf    3'    │
│ [B] 33  Neustadt          12'   │
│ [T] 5A  Käfertal          18'   │
└──────────────────────────────────┘
```

### Large View

```
┌──────────────────────────────────┐
│ 📍 Mannheim Hbf          14:32  │
├──────────────────────────────────┤
│ [T] 5   Heidelberg Hbf    3'    │
│ [B] 33  Neustadt          12'   │
│ [T] 5A  Käfertal          18'   │
│ [T] 1   Schönau           24'   │
│ [S] S1  Frankfurt         31'   │
│ [B] 63  Seckenheim        39'   │
└──────────────────────────────────┘
```

**Delay-Anzeige:** Wenn `delayMinutes > 0`, wird die Planzeit durchgestrichen und die Echtzeit in Orange daneben angezeigt. Beispiel: `~~14:35~~ 14:38`.

**Line-Badge:** Wiederverwendung von `WidgetLineBadge` und `WidgetTheme` aus `HomeScreenWidgets.swift`.

---

## Fehlerzustände

| Zustand | Anzeige |
|---------|---------|
| Kein Token | „Bitte App öffnen und anmelden" |
| Keine Station konfiguriert | „Station konfigurieren" + kurzer Hinweistext |
| Netzwerkfehler | Letzte bekannte Daten + „⚠ veraltet"-Badge |
| Keine Abfahrten in 60 min | „Keine Abfahrten" + Liniensymbol |
| Placeholder | Grau gefüllte Rechtecke (iOS-Standard) |

---

## Abgrenzung (nicht im Scope)

- Echtzeit-Stationssuche im Widget-Intent — Stationen kommen aus der App-History
- Mehrere Stationen gleichzeitig im selben Widget — ein Widget = eine Station
- Filter nach Linie oder Richtung — zeigt alle Abfahrten
- Watch-Widget — separates Feature
- Offline-Cache (Abfahrten persistent speichern) — kein Offline-Betrieb vorgesehen
