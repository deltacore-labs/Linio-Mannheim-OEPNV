# Action Button — „Ticket vorzeigen" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drücken des iPhone Action Buttons öffnet das Deutschlandticket sofort im Vollbild.

**Architecture:** `ShowTicketIntent` in `AppIntents.swift` setzt ein UserDefaults-Flag und postet eine NotificationCenter-Benachrichtigung. `ContentView` wechselt beim Empfang auf Tab 2. `TicketView` öffnet `showFullscreen = true` — beim Empfang der Notification (laufende App) und beim `.onAppear` via UserDefaults-Flag (Kaltstart).

**Tech Stack:** Swift, AppIntents (iOS 16+), NotificationCenter, UserDefaults, SwiftUI `.onReceive`

**Status: ✅ Implementierung vollständig** — Tasks 1–3 sind bereits in den Dateien vorhanden. Nur noch Task 4 (Manueller Test) und Task 5 (Commit) ausstehend.

---

## Dateien

| Aktion | Datei |
|---|---|
| ✅ Modify | `RNV-Transport-App/AppIntents.swift` |
| ✅ Modify | `RNV-Transport-App/Content/ContentView.swift` |
| ✅ Modify | `RNV-Transport-App/Content/TicketView.swift` |

---

### Task 1: `ShowTicketIntent` + Notification.Name in AppIntents.swift ✅

- [x] `Notification.Name.showTicketFullscreen` Extension vorhanden
- [x] `ShowTicketIntent` mit `openAppWhenRun = true`, UserDefaults-Flag und NotificationCenter-Post
- [x] `ShowTicketIntent` in `RNVAppShortcuts.appShortcuts` eingetragen

---

### Task 2: ContentView — Tab-Wechsel bei Action Button ✅

- [x] `.onReceive(.showTicketFullscreen)` → `selectedTab = 2`
- [x] `.onAppear` prüft `pendingShowTicketFullscreen` → `selectedTab = 2`

---

### Task 3: TicketView — Fullscreen bei Action Button ✅

- [x] `@State private var showFullscreen = false` vorhanden
- [x] `.fullScreenCover(isPresented: $showFullscreen)` → `TicketFullscreenView`
- [x] `.onAppear` prüft `pendingShowTicketFullscreen` → Flag löschen → `showFullscreen = true`
- [x] `.onReceive(.showTicketFullscreen)` → Flag löschen → `guard ticket != nil` → `showFullscreen = true`

---

---

### Task 4: Manueller Test

Kein Unit-Test-Target vorhanden — alle Szenarien manuell auf Gerät oder Simulator verifizieren.

- [ ] **Szenario A — App läuft im Vordergrund, Ticket hinterlegt**

  1. App starten, Ticket importieren (oder vorhandenes Ticket nutzen).
  2. In Xcode Console das Notification direkt auslösen:
     ```swift
     // In einer LLDB-Session oder einem Debug-Button:
     NotificationCenter.default.post(name: .showTicketFullscreen, object: nil)
     ```
     Alternativ: Action Button in Einstellungen konfigurieren und drücken.
  3. Erwartet: Tab wechselt zu „Ticket", Fullscreen-Ansicht öffnet sich sofort.

- [ ] **Szenario B — App läuft, kein Ticket hinterlegt**

  1. Ticket löschen (⋯ → Entfernen).
  2. Notification posten (wie oben).
  3. Erwartet: Tab wechselt zu „Ticket", Fullscreen öffnet sich **nicht** — leere Ticket-Ansicht.

- [ ] **Szenario C — Action Button in iOS-Einstellungen konfigurieren**

  1. iPhone 15 Pro oder neuer: **Einstellungen → Action Button**.
  2. Zur Option „App-Kurzbefehle" wischen → App auswählen → „Ticket vorzeigen" wählen.
  3. Action Button drücken.
  4. Erwartet (Ticket vorhanden): App öffnet sich direkt in Fullscreen-Ticket-Ansicht.

- [ ] **Szenario D — Kaltstart-Pfad simulieren**

  1. App komplett beenden (aus App-Switcher wischen).
  2. In Xcode: **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables** den Eintrag `SIMULATE_ACTION_BUTTON = 1` setzen ist nicht praktikabel. Stattdessen: Flag direkt vor App-Start in UserDefaults setzen, indem man kurz in die App startet, per LLDB in der Konsole ausführt:
     ```
     expr UserDefaults.standard.set(true, forKey: "pendingShowTicketFullscreen")
     ```
     dann App in App-Switcher neu starten (ohne Debugger-Attach).
     
     Oder einfacher: Action Button auf physischem Gerät drücken, während die App beendet ist.
  3. Erwartet: App startet, Tab 2 („Ticket") ist aktiv, Fullscreen öffnet sich sofort (wenn Ticket vorhanden).

---

### Task 5: Commit

- [ ] **Schritt 1: Geänderte Dateien prüfen**

  ```bash
  git diff --stat
  ```

  Erwartete Änderungen in `AppIntents.swift`, `ContentView.swift`, `TicketView.swift`.

- [ ] **Schritt 2: Committen**

  ```bash
  git add RNV-Transport-App/AppIntents.swift \
          RNV-Transport-App/Content/ContentView.swift \
          RNV-Transport-App/Content/TicketView.swift

  git commit -m "feat: Action Button öffnet Ticket im Vollbild

  ShowTicketIntent registriert als AppShortcut — Aktionstaste wechselt
  direkt auf den Ticket-Tab und öffnet TicketFullscreenView mit maximaler
  Helligkeit. Alle drei Szenarien abgedeckt: App läuft, Hintergrund,
  Kaltstart (UserDefaults-Flag)."
  ```

## Bekannte Einschränkungen

- **Action Button** ist nur auf iPhone 15 Pro, iPhone 15 Pro Max und allen iPhone 16-Modellen verfügbar.
- **AppIntents / AppShortcutsProvider** erfordern iOS 16+ (App-Deployment-Target bereits iOS 16+, kein `@available`-Guard nötig).
- **Simulator:** Der Action Button lässt sich im Simulator nicht simulieren. Szenario A (Notification direkt posten) ist der praktischste Simulator-Test.
