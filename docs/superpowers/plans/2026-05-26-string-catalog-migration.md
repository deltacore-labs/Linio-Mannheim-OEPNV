# String Catalog Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the custom BundleSwizzle + Swift translation dictionary with Apple's native `Localizable.xcstrings` String Catalog, keeping the in-app language switching behaviour intact via `.environment(\.locale, ...)`.

**Architecture:** A `Localizable.xcstrings` file holds all German (source) keys and their English translations. At runtime, SwiftUI's `Text` respects the `\.locale` environment value for `LocalizedStringKey` lookups, so setting `.environment(\.locale, Locale(identifier: appLanguage))` on the root view — combined with the existing `.id(appLanguage)` force re-render — switches the language instantly. `BundleSwizzle` and `AppLocalization` are deleted; `AppLanguage.swift` retains only the enum. One usage of `NSLocalizedString` in `TicketView.swift` is replaced with a `LocalizedStringKey`-typed `infoRow` overload.

**Tech Stack:** SwiftUI, Xcode String Catalog (`.xcstrings` JSON), `@AppStorage`, `\.locale` environment, no third-party libraries.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| **Create** | `Linio/Localizable.xcstrings` | All German keys + English translations |
| **Modify** | `Linio.xcodeproj/project.pbxproj` | Add `en` to `knownRegions` |
| **⚠️ Manual** | Xcode UI | Add `Localizable.xcstrings` to the app target |
| **Modify** | `Linio/AppLanguage.swift` | Remove `BundleSwizzle` + `AppLocalization`; keep enum only |
| **Modify** | `Linio/RNV_Transport_AppApp.swift` | Remove `init()`; add `.environment(\.locale, ...)` |
| **Modify** | `Linio/Content/TicketView.swift` | Add `LocalizedStringKey` overload for `infoRow`; fix one call site |

---

## Task 1: Add English to `project.pbxproj` `knownRegions`

**Files:**
- Modify: `Linio.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add `en` to `knownRegions`**

Find this block (around line 393):
```
knownRegions = (
    Base,
    de,
);
```

Replace with:
```
knownRegions = (
    Base,
    de,
    en,
);
```

- [ ] **Step 2: Verify the change**

Run:
```bash
grep -A 5 "knownRegions" "Linio.xcodeproj/project.pbxproj"
```
Expected output includes `en,` in the list.

---

## Task 2: Create `Localizable.xcstrings`

**Files:**
- Create: `Linio/Localizable.xcstrings`

- [ ] **Step 1: Create the file with this exact content**

```json
{
  "sourceLanguage" : "de",
  "strings" : {
    "Abbrechen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } }
      }
    },
    "OK" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "OK" } }
      }
    },
    "Fertig" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Done" } }
      }
    },
    "Beenden" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "End" } }
      }
    },
    "Schließen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Close" } }
      }
    },
    "Weiter" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Next" } }
      }
    },
    "Loslegen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Get Started" } }
      }
    },
    "Überspringen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Skip" } }
      }
    },
    "Aktualisieren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Refresh" } }
      }
    },
    "Erneut versuchen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Try Again" } }
      }
    },
    "Erneut verbinden" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Reconnect" } }
      }
    },
    "Bitte erneut versuchen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Please try again" } }
      }
    },
    "Auswählen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Select" } }
      }
    },
    "Bearbeiten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit" } }
      }
    },
    "Entfernen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Remove" } }
      }
    },
    "Ersetzen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Replace" } }
      }
    },
    "Sichern" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Save" } }
      }
    },
    "Einstellungen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } }
      }
    },
    "ÖPNV Mannheim" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Public Transit Mannheim" } }
      }
    },
    "Mannheim & Umgebung" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Mannheim & Surroundings" } }
      }
    },
    "Geplante Fahrten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Planned Trips" } }
      }
    },
    "Verbindungssuche" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Connection Search" } }
      }
    },
    "Verkehrsmittel" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Transport" } }
      }
    },
    "Live Activity & Mitteilungen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Live Activity & Notifications" } }
      }
    },
    "Standort" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Location" } }
      }
    },
    "App & Daten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "App & Data" } }
      }
    },
    "Entwickler" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Developer" } }
      }
    },
    "Sprache" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Language" } }
      }
    },
    "Fahrten & Archiv" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Trips & Archive" } }
      }
    },
    "Aktive Live Activities und Fahrtenverlauf" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Active Live Activities and trip history" } }
      }
    },
    "Max. Verbindungen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Max. Connections" } }
      }
    },
    "Suchradius" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Search Radius" } }
      }
    },
    "Nur Verspätungen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Delays Only" } }
      }
    },
    "Verbindungen ohne Verspätung ausblenden" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Hide connections without delays" } }
      }
    },
    "Straßenbahn" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Tram" } }
      }
    },
    "Bus" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Bus" } }
      }
    },
    "S-Bahn" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "S-Bahn" } }
      }
    },
    "Automatisch starten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Auto Start" } }
      }
    },
    "Bei jeder Verbindungssuche" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "On every connection search" } }
      }
    },
    "Push-Benachrichtigungen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Push Notifications" } }
      }
    },
    "Verspätungen und Änderungen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Delays and changes" } }
      }
    },
    "Erinnerung" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Reminder" } }
      }
    },
    "Systemeinstellungen öffnen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Open System Settings" } }
      }
    },
    "Benachrichtigungen in Einstellungen erlauben" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Allow Notifications in Settings" } }
      }
    },
    "Aktueller Standort" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Current Location" } }
      }
    },
    "Zugriff verweigert" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Access Denied" } }
      }
    },
    "Eingeschränkt" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Restricted" } }
      }
    },
    "Wird ermittelt …" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Determining …" } }
      }
    },
    "Nicht verfügbar" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Not available" } }
      }
    },
    "Standortzugriff in Einstellungen erlauben" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Allow Location Access in Settings" } }
      }
    },
    "Cache leeren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Clear Cache" } }
      }
    },
    "Alle Live Activities beenden" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "End All Live Activities" } }
      }
    },
    "Datenschutzerklärung" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Privacy Policy" } }
      }
    },
    "Entwicklermodus" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Developer Mode" } }
      }
    },
    "Mannheim Hbf (Test)" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Mannheim Hbf (Test)" } }
      }
    },
    "Heidelberg Hbf (Test)" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Heidelberg Hbf (Test)" } }
      }
    },
    "Debug: State ausgeben" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Debug: Print State" } }
      }
    },
    "Alle Activities beenden?" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "End All Activities?" } }
      }
    },
    "Alle aktiven Live Activities werden beendet und die Toggles zurückgesetzt." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "All active Live Activities will be ended and toggles reset." } }
      }
    },
    "Erfolgreich" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Success" } }
      }
    },
    "Alle Live Activities wurden beendet." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "All Live Activities have been ended." } }
      }
    },
    "Cache geleert" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cache Cleared" } }
      }
    },
    "Der gespeicherte Suchverlauf wurde gelöscht." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "The saved search history has been deleted." } }
      }
    },
    "Studentenprojekt – nicht verbunden mit der rnv GmbH oder anderen Verkehrsbetrieben." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Student project – not affiliated with rnv GmbH or other transit operators." } }
      }
    },
    "Öffentliche Daten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Public Data" } }
      }
    },
    "Mannheim" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Mannheim" } }
      }
    },
    "Abfahrten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Departures" } }
      }
    },
    "ABFAHRTEN" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "DEPARTURES" } }
      }
    },
    "NÄCHSTE ABFAHRTEN" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "NEXT DEPARTURES" } }
      }
    },
    "Lade Abfahrten …" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Loading departures …" } }
      }
    },
    "Für diese Haltestelle sind aktuell\nkeine Abfahrten verfügbar." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No departures currently\navailable for this stop." } }
      }
    },
    "Abfahrt" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Departure" } }
      }
    },
    "Abfahrt in" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Departing in" } }
      }
    },
    "Keine\nAbfahrten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No\nDepartures" } }
      }
    },
    "MEIN STEIG" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "MY PLATFORM" } }
      }
    },
    "Haltestelle auswählen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Select Stop" } }
      }
    },
    "Haltestellen auf der Karte auswählen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Select stops on map" } }
      }
    },
    "Kein Internet" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No Internet" } }
      }
    },
    "Kein Internet – Daten könnten veraltet sein" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No Internet – data may be outdated" } }
      }
    },
    "Kein Internet – angezeigte Daten könnten veraltet sein" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No Internet – displayed data may be outdated" } }
      }
    },
    "Verbindungen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Connections" } }
      }
    },
    "Verbindungsdetails" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Connection Details" } }
      }
    },
    "Wohin möchtest du fahren?" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Where do you want to go?" } }
      }
    },
    "Verbindungen suchen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Search Connections" } }
      }
    },
    "Verbindung fehlgeschlagen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Connection Failed" } }
      }
    },
    "Verbindung wird hergestellt..." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Connecting..." } }
      }
    },
    "Verbindung wird hergestellt" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Connecting" } }
      }
    },
    "Keine verspäteten Verbindungen." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No delayed connections." } }
      }
    },
    "Direkt" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Direct" } }
      }
    },
    "Wähle Start und Ziel oben, um Verbindungen zu finden." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Select start and destination above to find connections." } }
      }
    },
    "Wähle eine\nHaltestelle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Select a\nStop" } }
      }
    },
    "Haltestellen laden…" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Loading stops…" } }
      }
    },
    "In der Nähe" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Nearby" } }
      }
    },
    "Suche Haltestellen..." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Search stops..." } }
      }
    },
    "Suche..." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Search..." } }
      }
    },
    "Route" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Route" } }
      }
    },
    "Streckenverlauf" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Route Overview" } }
      }
    },
    "In Apple Karten navigieren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Navigate in Apple Maps" } }
      }
    },
    "Verbindung teilen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Share Connection" } }
      }
    },
    "Start und Ziel tauschen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Swap Start and Destination" } }
      }
    },
    "Streckenübersicht auf der Karte" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Route Overview on Map" } }
      }
    },
    "Haltestelle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Stop" } }
      }
    },
    "Keine Haltestelle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No Stop" } }
      }
    },
    "Fußweg · %@" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Walk · %@" } }
      }
    },
    "Archiv" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Archive" } }
      }
    },
    "Archiv leer" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Archive Empty" } }
      }
    },
    "Archiv leeren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Clear Archive" } }
      }
    },
    "Aktiv" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Active" } }
      }
    },
    "Keine aktiven Fahrten" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No Active Trips" } }
      }
    },
    "Live Activities werden hier angezeigt,\nsobald du eine Verbindung verfolgst" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Live Activities will appear here\nonce you track a connection" } }
      }
    },
    "Abgeschlossene Fahrten erscheinen\nhier nach Beendigung" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Completed trips appear\nhere after completion" } }
      }
    },
    "Alle beenden" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "End All" } }
      }
    },
    "Fahrtdetails" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Trip Details" } }
      }
    },
    "Ankunft" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Arrival" } }
      }
    },
    "Unterwegs" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "En Route" } }
      }
    },
    "Angekommen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Arrived" } }
      }
    },
    "Vor Abfahrt" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Before Departure" } }
      }
    },
    "Live aktiv" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Live Active" } }
      }
    },
    "Live-Verfolgung" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Live Tracking" } }
      }
    },
    "Nicht\nverfügbar" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Not\nAvailable" } }
      }
    },
    "Tickets" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Tickets" } }
      }
    },
    "Ticket wird erkannt…" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Scanning ticket…" } }
      }
    },
    "Kein Ticket hinterlegt" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No ticket stored" } }
      }
    },
    "Importiere einen oder zwei Screenshots\ndeines Tickets — die Daten werden\nautomatisch erkannt." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Import one or two screenshots\nof your ticket — the data will\nbe recognized automatically." } }
      }
    },
    "Aus Screenshot importieren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Import from Screenshot" } }
      }
    },
    "Manuell eingeben" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Enter Manually" } }
      }
    },
    "Vorzeigen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Present" } }
      }
    },
    "D-TICKET" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "D-TICKET" } }
      }
    },
    "Kein Barcode" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No Barcode" } }
      }
    },
    "Nur mit gültigem Lichtbildausweis · Nicht übertragbar" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Only with valid photo ID · Non-transferable" } }
      }
    },
    "Bitte prüfe die erkannten Daten und korrigiere sie falls nötig." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Please check the recognized data and correct if necessary." } }
      }
    },
    "Ticket-Screenshot importieren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Import Ticket Screenshot" } }
      }
    },
    "Aus Fotos (1–2 Screenshots)" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "From Photos (1–2 Screenshots)" } }
      }
    },
    "Aus Dateien" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "From Files" } }
      }
    },
    "Nicht angegeben" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Not specified" } }
      }
    },
    "Barcode" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Barcode" } }
      }
    },
    "Importiere die Barcode-Seite aus deiner Ticket-App." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Import the barcode page from your ticket app." } }
      }
    },
    "Neu scannen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Rescan" } }
      }
    },
    "Ticket entfernen?" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Remove Ticket?" } }
      }
    },
    "Wallet-Fehler" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Wallet Error" } }
      }
    },
    "Ticket verlängert?" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Ticket Renewed?" } }
      }
    },
    "Ja, Ticket aktualisieren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Yes, Update Ticket" } }
      }
    },
    "Neu einscannen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Rescan" } }
      }
    },
    "Nicht jetzt" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Not Now" } }
      }
    },
    "Ablauf simulieren" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Simulate Expiry" } }
      }
    },
    "Test-Notification (5s)" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Test Notification (5s)" } }
      }
    },
    "Dein Deutschlandticket ist jetzt als\nWallet-Pass verfügbar." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Your Deutschlandticket is now\navailable as a Wallet pass." } }
      }
    },
    "Ticket im Apple Wallet" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Ticket in Apple Wallet" } }
      }
    },
    "Daten prüfen" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Review Data" } }
      }
    },
    "Ticket" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Ticket" } }
      }
    },
    "Inhaber" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Holder" } }
      }
    },
    "Gültigkeit" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Validity" } }
      }
    },
    "Art" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Type" } }
      }
    },
    "Anbieter" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Provider" } }
      }
    },
    "Vor- und Nachname" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "First and Last Name" } }
      }
    },
    "Kundennummer (optional)" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Customer Number (optional)" } }
      }
    },
    "Von" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "From" } }
      }
    },
    "Bis" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "To" } }
      }
    },
    "INHABER" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "HOLDER" } }
      }
    },
    "KUNDENNUMMER" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "CUSTOMER NO." } }
      }
    },
    "GELTUNGSBEREICH" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "VALID FOR" } }
      }
    },
    "GÜLTIGKEIT" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "VALIDITY" } }
      }
    },
    "ANBIETER" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "PROVIDER" } }
      }
    },
    "Bundesweit im Nahverkehr" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Nationwide in local transit" } }
      }
    },
    "Willkommen bei\nÖPNV Mannheim" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Welcome to\nPublic Transit Mannheim" } }
      }
    },
    "Dein Begleiter für Bus, Tram und S-Bahn in Mannheim und Umgebung. Verbindungen in Echtzeit – direkt auf deinem iPhone." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Your companion for bus, tram and S-Bahn in Mannheim and the surrounding area. Real-time connections – directly on your iPhone." } }
      }
    },
    "Haltestellen\nin deiner Nähe" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Stops\nNearby" } }
      }
    },
    "Die App nutzt deinen Standort, um nahegelegene Haltestellen zu finden. Deine Position wird nur für die Suche verwendet und nie gespeichert." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "The app uses your location to find nearby stops. Your position is only used for searching and never stored." } }
      }
    },
    "Live Activity &\nDynamic Island" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Live Activity &\nDynamic Island" } }
      }
    },
    "Verfolge deine Fahrt direkt im Dynamic Island oder auf dem Sperrbildschirm – mit Echtzeit-Abfahrtszeiten und Verspätungsanzeige." : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Track your journey directly in the Dynamic Island or on the lock screen – with real-time departure times and delay indicator." } }
      }
    },
    "Stand: Mai 2026" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "As of: May 2026" } }
      }
    }
  },
  "version" : "1.0"
}
```

---

## Task 3: Add `Localizable.xcstrings` to the Xcode target

**⚠️ This step requires human action in Xcode — it cannot be done by editing files.**

- [ ] **Step 1: Open Xcode and add the file to the target**

  1. In Xcode's Project Navigator, right-click on the `Linio` group (the yellow folder containing Swift source files)
  2. Choose **Add Files to "Linio"…**
  3. Navigate to `Linio/Localizable.xcstrings`
  4. Make sure **"Add to targets: Linio"** is checked
  5. Click **Add**

- [ ] **Step 2: Verify the file appears in the target's Build Phases**

  In Xcode: select the project → target "Linio" → Build Phases → Copy Bundle Resources. `Localizable.xcstrings` should appear there.

- [ ] **Step 3: Build (`⌘B`) and verify no errors**

---

## Task 4: Slim down `AppLanguage.swift`

**Files:**
- Modify: `Linio/AppLanguage.swift`

Remove `BundleSwizzle`, `AppLocalization`, and the entire `Translations` enum. Keep only the `AppLanguage` enum.

- [ ] **Step 1: Replace the entire file with this content**

```swift
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .german:  return "Deutsch"
        case .english: return "English"
        }
    }
}
```

- [ ] **Step 2: Build (`⌘B`) and verify no errors**

  Expected: compiler errors for `AppLocalization.apply()` in `RNV_Transport_AppApp.swift` — fixed in Task 5.

---

## Task 5: Update `RNV_Transport_AppApp.swift`

**Files:**
- Modify: `Linio/RNV_Transport_AppApp.swift`

Remove `init()` (which only called `AppLocalization.apply()`). Add `.environment(\.locale, ...)` to both view paths so SwiftUI uses the chosen language for all `LocalizedStringKey` lookups.

- [ ] **Step 1: Replace the `@main struct` body with this**

```swift
@main
struct RNV_Transport_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var liveActivityManager = LiveActivityManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(liveActivityManager)
                    .environment(\.locale, Locale(identifier: appLanguage))
                    .id(appLanguage)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .environment(\.locale, Locale(identifier: appLanguage))
                    .id(appLanguage)
            }
        }
    }
}
```

- [ ] **Step 2: Build (`⌘B`) and verify no errors**

---

## Task 6: Fix `TicketView.swift` — replace `NSLocalizedString`

**Files:**
- Modify: `Linio/Content/TicketView.swift`

`NSLocalizedString` bypasses the SwiftUI locale environment. Add a `LocalizedStringKey`-typed overload of `infoRow` and use it for the one static value `"Bundesweit im Nahverkehr"`.

- [ ] **Step 1: Add `LocalizedStringKey` overload directly after the existing `infoRow` function**

Find the existing `infoRow` at line ~974:
```swift
private func infoRow(_ label: String, _ value: String) -> some View {
    HStack(alignment: .top) {
        Text(LocalizedStringKey(label))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppTheme.muted)
            .frame(width: 120, alignment: .leading)
        Text(value)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
}
```

Add this overload immediately after it:
```swift
private func infoRow(_ label: String, _ value: LocalizedStringKey) -> some View {
    HStack(alignment: .top) {
        Text(LocalizedStringKey(label))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppTheme.muted)
            .frame(width: 120, alignment: .leading)
        Text(value)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
}
```

- [ ] **Step 2: Replace the `NSLocalizedString` call**

Find (line ~956):
```swift
infoRow("GELTUNGSBEREICH", NSLocalizedString("Bundesweit im Nahverkehr", comment: ""))
```

Replace with:
```swift
infoRow("GELTUNGSBEREICH", LocalizedStringKey("Bundesweit im Nahverkehr"))
```

- [ ] **Step 3: Build (`⌘B`) and verify no errors**

---

## Task 7: Manual verification in Simulator

- [ ] **Step 1: Run on iPhone 15 Pro Simulator (iOS 17+)**

- [ ] **Step 2: Verify German default**

App launches in German. All labels show German text.

- [ ] **Step 3: Switch to English**

Settings → Sprache → English. Verify:
- Settings title: "Settings", section headers: "PLANNED TRIPS", "CONNECTION SEARCH", "TRANSPORT"
- Ticket card labels: "HOLDER", "CUSTOMER NO.", "VALID FOR", "VALIDITY", "PROVIDER"
- "Nationwide in local transit" for GELTUNGSBEREICH value
- Departures: "Departures", "NEXT DEPARTURES"
- Connections: "Connections", "Where do you want to go?"

- [ ] **Step 4: Switch back to German and verify**

Settings → Sprache → Deutsch. All labels back to German.
