# Steig-Karte in DepartureTripDetailView — Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Beim Öffnen der Detail-Ansicht einer Abfahrt (`DepartureTripDetailView`) erscheint unterhalb des Streckenverlaufs eine kleine Karte, die den relevanten Steig der Haltestelle hervorhebt. Tippen öffnet den bestehenden `SteigSheet`.

**Architecture:** `DepartureTripDetailView` bekommt zwei neue Parameter (`station`, `allDepartures`) durchgereicht. Eine zusätzliche `loadQuays()`-Funktion lädt die Steig-Daten via bestehender `getStationQuays(hafasID:accessToken:)`-API. Eine neue `quayMapSection`-View zeigt die Karte (`PlatformPin` wird aus `SteigSheet.swift` zugänglich gemacht). Tap auf die Karte öffnet das bestehende `SteigSheet`.

**Tech Stack:** SwiftUI, MapKit, GraphQL (bestehender `GraphQLService`)

**Spec:** `docs/superpowers/specs/2026-05-22-departure-detail-map-design.md`

---

### Task 1: `PlatformPin` zugänglich machen

**Files:**
- Modify: `Linio/Content/SteigSheet.swift` — Zeile 184

`PlatformPin` ist als `private struct` deklariert. Damit ihn auch `DepartureTripDetailView` (in `DepartureBoardView.swift`) nutzen kann, muss die Sichtbarkeit angehoben werden.

- [ ] **Schritt 1: `private` auf `PlatformPin` entfernen**

In `SteigSheet.swift`, Zeile 184:

Von:
```swift
private struct PlatformPin: View {
```

auf:
```swift
struct PlatformPin: View {
```

(Standard-Sichtbarkeit ist `internal`, kein expliziter Modifier nötig.)

- [ ] **Schritt 2: Projekt bauen (⌘B)**

Erwartet: Build Succeeded. Kein Verhaltens-Unterschied — `PlatformPin` wird bisher nur innerhalb dieser Datei genutzt.

- [ ] **Schritt 3: Commit**

```bash
git add Linio/Content/SteigSheet.swift
git commit -m "refactor: PlatformPin von private auf internal"
```

---

### Task 2: Neue Parameter in `DepartureTripDetailView`

**Files:**
- Modify: `Linio/Content/DepartureBoardView.swift` — Struct-Definition (ab ca. Zeile 622) und Aufruf-Stelle (ab ca. Zeile 107)

Zwei neue Parameter werden an `DepartureTripDetailView` durchgereicht: die `Station` (für die `hafasID` zum Quay-Laden) und `allDepartures` (zum Weiterreichen an den `SteigSheet`).

- [ ] **Schritt 1: Properties zu `DepartureTripDetailView` hinzufügen**

In `DepartureBoardView.swift`, im `DepartureTripDetailView`-Struct (ca. Zeile 622–625):

Von:
```swift
struct DepartureTripDetailView: View {
    let departure: Departure
    let graphQLService: GraphQLService
    let authService: AuthService
```

auf:
```swift
struct DepartureTripDetailView: View {
    let departure: Departure
    let station: Station?
    let allDepartures: [Departure]
    let graphQLService: GraphQLService
    let authService: AuthService
```

- [ ] **Schritt 2: Aufruf-Stelle in `DepartureBoardView` anpassen**

In `DepartureBoardView.swift`, im `.sheet(item: $selectedDeparture)`-Block (ca. Zeile 107–115):

Von:
```swift
.sheet(item: $selectedDeparture) { dep in
    DepartureTripDetailView(
        departure: dep,
        graphQLService: service,
        authService: authService
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
}
```

auf:
```swift
.sheet(item: $selectedDeparture) { dep in
    DepartureTripDetailView(
        departure: dep,
        station: selectedStation,
        allDepartures: departures,
        graphQLService: service,
        authService: authService
    )
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
}
```

- [ ] **Schritt 3: Projekt bauen (⌘B)**

Erwartet: Build Succeeded. Kein sichtbares Verhaltens-Update — die neuen Parameter werden noch nicht verwendet.

- [ ] **Schritt 4: Commit**

```bash
git add Linio/Content/DepartureBoardView.swift
git commit -m "feat: station und allDepartures an DepartureTripDetailView durchreichen"
```

---

### Task 3: Quay-Daten laden

**Files:**
- Modify: `Linio/Content/DepartureBoardView.swift` — `DepartureTripDetailView`

Drei neue States plus eine `loadQuays()`-Funktion. Wird parallel zum bestehenden `loadFullRoute()` im `.task`-Modifier aufgerufen.

- [ ] **Schritt 1: Neue `@State`-Properties hinzufügen**

In `DepartureTripDetailView`, nach dem bestehenden `@State private var isLoadingFullRoute = false` (ca. Zeile 633):

```swift
@State private var quays: [StationQuay] = []
@State private var isLoadingQuays = false
@State private var showSteigSheet = false
```

- [ ] **Schritt 2: `loadQuays()`-Methode hinzufügen**

In `DepartureTripDetailView`, direkt nach der bestehenden `loadFullRoute()`-Methode (ca. Zeile 687, also nach der schließenden `}` von `loadFullRoute`):

```swift
private func loadQuays() async {
    guard let station = station,
          !station.hafasID.isEmpty,
          departure.quayText != nil,
          let token = authService.accessToken else { return }
    isLoadingQuays = true
    quays = await graphQLService.getStationQuays(
        hafasID: station.hafasID,
        accessToken: token
    )
    isLoadingQuays = false
}
```

- [ ] **Schritt 3: `.task` erweitern**

Im `body` von `DepartureTripDetailView`, im `.task`-Block (ca. Zeile 665–667):

Von:
```swift
.task {
    await loadFullRoute()
}
```

auf:
```swift
.task {
    await loadFullRoute()
    await loadQuays()
}
```

- [ ] **Schritt 4: Projekt bauen (⌘B)**

Erwartet: Build Succeeded. Quays werden geladen, aber noch nicht angezeigt.

- [ ] **Schritt 5: Commit**

```bash
git add Linio/Content/DepartureBoardView.swift
git commit -m "feat: Quay-Daten in DepartureTripDetailView laden"
```

---

### Task 4: `quayMapSection`-View und SteigSheet-Trigger

**Files:**
- Modify: `Linio/Content/DepartureBoardView.swift` — `DepartureTripDetailView`

Die neue Sektion zeigt einen Header mit Steig-Buchstaben und eine MapKit-Karte. Die ganze Sektion ist tippbar und öffnet den `SteigSheet`.

- [ ] **Schritt 1: `MapKit`-Import in `DepartureBoardView.swift` ergänzen**

Falls noch nicht vorhanden (Datei-Anfang prüfen): direkt nach `import CoreLocation` (ca. Zeile 7) hinzufügen:

```swift
import MapKit
```

(Falls `import MapKit` bereits steht, Schritt überspringen.)

- [ ] **Schritt 2: `quayMapRegion` computed property hinzufügen**

In `DepartureTripDetailView`, vor `// MARK: Header` (ca. Zeile 700), neue MARK-Sektion einfügen:

```swift
// MARK: Quay Map

private var selectedQuayLetter: String? {
    departure.quayText.flatMap {
        $0.split(separator: " ").last.map(String.init)
    }
}

private var quayMapRegion: MKCoordinateRegion {
    let lats = quays.map { $0.coordinate.latitude }
    let lons = quays.map { $0.coordinate.longitude }
    guard let minLat = lats.min(), let maxLat = lats.max(),
          let minLon = lons.min(), let maxLon = lons.max() else {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.48, longitude: 8.47),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }
    let center = CLLocationCoordinate2D(
        latitude: (minLat + maxLat) / 2,
        longitude: (minLon + maxLon) / 2
    )
    let span = MKCoordinateSpan(
        latitudeDelta: max((maxLat - minLat) * 1.8, 0.002),
        longitudeDelta: max((maxLon - minLon) * 1.8, 0.002)
    )
    return MKCoordinateRegion(center: center, span: span)
}
```

- [ ] **Schritt 3: `quayMapSection` View hinzufügen**

Direkt nach den `quayMapRegion`-Properties aus Schritt 2:

```swift
@ViewBuilder
private var quayMapSection: some View {
    if !quays.isEmpty, let quayText = departure.quayText {
        Button {
            HapticHelper.selection()
            showSteigSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("MEIN STEIG")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                        .tracking(0.5)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    if let letter = selectedQuayLetter {
                        HStack(spacing: 6) {
                            PlatformPin(letter: letter, isHighlighted: true)
                                .scaleEffect(0.7)
                                .frame(width: 24, height: 24)
                            Text(quayText)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.inkAdaptive(colorScheme))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Map(
                    coordinateRegion: .constant(quayMapRegion),
                    annotationItems: quays
                ) { quay in
                    MapAnnotation(coordinate: quay.coordinate) {
                        PlatformPin(
                            letter: quay.letter,
                            isHighlighted: quay.letter == selectedQuayLetter
                        )
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .allowsHitTesting(false)
                .padding(.horizontal, 20)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quayText) auf der Karte. Tippen für Details und alle Abfahrten am Steig.")
    }
}
```

- [ ] **Schritt 4: Sektion in `body` einbinden**

Im `body` von `DepartureTripDetailView`, im `ScrollView`-`VStack` (ca. Zeile 645–654):

Von:
```swift
ScrollView {
    VStack(spacing: 0) {
        headerSection
        Divider().padding(.horizontal, 20)
        statusSection
        Divider().padding(.horizontal, 20)
        if hasStopData {
            stopTimelineSection
        }
        Spacer(minLength: 48)
    }
}
```

auf:
```swift
ScrollView {
    VStack(spacing: 0) {
        headerSection
        Divider().padding(.horizontal, 20)
        statusSection
        Divider().padding(.horizontal, 20)
        if hasStopData {
            stopTimelineSection
        }
        quayMapSection
        Spacer(minLength: 48)
    }
}
```

- [ ] **Schritt 5: `.sheet` für `SteigSheet` hinzufügen**

In `DepartureTripDetailView`, direkt nach dem `.task`-Modifier (ca. Zeile 668):

Von:
```swift
.task {
    await loadFullRoute()
    await loadQuays()
}
```

auf:
```swift
.task {
    await loadFullRoute()
    await loadQuays()
}
.sheet(isPresented: $showSteigSheet) {
    if let station = station {
        SteigSheet(
            departure: departure,
            allDepartures: allDepartures,
            station: station,
            graphQLService: graphQLService,
            authService: authService
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
```

- [ ] **Schritt 6: Projekt bauen (⌘B)**

Erwartet: Build Succeeded.

- [ ] **Schritt 7: Smoke-Test im Simulator**

Im iPhone-Simulator starten:
1. Abfahrtenseite öffnen (Tab "Abfahrten")
2. Eine Haltestelle wählen, bei der Steig-Daten erwartet werden (z. B. "Mannheim Hauptbahnhof")
3. Auf eine Abfahrt mit Steig-Badge tippen → Detail-Ansicht öffnet sich
4. Erwartet: Unten in der Detail-Ansicht erscheint der Block "MEIN STEIG" mit Karte und hervorgehobenem Steig
5. Auf die Karte tippen → `SteigSheet` öffnet sich mit Abfahrten am Steig
6. Bei einer Abfahrt **ohne** `quayText` (falls vorhanden): Detail-Ansicht erscheint **ohne** Map-Sektion, kein Crash

- [ ] **Schritt 8: Commit**

```bash
git add Linio/Content/DepartureBoardView.swift
git commit -m "feat: Steig-Karte in DepartureTripDetailView — tappable, öffnet SteigSheet"
```

---

## Hinweis: Commit-Verhalten

Die Commit-Schritte folgen dem Plan-Format dieses Repos. Da `CLAUDE.md` "niemals eigenständig committen" vorschreibt, bestätigt der User die Commits einzeln, bevor sie ausgeführt werden.
