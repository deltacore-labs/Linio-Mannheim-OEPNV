// WorkoutView.swift
// View für das Fußweg-Workout zur Haltestelle

import SwiftUI
import HealthKit

struct WorkoutView: View {
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @State private var selectedStation = WatchStation.all.first!
    @State private var showStationPicker = false
    
    var body: some View {
        NavigationStack {
            if workoutManager.isWorkoutActive {
                ActiveWorkoutView(workoutManager: workoutManager)
            } else {
                StartWorkoutView(workoutManager: workoutManager, selectedStation: $selectedStation, showStationPicker: $showStationPicker)
            }
        }
    }
}

private struct StartWorkoutView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    @Binding var selectedStation: WatchStation
    @Binding var showStationPicker: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "figure.walk").font(.system(size: 40)).foregroundColor(.green)
                Text("Fußweg zur Haltestelle".localized).font(.headline).multilineTextAlignment(.center)
                
                Button { showStationPicker = true } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.orange)
                        Text(selectedStation.name).font(.caption).lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(10).background(Color.gray.opacity(0.2)).cornerRadius(10)
                }.buttonStyle(.plain)
                
                Button {
                    Task { await workoutManager.startWalkToStation(selectedStation.name) }
                } label: {
                    HStack { Image(systemName: "play.fill"); Text("Starten".localized) }
                        .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity)
                        .padding().background(Color.green).cornerRadius(12)
                }.buttonStyle(.plain)
                
                if let error = workoutManager.errorMessage {
                    Text(error).font(.caption2).foregroundColor(.red).multilineTextAlignment(.center)
                }
            }.padding()
        }
        .navigationTitle("Fußweg".localized)
        .sheet(isPresented: $showStationPicker) { StationPickerSheet(selectedStation: $selectedStation) }
        .task { await workoutManager.requestAuthorization() }
    }
}

private struct ActiveWorkoutView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(formatTime(workoutManager.elapsedSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(.green)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StatBox(icon: "figure.walk", value: String(format: "%.0f", workoutManager.distanceMeters), unit: "m")
                    StatBox(icon: "flame.fill", value: String(format: "%.0f", workoutManager.activeCalories), unit: "kcal")
                    if workoutManager.heartRate > 0 {
                        StatBox(icon: "heart.fill", value: String(format: "%.0f", workoutManager.heartRate), unit: "bpm")
                    }
                }
                
                Button {
                    Task { await workoutManager.endWorkout() }
                } label: {
                    HStack { Image(systemName: "stop.fill"); Text("Beenden".localized) }
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity)
                        .padding().background(Color.red).cornerRadius(12)
                }.buttonStyle(.plain)
            }.padding()
        }.navigationTitle("Aktiv".localized).navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct StatBox: View {
    let icon: String; let value: String; let unit: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.secondary)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
            Text(unit).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(8).background(Color.gray.opacity(0.15)).cornerRadius(10)
    }
}

private struct StationPickerSheet: View {
    @Binding var selectedStation: WatchStation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(WatchStation.all) { station in
                Button {
                    selectedStation = station; dismiss()
                } label: {
                    HStack {
                        Text(station.name).font(.caption)
                        Spacer()
                        if station.id == selectedStation.id { Image(systemName: "checkmark").foregroundColor(.green) }
                    }
                }
            }
            .navigationTitle("Ziel".localized).navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
#Preview("Start") { WorkoutView() }
#endif
