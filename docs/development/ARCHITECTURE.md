# Linio - Architektur-Dokumentation

## Übersicht

Linio ist eine moderne iOS-App für den öffentlichen Nahverkehr in Mannheim/RNV-Gebiet. Die App folgt einer modularen Architektur mit klarer Trennung zwischen UI, Business-Logik und Datenebene.

## Projektstruktur

```
Linio/
├── Content/                    # SwiftUI Views
│   ├── ConnectionsView.swift   # Verbindungssuche
│   ├── DepartureBoardView.swift # Abfahrtsmonitor
│   ├── TicketView.swift        # Deutschlandticket
│   ├── SettingsView.swift      # Einstellungen
│   ├── TripDetailView.swift    # Fahrtdetails
│   ├── StationPickerView.swift # Haltestellenauswahl
│   └── Components/             # Wiederverwendbare UI-Komponenten
│
├── Services/                   # Business-Logik
│   ├── AuthService.swift       # Azure AD OAuth
│   ├── GraphQLService.swift    # RNV API Client
│   ├── GraphQLService+*.swift  # Extensions (Connections, Departures, Stations)
│   ├── WalletService.swift     # Apple Wallet PKPass
│   ├── NotificationService.swift # Lokale Benachrichtigungen
│   └── TicketRenewalService.swift # Ticket-Verlängerung
│
├── Managers/                   # State Management
│   ├── LiveActivityManager.swift # Live Activities
│   ├── FavoriteStationsManager.swift # Favoriten
│   ├── LocationManager.swift   # GPS/CoreLocation
│   └── NetworkMonitor.swift    # Netzwerkstatus
│
├── Models/                     # Datenmodelle
│   ├── SharedModels.swift      # App-weite Modelle
│   ├── Station.swift           # Haltestelle
│   ├── TripLeg.swift           # Fahrtabschnitt
│   └── NetworkError.swift      # Fehlerbehandlung
│
├── Helpers/                    # Utilities
│   ├── Helpers.swift           # DateFormattingHelper, TransportIconHelper
│   ├── AppTheme.swift          # Design System
│   └── AppConfiguration.swift  # Konfiguration
│
├── Security/                   # Sicherheit
│   ├── SecureConfigurationManager.swift # Verschlüsselte Secrets
│   └── EncryptionService.swift # AES-GCM Verschlüsselung
│
LinioLiveActivity/              # Live Activity Extension
├── LinioLiveActivityLiveActivity.swift
├── EndActivityIntent.swift
└── TripLiveActivityAttributes.swift

LinioWatch/                     # Apple Watch App
├── LinioWatchApp.swift
├── WatchConnectivityManager.swift
└── Views/

LinioTests/                     # Unit Tests
├── AuthServiceTests.swift
├── TicketRenewalServiceTests.swift
└── ...
```

## Architektur-Muster

### MVVM-Light

Die App verwendet ein vereinfachtes MVVM-Muster:
- **Views**: SwiftUI Views mit `@State` und `@Binding`
- **ViewModels**: `@ObservableObject` Services mit `@Published` Properties
- **Models**: Codable Structs für Daten

### Dependency Injection

Services werden über Initializer oder `@EnvironmentObject` injiziert:

```swift
struct ConnectionsView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var graphQLService: GraphQLService
    @EnvironmentObject var liveActivityManager: LiveActivityManager
}
```

### Singleton Pattern (mit Vorsicht)

Einige Manager verwenden das Singleton-Pattern:

```swift
class AuthService: ObservableObject {
    static let shared = AuthService()
}
```

**Hinweis**: Für bessere Testbarkeit werden Singletons über Protocol-Abstraktionen injiziert.

## Datenfluss

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   SwiftUI   │────▶│   Services   │────▶│  RNV API    │
│    View     │◀────│ (Observable) │◀────│  (GraphQL)  │
└─────────────┘     └──────────────┘     └─────────────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌──────────────┐
│  UserDefaults│     │   Keychain   │
│  (Settings)  │     │  (Secrets)   │
└─────────────┘     └──────────────┘
```

## Thread-Sicherheit

### MainActor

UI-bezogene Klassen sind mit `@MainActor` annotiert:

```swift
@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
}
```

### DispatchQueue

Für thread-sichere Zugriffe auf SharedState:

```swift
class LiveActivityState {
    private let queue = DispatchQueue(label: "com.app.liveactivitystate")
    
    func setTripActive(_ tripId: String, isActive: Bool) {
        queue.sync { /* ... */ }
    }
}
```

## Kommunikation zwischen Targets

### App Groups

Daten werden über App Groups geteilt:

```swift
let appGroupID = "group.com.stefanfriedrich.rnvapp"
let sharedDefaults = UserDefaults(suiteName: appGroupID)
```

### Watch Connectivity

iPhone ↔ Apple Watch Kommunikation:

```swift
class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    func pushCredentialsToWatch(token: String, tokenExpiry: Date)
}
```

## Sicherheit

### Verschlüsselte Secrets

API-Credentials werden verschlüsselt gespeichert:

```swift
class SecureConfigurationManager {
    private let encryptionService = EncryptionService()
    
    var clientID: String? {
        decryptedSecrets["RNV_CLIENT_ID"]
    }
}
```

### Keychain

Sensitive Daten im iOS Keychain:

```swift
let keychainQuery: [String: Any] = [
    kSecClass: kSecClassGenericPassword,
    kSecAttrService: "com.stefanfriedrich.rnvapp.auth",
    kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
```

## Fehlerbehandlung

### NetworkError Enum

Zentralisierte Fehlerbehandlung:

```swift
enum NetworkError: Error, LocalizedError {
    case noInternet
    case timeout
    case serverError
    case graphQLError(message: String)
    
    var isRetryable: Bool { /* ... */ }
    var iconName: String { /* ... */ }
}
```

## Performance-Optimierungen

1. **LazyVStack** für lange Listen
2. **Debounced Widget Updates** (0.5s)
3. **Cached DateFormatters** (thread-safe)
4. **Background Task Registration** für Live Activities
5. **Reduce Motion** Support für Animationen

## Weitere Dokumentation

- [Testing Guide](./TESTING.md)
- [API Integration](./API.md)
- [Code Style Guide](./CODE_STYLE.md)
