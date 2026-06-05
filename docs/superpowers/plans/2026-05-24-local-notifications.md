# Lokale Benachrichtigungen — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lokale Push-Benachrichtigungen X Minuten vor Abfahrt gespeicherter Trips, konfigurierbar per GlobalSetting und per Trip.

**Architecture:** Neuer `NotificationService`-Singleton kapselt `UNUserNotificationCenter`. `TripDataManager` ruft ihn beim Speichern/Löschen/Togglen auf. `TripData` bekommt `notificationsEnabled: Bool` (Default `true`, rückwärtskompatibel). `SettingsView` zeigt Vorlauf-Picker, `PlannedTripDetailSheet` zeigt per-Trip-Toggle.

**Tech Stack:** SwiftUI, `UserNotifications`-Framework, `AppStorage`/`UserDefaults`, `UNTimeIntervalNotificationTrigger`

---

## Dateiübersicht

| Aktion | Datei | Inhalt |
|---|---|---|
| Neu | `Linio/NotificationService.swift` | Singleton: `schedule`, `cancel`, `cancelAll`, `requestAuthorizationIfNeeded`, `authorizationStatus` |
| Ändern | `Linio/TripDataManager.swift` | `TripData.notificationsEnabled`, `getAllTrips()`, `toggleNotification(for:)`, NS-Aufrufe in save/remove/archive |
| Ändern | `Linio/Content/SettingsView.swift` | `@AppStorage("reminderMinutes")`, Vorlauf-Picker, Reschedule bei Änderung |
| Ändern | `Linio/Content/PlannedTripDetailSheet.swift` | Notification-Toggle-Card mit Hinweis bei verweigerter Berechtigung |
| Ändern | `Linio/RNV_Transport_AppApp.swift` | `requestAuthorizationIfNeeded()` beim App-Start |

---

## Task 1: NotificationService.swift erstellen

**Files:**
- Create: `Linio/NotificationService.swift`

- [ ] **Datei anlegen**

Neue Datei `Linio/NotificationService.swift` mit folgendem Inhalt:

```swift
//
//  NotificationService.swift
//  Linio
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func schedule(trip: TripData, minutesBefore: Int) {
        guard let departureDate = DateFormattingHelper.shared.parseISO8601(trip.startTime) else { return }
        let timeInterval = departureDate.timeIntervalSinceNow - Double(minutesBefore * 60)
        guard timeInterval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Abfahrt in \(minutesBefore) Min"

        let firstLeg = trip.legs.first(where: { $0.legType != "continuousLeg" })
        let line = firstLeg?.serviceName ?? ""
        let direction = firstLeg?.destinationLabel ?? trip.endStation
        let time = DateFormattingHelper.shared.formatTime(trip.startTime)
        content.body = "\(line) Richtung \(direction) – \(time) Uhr von \(trip.startStation)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: trip.id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("❌ [NOTIF] Fehler beim Planen: \(error)")
            } else {
                print("✅ [NOTIF] Geplant für \(String(trip.id.prefix(8))) in \(Int(timeInterval))s")
            }
            #endif
        }
    }

    func cancel(tripId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [tripId])
        #if DEBUG
        print("✅ [NOTIF] Abgebrochen: \(String(tripId.prefix(8)))")
        #endif
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #if DEBUG
        print("✅ [NOTIF] Alle ausstehenden Notifications abgebrochen")
        #endif
    }
}
```

- [ ] **Kompilieren**

Cmd+B. Erwartetes Ergebnis: kein Fehler.

---

## Task 2: TripData — notificationsEnabled hinzufügen

**Files:**
- Modify: `Linio/TripDataManager.swift` (Bereich `TripData`-Struct, ca. Zeile 306–314)

- [ ] **TripData-Struct ersetzen**

Bestehenden Block:

```swift
struct TripData: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let interchanges: Int
    let startStation: String
    let endStation: String
    let legs: [TripLegData]
}
```

Ersetzen durch:

```swift
struct TripData: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let interchanges: Int
    let startStation: String
    let endStation: String
    let legs: [TripLegData]
    var notificationsEnabled: Bool

    init(
        id: String, startTime: String, endTime: String, interchanges: Int,
        startStation: String, endStation: String, legs: [TripLegData],
        notificationsEnabled: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.interchanges = interchanges
        self.startStation = startStation
        self.endStation = endStation
        self.legs = legs
        self.notificationsEnabled = notificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        startTime = try c.decode(String.self, forKey: .startTime)
        endTime = try c.decode(String.self, forKey: .endTime)
        interchanges = try c.decode(Int.self, forKey: .interchanges)
        startStation = try c.decode(String.self, forKey: .startStation)
        endStation = try c.decode(String.self, forKey: .endStation)
        legs = try c.decode([TripLegData].self, forKey: .legs)
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
    }
}
```

- [ ] **Kompilieren**

Cmd+B. Erwartetes Ergebnis: kein Fehler.

---

## Task 3: TripDataManager — NotificationService-Integration

**Files:**
- Modify: `Linio/TripDataManager.swift`

- [ ] **Schritt 1: `getAllTrips()` nach `getTripData(for:)` einfügen (ca. Zeile 121)**

```swift
func getAllTrips() -> [TripData] {
    return queue.sync {
        loadCachedTrips(defaults: userDefaults)
    }
}
```

- [ ] **Schritt 2: `toggleNotification(for:)` nach `getAllTrips()` einfügen**

```swift
func toggleNotification(for tripId: String) {
    queue.async { [weak self] in
        guard let self else { return }
        guard let defaults = self.userDefaults else { return }
        var trips = self.loadCachedTrips(defaults: defaults)
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].notificationsEnabled.toggle()
        let enabled = trips[idx].notificationsEnabled
        do {
            defaults.set(try JSONEncoder().encode(trips), forKey: self.tripDataKey)
            self.cachedTrips = trips
        } catch { return }
        if enabled {
            let minutes = UserDefaults.standard.integer(forKey: "reminderMinutes")
            NotificationService.shared.schedule(trip: trips[idx], minutesBefore: minutes == 0 ? 10 : minutes)
        } else {
            NotificationService.shared.cancel(tripId: tripId)
        }
    }
}
```

- [ ] **Schritt 3: In `saveTripData` — Notification planen**

In `saveTripData`, nach `self.cachedTrips = savedTrips` und vor dem `#if DEBUG`-Block, einfügen:

```swift
if tripData.notificationsEnabled {
    let minutes = UserDefaults.standard.integer(forKey: "reminderMinutes")
    NotificationService.shared.schedule(trip: tripData, minutesBefore: minutes == 0 ? 10 : minutes)
}
```

- [ ] **Schritt 4: In `removeTripData` — Notification abbrechen**

In `removeTripData`, direkt nach `guard let defaults = self.userDefaults else { return }`, einfügen:

```swift
NotificationService.shared.cancel(tripId: tripId)
```

- [ ] **Schritt 5: In `archiveAndRemoveTripData` — Notification abbrechen**

In `archiveAndRemoveTripData`, direkt nach `guard let defaults = self.userDefaults else { return }`, einfügen:

```swift
NotificationService.shared.cancel(tripId: tripId)
```

- [ ] **Schritt 6: Kompilieren**

Cmd+B. Erwartetes Ergebnis: kein Fehler.

---

## Task 4: SettingsView — Vorlauf-Picker + Reschedule

**Files:**
- Modify: `Linio/Content/SettingsView.swift`

- [ ] **Schritt 1: `@AppStorage("reminderMinutes")` hinzufügen**

Nach `@AppStorage("developerMode") private var developerMode = false` einfügen:

```swift
@AppStorage("reminderMinutes") private var reminderMinutes = 10
```

- [ ] **Schritt 2: `rescheduleAllNotifications()` Methode hinzufügen**

Neue private Methode, z. B. nach dem letzten `// MARK:` in der View:

```swift
private func rescheduleAllNotifications() {
    NotificationService.shared.cancelAll()
    let trips = TripDataManager.shared.getAllTrips()
    for trip in trips where trip.notificationsEnabled {
        NotificationService.shared.schedule(trip: trip, minutesBefore: reminderMinutes)
    }
}
```

- [ ] **Schritt 3: Vorlauf-Picker in `notificationSection` einfügen**

In `notificationSection`, nach dem `ToggleRow` für „Push-Benachrichtigungen" und dessen `RowDivider`, einen weiteren `RowDivider` + Picker-Row einfügen. Den bestehenden Abschnitt:

```swift
        RowDivider(color: AppTheme.hairline)
        ActionRow(
```

Ersetzen durch:

```swift
        RowDivider(color: AppTheme.hairline)
        HStack(spacing: 12) {
            IconBadge(icon: "timer", color: .orange)
            Text("Erinnerung")
                .font(.body)
                .foregroundColor(AppTheme.ink)
            Spacer()
            Picker("", selection: $reminderMinutes) {
                ForEach([5, 10, 15, 20, 30], id: \.self) { min in
                    Text("\(min) Min").tag(min)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.primaryColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        RowDivider(color: AppTheme.hairline)
        ActionRow(
```

- [ ] **Schritt 4: `.onChange` für `reminderMinutes` am body anhängen**

Am Ende des `body`, nach `.sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicyView() }`, einfügen:

```swift
        .onChange(of: reminderMinutes) { _ in
            rescheduleAllNotifications()
        }
```

- [ ] **Schritt 5: Kompilieren**

Cmd+B. Erwartetes Ergebnis: kein Fehler.

---

## Task 5: PlannedTripDetailSheet — per-Trip Notification Toggle

**Files:**
- Modify: `Linio/Content/PlannedTripDetailSheet.swift`

- [ ] **Schritt 1: State-Properties hinzufügen**

Nach `@Environment(\.dismiss) private var dismiss` einfügen:

```swift
@State private var notifEnabled: Bool
@State private var notifDenied = false
```

- [ ] **Schritt 2: Expliziten `init` hinzufügen**

Direkt nach den Property-Deklarationen (`let tripId`, `let tripData`, `let onEnd`), einen init einfügen der `notifEnabled` aus `tripData` initialisiert:

```swift
init(tripId: String, tripData: TripData, onEnd: @escaping () -> Void) {
    self.tripId = tripId
    self.tripData = tripData
    self.onEnd = onEnd
    self._notifEnabled = State(initialValue: tripData.notificationsEnabled)
}
```

- [ ] **Schritt 3: `notificationCard` View-Property hinzufügen**

Neue private `@ViewBuilder`-Property, z. B. nach `phaseStatusBanner`:

```swift
@ViewBuilder
private var notificationCard: some View {
    Group {
        if notifDenied {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.orange)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Benachrichtigungen deaktiviert")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Button("In Systemeinstellungen aktivieren") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.primaryColor)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        } else {
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.orange)
                    .frame(width: 28)
                Text("Benachrichtigung")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Toggle("", isOn: $notifEnabled)
                    .labelsHidden()
                    .tint(AppTheme.primaryColor)
                    .onChange(of: notifEnabled) { _ in
                        TripDataManager.shared.toggleNotification(for: tripId)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(AppTheme.surfaceCard)
            .shadow(color: AppTheme.shadowColor(), radius: 8, y: 4)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.hairline, lineWidth: 1))
    )
    .task {
        let status = await NotificationService.shared.authorizationStatus()
        notifDenied = (status == .denied)
        if status == .notDetermined {
            NotificationService.shared.requestAuthorizationIfNeeded()
        }
    }
}
```

- [ ] **Schritt 4: `notificationCard` ins `body`-VStack einbinden**

Im `body`-VStack, nach `overviewCard` und vor `routeTimelineCard` einfügen:

```swift
notificationCard
```

Das VStack sieht danach so aus:

```swift
VStack(spacing: 16) {
    phaseStatusBanner
    overviewCard
    notificationCard
    routeTimelineCard
}
```

- [ ] **Schritt 5: Kompilieren**

Cmd+B. Erwartetes Ergebnis: kein Fehler.

---

## Task 6: App-Start — Berechtigung anfragen

**Files:**
- Modify: `Linio/RNV_Transport_AppApp.swift`

- [ ] **`requestAuthorizationIfNeeded()` in `AppDelegate.didFinishLaunchingWithOptions` aufrufen**

In `AppDelegate.application(_:didFinishLaunchingWithOptions:)`, nach dem `#if DEBUG`-Block und vor `return true`, einfügen:

```swift
NotificationService.shared.requestAuthorizationIfNeeded()
```

- [ ] **Kompilieren**

Cmd+B. Erwartetes Ergebnis: kein Fehler.

---

## Task 7: Manueller End-to-End-Test

- [ ] **App auf Simulator oder Gerät starten**

- [ ] **Trip suchen und speichern**
  - Sicherstellen, dass die Abfahrtszeit > 10 Min in der Zukunft liegt
  - Trip über den Speichern-Button sichern
  - Im Debug-Log `✅ [NOTIF] Geplant für ...` prüfen

- [ ] **Geplante Notifications prüfen (Simulator)**
  - Gerätezeit im Simulator auf kurz vor Abfahrt vorstellen (Features → Trigger notifications) oder Vorlauf auf 1 Min setzen und warten

- [ ] **PlannedTripDetailSheet öffnen**
  - Toggle „Benachrichtigung" ist sichtbar und aktiviert
  - Toggle deaktivieren → `✅ [NOTIF] Abgebrochen: ...` im Log
  - Toggle wieder aktivieren → `✅ [NOTIF] Geplant für ...` im Log

- [ ] **Vorlauf in Settings ändern**
  - Settings → Erinnerung Picker auf 5 Min → `✅ [NOTIF] Alle ausstehenden Notifications abgebrochen` + erneutes Planen im Log

- [ ] **Trip löschen**
  - Trip entfernen → `✅ [NOTIF] Abgebrochen: ...` im Log
