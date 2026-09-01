# Linio - Code Style Guide

## Übersicht

Dieses Dokument definiert die Coding-Standards für das Linio-Projekt.

## SwiftLint

Die Konfiguration befindet sich in `/.swiftlint.yml`.

### Installation

```bash
brew install swiftlint
```

### Build Phase hinzufügen

```bash
if which swiftlint >/dev/null; then
  swiftlint
fi
```

## Namenskonventionen

### Typen
- `PascalCase` für Klassen, Structs, Enums, Protocols
- Suffix `Protocol` für Protocols: `AuthServiceProtocol`
- Suffix `Manager` für State-Manager: `FavoriteStationsManager`
- Suffix `Helper` für Utility-Klassen: `DateFormattingHelper`

### Variablen & Funktionen
- `camelCase` für Variablen und Funktionen
- Präfix `is`/`has`/`should` für Booleans: `isAuthenticated`, `hasTicket`
- Verb-Präfix für Actions: `fetchConnections()`, `updateBadge()`

### Dateien
- Ein Haupttyp pro Datei
- Extensions mit `+Extension`: `GraphQLService+Connections.swift`
- Tests mit `Tests` Suffix: `AuthServiceTests.swift`

## Code-Organisation

### MARK Sections

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - UI Components
```

### Empfohlene Reihenfolge

```swift
class MyService {
    // MARK: - Properties
    static let shared = MyService()
    @Published var data: [Item] = []
    private var cache: [String: Item] = [:]
    
    // MARK: - Initialization
    init() { }
    
    // MARK: - Public Methods
    func fetchData() { }
    
    // MARK: - Private Methods
    private func processData() { }
}
```

## Logging

### Debug-Logs

```swift
// ✅ Richtig
DebugLog.log("Loading connections")

// ✅ Akzeptabel in DEBUG
#if DEBUG
print("Debug info: \(value)")
#endif

// ❌ Falsch - kein ungeschütztes print()
print("Loading connections")
```

## SwiftUI Best Practices

### View-Struktur

```swift
struct MyView: View {
    // MARK: - Environment & State
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    // MARK: - Properties
    let title: String
    
    // MARK: - Body
    var body: some View {
        content
    }
    
    // MARK: - View Components
    private var content: some View { }
    private var headerView: some View { }
}
```

### Accessibility

```swift
Button(action: { }) {
    Image(systemName: "star.fill")
}
.accessibilityLabel("Als Favorit markieren")
.accessibilityHint("Doppeltippen zum Speichern")
```

## Error Handling

```swift
// Verwende NetworkError für API-Fehler
func fetchData() async throws -> Data {
    guard NetworkMonitor.shared.isConnected else {
        throw NetworkError.noInternet
    }
    // ...
}
```

## Documentation

### Public APIs dokumentieren

```swift
/// Berechnet die Tage bis zum Ticket-Ablauf.
/// - Parameter ticket: Das zu prüfende Deutschlandticket
/// - Returns: Anzahl Tage (negativ wenn abgelaufen)
func daysUntilExpiry(for ticket: DeutschlandTicket) -> Int
```
