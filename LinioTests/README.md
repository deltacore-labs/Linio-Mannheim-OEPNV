# Linio Unit Tests

## Übersicht

Dieses Verzeichnis enthält Unit-Tests für die Linio-App. Die Tests sind nach Funktionsbereichen organisiert.

## Test-Dateien

| Datei | Beschreibung |
|-------|--------------|
| `DateFormattingHelperTests.swift` | Tests für Datum/Zeit-Parsing und -Formatierung |
| `OccupancyLevelTests.swift` | Tests für Auslastungs-Enum (API-Parsing, UI-Properties) |
| `StationModelTests.swift` | Tests für Station und StationQuay-Modelle |
| `TransportIconHelperTests.swift` | Tests für Transport-Icons und Linien-Erkennung |
| `TripLegTests.swift` | Tests für TripLeg und DetailedTrip-Modelle |

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
