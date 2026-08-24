# LinioWatch – Apple Watch App

## 📱 Übersicht

Die LinioWatch App ist eine vollständige Companion-App für die Apple Watch, die ÖPNV-Informationen direkt am Handgelenk bereitstellt.

---

## 🆕 Neue Features (August 2026)

### 1. ⌚ Haptic Feedback
**Datei:** `WatchHapticManager.swift`

Haptische Benachrichtigungen während der Fahrt:

| Event | Vibration | Timing |
|-------|-----------|--------|
| **Abfahrt-Erinnerung** | Notification | 5 Min vor Abfahrt |
| **Umstieg bald** | Notification | 2 Min vor Ankunft |
| **Jetzt umsteigen!** | Doppel-Vibration | Bei Ankunft am Umstieg |
| **Ankunft bald** | Notification | 2 Min vor Ziel |
| **Angekommen** | Doppel-Erfolg | Am Zielbahnhof |

```swift
// Haptic-Events
WatchHapticManager.shared.startMonitoring(for: trip)
WatchHapticManager.shared.playSuccess()
WatchHapticManager.shared.playWarning()
```

---

### 2. 🗣️ Siri Shortcuts
**Datei:** `WatchAppIntents.swift`

Sprachbefehle für die Apple Watch:

| Befehl | Funktion |
|--------|----------|
| *„Hey Siri, wann fährt die nächste Bahn in Linio"* | Zeigt nächste Abfahrt |
| *„Fahrt Status in Linio"* | Aktueller Fahrt-Status |
| *„Abfahrten in Linio"* | Öffnet Abfahrten-View |

**Intents:**
- `WatchNextDepartureIntent` – Nächste Abfahrt abfragen
- `WatchTripStatusIntent` – Aktuellen Fahrt-Status abfragen
- `WatchDeparturesAtStopIntent` – Abfahrten an Haltestelle

---

### 3. 🎯 Watch Complication
**Datei:** `WatchComplication.swift`

Zeigt nächste Abfahrt direkt auf dem Zifferblatt:

| Typ | Anzeige |
|-----|---------|
| **Circular** | Liniensymbol + Minuten bis Abfahrt |
| **Rectangular** | Linie, Ziel, Zeit + Gauge |
| **Inline** | „5 in 8 min" |
| **Corner** | Minuten + Label |

**Aktualisierung:** Alle 5 Minuten automatisch

```swift
// Widget Configuration
.supportedFamilies([
    .accessoryCircular,
    .accessoryRectangular,
    .accessoryInline,
    .accessoryCorner
])
```

---

### 4. 🏃 Workout Integration
**Dateien:** `WatchWorkoutManager.swift`, `Views/WorkoutView.swift`

Tracke deinen Fußweg zur Haltestelle als HealthKit-Workout:

| Metrik | Beschreibung |
|--------|--------------|
| **Zeit** | Verstrichene Zeit |
| **Distanz** | Gelaufene Meter |
| **Kalorien** | Verbrannte aktive Kalorien |
| **Herzfrequenz** | Live-Puls während des Gehens |

**Workflow:**
1. Zielhaltestelle auswählen
2. Workout starten
3. Zur Haltestelle laufen
4. Workout beenden → Wird in Health gespeichert

**Berechtigungen (Info.plist):**
- `NSHealthShareUsageDescription` – Lesen von Health-Daten
- `NSHealthUpdateUsageDescription` – Schreiben von Workouts

---

## 📂 Dateistruktur

```
LinioWatch/
├── WatchApp.swift              # App Entry Point
├── WatchModels.swift           # Datenmodelle
├── WatchDataManager.swift      # Datenverwaltung
├── WatchConnectivityManager.swift  # iPhone ↔ Watch Sync
├── WatchDirectService.swift    # API-Aufrufe direkt von der Watch
├── WatchDemoData.swift         # Demo-Daten für Previews
├── WatchHapticManager.swift    # 🆕 Haptic Feedback
├── WatchAppIntents.swift       # 🆕 Siri Shortcuts
├── WatchComplication.swift     # 🆕 Watch Face Complication
├── WatchWorkoutManager.swift   # 🆕 HealthKit Workout
├── Info.plist                  # App-Konfiguration
├── LinioWatch.entitlements     # Berechtigungen
└── Views/
    ├── ContentView.swift       # Haupt-TabView
    ├── ActiveTripView.swift    # Aktive Fahrt anzeigen
    ├── SavedTripsView.swift    # Geplante Fahrten
    ├── DeparturesView.swift    # Abfahrtsmonitor
    ├── ConnectionSearchView.swift  # Verbindungssuche
    ├── WatchStationPickerView.swift # Haltestellenauswahl
    ├── WorkoutView.swift       # 🆕 Workout-Tracking
    └── DebugView.swift         # Debug-Informationen
```

---

## 🔧 Konfiguration

### Entitlements
```xml
<!-- LinioWatch.entitlements -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.stefanfriedrich.rnvapp</string>
</array>
<key>com.apple.developer.healthkit</key>
<true/>
```

### Info.plist Einträge
- `WKApplication: true` – Standalone Watch App
- `WKRunsIndependentlyOfCompanionApp: false` – Benötigt iPhone
- Health Usage Descriptions für Workout-Feature

---

## 🚀 Tabs in der App

| Tab | Icon | Funktion |
|-----|------|----------|
| **Fahrt** | 🚃 | Aktive Fahrt mit Live-Updates |
| **Geplant** | 📅 | Gespeicherte/geplante Fahrten |
| **Abfahrten** | 🕐 | Abfahrtsmonitor an Haltestelle |
| **Suche** | 🔍 | Verbindung suchen |
| **Workout** | 🚶 | 🆕 Fußweg zur Haltestelle tracken |
| **Debug** | 🐞 | Debug-Informationen |

---

## 📡 Daten-Synchronisation

Die Watch App bezieht Daten über:

1. **WatchConnectivity** – Sync mit iPhone App
2. **App Group** – Geteilte UserDefaults (`group.com.stefanfriedrich.rnvapp`)
3. **Direct API** – Direkte GraphQL-Aufrufe von der Watch

---

## 🧪 Testen

### Simulator
```bash
xcodebuild -scheme LinioWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' \
  build
```

### Previews
Alle Views haben `#Preview` Makros für schnelles Testen in Xcode.

---

## ⚠️ Hinweise

1. **HealthKit** benötigt echte Apple Watch für vollständige Funktionalität
2. **Complication** muss manuell zum Zifferblatt hinzugefügt werden
3. **Siri Shortcuts** erscheinen nach erstem App-Start in den Einstellungen
4. **Haptic Feedback** funktioniert nur auf echter Hardware

---

## 📋 Changelog

### v4.1 (August 2026)
- ✅ Haptic Feedback für Umstieg und Ankunft
- ✅ Siri Shortcuts mit deutschen Phrasen
- ✅ Watch Face Complication (WidgetKit)
- ✅ Workout-Tracking für Fußweg zur Haltestelle
- ✅ Neuer Workout-Tab in der App

### v4.0
- Erste Watch App Version
- Sync mit iPhone via WatchConnectivity
- Abfahrtsmonitor und Verbindungssuche
