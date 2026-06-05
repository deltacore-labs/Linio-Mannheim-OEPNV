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

    static var systemDefault: AppLanguage {
        let tag = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "de"
        return AppLanguage(rawValue: tag) ?? .german
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
