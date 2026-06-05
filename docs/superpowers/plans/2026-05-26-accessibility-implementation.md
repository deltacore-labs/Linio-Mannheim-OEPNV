# Accessibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add VoiceOver labels, reduce-motion respect, and Dynamic Type support to the seven files that currently have zero accessibility annotations, and fix the two AppTheme font helpers to scale with Dynamic Type.

**Architecture:** Pure SwiftUI accessibility modifiers added at the view layer. No new files, no new types. Each task touches exactly one file, keeps changes minimal, and can be committed independently.

**Tech Stack:** SwiftUI accessibility APIs (`.accessibilityLabel`, `.accessibilityHint`, `.accessibilityElement`, `.accessibilityHidden`, `.accessibilityAddTraits`), `UIFontMetrics` for Dynamic Type scaling.

---

## Task 1: SteigSheet.swift — close button + departure rows

**Files:**
- Modify: `Linio/Content/SteigSheet.swift`

### What to change

Three spots:

**1a — Close button** (line 87–93): add `.accessibilityLabel("Schließen")` to the `Button`.

**1b — Departure row** (line 130–164, inside `departureList`): The `HStack` for each departure needs to be combined into one accessible element with a descriptive label.

**1c — "NÄCHSTE ABFAHRTEN" header** (line 122–126): The decorative `Text` is fine as-is since it's just a section header. No change needed.

- [ ] **Step 1: Add `.accessibilityLabel` to the close button**

In `header`, change:
```swift
Button {
    dismiss()
} label: {
    Image(systemName: "xmark.circle.fill")
        .font(.title2)
        .foregroundStyle(AppTheme.muted)
}
```
to:
```swift
Button {
    dismiss()
} label: {
    Image(systemName: "xmark.circle.fill")
        .font(.title2)
        .foregroundStyle(AppTheme.muted)
}
.accessibilityLabel("Schließen")
```

- [ ] **Step 2: Combine each departure row for VoiceOver**

In `departureList`, wrap the inner `HStack` block. The existing code (line 130–164):
```swift
ForEach(Array(departuresAtQuay.enumerated()), id: \.element.id) { index, dep in
    HStack(spacing: 14) {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(dep.lineColor)
                .frame(width: 32, height: 32)
            Text(dep.lineName)
                .font(.caption.weight(.black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        Text(dep.direction)
            .font(.subheadline.weight(.medium))
            .foregroundColor(AppTheme.ink)
            .lineLimit(1)
        Spacer()
        if let mins = dep.minutesUntilDeparture {
            Text(mins == 0 ? "jetzt" : "\(mins) min")
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundColor(mins <= 1 ? AppTheme.semanticSuccess : AppTheme.ink)
        } else {
            Text(formatter.formatTime(dep.scheduledDeparture))
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundColor(AppTheme.ink)
        }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
```
Add after `.padding(.vertical, 12)`:
```swift
    .accessibilityElement(children: .combine)
    .accessibilityLabel({
        let timeText: String
        if let mins = dep.minutesUntilDeparture {
            timeText = mins == 0 ? "jetzt" : "in \(mins) Minuten"
        } else {
            timeText = formatter.formatTime(dep.scheduledDeparture)
        }
        return "\(dep.lineName) Richtung \(dep.direction), \(timeText)"
    }())
```

- [ ] **Step 3: Commit**

```bash
git add Linio/Content/SteigSheet.swift
git commit -m "feat(a11y): SteigSheet — close button label + departure row VoiceOver"
```

---

## Task 2: PlannedTripCard.swift — card grouping + button labels + reduce motion

**Files:**
- Modify: `Linio/PlannedTripCard.swift`

### What to change

**2a** Add `@Environment(\.accessibilityReduceMotion)` and respect it in `onAppear`.  
**2b** The tappable header `HStack` needs `.accessibilityElement(children: .combine)` + `.accessibilityAddTraits(.isButton)` + `.accessibilityLabel` + `.accessibilityHint`.  
**2c** Details button → `.accessibilityLabel("Details anzeigen")`.  
**2d** End button → `.accessibilityLabel("Fahrt beenden")`.

- [ ] **Step 1: Add reduce-motion environment property**

After the existing `@EnvironmentObject var liveActivityManager: LiveActivityManager` line, add:
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

- [ ] **Step 2: Respect reduce motion in `onAppear`**

Change:
```swift
.onAppear {
    loadTripData()
    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
        isPulsing = true
    }
}
```
to:
```swift
.onAppear {
    loadTripData()
    if !reduceMotion {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
            isPulsing = true
        }
    }
}
```

- [ ] **Step 3: Add computed `headerAccessibilityLabel` property**

Add this computed property inside `PlannedTripCard` (before `body`):
```swift
private var headerAccessibilityLabel: String {
    if let trip = tripData {
        let start = formatter.formatTime(trip.startTime)
        let end = formatter.formatTime(trip.endTime)
        return "Aktive Fahrt, \(start) bis \(end)"
    }
    return "Live Activity"
}
```

- [ ] **Step 4: Make the tappable header accessible**

Change the `HStack { ... }.contentShape(Rectangle()).onTapGesture { showDetail = true }` block to:
```swift
HStack {
    VStack(alignment: .leading, spacing: 4) {
        Text("Live Activity")
            .font(.headline)
            .fontWeight(.semibold)

        if let trip = tripData {
            tripConnectionInfo(trip)
        } else {
            Text("Trip ID: \(String(tripId.prefix(8)))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    Spacer()

    statusBadge
}
.contentShape(Rectangle())
.onTapGesture { showDetail = true }
.accessibilityElement(children: .combine)
.accessibilityAddTraits(.isButton)
.accessibilityLabel(headerAccessibilityLabel)
.accessibilityHint("Details anzeigen")
```

- [ ] **Step 5: Label the Details and End buttons**

Change:
```swift
Button {
    showDetail = true
} label: {
    HStack(spacing: 4) {
        Image(systemName: "chevron.right")
            .font(.caption)
        Text("Details")
            .font(.subheadline)
    }
    .foregroundStyle(AppTheme.primaryColor)
}
```
to:
```swift
Button {
    showDetail = true
} label: {
    HStack(spacing: 4) {
        Image(systemName: "chevron.right")
            .font(.caption)
        Text("Details")
            .font(.subheadline)
    }
    .foregroundStyle(AppTheme.primaryColor)
}
.accessibilityLabel("Details anzeigen")
```

Change:
```swift
Button(action: {
    Task { await handleRemove() }
}) {
    HStack(spacing: 4) {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
        Text("Beenden")
            .font(.subheadline)
    }
    .foregroundColor(.red)
}
```
to:
```swift
Button(action: {
    Task { await handleRemove() }
}) {
    HStack(spacing: 4) {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
        Text("Beenden")
            .font(.subheadline)
    }
    .foregroundColor(.red)
}
.accessibilityLabel("Fahrt beenden")
```

- [ ] **Step 6: Commit**

```bash
git add Linio/PlannedTripCard.swift
git commit -m "feat(a11y): PlannedTripCard — button labels, reduce motion, card grouping"
```

---

## Task 3: PlannedTripsView.swift — toolbar + empty states + archived rows

**Files:**
- Modify: `Linio/Content/PlannedTripsView.swift`

### What to change

**3a** Toolbar refresh `Button` with `Image(systemName: "arrow.clockwise")` → `.accessibilityLabel("Aktualisieren")`.  
**3b** Empty state `Image(systemName: "bell.slash")` → `.accessibilityHidden(true)`.  
**3c** Archive empty state `Image(systemName: "archivebox")` → `.accessibilityHidden(true)`.  
**3d** `ArchivedTripRow` → `.accessibilityElement(children: .combine)` + `.accessibilityLabel` computed property.

- [ ] **Step 1: Label the refresh toolbar button**

Change:
```swift
Button(action: refreshActiveTrips) {
    Image(systemName: "arrow.clockwise")
        .foregroundStyle(AppTheme.primaryColor)
}
```
to:
```swift
Button(action: refreshActiveTrips) {
    Image(systemName: "arrow.clockwise")
        .foregroundStyle(AppTheme.primaryColor)
}
.accessibilityLabel("Aktualisieren")
```

- [ ] **Step 2: Hide decorative icon in active empty state**

Change:
```swift
Image(systemName: "bell.slash")
    .font(.system(size: 36, weight: .light))
    .foregroundStyle(AppTheme.muted)
```
to:
```swift
Image(systemName: "bell.slash")
    .font(.system(size: 36, weight: .light))
    .foregroundStyle(AppTheme.muted)
    .accessibilityHidden(true)
```

- [ ] **Step 3: Hide decorative icon in archive empty state**

Change:
```swift
Image(systemName: "archivebox")
    .font(.system(size: 36, weight: .light))
    .foregroundStyle(AppTheme.muted)
```
to:
```swift
Image(systemName: "archivebox")
    .font(.system(size: 36, weight: .light))
    .foregroundStyle(AppTheme.muted)
    .accessibilityHidden(true)
```

- [ ] **Step 4: Add accessibility to `ArchivedTripRow`**

Add a computed `accessibilityDescription` property to `ArchivedTripRow` (before `body`):
```swift
private var accessibilityDescription: String {
    let startTime = formatter.formatTime(trip.startTime)
    let endTime = formatter.formatTime(trip.endTime)
    let duration = formatter.calculateDuration(start: trip.startTime, end: trip.endTime)
    return "Abgeschlossene Fahrt: \(trip.startStation) nach \(trip.endStation), \(startTime) bis \(endTime), Dauer \(duration)"
}
```

At the end of `ArchivedTripRow.body`, after the last `.overlay(...)` on the background, add:
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel(accessibilityDescription)
```

So the end of `body` becomes:
```swift
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.surfaceCard)
                .shadow(color: AppTheme.shadowColor(isPast: true), radius: 4, y: 2)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.hairline, lineWidth: 1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
```

- [ ] **Step 5: Commit**

```bash
git add Linio/Content/PlannedTripsView.swift
git commit -m "feat(a11y): PlannedTripsView — toolbar label, empty state icons hidden, archived row labels"
```

---

## Task 4: PlannedTripDetailSheet.swift — buttons + banner + cards + timeline

**Files:**
- Modify: `Linio/Content/PlannedTripDetailSheet.swift`

### What to change

**4a** Close button in toolbar → `.accessibilityLabel("Schließen")`.  
**4b** `phaseStatusBanner` → `.accessibilityElement(children: .combine)` + `.accessibilityLabel(phaseBannerLabel)` + add `phaseBannerLabel` computed var.  
**4c** `overviewCard` → `.accessibilityElement(children: .combine)` + `.accessibilityLabel(overviewLabel)` + add `overviewLabel` computed var.  
**4d** Route timeline — each leg wrapped with `.accessibilityElement(children: .combine)` + leg label helpers.

- [ ] **Step 1: Label the close button**

Change:
```swift
ToolbarItem(placement: .navigationBarLeading) {
    Button {
        dismiss()
    } label: {
        Image(systemName: "xmark.circle.fill")
            .foregroundStyle(AppTheme.mutedSoft)
            .font(.title3)
    }
}
```
to:
```swift
ToolbarItem(placement: .navigationBarLeading) {
    Button {
        dismiss()
    } label: {
        Image(systemName: "xmark.circle.fill")
            .foregroundStyle(AppTheme.mutedSoft)
            .font(.title3)
    }
    .accessibilityLabel("Schließen")
}
```

- [ ] **Step 2: Add `phaseBannerLabel` computed property**

Add this property inside `PlannedTripDetailSheet` (before `body`):
```swift
private var phaseBannerLabel: String {
    switch tripPhase {
    case .beforeDeparture:
        if let depDate = formatter.parseISO8601(tripData.startTime) {
            let mins = max(0, Int(depDate.timeIntervalSinceNow / 60))
            return mins == 0 ? "Vor Abfahrt: Fährt jetzt ab" : "Vor Abfahrt: in \(mins) Minuten, \(formatter.formatTime(tripData.startTime))"
        }
        return "Vor Abfahrt"
    case .duringJourney:
        return "Unterwegs, Ankunft \(formatter.formatTime(tripData.endTime))"
    case .arrived:
        return "Angekommen bei \(tripData.endStation)"
    }
}
```

- [ ] **Step 3: Combine the phase status banner**

At the end of `phaseStatusBanner` (after the `.background(...)` modifier), add:
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel(phaseBannerLabel)
```

So the `phaseStatusBanner` var ends:
```swift
        )
    .accessibilityElement(children: .combine)
    .accessibilityLabel(phaseBannerLabel)
}
```

- [ ] **Step 4: Add `overviewLabel` computed property**

Add this property inside `PlannedTripDetailSheet`:
```swift
private var overviewLabel: String {
    let start = formatter.formatTime(tripData.startTime)
    let end = formatter.formatTime(tripData.endTime)
    let duration = formatter.calculateDuration(start: tripData.startTime, end: tripData.endTime)
    let interchangeText = tripData.interchanges == 0
        ? "Direktfahrt"
        : "\(tripData.interchanges) Umstieg\(tripData.interchanges == 1 ? "" : "e")"
    return "\(tripData.startStation) nach \(tripData.endStation), \(start) bis \(end), \(duration), \(interchangeText)"
}
```

- [ ] **Step 5: Combine the overview card**

At the end of `overviewCard` (after the last `.background(...)` modifier), add:
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel(overviewLabel)
```

- [ ] **Step 6: Add leg label helper functions**

Add these two private functions inside `PlannedTripDetailSheet`:
```swift
private func timedLegAccessibilityLabel(leg: TripLegData) -> String {
    let board = leg.boardStopName ?? ""
    let alight = leg.alightStopName ?? ""
    let dep = leg.departureTime.map { formatter.formatTime($0) } ?? ""
    let arr = leg.arrivalTime.map { formatter.formatTime($0) } ?? ""
    let line = leg.serviceName.map { TransportIconHelper.getShortLineName(from: $0) } ?? ""
    let dest = leg.destinationLabel ?? ""
    return "\(line) Richtung \(dest), ab \(board) \(dep), an \(alight) \(arr)"
}

private func walkLegAccessibilityLabel(leg: TripLegData) -> String {
    let duration = formatter.calculateDuration(
        start: leg.departureTime ?? "",
        end: leg.arrivalTime ?? ""
    )
    return "Fußweg, Dauer \(duration)"
}
```

- [ ] **Step 7: Combine each leg row in the route timeline ForEach**

Inside `routeTimelineCard`, change the `ForEach` block:
```swift
ForEach(Array(tripData.legs.enumerated()), id: \.offset) { idx, leg in
    if leg.legType == "continuousLeg" {
        walkLegRow(leg: leg)
    } else {
        let timedLegs = tripData.legs.filter { $0.legType != "continuousLeg" }
        let timedIdx = timedLegs.firstIndex(where: { $0.boardStopName == leg.boardStopName && $0.departureTime == leg.departureTime })
        let isLastTimed = timedIdx == (timedLegs.count - 1)
        timedLegRows(leg: leg, isLast: isLastTimed)
    }
}
```
to:
```swift
ForEach(Array(tripData.legs.enumerated()), id: \.offset) { idx, leg in
    if leg.legType == "continuousLeg" {
        walkLegRow(leg: leg)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(walkLegAccessibilityLabel(leg: leg))
    } else {
        let timedLegs = tripData.legs.filter { $0.legType != "continuousLeg" }
        let timedIdx = timedLegs.firstIndex(where: { $0.boardStopName == leg.boardStopName && $0.departureTime == leg.departureTime })
        let isLastTimed = timedIdx == (timedLegs.count - 1)
        timedLegRows(leg: leg, isLast: isLastTimed)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(timedLegAccessibilityLabel(leg: leg))
    }
}
```

- [ ] **Step 8: Commit**

```bash
git add Linio/Content/PlannedTripDetailSheet.swift
git commit -m "feat(a11y): PlannedTripDetailSheet — close button, banner/card/leg labels"
```

---

## Task 5: TransitMapSheet.swift — close button + stop buttons + panel

**Files:**
- Modify: `Linio/Content/TransitMapSheet.swift`

### What to change

**5a** `FullMapView` close button → `.accessibilityLabel("Schließen")`.  
**5b** Intermediate stop map buttons (in `TransitMapViewRepresentable`) → `.accessibilityLabel` + `.accessibilityHint`.  
**5c** `RouteStopsPanel` drag handle → `.accessibilityLabel` + `.accessibilityAddTraits(.isButton)`.  
**5d** `RouteStopsPanel` stop rows in `expandedContent` → `.accessibilityElement(children: .combine)` + label.

- [ ] **Step 1: Label the close button in `FullMapView`**

Change:
```swift
Button(action: { dismiss() }) {
    Image(systemName: "xmark.circle.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(.white, Color.black.opacity(0.28))
        .font(.system(size: 30))
}
```
to:
```swift
Button(action: { dismiss() }) {
    Image(systemName: "xmark.circle.fill")
        .symbolRenderingMode(.palette)
        .foregroundStyle(.white, Color.black.opacity(0.28))
        .font(.system(size: 30))
}
.accessibilityLabel("Schließen")
```

- [ ] **Step 2: Label intermediate stop buttons in `TransitMapViewRepresentable`**

In `mapAnnotations`, the intermediate stop `Button`:
```swift
Button {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
        onStopSelected?(isSelected ? "" : (item.name ?? ""))
    }
} label: {
    if isSelected {
        intermediateStopPin(name: item.name ?? "")
    } else {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .overlay(Circle().strokeBorder(routeColor, lineWidth: 2))
            .padding(10)
            .contentShape(Rectangle())
    }
}
.buttonStyle(.plain)
```
Add after `.buttonStyle(.plain)`:
```swift
.accessibilityLabel(item.name ?? "Zwischenhalt")
.accessibilityHint(isSelected ? "Tippen zum Aufheben" : "Tippen zum Hervorheben")
```

- [ ] **Step 3: Add `dragHandleLabel` computed property to `RouteStopsPanel`**

Add this computed property inside `RouteStopsPanel`:
```swift
private var dragHandleLabel: String {
    switch position {
    case .peek:      return "Streckenpanel einblenden"
    case .collapsed: return "Streckenpanel ausklappen"
    case .expanded:  return "Streckenpanel einklappen"
    }
}
```

- [ ] **Step 4: Make drag handle accessible in `RouteStopsPanel`**

In `dragHandle`, after `.onTapGesture { ... }`, add:
```swift
.accessibilityLabel(dragHandleLabel)
.accessibilityAddTraits(.isButton)
```

So `dragHandle` ends:
```swift
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                switch position {
                case .peek:
                    position = .collapsed
                    panelHeight = collapsedHeight
                case .collapsed:
                    position = .expanded
                    panelHeight = expandedHeight
                case .expanded:
                    position = .collapsed
                    panelHeight = collapsedHeight
                }
            }
        }
        .accessibilityLabel(dragHandleLabel)
        .accessibilityAddTraits(.isButton)
}
```

- [ ] **Step 5: Add `stopRowAccessibilityLabel` helper to `RouteStopsPanel`**

Add this function inside `RouteStopsPanel`:
```swift
private func stopRowAccessibilityLabel(_ stop: RouteStopEntry) -> String {
    let kindText: String
    switch stop.kind {
    case .origin:       kindText = "Startstation"
    case .destination:  kindText = "Zielstation"
    case .transfer:     kindText = "Umstieg"
    case .intermediate: kindText = "Zwischenstation"
    }
    if let time = stop.time {
        return "\(kindText): \(stop.name), \(formatter.formatTime(time))"
    }
    return "\(kindText): \(stop.name)"
}
```

- [ ] **Step 6: Combine stop rows in `expandedContent`**

In `expandedContent`, change:
```swift
ForEach(Array(stops.enumerated()), id: \.offset) { i, stop in
    stopRow(stop, isFirst: i == 0, isLast: i == stops.count - 1)
        .padding(.horizontal, 4)
        .id(stop.name)
}
```
to:
```swift
ForEach(Array(stops.enumerated()), id: \.offset) { i, stop in
    stopRow(stop, isFirst: i == 0, isLast: i == stops.count - 1)
        .padding(.horizontal, 4)
        .id(stop.name)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stopRowAccessibilityLabel(stop))
}
```

- [ ] **Step 7: Commit**

```bash
git add Linio/Content/TransitMapSheet.swift
git commit -m "feat(a11y): TransitMapSheet — close button, stop buttons, panel drag handle labels"
```

---

## Task 6: StationPickerView.swift — search bar, station rows, map sheet

**Files:**
- Modify: `Linio/Content/StationPickerView.swift`

### What to change

**6a** Search bar magnifying glass → `.accessibilityHidden(true)`.  
**6b** Clear button → `.accessibilityLabel("Suche löschen")`.  
**6c** Inline loading `ProgressView` in search bar → `.accessibilityHidden(true)`.  
**6d** "In der Nähe" button → `.accessibilityLabel("In der Nähe: Haltestellen auf der Karte auswählen")`.  
**6e** Decorative `Image(systemName: "calendar.badge.clock")` in date section → `.accessibilityHidden(true)`.  
**6f** Decorative `Image(systemName: "clock.arrow.circlepath")` in recents header → `.accessibilityHidden(true)`.  
**6g** Station row buttons → `.accessibilityLabel(station.longName)` + `.accessibilityHint("Tippen zum Auswählen")`.  
**6h** `stationRowContent` decorative images → `.accessibilityHidden(true)`.  
**6i** `loadingView` → `.accessibilityElement(children: .combine)` + `.accessibilityLabel("Haltestellen werden gesucht")`.  
**6j** `NearbyStationMapSheet` station pin buttons → `.accessibilityLabel` + `.accessibilityHint`.  
**6k** `NearbyStationMapSheet` loading overlay → `.accessibilityElement(children: .combine)` + `.accessibilityLabel`.

- [ ] **Step 1: Hide decorative magnifying glass in search bar**

In `searchBar`, change:
```swift
Image(systemName: "magnifyingglass")
    .foregroundColor(.secondary)
    .font(.system(size: 15, weight: .medium))
```
to:
```swift
Image(systemName: "magnifyingglass")
    .foregroundColor(.secondary)
    .font(.system(size: 15, weight: .medium))
    .accessibilityHidden(true)
```

- [ ] **Step 2: Label the clear button**

In `searchBar`, the `Button { ... } label: { Image(systemName: "xmark.circle.fill") ... }` block:
```swift
Button {
    withAnimation(.easeInOut(duration: 0.2)) {
        searchText = ""
        graphQLService.stations = []
        hasLoadedStations = false
    }
} label: {
    Image(systemName: "xmark.circle.fill")
        .foregroundColor(.secondary.opacity(0.6))
        .font(.system(size: 16))
}
.transition(.opacity.combined(with: .scale))
```
Add `.accessibilityLabel("Suche löschen")` after `.transition(...)`:
```swift
.transition(.opacity.combined(with: .scale))
.accessibilityLabel("Suche löschen")
```

- [ ] **Step 3: Hide the inline loading indicator from accessibility**

In `searchBar`, change:
```swift
if graphQLService.isLoading && !searchText.isEmpty {
    ProgressView()
        .scaleEffect(0.7)
        .transition(.opacity)
}
```
to:
```swift
if graphQLService.isLoading && !searchText.isEmpty {
    ProgressView()
        .scaleEffect(0.7)
        .transition(.opacity)
        .accessibilityHidden(true)
}
```

- [ ] **Step 4: Label the "In der Nähe" location button**

In `quickActionsView`, the `Button { loadNearbyStations(); showNearbyMap = true }` block — add after `.buttonStyle(.plain)`:
```swift
.accessibilityLabel("In der Nähe: Haltestellen auf der Karte auswählen")
```

- [ ] **Step 5: Hide decorative icons in the date section and recents header**

In `dateTimeSection`, change:
```swift
Image(systemName: "calendar.badge.clock")
    .font(.system(size: 12, weight: .semibold))
    .foregroundColor(.secondary)
```
to:
```swift
Image(systemName: "calendar.badge.clock")
    .font(.system(size: 12, weight: .semibold))
    .foregroundColor(.secondary)
    .accessibilityHidden(true)
```

In `quickActionsView` (the "Zuletzt verwendet" header), change:
```swift
Image(systemName: "clock.arrow.circlepath")
    .font(.system(size: 12, weight: .semibold))
    .foregroundColor(.secondary)
```
to:
```swift
Image(systemName: "clock.arrow.circlepath")
    .font(.system(size: 12, weight: .semibold))
    .foregroundColor(.secondary)
    .accessibilityHidden(true)
```

- [ ] **Step 6: Label station row buttons**

In `stationList`, each station `Button`:
```swift
Button {
    selectAndDismiss(station)
} label: {
    stationRowContent(station: station)
}
.buttonStyle(StationRowButtonStyle())
```
Add after `.buttonStyle(StationRowButtonStyle())`:
```swift
.accessibilityLabel(station.longName)
.accessibilityHint("Tippen zum Auswählen")
```

Do the same for the recent stations `ForEach` in `quickActionsView`:
```swift
Button {
    selectAndDismiss(station)
} label: {
    stationRowContent(station: station)
}
.buttonStyle(.plain)
```
Add after `.buttonStyle(.plain)`:
```swift
.accessibilityLabel(station.longName)
.accessibilityHint("Tippen zum Auswählen")
```

- [ ] **Step 7: Hide decorative images inside `stationRowContent`**

In `stationRowContent`, change:
```swift
Image(systemName: "tram.fill")
    .font(.system(size: 14, weight: .medium))
    .foregroundStyle(AppTheme.primary)
```
to:
```swift
Image(systemName: "tram.fill")
    .font(.system(size: 14, weight: .medium))
    .foregroundStyle(AppTheme.primary)
    .accessibilityHidden(true)
```

And:
```swift
Image(systemName: "chevron.right")
    .font(.system(size: 11, weight: .medium))
    .foregroundColor(.secondary.opacity(0.25))
```
to:
```swift
Image(systemName: "chevron.right")
    .font(.system(size: 11, weight: .medium))
    .foregroundColor(.secondary.opacity(0.25))
    .accessibilityHidden(true)
```

- [ ] **Step 8: Combine the loading view**

In `loadingView`, after the outer `VStack`'s closing brace, add before the method closes:
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("Haltestellen werden gesucht")
```

- [ ] **Step 9: Label station pin buttons in `NearbyStationMapSheet`**

In `NearbyStationMapSheet.body`, the annotation button:
```swift
Button {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
        selected = isSelected ? nil : station
    }
} label: {
    stationPin(isSelected: isSelected, name: station.longName)
}
.buttonStyle(.plain)
```
Add after `.buttonStyle(.plain)`:
```swift
.accessibilityLabel(station.longName)
.accessibilityHint(isSelected ? "Tippen zum Schließen" : "Tippen zum Auswählen")
```

- [ ] **Step 10: Combine the loading overlay in `NearbyStationMapSheet`**

Change:
```swift
if graphQLService.isLoading || (geocoded.isEmpty && !graphQLService.stations.isEmpty) {
    VStack(spacing: 8) {
        ProgressView().tint(.white)
        Text("Haltestellen laden…")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
    }
    .padding(16)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
    .padding(.bottom, 160)
}
```
to:
```swift
if graphQLService.isLoading || (geocoded.isEmpty && !graphQLService.stations.isEmpty) {
    VStack(spacing: 8) {
        ProgressView().tint(.white)
        Text("Haltestellen laden…")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
    }
    .padding(16)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
    .padding(.bottom, 160)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Haltestellen werden geladen")
}
```

- [ ] **Step 11: Commit**

```bash
git add Linio/Content/StationPickerView.swift
git commit -m "feat(a11y): StationPickerView — station rows, search controls, map sheet labels"
```

---

## Task 7: TicketView.swift — barcode, menu, card, scanning overlay

**Files:**
- Modify: `Linio/Content/TicketView.swift`

### What to change

**7a** Scanning overlay → `.accessibilityElement(children: .combine)` + `.accessibilityLabel("Ticket wird erkannt")`.  
**7b** `ticketIllustration` (decorative placeholder) → `.accessibilityHidden(true)`.  
**7c** Menu button → `.accessibilityLabel("Ticketmenü")` on the `Menu`.  
**7d** `TicketCardView.body` → `.accessibilityElement(children: .combine)` + `.accessibilityLabel(cardAccessibilityLabel)`.  
**7e** `perforatedLine` → `.accessibilityHidden(true)`.  
**7f** Add `cardAccessibilityLabel` computed property to `TicketCardView`.

- [ ] **Step 1: Combine the scanning overlay**

Change `scanningOverlay`:
```swift
private var scanningOverlay: some View {
    VStack(spacing: 20) {
        Spacer()
        ProgressView().scaleEffect(1.4)
        Text("Ticket wird erkannt…")
            .font(.subheadline)
            .foregroundStyle(AppTheme.muted)
        Spacer()
    }
}
```
to:
```swift
private var scanningOverlay: some View {
    VStack(spacing: 20) {
        Spacer()
        ProgressView().scaleEffect(1.4)
        Text("Ticket wird erkannt…")
            .font(.subheadline)
            .foregroundStyle(AppTheme.muted)
        Spacer()
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Ticket wird erkannt")
}
```

- [ ] **Step 2: Hide the decorative ticket illustration**

Change `ticketIllustration`:
```swift
private var ticketIllustration: some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20)
            ...
    }
}
```
Add `.accessibilityHidden(true)` at the end of the returned `ZStack`, right before the closing brace of the computed property. The property returns the `ZStack`, so add it like:
```swift
private var ticketIllustration: some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.secondarySystemBackground))
            .frame(width: 240, height: 148)
            .shadow(color: AppTheme.shadowColor(), radius: 14, y: 7)
        VStack(spacing: 8) {
            DTicketLogoView(width: 66)
            Text("D-TICKET")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color(hex: "#1a1a1a"))
        }
    }
    .accessibilityHidden(true)
}
```

- [ ] **Step 3: Label the menu button**

Change:
```swift
} label: { Image(systemName: "ellipsis.circle") }
```
to:
```swift
} label: { Image(systemName: "ellipsis.circle") }
.accessibilityLabel("Ticketmenü")
```

- [ ] **Step 4: Add `cardAccessibilityLabel` to `TicketCardView`**

Add this computed property inside `TicketCardView` (before `body`):
```swift
private var cardAccessibilityLabel: String {
    var parts: [String] = ["Deutschlandticket"]
    if ticket.ticketLabel != "Deutschlandticket" {
        parts.append(ticket.ticketLabel)
    }
    if !ticket.holderName.isEmpty {
        parts.append("Inhaber: \(ticket.holderName)")
    }
    parts.append("Gültig von \(Self.df.string(from: ticket.validFrom)) bis \(Self.df.string(from: ticket.validUntil))")
    if !ticket.customerNumber.isEmpty {
        parts.append("Kundennummer: \(ticket.customerNumber)")
    }
    return parts.joined(separator: ". ")
}
```

- [ ] **Step 5: Combine `TicketCardView.body` as one accessible element**

At the end of `TicketCardView.body`, after `.shadow(...)`, add:
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel(cardAccessibilityLabel)
```

So `body` ends:
```swift
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.hairline, lineWidth: 1))
    .shadow(color: AppTheme.shadowColor(), radius: 12, y: 6)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(cardAccessibilityLabel)
}
```

- [ ] **Step 6: Hide decorative perforated lines**

Change `perforatedLine` (there are two uses but one definition). At the end of the `perforatedLine` computed var, add `.accessibilityHidden(true)`:
```swift
private var perforatedLine: some View {
    ZStack {
        AppTheme.surfaceCard
        // ... existing path code ...
    }
    .frame(height: 20)
    .accessibilityHidden(true)
}
```

- [ ] **Step 7: Commit**

```bash
git add Linio/Content/TicketView.swift
git commit -m "feat(a11y): TicketView — ticket card label, barcode, menu, scanning overlay"
```

---

## Task 8: ContentView.swift — Dynamic Type for AppTheme custom fonts

**Files:**
- Modify: `Linio/Content/ContentView.swift` (lines 199–201)

### What to change

`AppTheme.displayFont` and `AppTheme.monoFont` use `.system(size:)` with a hard-coded point size. Wrapping with `UIFontMetrics.scaledValue(for:)` makes them respect the Dynamic Type category at call time. Since SwiftUI re-evaluates `body` when the environment changes (e.g., user changes text size in Settings), the font size is recalculated automatically.

`UIFontMetrics` is in UIKit. Add `import UIKit` to ContentView.swift.

- [ ] **Step 1: Add `import UIKit` to ContentView.swift**

After `import SwiftUI`, add:
```swift
import UIKit
```

So the imports become:
```swift
import SwiftUI
import UIKit
import WidgetKit
import CoreLocation
```

- [ ] **Step 2: Update `displayFont`**

Change:
```swift
static func displayFont(size: CGFloat) -> Font { .system(size: size, weight: .light, design: .serif) }
```
to:
```swift
static func displayFont(size: CGFloat) -> Font {
    .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: .light, design: .serif)
}
```

- [ ] **Step 3: Update `monoFont`**

Change:
```swift
static func monoFont(size: CGFloat, weight: Font.Weight = .bold) -> Font { .system(size: size, weight: weight, design: .monospaced) }
```
to:
```swift
static func monoFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
    .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: weight, design: .monospaced)
}
```

- [ ] **Step 4: Commit**

```bash
git add Linio/Content/ContentView.swift
git commit -m "feat(a11y): AppTheme display/mono fonts scale with Dynamic Type via UIFontMetrics"
```

---

## Self-Review Against Audit

| Audit item | Covered by |
|---|---|
| StationPickerView — zero accessibility | Task 6 |
| TicketView — zero accessibility | Task 7 |
| PlannedTripCard — zero accessibility | Task 2 |
| PlannedTripsView — zero accessibility | Task 3 |
| PlannedTripDetailSheet — zero accessibility | Task 4 |
| SteigSheet — zero accessibility | Task 1 |
| TransitMapSheet — zero accessibility | Task 5 |
| AppTheme fonts don't scale with Dynamic Type | Task 8 |
| 232 hard-coded `.font(.system(size:))` calls | **Not in this plan** — separate sweep; each caller needs `@ScaledMetric` or `relativeTo:` |
| `differentiateWithoutColor` for delay indicators | **Not in this plan** — requires per-component redesign of delay badges; out of scope |
