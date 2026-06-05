# Lokale Benachrichtigungen für geplante Trips

**Datum:** 2026-05-24  
**Status:** Approved

## Ziel

Nutzer erhalten eine lokale Push-Benachrichtigung X Minuten vor Abfahrt eines gespeicherten Trips. Der Vorlauf ist global in den Einstellungen konfigurierbar; einzelne Trips können per Toggle deaktiviert werden.

---

## Architektur

### Neue Datei

**`NotificationService.swift`** — Singleton, kapselt `UNUserNotificationCenter`.

Verantwortlichkeiten:
- `requestAuthorizationIfNeeded()` — fragt Berechtigung an (nur einmalig nötig)
- `schedule(trip: TripData, minutesBefore: Int)` — plant eine Notification mit ID = `trip.id`
- `cancel(tripId: String)` — entfernt eine ausstehende Notification
- `cancelAll()` — entfernt alle ausstehenden Notifications des App
- `authorizationStatus() async -> UNAuthorizationStatus` — für UI-Hinweis

### Geänderte Dateien

| Datei | Änderung |
|---|---|
| `TripDataManager.swift` | `saveTripData` und `removeTripData`/`archiveAndRemoveTripData` rufen `NotificationService` auf; neues `toggleNotification(for tripId:)` |
| `TripData` (in TripDataManager) | Neues Feld `notificationsEnabled: Bool`, Default `true`; rückwärtskompatibel via `var notificationsEnabled: Bool = true` im Codable-Decode |
| `SettingsView.swift` | Neuer Abschnitt „Benachrichtigungen" mit Picker für Vorlauf (5 / 10 / 15 / 20 / 30 Min); Wert in `UserDefaults` unter Key `reminderMinutes` |
| `PlannedTripDetailSheet.swift` | Toggle-Switch „Benachrichtigung" pro Trip; bei verweigerter Systemberechtigung: Toggle deaktiviert + Hinweistext mit Link zu Systemeinstellungen |

**Keine Änderungen nötig:** Entitlements, `Info.plist` — lokale Notifications erfordern kein spezielles Entitlement.

---

## Notification-Inhalt

| Feld | Wert |
|---|---|
| Titel | `Abfahrt in {X} Min` |
| Body | `{Linie} Richtung {Ziel} – {Uhrzeit} Uhr von {Startbahnhof}` |
| Beispiel | „RNV 5 Richtung Heidelberg Hbf – 14:32 Uhr von Mannheim Hbf" |
| Sound | Standard-System-Sound |

> Gleis ist im aktuellen `TripLegData`-Modell nicht vorhanden und wird daher nicht angezeigt. Kann ergänzt werden, sobald das Datenmodell erweitert wird.

Datenquellen aus `TripData`:
- `startTime` → Trigger-Zeitpunkt und formatierte Uhrzeit im Body
- `startStation` → Abfahrtsort
- `endStation` → Ziel (Fallback falls `destinationLabel` im ersten Leg fehlt)
- Erstes `TripLegData` → `serviceName` (Linie), `destinationLabel` (Richtung)

---

## Ablauf

```
saveTripData(trip)
  └─ notificationsEnabled == true?
       ├─ ja  → NotificationService.schedule(trip:minutesBefore:)
       │          ├─ Berechtigung erteilt  → UNNotificationRequest hinzufügen
       │          ├─ Noch nicht angefragt  → requestAuthorization, dann planen
       │          └─ Verweigert           → still skippen
       └─ nein → nichts tun

removeTripData / archiveAndRemoveTripData(tripId)
  └─ NotificationService.cancel(tripId:)

toggleNotification(for tripId:)
  └─ TripData.notificationsEnabled umschalten
       ├─ true  → schedule(trip:)
       └─ false → cancel(tripId:)
```

**Trigger:** `UNTimeIntervalNotificationTrigger` mit `timeInterval = departureDate - now - (reminderMinutes * 60)`. Wenn der berechnete Zeitintervall ≤ 0 (Abfahrt schon vorbei oder zu nah), wird keine Notification geplant.

**Notification-ID:** `trip.id` — ermöglicht gezieltes Canceln ohne separate Buchführung.

---

## Einstellungen

- Key: `reminderMinutes` in `UserDefaults` (Standard-Suite, kein App Group nötig)
- Default: `10`
- Optionen im Picker: 5, 10, 15, 20, 30 Minuten
- Änderung des Vorlaufs → alle ausstehenden Notifications neu planen (`cancelAll()` + alle aktiven Trips neu schedulen)

---

## Fehlerbehandlung

| Szenario | Verhalten |
|---|---|
| Berechtigung verweigert | Notification still skippen; Toggle in `PlannedTripDetailSheet` deaktiviert + Hinweis mit `UIApplication.openSettingsURLString` |
| Abfahrt in der Vergangenheit | `timeInterval ≤ 0` → nicht planen, kein Fehler |
| Trip-ID existiert nicht mehr | `UNUserNotificationCenter.removePendingNotificationRequests` ist idempotent → kein Problem |
| Vorlauf-Änderung in Settings | Alle pending Notifications canceln, alle `TripData` mit `notificationsEnabled == true` neu planen |
