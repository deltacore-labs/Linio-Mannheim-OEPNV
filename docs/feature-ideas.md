# Linio — Feature-Ideen (Stand 2026-08-20)

Übersicht über Ideen für Features, die noch nicht implementiert sind.

---

## System-Integration

| Idee | Beschreibung |
|---|---|
| **Lock Screen Widgets** | WidgetKit Accessory-Familie (iOS 16+) — Countdown zur nächsten Abfahrt als Complication direkt am Sperrbildschirm |
| **StandBy Mode** | iOS 17 StandBy-optimiertes Widget: große Uhr + Abfahrtsmonitor für nachts am Ladegerät |
| **Interactive Widgets** | iOS 17+ — Button im Widget startet direkt eine Live Activity ohne die App zu öffnen |
| **Siri Shortcuts** | "Wann fährt die nächste 5er?" via AppIntents (Infra ist schon vorhanden) |

---

## Verbindungssuche / UX

| Idee | Beschreibung |
|---|---|
| **Favoriten-Haltestellen** | Fixierte Lieblingshaltestellen (Wohnung, Arbeit, Uni) — schneller Zugriff ohne Suche |
| **Verbindung teilen** | ShareLink: Fahrtdetails als Text oder Deeplink an Freunde schicken |
| **Filter speichern** | Bevorzugte Verkehrsmittel-Kombination als Default persistieren |
| **"Jetzt in der Nähe"-Button** | GPS-basierter Schnellzugriff: nächstgelegene Haltestelle sofort im Abfahrtsmonitor öffnen |

---

## Informations-Features

| Idee | Beschreibung |
|---|---|
| **Störungsmeldungen** | Service Alerts aus der RNV-API anzeigen (wenn verfügbar) — Baustellen, Ausfälle, Umleitungen |
| **Linienverlauf-Ansicht** | Alle Halte einer Linie von Anfang bis Ende scrollbar anzeigen |
| **Auslastungs-Trend** | Historische Auslastung für eine Verbindung (z.B. "montags morgens voll") — wenn API-Daten das hergeben |

---

## Ticket / Wallet

| Idee | Beschreibung |
|---|---|
| **Mehrere Tickets verwalten** | Neben dem D-Ticket z.B. ein Jobticket oder 9-Euro-Archiv ablegen |
| **Ticket-Widget** | Kleines Widget, das Ablaufdatum + Barcode-Schnellzugriff zeigt |

---

## Apple Watch

| Idee | Beschreibung |
|---|---|
| **Watch Complication** | Countdown zur nächsten Abfahrt für das Watch-Zifferblatt (WidgetKit-Watch) |
| **Haptisches Feedback bei Ankunft** | Vibration wenn man an der Zielhaltestelle ankommt |

---

## Sonstiges

| Idee | Beschreibung |
|---|---|
| **Onboarding-Update** | Nach D-Ticket- und Watch-Features neu erklären was alles geht |
| **App Clip** | Schnellstart für Gäste: nur Abfahrtsmonitor, ohne volle Installation |

---

## Priorität (subjektiv)

1. **Favoriten-Haltestellen** — fehlt komplett, hoher Alltagsnutzen
2. **Lock Screen Widgets** — passt zur bestehenden Widget-Infra
3. **Siri Shortcuts** — AppIntents ist schon drin, nur Haltestellen-Intents fehlen
4. **Störungsmeldungen** — wenn die RNV-API das hergibt
