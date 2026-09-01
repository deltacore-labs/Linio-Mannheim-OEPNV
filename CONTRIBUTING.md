# Contributing Guide

Vielen Dank für dein Interesse, zu Linio beizutragen! 🚌

## Entwicklungsumgebung

### Voraussetzungen

- macOS 14+ (Sonoma)
- Xcode 16+
- iOS 16.2+ Simulator oder Gerät
- watchOS 10+ für Watch-Entwicklung
- SwiftLint (optional, aber empfohlen)

### Setup

```bash
# Repository klonen
git clone https://github.com/deltacore-labs/Linio-Mannheim-OEPNV.git
cd Linio-Mannheim-OEPNV

# SwiftLint installieren
brew install swiftlint

# Projekt öffnen
open Linio.xcodeproj
```

### API-Zugangsdaten

Für API-Zugriff benötigst du Azure AD Credentials. Kontaktiere die Maintainer.

## Code-Stil

Bitte lies den [Code Style Guide](docs/development/CODE_STYLE.md).

### Wichtige Punkte

- Verwende `DebugLog` statt `print()` für Logging
- Organisiere Code mit MARK-Sections
- Schreibe Tests für neue Features
- Dokumentiere öffentliche APIs

## Pull Requests

### Workflow

1. Fork das Repository
2. Erstelle einen Feature-Branch: `git checkout -b feature/mein-feature`
3. Committe deine Änderungen: `git commit -m 'Add: Mein neues Feature'`
4. Push zum Branch: `git push origin feature/mein-feature`
5. Öffne einen Pull Request

### Commit-Messages

```
Add: Neues Feature
Fix: Bugfix-Beschreibung
Update: Aktualisierung
Refactor: Code-Verbesserung
Docs: Dokumentationsänderung
Test: Test-Ergänzung
```

### Checkliste

- [ ] Code kompiliert ohne Warnings
- [ ] SwiftLint zeigt keine Errors
- [ ] Tests laufen durch
- [ ] Neue Features haben Tests
- [ ] CHANGELOG.md aktualisiert

## Tests

```bash
# Alle Tests ausführen
xcodebuild test -scheme Linio -destination 'platform=iOS Simulator,name=iPhone 16'
```

Siehe [Testing Guide](docs/development/TESTING.md) für Details.

## Fragen?

Öffne ein Issue oder kontaktiere uns: [delta.corelabs@gmail.com](mailto:delta.corelabs@gmail.com)
