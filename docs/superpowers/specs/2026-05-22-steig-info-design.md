# Steig-Info mit MapKit-Sheet

**Datum:** 2026-05-22  
**Status:** Bereit zur Implementierung

## Ziel

Fahrgäste sollen direkt in der Abfahrtstafel sehen, von welchem Steig ihre Bahn abfährt. Bei Unklarheit können sie auf den Steig-Badge tippen, um eine MapKit-Karte der Station mit allen Steig-Pins zu sehen — der gesuchte Steig ist hervorgehoben, der eigene Standort (blauer Punkt) zeigt die Laufrichtung.

Feature gilt für **alle Stationen** (vollständig dynamisch, kein statischer Stationsplan).

---

## Architektur

### Neue Dateien

- `RNV-Transport-App/Content/SteigSheet.swift` — Bottom Sheet mit MapKit + Abfahrtsliste
- Model `StationQuay` wird in `GraphQLService.swift` als eigenständiges Struct definiert

### Geänderte Dateien

- `GraphQLService.swift` — neues `StationQuay`-Model, neue Methode `getStationQuays()`, erweiterter Journeys-Query
- `DepartureBoardView.swift` — `Departure` erhält `quayText`, `DepartureRowView` bekommt Steig-Badge, Sheet-Trigger

---

## Datenmodell

### `StationQuay`

```swift
struct StationQuay: Identifiable {
    let id: String          // hafasID des Einzelhaltepunkts
    let name: String        // z.B. "MA Hauptbahnhof, Steig A"
    let letter: String      // z.B. "A" – letztes Wort des Namens oder letztes boardRef-Segment
    let coordinate: CLLocationCoordinate2D
}
```

### `Departure` — neues Feld

```swift
var quayText: String? = nil  // z.B. "Steig A", nil → Badge ausblenden
```

---

## Datenfluss: `quayText`-Befüllung

Priorität beim Parsen (erste erfolgreiche Quelle gewinnt):

1. **API-Feld `quayText`** auf `journeys.stops` — wird in den Journeys-Query aufgenommen. Falls das Feld im Schema existiert, kommt der Steig direkt als String (z.B. `"Steig A"`).

2. **`stop.hafasID` auf `journeys.stops`** — wird parallel zu `quayText` abgefragt.  
   Format: `de:08222:2505:3:A` → letztes Segment = Steig-Buchstabe.  
   Greift wenn `quayText` null/leer ist.

3. **`boardRef` parsen** — gleicher Mechanismus wie (2), greift nur beim trips-basierten Fallback-Ladepfad (`fetchFirstLegsAsDepartures`), wo `boardRef` bereits im Modell gesetzt wird.

4. **`nil`** — Steig-Badge wird ausgeblendet, kein Fehler.

---

## Datenfluss: Steig-Koordinaten für die Karte

Wenn `SteigSheet` geöffnet wird, lädt `GraphQLService.getStationQuays(hafasID:)` einmalig alle Haltepunkte der Station:

```graphql
{
  station(id: "<hafasID>") {
    stops {
      hafasID
      name
      lat
      lon
    }
  }
}
```

- Letter-Extraktion: letztes Wort von `name` (z.B. `"MA Hauptbahnhof, Steig A"` → `"A"`), Fallback: letztes Segment der `hafasID`.
- Falls `lat`/`lon` null oder 0,0 → Haltepunkt wird nicht auf der Karte angezeigt.
- Falls die Query fehlschlägt oder keine Stops zurückgibt → Karte entfällt, Sheet zeigt nur die Abfahrtsliste.

---

## UI-Komponenten

### Steig-Badge in `DepartureRowView`

- Tippbarer Badge ganz rechts in der Zeile (hinter der Abfahrtszeit).
- Text: `quayText` (z.B. `"Steig A"`).
- Nur sichtbar wenn `quayText != nil`.
- Tap → setzt `selectedSteigDeparture` in `DepartureBoardView` → öffnet `SteigSheet`.
- Styling passt zur App-Palette (analog zu bestehenden Badges in der App).

### `SteigSheet`

Sheet-Struktur (`.sheet` Modifier, `presentationDetents: [.medium, .large]`):

```
┌─────────────────────────────────┐
│  ────  (pull handle)            │
│  MA Hauptbahnhof                │  ← station name, small/gray
│  Steig A                        │  ← large bold
│  Linie 1 · 5 · 5A · 6          │  ← lines at this quay, small/gray
├─────────────────────────────────┤
│  [MapKit-Karte, ~160pt hoch]    │  ← alle Steige als Pins
│    ● A  ○ B  ○ C  ○ D ...       │     gesuchter Steig = orange
│    blauer Punkt = Standort      │
├─────────────────────────────────┤
│  NÄCHSTE ABFAHRTEN              │
│  [1] Rheinau Bf    jetzt        │
│  [5] Weinheim      3 min        │
│  [6] Neuostheim    9 min        │
└─────────────────────────────────┘
```

**MapKit-Details:**
- `Map` mit `MapAnnotation` pro `StationQuay`.
- Hervorgehobener Steig: oranger Pin mit weißem Letter, größer (28 × 28 pt vs 22 × 22 pt).
- Andere Steige: dunkelblauer Pin, grauer Letter.
- `showsUserLocation: true` — nutzt `LocationManager` (bereits im App).
- Karten-Region: automatisch auf alle Pins + Nutzerstandort zentriert (`MKCoordinateRegion` mit Padding).
- Falls keine Koordinaten vorhanden: Karte wird nicht gerendert, Sheet zeigt nur Liste.

**Abfahrtsliste im Sheet:**
- Gefiltert auf `departure.quayText == selectedSteigDeparture.quayText`.
- Sortiert nach Abfahrtszeit.
- Zeigt Linie (farbiger Badge), Richtung, Minuten.

---

## Fehlerbehandlung

| Situation | Verhalten |
|-----------|-----------|
| `quayText == nil` | Badge ausgeblendet, kein Sheet |
| `getStationQuays` schlägt fehl | Sheet öffnet ohne Karte, nur Abfahrtsliste |
| Keine Koordinaten für Steig | Pin wird nicht gerendert, restliche Pins unverändert |
| Keine anderen Abfahrten vom selben Steig | Liste zeigt nur die eine ausgewählte Abfahrt |

---

## Offene technische Frage

**Existiert `quayText` im RNV GraphQL Schema?**  
Kann erst beim ersten App-Start mit echtem Token geprüft werden. Der Code muss so gebaut sein, dass er beim Fehlen des Feldes (GraphQL-Fehler oder null) automatisch auf `boardRef`-Parsing zurückfällt. Beim ersten Aufruf ggf. beide Quellen im Debug-Log ausgeben.

---

## Abgrenzung (nicht im Scope)

- Schematischer Offline-Stationsplan — nicht nötig, da MapKit dynamisch.
- Steig-Info in der Watch-App — separates Feature.
- Steig-Info in Live Activities — separates Feature.
- Navigation zum Steig (Turn-by-Turn) — nicht im Scope.
