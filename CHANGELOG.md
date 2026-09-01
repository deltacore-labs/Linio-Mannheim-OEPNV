# Changelog

Alle wichtigen Änderungen am Linio-Projekt werden hier dokumentiert.

## [Unreleased]

### Hinzugefügt
- **SwiftLint-Konfiguration** (`.swiftlint.yml`) für einheitliche Code-Qualität
- **Entwickler-Dokumentation** unter `docs/development/`:
  - `ARCHITECTURE.md` - Projektstruktur und Architektur
  - `TESTING.md` - Test-Strategie und -Konventionen
  - `CODE_STYLE.md` - Coding-Standards
  - `API.md` - RNV GraphQL API Integration

### Neue Unit Tests
- `AuthServiceTests.swift` (8 Tests) - Authentifizierung & Token-Management
- `TicketRenewalServiceTests.swift` (10 Tests) - Ticket-Verlängerungslogik
- `FavoriteStationsManagerTests.swift` (7 Tests) - Favoriten-Verwaltung
- `LiveActivityStateTests.swift` (6 Tests) - Live Activity Status

### Verbessert
- **ConnectionsView.swift** - MARK-Sections für bessere Code-Organisation
- **Debug-Logging** - Alle `print()` Statements in `#if DEBUG` oder `DebugLog` konvertiert

### Behoben
- Ungeschütztes `print()` in `TicketRenewalService.swift` → verwendet jetzt `DebugLog`
- Ungeschütztes `print()` in `WatchConnectivityManager.swift` → `#if DEBUG` Block

---

## [4.2.0] - August 2026

### Apple Watch
- **Intelligentes Caching** - Reduziert API-Aufrufe um bis zu 60%
- **Offline-Modus** - Gecachte Abfahrten für 1 Stunde verfügbar
- **Auto-Retry** - Automatisches Wiederholen bei Verbindungsfehlern
- **Favoriten-Haltestellen** - Quick-Access zu oft genutzten Stationen
- **Progress Bar** - Visueller Fortschritt während der Fahrt
- **Verbesserte Complication** - Fortschrittsring mit Linien-Anzeige

### iPhone
- **Verbesserte Fehlerbehandlung** - NetworkError mit isRetryable
- **Performance** - Optimierte DateFormatter-Caching

---

## [4.1.0] - August 2026

### Apple Watch
- Haptic Feedback für Umstieg und Ankunft
- Siri Shortcuts mit deutschen Phrasen
- Watch Face Complication (WidgetKit)

---

## [4.0.0] - 2026

### Neu
- Erste Apple Watch App Version
- Live Activities & Dynamic Island
- Deutschlandticket-Import per OCR
- Apple Wallet Integration
- Home-Screen Widgets

---

## Versionsschema

Das Projekt folgt [Semantic Versioning](https://semver.org/):

- **MAJOR**: Inkompatible Änderungen
- **MINOR**: Neue Features (abwärtskompatibel)
- **PATCH**: Bugfixes (abwärtskompatibel)
