# Caching-Strategie für Linio

## Übersicht

Die Linio-App verwendet verschiedene Caching-Ebenen für optimale Performance und Offline-Fähigkeit.

## App Group Shared Storage

**Identifier:** `group.com.stefanfriedrich.rnvapp`

Verwendet für Datenaustausch zwischen:
- Haupt-App
- Widgets (LinioLiveActivity)
- Apple Watch (LinioWatch)

### Gespeicherte Daten

| Key | Typ | Beschreibung | Geschrieben von |
|-----|-----|--------------|-----------------|
| `activeTrips` | `[String]` | IDs aktiver Trip-Verfolgungen | Haupt-App |
| `savedTripData` | `Data` (JSON) | Vollständige Trip-Daten für Widgets | Haupt-App |
| `plannedTripData` | `Data` (JSON) | Geplante Verbindungen für Watch | Haupt-App |
| `widgetAccessToken` | `String` | Auth-Token für Widget-API-Calls | AuthService |
| `widgetAccessTokenExpiry` | `TimeInterval` | Token-Ablaufzeitpunkt | AuthService |
| `widgetRecentStations` | `Data` (JSON) | Letzte Stationen für Widget-Intent | StationPickerView |
| `widgetFavoriteStations` | `Data` (JSON) | Favoriten für Widget-Intent | FavoriteStationsManager |

## Datenmodelle für Shared Storage

### WidgetTripData (für Widgets)
```swift
struct WidgetTripData: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let interchanges: Int
    let startStation: String
    let endStation: String
    let legs: [WidgetTripLegData]
}
```

### TripData (für Watch)
```swift
struct TripData: Codable {
    let id: String
    let departure: String
    let arrival: String
    let destination: String
    let lineName: String?
}
```

## Synchronisation

### App → Widget
```swift
// TripDataManager.swift
func saveTripForWidget(_ trip: DetailedTrip) {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
    
    // Konvertiere zu Widget-Format
    let widgetTrip = WidgetTripData(from: trip)
    
    // Speichere
    if let data = try? JSONEncoder().encode(widgetTrip) {
        defaults.set(data, forKey: "savedTripData")
    }
    
    // Trigger Widget-Refresh
    WidgetCenter.shared.reloadAllTimelines()
}
```

### App → Watch
```swift
// PhoneConnectivityManager.swift
func syncTripData() {
    let defaults = UserDefaults(suiteName: appGroupID)
    
    var context = WCSession.default.applicationContext
    if let tripData = defaults?.data(forKey: "plannedTripData") {
        context["plannedTripData"] = tripData
    }
    
    try? WCSession.default.updateApplicationContext(context)
}
```

## Best Practices

### 1. Schreiben
- Immer auf Main-Thread oder mit `@MainActor`
- Nach Schreiben: `WidgetCenter.shared.reloadAllTimelines()` aufrufen
- Daten kompakt halten (Widgets haben begrenzte Ladezeit)

### 2. Lesen
- Defensive Programmierung: Immer mit `guard let` prüfen
- Decoder-Fehler abfangen
- Fallback-Werte bereitstellen

### 3. Token-Handling
- Token nur in App Group speichern, wenn Widget-Zugriff nötig
- Token-Ablauf prüfen bevor API-Calls
- Bei abgelaufenem Token: Widget zeigt Login-Hinweis

## Performance-Tipps

1. **Batching**: Mehrere Schreibvorgänge sammeln
2. **Lazy Loading**: Daten nur bei Bedarf laden
3. **Cleanup**: Alte/abgelaufene Trips regelmäßig entfernen
4. **Komprimierung**: Große Datenmengen mit JSONEncoder komprimieren

## Debugging

```swift
// Alle App Group Daten auslesen
func debugPrintAppGroupData() {
    guard let defaults = UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp") else { return }
    
    print("=== App Group Contents ===")
    defaults.dictionaryRepresentation().forEach { key, value in
        if key.hasPrefix("widget") || key.contains("Trip") {
            print("\(key): \(type(of: value))")
        }
    }
}
```

## Sicherheit

- Auth-Tokens sollten langfristig in Keychain migriert werden
- Sensible Daten nicht in Klartext speichern
- App Group nur für notwendige Daten verwenden
