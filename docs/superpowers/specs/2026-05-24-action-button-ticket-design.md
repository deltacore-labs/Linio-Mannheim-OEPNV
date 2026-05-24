# Design: Action Button — „Ticket vorzeigen"

**Datum:** 2026-05-24  
**Scope:** iPhone Action Button (iPhone 15 Pro+) → Ticket sofort im Vollbild öffnen

---

## Ziel

Wenn der User den Action Button drückt, öffnet die App das Deutschlandticket sofort im
Vollbild mit maximaler Displayhelligkeit — ideal um es einem Kontrolleur vorzuzeigen.

Der User konfiguriert dies einmalig in:  
**Einstellungen → Action Button → App-Kurzbefehle → RNV-App → Ticket vorzeigen**

---

## Architektur

### Neues File: `RNV-Transport-App/ShowTicketIntent.swift`

Enthält zwei Typen:

**`ShowTicketIntent: AppIntent`**
- `static var openAppWhenRun: Bool = true` — iOS öffnet die App vor dem perform()-Aufruf
- `perform()` führt zwei Aktionen aus:
  1. Setzt `UserDefaults.standard.set(true, forKey: "pendingShowTicketFullscreen")` — für Kaltstart
  2. Postet `NotificationCenter.default.post(name: .showTicketFullscreen, object: nil)` — für laufende App
- Gibt `.result()` zurück (kein UI-Output nötig)

**`RNVAppShortcuts: AppShortcutsProvider`**
- Registriert den Intent als `AppShortcut` mit:
  - `shortTitle`: „Ticket vorzeigen"
  - `systemImageName`: `"qrcode"`
  - Zwei Siri-Phrasen: `"Ticket vorzeigen mit \(.applicationName)"` und `"Deutschlandticket mit \(.applicationName) zeigen"`

**`extension Notification.Name`**
- Definiert `static let showTicketFullscreen = Notification.Name("de.rnv.showTicketFullscreen")`  
  in `ShowTicketIntent.swift` — als Swift-Modul-Extension auf `Foundation.Notification.Name`
  direkt nutzbar in ContentView und TicketView ohne zusätzliche Imports.

---

### Änderung: `ContentView.swift`

Zwei neue Reaktionspfade die `selectedTab = 2` setzen:

1. **Notification (App läuft / Hintergrund):**
   ```swift
   .onReceive(NotificationCenter.default.publisher(for: .showTicketFullscreen)) { _ in
       selectedTab = 2
   }
   ```

2. **UserDefaults-Flag (Kaltstart):**  
   In der bestehenden `.onAppear`-Closure:
   ```swift
   if UserDefaults.standard.bool(forKey: "pendingShowTicketFullscreen") {
       selectedTab = 2
   }
   ```
   Das Flag selbst wird erst in `TicketView` zurückgesetzt, damit die View es auslesen kann.

---

### Änderung: `TicketView.swift`

Zwei neue Reaktionspfade die `showFullscreen = true` setzen.  
Beide prüfen `guard ticket != nil` — kein Ticket hinterlegt → keine Aktion.

1. **Notification (App läuft / Hintergrund):**
   ```swift
   .onReceive(NotificationCenter.default.publisher(for: .showTicketFullscreen)) { _ in
       guard ticket != nil else { return }
       showFullscreen = true
   }
   ```

2. **UserDefaults-Flag (Kaltstart) — im bestehenden `.onAppear`:**
   ```swift
   if UserDefaults.standard.bool(forKey: "pendingShowTicketFullscreen") {
       UserDefaults.standard.set(false, forKey: "pendingShowTicketFullscreen")
       if ticket != nil { showFullscreen = true }
   }
   ```

---

## Ablauf je Szenario

| Szenario | Pfad |
|---|---|
| App läuft im Vordergrund | Notification → ContentView schaltet Tab → TicketView öffnet Fullscreen |
| App im Hintergrund | `openAppWhenRun` bringt App in den Vordergrund → perform() → Notification → wie oben |
| App komplett beendet (Kaltstart) | `openAppWhenRun` startet App → perform() → UserDefaults-Flag → `.onAppear` in ContentView + TicketView |

---

## Randfälle

- **Kein Ticket hinterlegt:** Fullscreen wird nicht geöffnet; Tab-Wechsel zum Ticket passiert trotzdem (sinnvoll — User sieht leere Ticket-Ansicht).
- **UserDefaults-Flag bleibt hängen:** Flag wird in `TicketView.onAppear` zurückgesetzt; selbst wenn TicketView nie erscheint (z.B. Absturz), schadet ein erneutes Tab-Wechseln beim nächsten App-Start nicht.
- **Mehrfaches Drücken:** Jeder Druck postet erneut die Notification; `showFullscreen` ist ein Bool — wird von `true` auf `true` gesetzt, ohne Nebenwirkung.

---

## Nicht im Scope

- Siri-Sprachsteuerung testen (Siri-Phrasen sind registriert, aber nicht Teil dieses Features)
- Anpassung des Action Buttons an weitere Aktionen (z.B. Abfahrten)
- iOS-Versionen vor 16 (AppIntents erfordern iOS 16+; Action Button selbst erfordert iPhone 15 Pro / iOS 17)
