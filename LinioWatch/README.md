# LinioWatch – Apple Watch App

## 📱 Übersicht

Die LinioWatch App ist eine vollständige Companion-App für die Apple Watch, die ÖPNV-Informationen direkt am Handgelenk bereitstellt.

---

## 🆕 v4.2 Update (August 2026)

### Performance-Verbesserungen
- **Intelligentes Caching** – Reduziert API-Aufrufe um bis zu 60%
- **Offline-Modus** – Gecachte Abfahrten für 1 Stunde verfügbar
- **Auto-Retry** – Automatisches Wiederholen bei Verbindungsfehlern

### Neue Features
- **⭐ Favoriten-Haltestellen** – Quick-Access zu oft genutzten Stationen
- **📊 Cache-Statistiken** – Einsicht in gesparte API-Aufrufe
- **🎯 Verbesserte Complication** – Fortschrittsring mit Linien-Anzeige
- **🔄 Deep Links** – Navigation via URL-Schema

### UI/UX Verbesserungen
- **Vertikale Tab-Navigation** – Natürlichere Wisch-Gesten
- **Progress Bar** – Visueller Fortschritt während der Fahrt
- **Swipe-to-Favorite** – Schnelles Hinzufügen von Favoriten
- **Einstellungen-Tab** – Ersetzt Debug-View für Endnutzer

---

## 🆕 Frühere Features (August 2026)

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

## 📂 Dateistruktur

```
LinioWatch/
├── WatchApp.swift              # App Entry Point
├── WatchModels.swift           # Datenmodelle
├── WatchDataManager.swift      # Datenverwaltung
├── WatchConnectivityManager.swift  # iPhone ↔ Watch Sync (mit Auto-Retry)
├── WatchDirectService.swift    # API-Aufrufe direkt von der Watch
├── WatchCacheManager.swift     # 🆕 Intelligentes Caching-System
├── WatchDemoData.swift         # Demo-Daten für Previews
├── WatchHapticManager.swift    # Haptic Feedback
├── WatchAppIntents.swift       # Siri Shortcuts
├── WatchComplication.swift     # Watch Face Complication
├── WatchLocalization.swift     # Dynamische Lokalisierung
├── Info.plist                  # App-Konfiguration
├── LinioWatch.entitlements     # Berechtigungen
└── Views/
    ├── ContentView.swift       # Haupt-TabView + SettingsView
    ├── ActiveTripView.swift    # Aktive Fahrt mit Progress Bar
    ├── SavedTripsView.swift    # Geplante Fahrten
    ├── DeparturesView.swift    # Abfahrtsmonitor mit Favoriten
    ├── ConnectionSearchView.swift  # Verbindungssuche
    ├── WatchStationPickerView.swift # Haltestellenauswahl
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
```

### Info.plist Einträge
- `WKApplication: true` – Standalone Watch App
- `WKRunsIndependentlyOfCompanionApp: false` – Benötigt iPhone

---

## 🚀 Tabs in der App

| Tab | Icon | Funktion |
|-----|------|----------|
| **Fahrt** | 🚃 | Aktive Fahrt mit Live-Updates |
| **Geplant** | 📅 | Gespeicherte/geplante Fahrten |
| **Abfahrten** | 🕐 | Abfahrtsmonitor an Haltestelle |
| **Suche** | 🔍 | Verbindung suchen |
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

1. **Complication** muss manuell zum Zifferblatt hinzugefügt werden
2. **Siri Shortcuts** erscheinen nach erstem App-Start in den Einstellungen
3. **Haptic Feedback** funktioniert nur auf echter Hardware

---

## 📋 Changelog

### v4.2 (August 2026)
- ✅ **WatchCacheManager** – Intelligentes Caching mit TTL
- ✅ **Favoriten-Haltestellen** – Quick-Access mit Swipe-to-Add
- ✅ **Offline-Modus** – Gecachte Daten für 1 Stunde
- ✅ **Auto-Retry** – Automatisches Wiederholen bei Fehlern
- ✅ **Progress Bar** – Visueller Fahrtfortschritt
- ✅ **Verbesserte Complication** – Mit Fortschrittsring
- ✅ **Einstellungen-Tab** – Cache-Statistiken & Favoriten
- ✅ **Deep Links** – URL-Schema Navigation
- ✅ **Vertikale Tab-Navigation** – Bessere UX

### v4.1 (August 2026)
- ✅ Haptic Feedback für Umstieg und Ankunft
- ✅ Siri Shortcuts mit deutschen Phrasen
- ✅ Watch Face Complication (WidgetKit)

### v4.0
- Erste Watch App Version
- Sync mit iPhone via WatchConnectivity
- Abfahrtsmonitor und Verbindungssuche
