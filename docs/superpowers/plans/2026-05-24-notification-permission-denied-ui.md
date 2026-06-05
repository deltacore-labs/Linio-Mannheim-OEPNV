# Notification Permission Denied UI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deaktiviere Toggle und Picker in SettingsView wenn iOS-Benachrichtigungsberechtigung verweigert ist, und zeige einen Direkt-Link zu den iOS-Einstellungen.

**Architecture:** Einzige geänderte Datei ist `SettingsView.swift`. Ein neuer `@State`-Wert hält den aktuellen `UNAuthorizationStatus`. Dieser wird beim View-Erscheinen und bei jedem Vordergrundwechsel neu geladen. Die bestehende `notificationSection` reagiert auf den Status: Toggle und Picker werden deaktiviert, die ActionRow ändert Text und Farbe.

**Tech Stack:** SwiftUI, UserNotifications framework, `NotificationService.shared.authorizationStatus()` (bereits vorhanden)

---

### Task 1: Import und State hinzufügen

**Files:**
- Modify: `Linio/Linio/Content/SettingsView.swift:8-31`

- [ ] **Schritt 1: `UserNotifications` importieren**

Zeile 9 (nach `import CoreLocation`) einfügen:

```swift
import UserNotifications
```

- [ ] **Schritt 2: `@State` für Auth-Status ergänzen**

Nach Zeile 31 (`@State private var showPrivacyPolicy = false`) einfügen:

```swift
@State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
```

- [ ] **Schritt 3: Build prüfen**

In Xcode `⌘B` — muss fehlerfrei kompilieren.

---

### Task 2: Status laden und aktuell halten

**Files:**
- Modify: `Linio/Linio/Content/SettingsView.swift:81-84`

Die bestehenden View-Modifier am `NavigationView` (aktuell endet der Block mit `.onChange(of: reminderMinutes)` auf Zeile 81) werden um zwei Modifier erweitert.

- [ ] **Schritt 1: `.task` und `.onReceive` nach `.onChange` einfügen**

Den Block nach der schließenden `}` von `.onChange(of: reminderMinutes)` (Zeile 83) wie folgt erweitern:

```swift
.onChange(of: reminderMinutes) { _ in
    rescheduleAllNotifications()
}
.task {
    notificationAuthStatus = await NotificationService.shared.authorizationStatus()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
    Task {
        notificationAuthStatus = await NotificationService.shared.authorizationStatus()
    }
}
```

- [ ] **Schritt 2: Build prüfen**

`⌘B` — muss fehlerfrei kompilieren.

---

### Task 3: notificationSection anpassen

**Files:**
- Modify: `Linio/Linio/Content/SettingsView.swift:231-278`

Die gesamte `notificationSection` wird ersetzt. Änderungen:
1. `ToggleRow` "Push-Benachrichtigungen" bekommt `.disabled(notificationAuthStatus == .denied)`
2. Picker-`HStack` bekommt `.disabled(notificationAuthStatus == .denied)`
3. `ActionRow` wechselt Text und Farbe je nach Status

- [ ] **Schritt 1: `notificationSection` ersetzen**

Den gesamten Block von `// MARK: - Notification Section` bis zur schließenden `}` der `notificationSection` durch folgenden Code ersetzen:

```swift
// MARK: - Notification Section

private var notificationSection: some View {
    SettingsCard(title: "Live Activity & Mitteilungen", icon: "bell.badge.fill", iconColor: .orange, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
        ToggleRow(
            title: "Automatisch starten",
            subtitle: "Bei jeder Verbindungssuche",
            icon: "livephoto",
            iconColor: AppTheme.primaryColor,
            binding: $autoStartLiveActivity
        )
        RowDivider(color: AppTheme.hairline)
        ToggleRow(
            title: "Push-Benachrichtigungen",
            subtitle: "Verspätungen und Änderungen",
            icon: "bell.fill",
            iconColor: .orange,
            binding: $notificationsEnabled
        )
        .disabled(notificationAuthStatus == .denied)
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
        .disabled(notificationAuthStatus == .denied)
        RowDivider(color: AppTheme.hairline)
        if notificationAuthStatus == .denied {
            ActionRow(
                title: "Benachrichtigungen in Einstellungen erlauben",
                icon: "arrow.up.right.square",
                iconColor: AppTheme.primaryColor,
                inkColor: AppTheme.primaryColor,
                showChevron: false
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } else {
            ActionRow(
                title: "Systemeinstellungen öffnen",
                icon: "arrow.up.right.square",
                iconColor: AppTheme.muted,
                inkColor: AppTheme.ink,
                showChevron: false
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}
```

- [ ] **Schritt 2: Build prüfen**

`⌘B` — muss fehlerfrei kompilieren.

---

### Task 4: Manuell verifizieren

- [ ] **Schritt 1: Denied-Zustand testen**

  1. Im Simulator oder Gerät: Einstellungen → Mitteilungen → RNV → Alle Mitteilungen erlauben: **Aus**
  2. App starten (oder in den Vordergrund bringen)
  3. Einstellungen-Tab öffnen
  4. Erwartung: Toggle "Push-Benachrichtigungen" ist ausgegraut, Picker "Erinnerung" ist ausgegraut, ActionRow zeigt "Benachrichtigungen in Einstellungen erlauben" in `primaryColor`

- [ ] **Schritt 2: Deep-Link testen**

  1. ActionRow antippen
  2. Erwartung: iOS öffnet Einstellungen auf der App-Seite

- [ ] **Schritt 3: Wiederherstellung testen**

  1. In iOS-Einstellungen Berechtigung erteilen (Mitteilungen → App → Alle Mitteilungen erlauben: **Ein**)
  2. Zurück zur App wechseln
  3. Erwartung: Toggle und Picker sind wieder aktiv, ActionRow zeigt "Systemeinstellungen öffnen" in `AppTheme.muted`

- [ ] **Schritt 4: Normalzustand testen**

  1. App frisch auf Gerät ohne vorherige Berechtigung starten
  2. Berechtigungsdialog mit "Erlauben" bestätigen
  3. Einstellungen öffnen → Toggle und Picker müssen bedienbar sein
