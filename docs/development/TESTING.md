# Linio - Testing Guide

## Übersicht

Diese Dokumentation beschreibt die Test-Strategie für die Linio-App.

## Test-Struktur

```
LinioTests/
├── Models/
│   ├── StationModelTests.swift      # Station, StationQuay
│   ├── TripLegTests.swift           # TripLeg, DetailedTrip
│   ├── NetworkErrorTests.swift      # NetworkError Enum
│   └── OccupancyLevelTests.swift    # OccupancyLevel Enum
├── Services/
│   ├── AuthServiceTests.swift       # Authentifizierung
│   ├── TicketRenewalServiceTests.swift # Ticket-Verlängerung
│   └── NetworkErrorFactoryTests.swift  # Error Factory
├── Managers/
│   ├── FavoriteStationsManagerTests.swift # Favoriten
│   └── LiveActivityStateTests.swift      # Live Activity State
├── Helpers/
│   ├── DateFormattingHelperTests.swift   # Datum-Formatierung
│   ├── TransportIconHelperTests.swift    # Transport-Icons
│   └── AccessibilityHelpersTests.swift   # Barrierefreiheit
└── README.md
```

## Test-Konventionen

### Namensschema

`test_<Methode>_<Zustand>_<Erwartung>`

```swift
func test_daysUntilExpiry_whenExpired_returnsNegativeDays() { }
```

### Given-When-Then

```swift
func test_addFavorite_whenUnderLimit_addsSuccessfully() {
    // Given
    let station = createStation(globalID: "de:08222:2471", name: "Hauptbahnhof")
    
    // When
    let result = sut.addFavorite(station: station, label: .home)
    
    // Then
    XCTAssertTrue(result)
    XCTAssertEqual(sut.favorites.count, 1)
}
```

## Test-Abdeckung

| Modul | Tests | Beschreibung |
|-------|-------|--------------|
| StationModelTests | 12 | Station, StationQuay, Codable |
| TripLegTests | 15 | TripLeg, DetailedTrip |
| NetworkErrorTests | 11 | Error-Typen, Retryable |
| OccupancyLevelTests | 10 | API-Parsing, UI-Properties |
| AuthServiceTests | 8 | Token, Auth-Flow |
| TicketRenewalServiceTests | 10 | Expiry, Snooze |
| NetworkErrorFactoryTests | 8 | Factory-Pattern |
| FavoriteStationsManagerTests | 7 | CRUD, Limits |
| LiveActivityStateTests | 6 | State, Notifications |
| DateFormattingHelperTests | 12 | Parsing, Formatting |
| TransportIconHelperTests | 8 | Icons, Linien |
| AccessibilityHelpersTests | 6 | Labels, Hints |

**Gesamt: ~113 Unit Tests**

## Tests ausführen

### Xcode
- `Cmd + U` - Alle Tests
- `Cmd + Ctrl + U` - Aktueller Test

### Terminal
```bash
xcodebuild test \
  -scheme Linio \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Best Practices

✅ **Do:**
- Einen Aspekt pro Test
- Aussagekräftige Namen
- Given-When-Then Struktur
- Tests unabhängig halten

❌ **Don't:**
- Netzwerk-Calls in Unit Tests
- Shared State zwischen Tests
- Sleep ohne XCTestExpectation
