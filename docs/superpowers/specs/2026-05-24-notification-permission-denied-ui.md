# Spec: Notification Permission Denied UI

## Ziel

Wenn der User die iOS-Benachrichtigungsberechtigung verweigert hat, soll die App das in den Einstellungen sichtbar machen — Toggle und Picker werden deaktiviert, ein Direkt-Link zu den iOS-Einstellungen erscheint.

## Kontext

`SettingsView` hat einen In-App-Toggle `notificationsEnabled` (`@AppStorage`), der unabhängig vom iOS-Systemzustand ist. Wenn iOS-Berechtigung denied ist, können `schedule()`-Aufrufe nie erfolgreich sein — der Toggle wirkt aber als wäre er aktiv. Das ist irreführend.

Referenzmuster: Die Standort-Section in derselben View zeigt bei `denied` bereits einen `ActionRow` "Standortzugriff in Einstellungen erlauben". Dieses Muster wird übernommen.

## Verhalten

### Normalzustand (authorized / notDetermined)
- Keine Änderung zum aktuellen Verhalten
- ActionRow "Systemeinstellungen öffnen" bleibt wie gehabt

### Denied-Zustand (UNAuthorizationStatus == .denied)
- Toggle "Push-Benachrichtigungen" → `.disabled(true)` (ausgegraut)
- Picker "Erinnerung" → `.disabled(true)` (ausgegraut)
- ActionRow "Systemeinstellungen öffnen" wird ersetzt durch ActionRow "Benachrichtigungen in Einstellungen erlauben" (icon: `arrow.up.right.square`, primaryColor — identisch zum Standort-Muster)

## Technische Umsetzung

**Datei:** `SettingsView.swift`

### State
```swift
@State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
```

### Status laden
```swift
.task {
    notificationAuthStatus = await NotificationService.shared.authorizationStatus()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
    Task {
        notificationAuthStatus = await NotificationService.shared.authorizationStatus()
    }
}
```

### Notification Section (Änderungen)
- Toggle: kein struktureller Umbau, `.disabled(notificationAuthStatus == .denied)` über den umgebenden `HStack` via Modifier auf `ToggleRow`
- Picker-Block: ebenfalls `.disabled(notificationAuthStatus == .denied)`
- ActionRow: konditionell — bei `.denied` der neue Text, sonst wie bisher

## Nicht in Scope
- Status `.notDetermined` wird nicht speziell behandelt (Berechtigung wird beim App-Start angefragt)
- `notificationsEnabled` AppStorage wird nicht zurückgesetzt — bleibt gespeichert, wirkt sobald Berechtigung erteilt wird
- Keine Änderung an `NotificationService`

## Verifikation
1. iOS-Simulator: Benachrichtigungen für App deaktivieren (Einstellungen → Mitteilungen → App → Aus)
2. App starten → Toggle und Picker sind ausgegraut, neue ActionRow erscheint
3. ActionRow antippen → iOS-Einstellungen öffnen sich auf der App-Seite
4. Berechtigung erteilen, zurück zur App → Toggle und Picker sind wieder aktiv, alte ActionRow erscheint
