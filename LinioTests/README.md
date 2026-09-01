# Linio Unit Tests

## Übersicht

Dieses Verzeichnis enthält Unit-Tests für die Linio-App. Die Tests sind nach Funktionsbereichen organisiert und folgen dem Given-When-Then Muster.

## Test-Dateien

| Datei | Beschreibung | Tests |
|-------|--------------|-------|
| `AccessibilityHelpersTests.swift` | Tests für Barrierefreiheit-Helfer | 6 |
| `AuthServiceTests.swift` | Tests für Authentifizierung & Token-Management | 8 |
| `DateFormattingHelperTests.swift` | Tests für Datum/Zeit-Parsing und -Formatierung | 12 |
| `FavoriteStationsManagerTests.swift` | Tests für Favoriten-Haltestellen | 7 |
| `LiveActivityStateTests.swift` | Tests für Live Activity Status | 6 |
| `NetworkErrorFactoryTests.swift` | Tests für Netzwerk-Error-Factory | 8 |
| `NetworkErrorTests.swift` | Tests für NetworkError-Enum | 11 |
| `OccupancyLevelTests.swift` | Tests für Auslastungs-Enum | 10 |
| `StationModelTests.swift` | Tests für Station-Modelle | 12 |
| `TicketRenewalServiceTests.swift` | Tests für Ticket-Verlängerungslogik | 10 |
| `TransportIconHelperTests.swift` | Tests für Transport-Icons | 8 |
| `TripLegTests.swift` | Tests für Trip/Leg-Modelle | 15 |

**Gesamt: ~113 Unit Tests**

## Test-Kategorien

### Models (48 Tests)
- **StationModelTests**: Station-Initialisierung, Codable, Equatable
- **TripLegTests**: TripLeg-Parsing, Berechnungen, Edge Cases
- **NetworkErrorTests**: Error-Typen, LocalizedError, isRetryable
- **OccupancyLevelTests**: API-Werte, UI-Properties, Farben

### Services (26 Tests)
- **AuthServiceTests**: Initial State, Token-Validierung, Auth-Flow
- **TicketRenewalServiceTests**: Ablauf-Berechnung, Badge-States, Snooze
- **NetworkErrorFactoryTests**: Factory-Pattern, Error-Mapping

### Managers (13 Tests)
- **FavoriteStationsManagerTests**: CRUD-Operationen, Labels, Limits
- **LiveActivityStateTests**: Trip-Aktivierung, Thread-Sicherheit, Notifications

### Helpers (26 Tests)
- **DateFormattingHelperTests**: ISO8601-Parsing, relative Zeiten
- **TransportIconHelperTests**: SF-Symbols, Linien-Erkennung
- **AccessibilityHelpersTests**: VoiceOver-Labels, Hints

## Test-Target einrichten

Da das Test-Target noch nicht im Xcode-Projekt existiert, muss es manuell hinzugefügt werden:

### Option 1: In Xcode (empfohlen)

1. Öffne `Linio.xcodeproj` in Xcode
2. File → New → Target
3. Wähle "iOS Unit Testing Bundle"
4. Name: `LinioTests`
5. Bundle Identifier: `Stefan.Mannheim-Transportation.LinioTests`
6. Team: Dein Development Team
7. Host Application: `Linio`
8. Nach Erstellung: Ziehe alle `.swift` Dateien aus diesem Ordner ins neue Target

### Option 2: Mit xcodeproj Ruby Gem

```bash
cd /Users/I767513/Xcode/RNV-Transport-App
gem install xcodeproj
ruby add_test_target.rb
```

## Tests ausführen

Nach Einrichtung des Test-Targets:

- In Xcode: `Cmd + U`
- Terminal: `xcodebuild test -scheme Linio -destination 'platform=iOS Simulator,name=iPhone 16'`

## Test-Konventionen

- Test-Methoden folgen dem Schema: `test<Was>_<Zustand>_<Erwartung>()`
- Jeder Test hat Given/When/Then-Kommentare
- Tests sind unabhängig und können in beliebiger Reihenfolge laufen
