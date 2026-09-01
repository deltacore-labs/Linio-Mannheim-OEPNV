## 🌐 Website
**[https://deltacore-labs.github.io/Linio-Mannheim-OEPNV/](https://deltacore-labs.github.io/Linio-Mannheim-OEPNV/)**

---

> 👉 **English version below:** [Jump to English](#linio-english-)

# <a name="linio"></a>Linio 🚌💨

**Deine Echtzeit-Reisebegleitung für den Mannheimer ÖPNV**

Linio ist eine moderne iOS-App für Verbindungen im RNV-Netz – mit Live Activities in der Dynamic Island, Abfahrtsmonitor, Deutschlandticket-Integration und Apple Watch-Unterstützung.

> [!NOTE]
> Dies ist ein **Studentenprojekt**, das die Möglichkeiten der RNV-API, Apple Live Activities und moderner iOS-Entwicklung in der Praxis erprobt.

---

## 🌟 Features

### 🔍 Verbindungssuche
* Suche nach Verbindungen zwischen zwei Haltestellen mit Echtzeit-Ergebnissen
* Abfahrts- und Ankunftsmodus mit Datum- & Uhrzeit-Auswahl
* Navigation zu früheren/späteren Verbindungen
* Filter nach Verkehrsmittel (Straßenbahn, Bus, S-Bahn)
* Verspätungsanzeige mit farbigen Badges; Filter „Nur Verspätungen"
* Auslastungsanzeige pro Verbindung
* Zuletzt verwendete Haltestellen mit Häufigkeitsranking

### 🚉 Abfahrtsmonitor
* Echtzeit-Abfahrten für beliebige Haltestellen, auto-refresh alle 60 Sekunden
* Countdown in Minuten bis zur nächsten Abfahrt
* Verspätungs-Badges (+ X min), Auslastungsanzeige, Steig-Buchstaben (A/B/…)
* Steig-Sheet: Detailansicht aller Abfahrten an einem bestimmten Gleis inkl. Mini-Karte
* Abfrage beliebiger Zeitpunkte per Datums-/Uhrzeit-Picker

### ⚡ Live Activities & Dynamic Island
* Live Activity auf dem Sperrbildschirm für aktive Fahrten
* Dynamic Island: Kompakt-, Erweiterungs- und Minimalansicht
* Phasendarstellung: **Vor Abfahrt** → **Unterwegs** → **Angekommen**
* Countdown zur Abfahrt, Echtzeit-Verspätung, nächster Umstieg
* Direkter Deeplink aus der Dynamic Island in die App
* Farbcodierte Linienbadges

### 🎫 Ticket & Apple Wallet
* Deutschlandticket-Import per Foto (1–2 Screenshots, OCR-gestützt)
* Automatische Erkennung von Name, Kundennummer, Gültigkeitsdaten und Aussteller
* Manuelle Eingabe als Fallback
* Barcode-Extraktion (Aztec / QR / Data Matrix)
* „Zu Apple Wallet hinzufügen" – generiert ein PKPass direkt in der App
* Vollbild-Ticketansicht mit maximaler Helligkeit
* Ticket-Verlängerungserinnerung am Ablaufdatum um 09:00 Uhr, Snooze um 3 Tage

### 🔔 Benachrichtigungen
* Lokale Erinnerungen vor Abfahrt (5 / 10 / 15 / 20 / 30 Minuten konfigurierbar)
* Automatischer Live-Activity-Start bei Fahrtbeginn (optional)
* Erneuerungserinnerung für das Deutschlandticket
* Verwaltung der iOS-Benachrichtigungsrechte mit direktem Link in die Einstellungen

### 🗺️ Karte & Route
* Routenübersicht mit Start-/Ziel-Pins und Umstiegspunkten
* Interaktive Zwischenhalte-Anzeige als Polylinie
* Aufklappbares Routen-Panel (Peek / Kompakt / Vollbild)
* Vollbild-Kartenansicht mit Kompass, Nutzerstandort und Maßstab
* Apple-Maps-Deeplink für Turn-by-Turn-Navigation

### 📱 Home-Screen-Widget
* Konfigurierbares Abfahrtsmonitor-Widget für eine beliebige Haltestelle
* Drei Größen: Small (1 Abfahrt), Medium (3), Large (6)
* Countdown in Minuten, Verspätungsanzeige, Steig-Label
* Auto-Refresh alle 15 Minuten

### ⌚ Apple Watch
* Aktive Fahrt: Echtzeit-Tracking mit Countdown und Phasenanzeige
* Geplante Fahrten: Liste der gespeicherten Trips vom iPhone
* Abfahrtsmonitor: Echtzeit-Tafel für ausgewählte Haltestelle
* Verbindungssuche direkt von der Watch
* Steig- und Linienangaben auf dem Handgelenk

### ⚙️ Einstellungen
* Maximale Verbindungsanzahl (3–10) und Suchradius (0,5–5 km)
* Verkehrsmittel-Toggles, Auto-Start Live Activity
* Sprache: Deutsch / Englisch
* Standortberechtigung verwalten, Cache leeren
* Alle Live Activities beenden
* Datenschutzerklärung

### ♿ Barrierefreiheit
* Accessibility-Labels und -Hints auf allen interaktiven Elementen
* Dynamic Type – alle Texte skalieren mit der Schriftgröße des Systems
* Reduce-Motion-Unterstützung im Onboarding
* Vollständige VoiceOver-Kompatibilität

---

## 🛠️ Technologie-Stack

| Technologie | Einsatzbereich |
| :--- | :--- |
| **SwiftUI** | Deklaratives UI-Framework |
| **ActivityKit** | Live Activities & Dynamic Island |
| **WidgetKit** | Home-Screen-Widgets |
| **AppIntents** | Interaktion mit Live Activities |
| **WatchKit / SwiftUI** | Apple Watch App |
| **CoreLocation** | GPS-basierte Standortbestimmung |
| **MapKit** | Routen- und Haltestellenkarten |
| **PassKit** | Apple Wallet PKPass-Generierung |
| **Vision** | OCR für Ticket-Screenshots |
| **GraphQL** | RNV-API-Anbindung |
| **Combine** | Reaktive Datenflüsse |
| **Azure AD** | Client Credentials Flow (Auth) |

* **Mindest-iOS-Version:** iOS 16.2+

---

## 🚀 Einrichtung des Projekts

### 1. Klonen des Repositorys
```bash
git clone https://github.com/deltacore-labs/Linio-Mannheim-OEPNV.git
cd Linio-Mannheim-OEPNV
```

### 2. API-Authentifizierung einrichten

Ersetze die Platzhalter in `RNV-Transport-App/AuthService.swift` mit deinen Anmeldedaten aus dem Azure Portal:

```swift
private let clientID     = "DEIN_CLIENT_ID"
private let clientSecret = "DEIN_CLIENT_SECRET"
private let tenantID     = "DEIN_TENANT_ID"
private let resource     = "DEINE_RESOURCE_ID"
```

### 3. App Groups konfigurieren

Damit Haupt-App, Widget und Live-Activity-Extension Daten teilen können:

* **Target `Linio`** → Signing & Capabilities → App Group hinzufügen (z. B. `group.com.yourcompany.linioapp`)
* Dasselbe für **`RNVLiveActivity`** und **`RNVWatch`** mit exakt derselben Group-ID

### 4. Standortdienste (Info.plist)

Die `NSLocationWhenInUseUsageDescription` und `NSLocationAlwaysAndWhenInUseUsageDescription` sind bereits gesetzt.

---

## 👨‍💻 Verwendung

* **Suchen:** Route per GPS oder manuelle Eingabe finden
* **Tracken:** Live-Activity-Toggle bei der gewünschten Verbindung aktivieren
* **Abfahrten:** Tab „Abfahrten" für den Echtzeit-Monitor
* **Ticket:** Tab „Ticket" → Deutschlandticket importieren und zu Wallet hinzufügen
* **Beenden:** Roter „Beenden"-Button in der Dynamic Island oder Toggle in der App

---

## 📸 Screenshots

*(Coming Soon!)*

---

## 🤝 Contributing

Beiträge sind herzlich willkommen! Fork das Projekt, erstelle Issues oder reiche Pull Requests ein.

Bei Fragen oder Feedback: [delta.corelabs@gmail.com](mailto:delta.corelabs@gmail.com)

---

## 📄 License

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert – siehe [LICENSE](LICENSE) für Details.

---

# <a name="linio-english-"></a>Linio (English) 🚌💨

## 🌐 Website
**[https://deltacore-labs.github.io/Linio-Mannheim-OEPNV/](https://deltacore-labs.github.io/Linio-Mannheim-OEPNV/)**

**Your real-time transit companion for the Mannheim public transport network**

Linio is a modern iOS app for RNV connections – with Live Activities in the Dynamic Island, a departure board, Deutschlandticket integration, and Apple Watch support.

> [!NOTE]
> This is a **student project** exploring the RNV API, Apple Live Activities, and modern iOS development in practice.

---

## 🌟 Features

### 🔍 Connection Search
* Search connections between any two stops with real-time results
* Departure and arrival time modes with date & time picker
* Navigate to earlier / later connections
* Filter by transport type (Tram, Bus, S-Bahn)
* Delay badges with an optional "Delays only" filter
* Occupancy level indicators
* Recently used stops with frequency-based ranking

### 🚉 Departure Board
* Live departures for any stop, auto-refreshed every 60 seconds
* Countdown in minutes, delay badges (+ X min), occupancy, platform letters
* Platform sheet: all departures at a specific platform with a mini-map
* Historical queries via date & time picker

### ⚡ Live Activities & Dynamic Island
* Lock screen Live Activity for active trips
* Dynamic Island: compact, expanded, and minimal views
* Phases: **Before Departure** → **En Route** → **Arrived**
* Departure countdown, real-time delay, next transfer info
* Deep link from Dynamic Island directly into the app
* Color-coded line badges

### 🎫 Ticket & Apple Wallet
* Deutschlandticket import via photo (1–2 screenshots, OCR-powered)
* Auto-recognition of name, customer number, validity dates, and issuer
* Manual entry fallback
* Barcode extraction (Aztec / QR / Data Matrix)
* "Add to Apple Wallet" – generates a PKPass directly in the app
* Full-screen ticket view at maximum brightness
* Renewal reminder on the expiry date at 09:00, snooze by 3 days

### 🔔 Notifications
* Local reminders before departure (5 / 10 / 15 / 20 / 30 min, configurable)
* Optional auto-start Live Activity on departure
* Renewal reminder for the Deutschlandticket
* iOS notification permission management with a direct link to Settings

### 🗺️ Map & Route
* Route overview with origin/destination pins and transfer markers
* Interactive stop dots along the polyline
* Collapsible route panel (peek / compact / full screen)
* Full-screen map with compass, user location, and scale
* Apple Maps deep link for turn-by-turn navigation

### 📱 Home Screen Widget
* Configurable departure board widget for any stop
* Three sizes: Small (1 departure), Medium (3), Large (6)
* Countdown in minutes, delay display, platform label
* Auto-refresh every 15 minutes

### ⌚ Apple Watch
* Active trip: real-time tracking with countdown and phase display
* Planned trips: list of saved trips from iPhone
* Departure board: live departures for a selected stop
* Connection search directly from the Watch
* Platform and line details on your wrist

### ⚙️ Settings
* Max connections (3–10) and search radius (0.5–5 km)
* Transport type toggles, auto-start Live Activity
* Language: German / English
* Location permission management, cache clearing
* End all Live Activities
* Privacy Policy

### ♿ Accessibility
* Accessibility labels and hints on all interactive elements
* Dynamic Type – all text scales with the system font size
* Reduce Motion support in onboarding
* Full VoiceOver compatibility

---

## 🛠️ Technology Stack

| Technology | Purpose |
| :--- | :--- |
| **SwiftUI** | Declarative UI framework |
| **ActivityKit** | Live Activities & Dynamic Island |
| **WidgetKit** | Home screen widgets |
| **AppIntents** | Live Activity interaction |
| **WatchKit / SwiftUI** | Apple Watch app |
| **CoreLocation** | GPS-based location services |
| **MapKit** | Route and stop maps |
| **PassKit** | Apple Wallet PKPass generation |
| **Vision** | OCR for ticket screenshots |
| **GraphQL** | RNV API integration |
| **Combine** | Reactive data streams |
| **Azure AD** | Client Credentials Flow (auth) |

* **Minimum iOS version:** iOS 16.2+

---

## 🚀 Project Setup

### 1. Clone the Repository
```bash
git clone https://github.com/deltacore-labs/Linio-Mannheim-OEPNV.git
cd Linio-Mannheim-OEPNV
```

### 2. Configure API Authentication

Replace the placeholders in `RNV-Transport-App/AuthService.swift` with your Azure Portal credentials:

```swift
private let clientID     = "YOUR_CLIENT_ID"
private let clientSecret = "YOUR_CLIENT_SECRET"
private let tenantID     = "YOUR_TENANT_ID"
private let resource     = "YOUR_RESOURCE_ID"
```

### 3. Configure App Groups

For data sharing between the main app, widget, and Live Activity extension:

* **Target `Linio`** → Signing & Capabilities → add an App Group (e.g. `group.com.yourcompany.linioapp`)
* Repeat for **`RNVLiveActivity`** and **`RNVWatch`** using the exact same Group ID

### 4. Location Services

`NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` are already set in `Info.plist`.

---

## 👨‍💻 Usage

* **Search:** Find routes using GPS or manual input
* **Track:** Enable the Live Activity toggle on any connection
* **Departures:** Use the "Departures" tab for the live board
* **Ticket:** "Ticket" tab → import your Deutschlandticket and add it to Wallet
* **End:** Tap the red "End" button in the Dynamic Island or disable the toggle in the app

---

## 📸 Screenshots

*(Coming Soon!)*

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [CHANGELOG.md](CHANGELOG.md) | Version history and changes |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [docs/development/](docs/development/) | Developer documentation |
| [LinioTests/README.md](LinioTests/README.md) | Unit test documentation |
| [LinioWatch/README.md](LinioWatch/README.md) | Apple Watch app documentation |

### Developer Docs

- [Architecture](docs/development/ARCHITECTURE.md) - Project structure & patterns
- [Testing](docs/development/TESTING.md) - Test strategy & conventions
- [Code Style](docs/development/CODE_STYLE.md) - Coding standards & SwiftLint
- [API](docs/development/API.md) - RNV GraphQL API integration

---

## 🤝 Contributing

Contributions are welcome! Fork the project, open issues, or submit pull requests.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

For questions or feedback: [delta.corelabs@gmail.com](mailto:delta.corelabs@gmail.com)

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.
