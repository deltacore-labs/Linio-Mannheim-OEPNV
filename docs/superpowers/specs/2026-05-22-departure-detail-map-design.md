# Steig-Karte in DepartureTripDetailView

**Datum:** 2026-05-22
**Status:** Design

## Ziel

Beim Antippen einer Abfahrt in der `DepartureBoardView` öffnet sich die `DepartureTripDetailView`. Diese soll am Ende — unterhalb des Streckenverlaufs — eine kleine Karte erhalten, die zeigt, an welchem Steig der Haltestelle der User einsteigen muss. Die Karte ist tippbar und öffnet den bestehenden `SteigSheet` mit allen Abfahrten am Steig.

## Kontext

- `DepartureBoardView` hat bereits zwei separate Sheets:
  - `DepartureTripDetailView` (Linie + Streckenverlauf, **ohne Karte**)
  - `SteigSheet` (Karte + Abfahrten am Steig, geöffnet via Steig-Badge)
- Die Karten-Logik im `SteigSheet` ist funktionsfähig und wird wiederverwendet (gleiche `MapKit`-Darstellung, gleicher `PlatformPin`).
- `getStationQuays(hafasID:accessToken:)` im `GraphQLService` liefert bereits die Steig-Daten.

## Scope

**In Scope:**

- Neue Karten-Sektion in `DepartureTripDetailView` unterhalb des Streckenverlaufs
- Tippen öffnet das bestehende `SteigSheet`
- Sektion bleibt ausgeblendet, wenn kein Steig bekannt oder keine `Station` verfügbar

**Out of Scope:**

- Refactoring des `SteigSheet`
- Eigene wiederverwendbare `QuayMapCard`-Komponente (kann später folgen)
- Änderungen an der `getStationQuays`-API

## Design

### Aufruf-Stelle (`DepartureBoardView.swift`)

`DepartureTripDetailView` erhält zwei neue Parameter:

- `station: Station?` — wird aus `selectedStation` durchgereicht
- `allDepartures: [Departure]` — wird aus `departures` durchgereicht

Beide werden für die Map-Sektion bzw. für die Weitergabe an den `SteigSheet` benötigt.

### Daten-Laden (`DepartureTripDetailView.swift`)

Neue States:

- `@State private var quays: [StationQuay] = []`
- `@State private var isLoadingQuays = false`
- `@State private var showSteigSheet = false`

In `.task` wird zusätzlich zu `loadFullRoute()` ein neues `loadQuays()` aufgerufen (sequenziell — die Reihenfolge ist nicht kritisch, da beide unabhängig sind). Es lädt **nur**, wenn:

- `station?.hafasID` ist gesetzt **und**
- `departure.quayText` ist gesetzt

Andernfalls wird kein API-Call abgesetzt und die Sektion bleibt leer.

Quelle: `graphQLService.getStationQuays(hafasID:accessToken:)`.

### Map-Card-UI

Neue Sektion `quayMapSection`, platziert nach `stopTimelineSection` im `ScrollView`. Sichtbar nur, wenn `!quays.isEmpty && departure.quayText != nil`.

**Aufbau (von oben nach unten):**

1. Header-Zeile:
   - Links: Label `MEIN STEIG` (Caption2, semibold, uppercase, tracking 0.5 — gleicher Stil wie `STRECKENVERLAUF`)
   - Rechts: hervorgehobener `PlatformPin` (Steig-Buchstabe) + Text "Steig X"
2. `MapKit`-Karte (`allowsHitTesting(false)`):
   - Höhe ca. 140 pt
   - Eckenradius 14 pt (wie im `SteigSheet`)
   - Zeigt alle Steige der Haltestelle, relevanter Steig orange hervorgehoben

**Interaktion:**

- Die gesamte Karte (Header + Map) ist in einen `Button` gewrappt
- Tap setzt `showSteigSheet = true`
- `.sheet(isPresented: $showSteigSheet)` präsentiert den bestehenden `SteigSheet(departure:, allDepartures:, station:, graphQLService:, authService:)`

### Sichtbarkeits-Auflösung (`SteigSheet.swift`)

`PlatformPin` ist aktuell als `private struct` deklariert. Wird auf `internal` (Standard-Sichtbarkeit, also kein expliziter Modifier) angehoben, damit `DepartureTripDetailView` ihn auch nutzen kann. Kein Datei-Move.

### Fehlerbehandlung

- Quay-Laden schlägt fehl → `quays` bleibt leer → Sektion erscheint nicht (silent degradation)
- Kein `station` oder kein `quayText` → Sektion erscheint nicht
- Kein `accessToken` → kein API-Call, keine Sektion

Es gibt keine sichtbare Fehlermeldung in der Detail-Ansicht. Die Hauptinformation der Detail-Ansicht (Linie, Zeit, Streckenverlauf) bleibt davon unberührt.

## Datenfluss

```
DepartureBoardView
  ├── selectedStation: Station?
  ├── departures: [Departure]
  └── selectedDeparture: Departure?
        │
        ▼
  DepartureTripDetailView(departure, station, allDepartures, ...)
        │
        ├── .task → loadFullRoute()  (bestehend)
        └── .task → loadQuays()      (neu)
              │
              ▼
          GraphQLService.getStationQuays(hafasID:)
              │
              ▼
          quays: [StationQuay]
              │
              ▼
          quayMapSection (sichtbar wenn quays + quayText)
              │
              └── tap → showSteigSheet = true
                    │
                    ▼
                SteigSheet(departure, allDepartures, station, ...)
```

## Geänderte Dateien

- `Linio/Content/DepartureBoardView.swift`
  - Aufruf von `DepartureTripDetailView` um `station` und `allDepartures` erweitern
  - `DepartureTripDetailView`: zwei neue Parameter, drei neue States, `loadQuays()`-Funktion, `quayMapSection`-View, `.sheet`-Modifier für `SteigSheet`
- `Linio/Content/SteigSheet.swift`
  - `PlatformPin` von `private` auf `internal` heben (oder in eigene Datei verschieben)

## Akzeptanzkriterien

1. Tippt der User auf eine Abfahrt in der Liste, öffnet sich die Detail-Ansicht und enthält am Ende eine Karte, die den Steig zeigt — sofern der Steig bekannt ist.
2. Der relevante Steig ist auf der Karte deutlich hervorgehoben (orange).
3. Tippt der User auf die Karte, öffnet sich der bestehende `SteigSheet` mit allen Abfahrten am Steig.
4. Hat die Abfahrt keinen Steig (`quayText == nil`), erscheint die Sektion nicht — die restliche Detail-Ansicht funktioniert unverändert.
5. Schlägt das Quay-Laden fehl, erscheint die Sektion nicht — keine sichtbare Fehlermeldung.
