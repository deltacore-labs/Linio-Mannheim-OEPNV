# Language Switching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a language picker (German/English) to SettingsView; switching language instantly re-renders the whole app without restart and without touching any existing `Text(...)` call.

**Architecture:** All translated strings live in a single `AppLanguage.swift` file. At app startup, `Bundle.main`'s ISA pointer is swapped to a custom `BundleSwizzle` subclass whose `localizedString(forKey:...)` override intercepts every SwiftUI `Text(...)` lookup. German (`"de"`) falls through to super (the German literal IS the fallback key). English (`"en"`) returns from an embedded Swift dictionary. Adding a future language means adding a new `AppLanguage` case and a new dictionary in `AppLanguage.swift`.

**Tech Stack:** SwiftUI, `@AppStorage`, Objective-C runtime (`object_setClass`), no `.lproj` files, no Xcode project file changes.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| **Create** | `Linio/AppLanguage.swift` | `AppLanguage` enum · `BundleSwizzle` class · `AppLocalization` helper · full English translations dictionary |
| **Modify** | `Linio/RNV_Transport_AppApp.swift` | Call `AppLocalization.apply()` at init · add `.id(appLanguage)` to force view-tree re-render on switch |
| **Modify** | `Linio/Content/SettingsView.swift` | Add "Sprache / Language" `SettingsCard` with `Picker` as first section |
| **Modify** | `Linio/Content/OnboardingView.swift` | Wrap `Text(pages[...].title/body)` in `LocalizedStringKey()` so onboarding strings go through the swizzle |
| **Modify** | `Linio/Content/TicketView.swift` | Change `Text(label)` → `Text(LocalizedStringKey(label))` in `infoRow` so ticket card field labels localise |

---

## Task 1: Create `AppLanguage.swift`

**Files:**
- Create: `Linio/AppLanguage.swift`

- [ ] **Step 1: Create the file with this exact content**

```swift
// AppLanguage.swift
import Foundation
import ObjectiveC.runtime

// MARK: - Language enum

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

// MARK: - Bundle swizzle

private final class BundleSwizzle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "de"
        guard lang != "de",
              let dict = Translations.table[lang],
              let translated = dict[key] else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return translated
    }
}

// MARK: - Activation

enum AppLocalization {
    static func apply() {
        object_setClass(Bundle.main, BundleSwizzle.self)
    }
}

// MARK: - Translations

private enum Translations {
    static let table: [String: [String: String]] = [
        "en": en
    ]

    // English translations — keys are the German string literals used in Text("...") calls.
    // Adding a new language: add a new key ("fr", "es", …) with its own dictionary here.
    static let en: [String: String] = [

        // MARK: Common
        "Abbrechen": "Cancel",
        "OK": "OK",
        "Fertig": "Done",
        "Beenden": "End",
        "Schließen": "Close",
        "Weiter": "Next",
        "Loslegen": "Get Started",
        "Überspringen": "Skip",
        "Aktualisieren": "Refresh",
        "Erneut versuchen": "Try Again",
        "Erneut verbinden": "Reconnect",
        "Bitte erneut versuchen": "Please try again",
        "Auswählen": "Select",
        "Bearbeiten": "Edit",
        "Entfernen": "Remove",
        "Ersetzen": "Replace",
        "Sichern": "Save",

        // MARK: Settings — navigation
        "Einstellungen": "Settings",

        // MARK: Settings — header card
        "ÖPNV Mannheim": "Public Transit Mannheim",
        "Mannheim & Umgebung": "Mannheim & Surroundings",

        // MARK: Settings — sections
        "Geplante Fahrten": "Planned Trips",
        "Verbindungssuche": "Connection Search",
        "Verkehrsmittel": "Transport",
        "Live Activity & Mitteilungen": "Live Activity & Notifications",
        "Standort": "Location",
        "App & Daten": "App & Data",
        "Entwickler": "Developer",
        "Sprache": "Language",

        // MARK: Settings — planned trips row
        "Fahrten & Archiv": "Trips & Archive",
        "Aktive Live Activities und Fahrtenverlauf": "Active Live Activities and trip history",

        // MARK: Settings — connection search rows
        "Max. Verbindungen": "Max. Connections",
        "Suchradius": "Search Radius",
        "Nur Verspätungen": "Delays Only",
        "Verbindungen ohne Verspätung ausblenden": "Hide connections without delays",

        // MARK: Settings — transport rows
        "Straßenbahn": "Tram",
        "Bus": "Bus",
        "S-Bahn": "S-Bahn",

        // MARK: Settings — notifications rows
        "Automatisch starten": "Auto Start",
        "Bei jeder Verbindungssuche": "On every connection search",
        "Push-Benachrichtigungen": "Push Notifications",
        "Verspätungen und Änderungen": "Delays and changes",
        "Erinnerung": "Reminder",
        "Systemeinstellungen öffnen": "Open System Settings",
        "Benachrichtigungen in Einstellungen erlauben": "Allow Notifications in Settings",

        // MARK: Settings — location rows
        "Aktueller Standort": "Current Location",
        "Zugriff verweigert": "Access Denied",
        "Eingeschränkt": "Restricted",
        "Wird ermittelt …": "Determining …",
        "Nicht verfügbar": "Not available",
        "Standortzugriff in Einstellungen erlauben": "Allow Location Access in Settings",

        // MARK: Settings — app & data rows
        "Cache leeren": "Clear Cache",
        "Alle Live Activities beenden": "End All Live Activities",
        "Datenschutzerklärung": "Privacy Policy",

        // MARK: Settings — developer rows
        "Entwicklermodus": "Developer Mode",
        "Mannheim Hbf (Test)": "Mannheim Hbf (Test)",
        "Heidelberg Hbf (Test)": "Heidelberg Hbf (Test)",
        "Debug: State ausgeben": "Debug: Print State",

        // MARK: Settings — alerts
        "Alle Activities beenden?": "End All Activities?",
        "Alle aktiven Live Activities werden beendet und die Toggles zurückgesetzt.": "All active Live Activities will be ended and toggles reset.",
        "Erfolgreich": "Success",
        "Alle Live Activities wurden beendet.": "All Live Activities have been ended.",
        "Cache geleert": "Cache Cleared",
        "Der gespeicherte Suchverlauf wurde gelöscht.": "The saved search history has been deleted.",

        // MARK: Settings — footer
        "Studentenprojekt – nicht verbunden mit der rnv GmbH oder anderen Verkehrsbetrieben.": "Student project – not affiliated with rnv GmbH or other transit operators.",
        "Öffentliche Daten": "Public Data",
        "Mannheim": "Mannheim",

        // MARK: Departures
        "Abfahrten": "Departures",
        "ABFAHRTEN": "DEPARTURES",
        "NÄCHSTE ABFAHRTEN": "NEXT DEPARTURES",
        "Lade Abfahrten …": "Loading departures …",
        "Für diese Haltestelle sind aktuell\nkeine Abfahrten verfügbar.": "No departures currently\navailable for this stop.",
        "Abfahrt": "Departure",
        "Abfahrt in": "Departing in",
        "Keine\nAbfahrten": "No\nDepartures",
        "MEIN STEIG": "MY PLATFORM",
        "Haltestelle auswählen": "Select Stop",
        "Haltestellen auf der Karte auswählen": "Select stops on map",
        "Kein Internet": "No Internet",
        "Kein Internet – Daten könnten veraltet sein": "No Internet – data may be outdated",
        "Kein Internet – angezeigte Daten könnten veraltet sein": "No Internet – displayed data may be outdated",

        // MARK: Connections
        "Verbindungen": "Connections",
        "Verbindungsdetails": "Connection Details",
        "Wohin möchtest du fahren?": "Where do you want to go?",
        "Verbindungen suchen": "Search Connections",
        "Verbindung fehlgeschlagen": "Connection Failed",
        "Verbindung wird hergestellt...": "Connecting...",
        "Verbindung wird hergestellt": "Connecting",
        "Keine verspäteten Verbindungen.": "No delayed connections.",
        "Direkt": "Direct",
        "Wähle Start und Ziel oben, um Verbindungen zu finden.": "Select start and destination above to find connections.",
        "Wähle eine\nHaltestelle": "Select a\nStop",
        "Haltestellen laden…": "Loading stops…",
        "In der Nähe": "Nearby",
        "Suche Haltestellen...": "Search stops...",
        "Suche...": "Search...",
        "Route": "Route",
        "Streckenverlauf": "Route Overview",
        "In Apple Karten navigieren": "Navigate in Apple Maps",
        "Verbindung teilen": "Share Connection",
        "Start und Ziel tauschen": "Swap Start and Destination",
        "Streckenübersicht auf der Karte": "Route Overview on Map",
        "Haltestelle": "Stop",
        "Keine Haltestelle": "No Stop",
        "Fußweg · %@": "Walk · %@",

        // MARK: Planned Trips
        "Archiv": "Archive",
        "Archiv leer": "Archive Empty",
        "Archiv leeren": "Clear Archive",
        "Aktiv": "Active",
        "Keine aktiven Fahrten": "No Active Trips",
        "Live Activities werden hier angezeigt,\nsobald du eine Verbindung verfolgst": "Live Activities will appear here\nonce you track a connection",
        "Abgeschlossene Fahrten erscheinen\nhier nach Beendigung": "Completed trips appear\nhere after completion",
        "Alle beenden": "End All",
        "Fahrtdetails": "Trip Details",
        "Ankunft": "Arrival",
        "Unterwegs": "En Route",
        "Angekommen": "Arrived",
        "Vor Abfahrt": "Before Departure",
        "Live aktiv": "Live Active",
        "Live-Verfolgung": "Live Tracking",
        "Nicht\nverfügbar": "Not\nAvailable",

        // MARK: Tickets
        "Tickets": "Tickets",
        "Ticket wird erkannt…": "Scanning ticket…",
        "Kein Ticket hinterlegt": "No ticket stored",
        "Importiere einen oder zwei Screenshots\ndeines Tickets — die Daten werden\nautomatisch erkannt.": "Import one or two screenshots\nof your ticket — the data will\nbe recognized automatically.",
        "Aus Screenshot importieren": "Import from Screenshot",
        "Manuell eingeben": "Enter Manually",
        "Vorzeigen": "Present",
        "D-TICKET": "D-TICKET",
        "Kein Barcode": "No Barcode",
        "Nur mit gültigem Lichtbildausweis · Nicht übertragbar": "Only with valid photo ID · Non-transferable",
        "Bitte prüfe die erkannten Daten und korrigiere sie falls nötig.": "Please check the recognized data and correct if necessary.",
        "Ticket-Screenshot importieren": "Import Ticket Screenshot",
        "Aus Fotos (1–2 Screenshots)": "From Photos (1–2 Screenshots)",
        "Aus Dateien": "From Files",
        "Nicht angegeben": "Not specified",
        "Barcode": "Barcode",
        "Importiere die Barcode-Seite aus deiner Ticket-App.": "Import the barcode page from your ticket app.",
        "Neu scannen": "Rescan",
        "Ticket entfernen?": "Remove Ticket?",
        "Wallet-Fehler": "Wallet Error",
        "Ticket verlängert?": "Ticket Renewed?",
        "Ja, Ticket aktualisieren": "Yes, Update Ticket",
        "Neu einscannen": "Rescan",
        "Nicht jetzt": "Not Now",
        "Ablauf simulieren": "Simulate Expiry",
        "Test-Notification (5s)": "Test Notification (5s)",
        "Dein Deutschlandticket ist jetzt als\nWallet-Pass verfügbar.": "Your Deutschlandticket is now\navailable as a Wallet pass.",
        "Ticket im Apple Wallet": "Ticket in Apple Wallet",
        "Daten prüfen": "Review Data",

        // Ticket card field labels (used as LocalizedStringKey via infoRow fix in TicketView)
        "Ticket": "Ticket",
        "Inhaber": "Holder",
        "Gültigkeit": "Validity",
        "Art": "Type",
        "Anbieter": "Provider",
        "Vor- und Nachname": "First and Last Name",
        "Kundennummer (optional)": "Customer Number (optional)",
        "Von": "From",
        "Bis": "To",
        "INHABER": "HOLDER",
        "KUNDENNUMMER": "CUSTOMER NO.",
        "GELTUNGSBEREICH": "VALID FOR",
        "GÜLTIGKEIT": "VALIDITY",
        "ANBIETER": "PROVIDER",
        "Bundesweit im Nahverkehr": "Nationwide in local transit",

        // MARK: Onboarding (used as LocalizedStringKey via OnboardingView fix)
        "Willkommen bei\nÖPNV Mannheim": "Welcome to\nPublic Transit Mannheim",
        "Dein Begleiter für Bus, Tram und S-Bahn in Mannheim und Umgebung. Verbindungen in Echtzeit – direkt auf deinem iPhone.": "Your companion for bus, tram and S-Bahn in Mannheim and the surrounding area. Real-time connections – directly on your iPhone.",
        "Haltestellen\nin deiner Nähe": "Stops\nNearby",
        "Die App nutzt deinen Standort, um nahegelegene Haltestellen zu finden. Deine Position wird nur für die Suche verwendet und nie gespeichert.": "The app uses your location to find nearby stops. Your position is only used for searching and never stored.",
        "Live Activity &\nDynamic Island": "Live Activity &\nDynamic Island",
        "Verfolge deine Fahrt direkt im Dynamic Island oder auf dem Sperrbildschirm – mit Echtzeit-Abfahrtszeiten und Verspätungsanzeige.": "Track your journey directly in the Dynamic Island or on the lock screen – with real-time departure times and delay indicator.",

        // MARK: Privacy Policy
        "Stand: Mai 2026": "As of: May 2026",
    ]
}
```

- [ ] **Step 2: Verify the file compiles (no Xcode errors)**

Build with `⌘B` in Xcode. Expected: no errors or warnings in `AppLanguage.swift`.

---

## Task 2: Update `RNV_Transport_AppApp.swift`

**Files:**
- Modify: `Linio/RNV_Transport_AppApp.swift`

- [ ] **Step 1: Add `@AppStorage` for language and call `AppLocalization.apply()` in `App.init()`**

The current file has `RNV_Transport_AppApp: App` with no `init()`. Add one and add the `@AppStorage`:

```swift
@main
struct RNV_Transport_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var liveActivityManager = LiveActivityManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = "de"  // ADD THIS

    init() {                          // ADD THIS
        AppLocalization.apply()       // ADD THIS
    }                                 // ADD THIS

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(liveActivityManager)
                    .id(appLanguage)                          // ADD THIS
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .id(appLanguage)                          // ADD THIS
            }
        }
    }
}
```

The `.id(appLanguage)` causes SwiftUI to destroy and recreate the full view tree when the language changes, forcing all `Text(...)` views to re-resolve their localized strings from the now-swizzled bundle.

- [ ] **Step 2: Build (`⌘B`) and verify no errors**

---

## Task 3: Add language picker to `SettingsView.swift`

**Files:**
- Modify: `Linio/Content/SettingsView.swift`

- [ ] **Step 1: Add `@AppStorage("appLanguage")` to `SettingsView`**

In `SettingsView`, add after the existing `@AppStorage("reminderMinutes")` line:

```swift
@AppStorage("appLanguage") private var appLanguage = "de"
```

- [ ] **Step 2: Add `languageSection` computed property before the existing `tripsSection`**

Add this new section after the `// MARK: - App Header` section and before `// MARK: - Trips Section`:

```swift
// MARK: - Language Section

private var languageSection: some View {
    SettingsCard(title: "Sprache", icon: "globe", iconColor: AppTheme.primaryColor, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
        HStack(spacing: 12) {
            IconBadge(icon: "globe", color: AppTheme.primaryColor)
            Text("Sprache")
                .font(.body)
                .foregroundColor(AppTheme.ink)
            Spacer()
            Picker("", selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.primaryColor)
            .accessibilityLabel("Sprache")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
```

- [ ] **Step 3: Insert `languageSection` at the top of the `body` VStack**

In `var body: some View`, the `VStack(spacing: 28)` currently starts with `appHeader`. Change the VStack content to:

```swift
VStack(spacing: 28) {
    appHeader
    languageSection    // ADD HERE
    tripsSection
    searchSection
    transportSection
    notificationSection
    locationSection
    appSection
    developerSection
    footerSection
}
```

- [ ] **Step 4: Build (`⌘B`) and verify no errors**

---

## Task 4: Fix `OnboardingView.swift` to localize title and body

**Files:**
- Modify: `Linio/Content/OnboardingView.swift`

SwiftUI's `Text(someString: String)` does NOT perform a localization lookup — it displays the String verbatim. The onboarding pages store their title/body as `String` properties. To route them through `BundleSwizzle`, wrap them in `LocalizedStringKey`.

- [ ] **Step 1: Change the two `Text(pages[currentPage]...)` calls in `pageContent`**

Current:
```swift
Text(pages[currentPage].title)
    .font(.system(size: 32, weight: .bold, design: .default))
    .foregroundStyle(.white)
    .multilineTextAlignment(.center)

Text(pages[currentPage].body)
    .font(.system(size: 17))
    .foregroundStyle(.white.opacity(0.75))
    .multilineTextAlignment(.center)
    .lineSpacing(4)
    .padding(.horizontal, 8)
```

Replace with:
```swift
Text(LocalizedStringKey(pages[currentPage].title))
    .font(.system(size: 32, weight: .bold, design: .default))
    .foregroundStyle(.white)
    .multilineTextAlignment(.center)

Text(LocalizedStringKey(pages[currentPage].body))
    .font(.system(size: 17))
    .foregroundStyle(.white.opacity(0.75))
    .multilineTextAlignment(.center)
    .lineSpacing(4)
    .padding(.horizontal, 8)
```

- [ ] **Step 2: Build (`⌘B`) and verify no errors**

---

## Task 5: Fix `TicketView.swift` — localize `infoRow` labels

**Files:**
- Modify: `Linio/Content/TicketView.swift`

The `infoRow` function receives `label` as a `String` and passes it to `Text(label)`. Changing to `Text(LocalizedStringKey(label))` routes it through `BundleSwizzle` so `"INHABER"` → `"HOLDER"` etc. The `value` parameter must stay as `String` (it holds dynamic user data).

- [ ] **Step 1: Find `infoRow` in `TicketCardView` and change `Text(label)` to `Text(LocalizedStringKey(label))`**

Current:
```swift
private func infoRow(_ label: String, _ value: String) -> some View {
    HStack(alignment: .top) {
        Text(label)
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

Replace with:
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

- [ ] **Step 2: Localize the static value `"Bundesweit im Nahverkehr"`**

Find this call in `TicketCardView.infoSection`:
```swift
infoRow("GELTUNGSBEREICH", "Bundesweit im Nahverkehr")
```

Replace with:
```swift
infoRow("GELTUNGSBEREICH", NSLocalizedString("Bundesweit im Nahverkehr", comment: ""))
```

`NSLocalizedString` calls `Bundle.main.localizedString(forKey:...)` which is intercepted by `BundleSwizzle`.

- [ ] **Step 3: Build (`⌘B`) and verify no errors**

---

## Task 6: Manual verification

- [ ] **Step 1: Run the app in Simulator**

Build and run on iPhone 15 Pro simulator (iOS 17+).

- [ ] **Step 2: Verify German default**

App launches in German. All labels, navigation titles, and buttons show German text.

- [ ] **Step 3: Switch to English**

Settings → Sprache → English. The whole app re-renders. Verify:
- Settings navigation title: "Settings"
- Section headers: "PLANNED TRIPS", "CONNECTION SEARCH", "TRANSPORT", "LIVE ACTIVITY & NOTIFICATIONS", "LOCATION", "APP & DATA", "DEVELOPER"
- Toggle labels: "Tram", "Bus", "S-Bahn", "Auto Start", "Developer Mode", "Delays Only"
- Tab bar (if visible): "Departures", "Connections", "Tickets", "Settings"
- Departures view: "Departures" title, "NEXT DEPARTURES" header
- Connections view: "Connections" title, "Where do you want to go?"
- Tickets view: "Tickets" title
- Ticket card labels: "HOLDER", "CUSTOMER NO.", "VALID FOR", "VALIDITY"

- [ ] **Step 4: Switch back to German**

Settings → Sprache → Deutsch. Verify app returns to German.

- [ ] **Step 5: Verify onboarding**

Reset onboarding (`UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")` in Xcode console or re-install). Switch to English first, then view onboarding — should show English titles and body text.
