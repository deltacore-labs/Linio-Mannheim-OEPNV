//
//  LinioLiveActivityBundle.swift
//  LinioLiveActivity
//
//

import WidgetKit
import SwiftUI

@main
struct LinioLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        LinioLiveActivityLiveActivity()
        NextDepartureWidget()
        ActiveTripsWidget()
        QuickSearchWidget()
        StationDepartureWidget()
    }
}
