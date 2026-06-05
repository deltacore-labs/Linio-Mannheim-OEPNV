//
//  RNVLiveActivityBundle.swift
//  RNVLiveActivity
//
//

import WidgetKit
import SwiftUI

@main
struct RNVLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        RNVLiveActivityLiveActivity()
        NextDepartureWidget()
        ActiveTripsWidget()
        QuickSearchWidget()
        StationDepartureWidget()
    }
}
