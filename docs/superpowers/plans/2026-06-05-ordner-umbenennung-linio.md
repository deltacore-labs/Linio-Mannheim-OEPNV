# Ordner-Umbenennung zu Linio – Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alle Ordner, Dateien und Referenzen im Projekt von den alten Namen (`RNV-Transport-App`, `RNVLiveActivity`, `RNVWatch`, `Mannheim ÖPNV`) auf den neuen Namen `Linio` umstellen.

**Architecture:** Reine Umbenennung – keine Verhaltensänderungen. Alle Schritte sind atomar: zuerst Filesystem, dann pbxproj, dann xcschemes, dann Swift-Quellcode. Xcode muss vor den Umbenennungen geschlossen sein.

**Tech Stack:** Bash (mv, sed), Swift-Quellcode, Xcode project.pbxproj (text), xcscheme XML

---

## Vollständige Übersicht der Umbenennungen

| Alt | Neu |
|-----|-----|
| `Mannheim ÖPNV.xcodeproj` | `Linio.xcodeproj` |
| `RNV-Transport-App/` (Quellordner) | `Linio/` |
| `RNV-Transport-App/RNV-Transport-App.entitlements` | `Linio/Linio.entitlements` |
| `RNV-Transport-App/RNV-Transport-AppRelease.entitlements` | `Linio/LinioRelease.entitlements` |
| `RNV-Transport-App/RNV_Transport_App.xcdatamodeld/` | `Linio/Linio.xcdatamodeld/` |
| `RNV-Transport-App/RNV_Transport_App.xcdatamodeld/RNV_Transport_App.xcdatamodel/` | `Linio/Linio.xcdatamodeld/Linio.xcdatamodel/` |
| `RNV-Transport-App/RNV_Transport_AppApp.swift` | `Linio/LinioApp.swift` |
| `RNVLiveActivity/` | `LinioLiveActivity/` |
| `RNVLiveActivity/RNVLiveActivityBundle.swift` | `LinioLiveActivity/LinioLiveActivityBundle.swift` |
| `RNVLiveActivity/RNVLiveActivityLiveActivity.swift` | `LinioLiveActivity/LinioLiveActivityLiveActivity.swift` |
| `RNVLiveActivityExtension.entitlements` (root) | `LinioLiveActivityExtension.entitlements` |
| `RNVWatch/` | `LinioWatch/` |
| `RNVWatch/RNVWatch.entitlements` | `LinioWatch/LinioWatch.entitlements` |
| xcscheme `RNV-Transport-App.xcscheme` | `Linio.xcscheme` |
| xcscheme `RNVLiveActivityExtension.xcscheme` | `LinioLiveActivityExtension.xcscheme` |

---

### Task 1: Xcode schließen und Filesystem-Umbenennungen

**Wichtig:** Xcode muss vollständig geschlossen sein, bevor diese Schritte ausgeführt werden.

**Files:**
- Rename: `Mannheim ÖPNV.xcodeproj/` → `Linio.xcodeproj/`
- Rename: `RNV-Transport-App/` → `Linio/`
- Rename: `RNVLiveActivity/` → `LinioLiveActivity/`
- Rename: `RNVWatch/` → `LinioWatch/`
- Rename: diverse Einzeldateien (s.u.)

- [ ] **Schritt 1: xcodeproj umbenennen**

```bash
cd /Users/I767513/Xcode/RNV-Transport-App
mv "Mannheim ÖPNV.xcodeproj" "Linio.xcodeproj"
```

- [ ] **Schritt 2: Quellordner umbenennen**

```bash
mv "RNV-Transport-App" "Linio"
mv "RNVLiveActivity"   "LinioLiveActivity"
mv "RNVWatch"          "LinioWatch"
```

- [ ] **Schritt 3: Entitlements-Dateien umbenennen**

```bash
mv "Linio/RNV-Transport-App.entitlements"        "Linio/Linio.entitlements"
mv "Linio/RNV-Transport-AppRelease.entitlements" "Linio/LinioRelease.entitlements"
mv "RNVLiveActivityExtension.entitlements"       "LinioLiveActivityExtension.entitlements"
mv "LinioWatch/RNVWatch.entitlements"            "LinioWatch/LinioWatch.entitlements"
```

- [ ] **Schritt 4: CoreData-Modell umbenennen**

```bash
mv "Linio/RNV_Transport_App.xcdatamodeld/RNV_Transport_App.xcdatamodel" \
   "Linio/RNV_Transport_App.xcdatamodeld/Linio.xcdatamodel"
mv "Linio/RNV_Transport_App.xcdatamodeld" \
   "Linio/Linio.xcdatamodeld"
```

- [ ] **Schritt 5: Swift-Dateien mit alten Namen umbenennen**

```bash
mv "Linio/RNV_Transport_AppApp.swift"                             "Linio/LinioApp.swift"
mv "LinioLiveActivity/RNVLiveActivityBundle.swift"                "LinioLiveActivity/LinioLiveActivityBundle.swift"
mv "LinioLiveActivity/RNVLiveActivityLiveActivity.swift"          "LinioLiveActivity/LinioLiveActivityLiveActivity.swift"
```

- [ ] **Schritt 6: xcscheme-Dateien umbenennen**

```bash
mv "Linio.xcodeproj/xcshareddata/xcschemes/RNV-Transport-App.xcscheme" \
   "Linio.xcodeproj/xcshareddata/xcschemes/Linio.xcscheme"
mv "Linio.xcodeproj/xcshareddata/xcschemes/RNVLiveActivityExtension.xcscheme" \
   "Linio.xcodeproj/xcshareddata/xcschemes/LinioLiveActivityExtension.xcscheme"
```

- [ ] **Schritt 7: Ergebnis überprüfen**

```bash
ls /Users/I767513/Xcode/RNV-Transport-App/
# Erwartete Ausgabe enthält: Linio.xcodeproj  Linio/  LinioLiveActivity/  LinioWatch/  LinioLiveActivityExtension.entitlements
ls /Users/I767513/Xcode/RNV-Transport-App/Linio/
# Enthält: Linio.entitlements  LinioRelease.entitlements  Linio.xcdatamodeld/  LinioApp.swift
ls /Users/I767513/Xcode/RNV-Transport-App/Linio/Linio.xcdatamodeld/
# Enthält: Linio.xcdatamodel/  .xccurrentversion
```

---

### Task 2: project.pbxproj aktualisieren

**Files:**
- Modify: `Linio.xcodeproj/project.pbxproj`

Die `project.pbxproj` ist eine Textdatei. Alle Pfad- und Namensreferenzen müssen aktualisiert werden. Die UUID-Kommentare (z. B. `/* RNV-Transport-App */`) sind in Xcode nicht funktional – trotzdem aktualisieren wir sie für Lesbarkeit.

- [ ] **Schritt 1: Ordnerpfade aktualisieren**

Ersetze `path = "RNV-Transport-App"` → `path = Linio`
Ersetze `path = RNVLiveActivity` → `path = LinioLiveActivity`
Ersetze `path = RNVWatch` → `path = LinioWatch`

```bash
cd /Users/I767513/Xcode/RNV-Transport-App
sed -i '' 's|path = "RNV-Transport-App";|path = Linio;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|path = RNVLiveActivity;|path = LinioLiveActivity;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|path = RNVWatch;|path = LinioWatch;|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 2: Entitlements-Pfade aktualisieren**

```bash
sed -i '' 's|CODE_SIGN_ENTITLEMENTS = "RNV-Transport-App/RNV-Transport-App.entitlements";|CODE_SIGN_ENTITLEMENTS = "Linio/Linio.entitlements";|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|CODE_SIGN_ENTITLEMENTS = "RNV-Transport-App/RNV-Transport-AppRelease.entitlements";|CODE_SIGN_ENTITLEMENTS = "Linio/LinioRelease.entitlements";|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|CODE_SIGN_ENTITLEMENTS = RNVLiveActivityExtension.entitlements;|CODE_SIGN_ENTITLEMENTS = LinioLiveActivityExtension.entitlements;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|CODE_SIGN_ENTITLEMENTS = RNVWatch/RNVWatch.entitlements;|CODE_SIGN_ENTITLEMENTS = LinioWatch/LinioWatch.entitlements;|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 3: INFOPLIST_FILE-Pfade aktualisieren**

```bash
sed -i '' 's|INFOPLIST_FILE = "RNV-Transport-App/Info.plist";|INFOPLIST_FILE = "Linio/Info.plist";|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|INFOPLIST_FILE = RNVLiveActivity/Info.plist;|INFOPLIST_FILE = LinioLiveActivity/Info.plist;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|INFOPLIST_FILE = RNVWatch/Info.plist;|INFOPLIST_FILE = LinioWatch/Info.plist;|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 4: Entitlements-Dateireferenzen (path-Zeilen) aktualisieren**

```bash
sed -i '' 's|path = RNVLiveActivityExtension.entitlements;|path = LinioLiveActivityExtension.entitlements;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|path = RNVWatch.entitlements;|path = LinioWatch.entitlements;|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 5: Produktnamen und Target-Namen aktualisieren**

```bash
# Produktreferenz-Pfade (.app / .appex)
sed -i '' 's|path = "RNV-Transport-App.app";|path = "Linio.app";|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|path = RNVLiveActivityExtension.appex;|path = LinioLiveActivityExtension.appex;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|path = RNVWatch.app;|path = LinioWatch.app;|g' "Linio.xcodeproj/project.pbxproj"

# Target name / productName
sed -i '' 's|name = "RNV-Transport-App";|name = Linio;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|productName = "RNV-Transport-App";|productName = Linio;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|name = RNVLiveActivityExtension;|name = LinioLiveActivityExtension;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|productName = RNVLiveActivityExtension;|productName = LinioLiveActivityExtension;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|name = RNVWatch;|name = LinioWatch;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|productName = RNVWatch;|productName = LinioWatch;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|PRODUCT_NAME = RNVWatch;|PRODUCT_NAME = LinioWatch;|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 6: remoteInfo-Felder aktualisieren**

```bash
sed -i '' 's|remoteInfo = RNVLiveActivityExtension;|remoteInfo = LinioLiveActivityExtension;|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|remoteInfo = RNVWatch;|remoteInfo = LinioWatch;|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 7: UUID-Kommentare (lesbarkeitshalber) und Bundle Display Name aktualisieren**

```bash
# Kommentare in pbxproj (nach /* und vor */)
sed -i '' 's|/\* RNV-Transport-App \*/|/* Linio */|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|/\* RNVLiveActivityExtension \*/|/* LinioLiveActivityExtension */|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|/\* RNVWatch \*/|/* LinioWatch */|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|/\* RNV-Transport-App.app \*/|/* Linio.app */|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|/\* RNVLiveActivityExtension.appex \*/|/* LinioLiveActivityExtension.appex */|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|/\* RNVWatch.app \*/|/* LinioWatch.app */|g' "Linio.xcodeproj/project.pbxproj"

# LiveActivity Bundle Display Name
sed -i '' 's|INFOPLIST_KEY_CFBundleDisplayName = RNVLiveActivity;|INFOPLIST_KEY_CFBundleDisplayName = LinioLiveActivity;|g' "Linio.xcodeproj/project.pbxproj"

# "Exceptions for ..."-Beschreibungen
sed -i '' 's|Exceptions for "RNV-Transport-App" folder in "RNV-Transport-App" target|Exceptions for "Linio" folder in "Linio" target|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|Exceptions for "RNVLiveActivity" folder in "RNVLiveActivityExtension" target|Exceptions for "LinioLiveActivity" folder in "LinioLiveActivityExtension" target|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|Exceptions for "RNV-Transport-App" folder in "RNVLiveActivityExtension" target|Exceptions for "Linio" folder in "LinioLiveActivityExtension" target|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|Exceptions for "RNV-Transport-App" folder in "RNVWatch" target|Exceptions for "Linio" folder in "LinioWatch" target|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 8: CoreData-Modell-Referenz im pbxproj aktualisieren**

```bash
sed -i '' 's|RNV_Transport_App.xcdatamodeld|Linio.xcdatamodeld|g' "Linio.xcodeproj/project.pbxproj"
sed -i '' 's|RNV_Transport_App.xcdatamodel|Linio.xcdatamodel|g' "Linio.xcodeproj/project.pbxproj"
```

- [ ] **Schritt 9: Prüfung – keine alten Namen mehr im pbxproj**

```bash
grep -n "RNV-Transport-App\|RNVLiveActivity\|RNVWatch\|RNV_Transport_App\|Mannheim" "Linio.xcodeproj/project.pbxproj"
# Erwartetes Ergebnis: nur noch "Mannheim ÖPNV" in Kommentaren (Projektname), sonst keine Treffer
```

Falls noch Treffer auftauchen, diese manuell korrigieren.

---

### Task 3: xcscheme-Dateien aktualisieren

**Files:**
- Modify: `Linio.xcodeproj/xcshareddata/xcschemes/Linio.xcscheme`
- Modify: `Linio.xcodeproj/xcshareddata/xcschemes/LinioLiveActivityExtension.xcscheme`

- [ ] **Schritt 1: Linio.xcscheme – BuildableName, BlueprintName, ReferencedContainer**

```bash
SCHEME="Linio.xcodeproj/xcshareddata/xcschemes/Linio.xcscheme"
sed -i '' 's|BuildableName = "RNV-Transport-App.app"|BuildableName = "Linio.app"|g' "$SCHEME"
sed -i '' 's|BlueprintName = "RNV-Transport-App"|BlueprintName = "Linio"|g' "$SCHEME"
sed -i '' 's|container:Mannheim O&#x308;PNV.xcodeproj|container:Linio.xcodeproj|g' "$SCHEME"
```

- [ ] **Schritt 2: LinioLiveActivityExtension.xcscheme aktualisieren**

```bash
SCHEME="Linio.xcodeproj/xcshareddata/xcschemes/LinioLiveActivityExtension.xcscheme"
sed -i '' 's|BuildableName = "RNVLiveActivityExtension.appex"|BuildableName = "LinioLiveActivityExtension.appex"|g' "$SCHEME"
sed -i '' 's|BlueprintName = "RNVLiveActivityExtension"|BlueprintName = "LinioLiveActivityExtension"|g' "$SCHEME"
sed -i '' 's|BuildableName = "RNV-Transport-App.app"|BuildableName = "Linio.app"|g' "$SCHEME"
sed -i '' 's|BlueprintName = "RNV-Transport-App"|BlueprintName = "Linio"|g' "$SCHEME"
sed -i '' 's|container:Mannheim O&#x308;PNV.xcodeproj|container:Linio.xcodeproj|g' "$SCHEME"
```

---

### Task 4: CoreData .xccurrentversion aktualisieren

**Files:**
- Modify: `Linio/Linio.xcdatamodeld/.xccurrentversion`

- [ ] **Schritt 1: Interne Versionsreferenz auf neuen Namen ändern**

```bash
sed -i '' 's|RNV_Transport_App.xcdatamodel|Linio.xcdatamodel|g' \
  "Linio/Linio.xcdatamodeld/.xccurrentversion"
```

- [ ] **Schritt 2: Prüfen**

```bash
cat "Linio/Linio.xcdatamodeld/.xccurrentversion"
# Erwartete Ausgabe:
# <?xml version="1.0" encoding="UTF-8"?>
# ...
#   <key>_XCCurrentVersionName</key>
#   <string>Linio.xcdatamodel</string>
```

---

### Task 5: Swift-Quellcode aktualisieren

**Files:**
- Modify: `Linio/LinioApp.swift`
- Modify: `LinioLiveActivity/LinioLiveActivityBundle.swift`
- Modify: `LinioLiveActivity/LinioLiveActivityLiveActivity.swift`
- Modify: `LinioWatch/WatchApp.swift`

- [ ] **Schritt 1: LinioApp.swift – Struct-Namen umbenennen**

In `Linio/LinioApp.swift`:
- Kommentar `//  RNV_Transport_AppApp.swift` → `//  LinioApp.swift`
- `struct RNV_Transport_AppApp: App` → `struct LinioApp: App`

```bash
sed -i '' 's|RNV_Transport_AppApp.swift|LinioApp.swift|g' "Linio/LinioApp.swift"
sed -i '' 's|struct RNV_Transport_AppApp: App|struct LinioApp: App|g' "Linio/LinioApp.swift"
```

- [ ] **Schritt 2: LinioLiveActivityBundle.swift – Struct-Namen umbenennen**

```bash
# Dateikommentar
sed -i '' 's|//  RNVLiveActivityBundle.swift|//  LinioLiveActivityBundle.swift|g' \
  "LinioLiveActivity/LinioLiveActivityBundle.swift"
# Kommentar mit Modulname
sed -i '' 's|//  RNVLiveActivity$|//  LinioLiveActivity|g' \
  "LinioLiveActivity/LinioLiveActivityBundle.swift"
# Struct-Definition und Verwendung
sed -i '' 's|struct RNVLiveActivityBundle: WidgetBundle|struct LinioLiveActivityBundle: WidgetBundle|g' \
  "LinioLiveActivity/LinioLiveActivityBundle.swift"
sed -i '' 's|RNVLiveActivityLiveActivity()|LinioLiveActivityLiveActivity()|g' \
  "LinioLiveActivity/LinioLiveActivityBundle.swift"
```

- [ ] **Schritt 3: LinioLiveActivityLiveActivity.swift – Struct-Namen umbenennen**

```bash
sed -i '' 's|//  RNVLiveActivityLiveActivity.swift|//  LinioLiveActivityLiveActivity.swift|g' \
  "LinioLiveActivity/LinioLiveActivityLiveActivity.swift"
sed -i '' 's|//  RNVLiveActivity$|//  LinioLiveActivity|g' \
  "LinioLiveActivity/LinioLiveActivityLiveActivity.swift"
sed -i '' 's|struct RNVLiveActivityLiveActivity: Widget|struct LinioLiveActivityLiveActivity: Widget|g' \
  "LinioLiveActivity/LinioLiveActivityLiveActivity.swift"
sed -i '' 's|RNVLiveActivityLiveActivity()|LinioLiveActivityLiveActivity()|g' \
  "LinioLiveActivity/LinioLiveActivityLiveActivity.swift"
```

- [ ] **Schritt 4: WatchApp.swift – Struct-Namen und Kommentar umbenennen**

```bash
sed -i '' 's|// RNVWatch – Apple Watch App für Linio|// LinioWatch – Apple Watch App für Linio|g' \
  "LinioWatch/WatchApp.swift"
sed -i '' 's|struct RNVWatchApp: App|struct LinioWatchApp: App|g' \
  "LinioWatch/WatchApp.swift"
```

- [ ] **Schritt 5: Prüfen – keine alten Swift-Namen mehr**

```bash
grep -rn "RNV_Transport_AppApp\|RNVLiveActivityBundle\|RNVLiveActivityLiveActivity\|RNVWatchApp" \
  Linio/ LinioLiveActivity/ LinioWatch/ 2>/dev/null
# Erwartetes Ergebnis: keine Ausgabe
```

---

### Task 6: Abschluss-Prüfung

- [ ] **Schritt 1: Gesamtprüfung auf verbleibende alte Namen**

```bash
cd /Users/I767513/Xcode/RNV-Transport-App
grep -rn "RNV-Transport-App\|RNVLiveActivity\|RNVWatch\|RNV_Transport_App" \
  Linio/ LinioLiveActivity/ LinioWatch/ \
  "Linio.xcodeproj/project.pbxproj" \
  "Linio.xcodeproj/xcshareddata/xcschemes/" \
  2>/dev/null
# Erwartetes Ergebnis: keine Ausgabe
```

- [ ] **Schritt 2: Ordnerstruktur verifizieren**

```bash
ls /Users/I767513/Xcode/RNV-Transport-App/
# Muss enthalten: Linio.xcodeproj/  Linio/  LinioLiveActivity/  LinioWatch/  LinioLiveActivityExtension.entitlements
# Darf NICHT mehr enthalten: Mannheim ÖPNV.xcodeproj  RNV-Transport-App/  RNVLiveActivity/  RNVWatch/
```

- [ ] **Schritt 3: Xcode öffnen und Build starten**

```bash
open /Users/I767513/Xcode/RNV-Transport-App/Linio.xcodeproj
```

Dann in Xcode: **Cmd+B** – Build muss ohne Fehler durchlaufen.

Falls Xcode Fehler meldet:
- „file not found"-Fehler → in pbxproj nach dem falsch gebliebenen Pfad suchen
- „no such module"-Fehler → Swift-Datei-Referenzen prüfen
- „could not load configuration file" → xcconfig-Pfade prüfen (Debug.xcconfig, Release.xcconfig, Secrets.xcconfig)

> **Hinweis zum Root-Ordner:** Der übergeordnete Ordner `/Users/I767513/Xcode/RNV-Transport-App` (der Git-Arbeitsordner selbst) kann nicht von Claude umbenannt werden, da er das aktuelle Arbeitsverzeichnis ist. Diesen Ordner bitte manuell im Finder umbenennen – **nachdem** alle obigen Schritte abgeschlossen sind und Xcode geschlossen ist. Dabei auch den Git-Remote ggf. anpassen.
