# GraphQLService Dokumentation

## Übersicht

Der `GraphQLService` ist die zentrale Netzwerk- und Datenschicht der Linio-App. Er verwaltet alle API-Aufrufe zur RNV/VRN GraphQL-API und stellt die Datenmodelle bereit.

## Architektur

```
┌─────────────────────────────────────────────────────────────┐
│                       Views / ViewModels                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      GraphQLService                          │
│  ┌───────────────┬──────────────────┬────────────────────┐  │
│  │ Data Models   │  API Methods     │  Query Builders    │  │
│  │ - Station     │  - searchTrips() │  - tripQuery       │  │
│  │ - TripLeg     │  - fetchStops()  │  - stationQuery    │  │
│  │ - DetailedTrip│  - getDepartures │  - departureQuery  │  │
│  └───────────────┴──────────────────┴────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   RNV/VRN GraphQL API                        │
└─────────────────────────────────────────────────────────────┘
```

## Datenmodelle

### Station
Repräsentiert eine Haltestelle.

```swift
struct Station: Identifiable, Codable, Equatable {
    let hafasID: String      // HAFAS-interne ID
    let globalID: String     // Eindeutige globale ID (verwendet als `id`)
    let longName: String     // Vollständiger Name
    let latitude: Double?
    let longitude: Double?
}
```

### TripLeg
Ein einzelnes Segment einer Verbindung.

```swift
struct TripLeg: Identifiable, Codable, Equatable {
    let id: UUID
    let legType: LegType           // .timedLeg, .continuousLeg, .interchangeLeg
    let startStopName: String?
    let endStopName: String?
    let timetabledDeparture: String?
    let estimatedDeparture: String?
    let timetabledArrival: String?
    let estimatedArrival: String?
    let serviceName: String?       // z.B. "5", "S3", "RE10"
    let serviceType: String?       // z.B. "TRAM", "S_BAHN", "REGIONAL"
    // ... weitere Eigenschaften
}
```

### DetailedTrip
Eine vollständige Verbindung mit allen Legs.

```swift
struct DetailedTrip: Identifiable, Codable, Equatable {
    let id: String
    let startTime: String
    let endTime: String
    let interchanges: Int
    let legs: [TripLeg]
    
    var stableID: String { ... }  // Stabiler Hash für Vergleiche
}
```

### OccupancyLevel
Auslastungsgrad eines Fahrzeugs.

```swift
enum OccupancyLevel: String, Codable {
    case unknown = "UNKNOWN"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    
    init(from apiValue: String)  // Unterstützt "I", "II", "III" Format
}
```

## API-Methoden

### Verbindungssuche
```swift
func searchTrips(
    from: Station,
    to: Station,
    dateTime: Date,
    isArrivalTime: Bool
) async throws -> [DetailedTrip]
```

### Haltestellen-Suche
```swift
func fetchStopsAsync(_ query: String) async throws -> [Station]
```

### Abfahrten abrufen
```swift
func fetchDepartures(
    for stationID: String,
    limit: Int
) async throws -> [Departure]
```

## Fehlerbehandlung

```swift
enum GraphQLError: LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case apiError(message: String)
    case noData
}
```

Für UI-Integration verwende `NetworkError` aus `/Services/NetworkError.swift`.

## Caching-Strategie

- **Stations-Cache**: `NSCache` mit 100 Einträgen, 5 Min TTL
- **Trips-Cache**: Kurzfristig (30 Sek) wegen Echtzeitdaten
- **Abfahrten-Cache**: Kein Cache (immer live)

## Best Practices

1. **Async/Await bevorzugen**: Neuere API-Methoden nutzen `async throws`
2. **Fehler granular behandeln**: `NetworkError.from()` für UI-Anzeige
3. **Cancellation unterstützen**: Tasks bei View-Wechsel abbrechen
4. **Retry-Logik**: Bei `isRetryable == true` automatisch wiederholen

## Beispiel

```swift
@MainActor
class TripSearchViewModel: ObservableObject {
    @Published var trips: [DetailedTrip] = []
    @Published var error: NetworkError?
    @Published var isLoading = false
    
    func search(from: Station, to: Station) async {
        isLoading = true
        error = nil
        
        do {
            trips = try await GraphQLService.shared.searchTrips(
                from: from,
                to: to,
                dateTime: Date(),
                isArrivalTime: false
            )
        } catch {
            self.error = NetworkError.from(error)
        }
        
        isLoading = false
    }
}
```

## Refactoring-Plan (Zukunft)

Der GraphQLService (~1550 Zeilen) sollte aufgeteilt werden in:
- `Linio/Models/` - Datenmodelle
- `Linio/Services/TripService.swift` - Verbindungssuche
- `Linio/Services/StationService.swift` - Haltestellen
- `Linio/Services/DepartureService.swift` - Abfahrten
- `Linio/Network/GraphQLClient.swift` - Basis-Client

**Wichtig**: Modelle müssen im gleichen Module bleiben oder über `@_exported import` verfügbar sein.
