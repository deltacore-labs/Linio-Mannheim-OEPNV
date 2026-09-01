# Linio - Entwickler-Dokumentation

Willkommen zur Entwickler-Dokumentation für Linio!

## Inhaltsverzeichnis

| Dokument | Beschreibung |
|----------|--------------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Projektstruktur, MVVM-Pattern, Datenfluss |
| [TESTING.md](./TESTING.md) | Test-Strategie, Konventionen, Test-Abdeckung |
| [CODE_STYLE.md](./CODE_STYLE.md) | Coding-Standards, SwiftLint, Namenskonventionen |
| [API.md](./API.md) | RNV GraphQL API, Authentifizierung, Endpoints |

## Schnellstart

### 1. Projekt einrichten

```bash
git clone https://github.com/deltacore-labs/Linio-Mannheim-OEPNV.git
cd Linio-Mannheim-OEPNV
open Linio.xcodeproj
```

### 2. API-Credentials konfigurieren

Ersetze die Platzhalter in `AuthService.swift`:

```swift
private let clientID     = "YOUR_CLIENT_ID"
private let clientSecret = "YOUR_CLIENT_SECRET"
```

### 3. App Groups einrichten

Konfiguriere App Groups für alle Targets:
- Linio
- LinioLiveActivity
- LinioWatch

### 4. Build & Run

`Cmd + R` in Xcode

## Wichtige Links

- [Haupt-README](../../README.md)
- [CHANGELOG](../../CHANGELOG.md)
- [CONTRIBUTING](../../CONTRIBUTING.md)
- [Test-README](../../LinioTests/README.md)
- [Watch-README](../../LinioWatch/README.md)

## Kontakt

Bei Fragen: [delta.corelabs@gmail.com](mailto:delta.corelabs@gmail.com)
