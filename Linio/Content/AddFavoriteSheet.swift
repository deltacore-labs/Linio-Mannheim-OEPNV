//
//  AddFavoriteSheet.swift
//  Linio
//
//  Sheet zum Hinzufügen einer Haltestelle als Favorit
//

import SwiftUI

struct AddFavoriteSheet: View {
    let station: Station
    let onDismiss: () -> Void
    
    // Performance: @StateObject für Singleton
    @StateObject private var favoritesManager = FavoriteStationsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLabel: FavoriteLabel = .home
    @State private var customLabelText: String = ""
    @State private var showCustomInput = false
    @FocusState private var isCustomInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    stationHeader
                    labelSelectionSection
                    if showCustomInput || selectedLabel == .custom {
                        customLabelSection
                    }
                    saveButton
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("Favorit hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.primaryColor)
                }
            }
        }
    }
    
    private var stationHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "tram.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppTheme.primaryColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(station.longName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text("Als Favorit speichern")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.hairline, lineWidth: 1))
        )
    }

    private var labelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategorie wählen")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(FavoriteLabel.allCases) { label in
                    labelButton(label)
                }
            }
        }
    }
    
    private func labelButton(_ label: FavoriteLabel) -> some View {
        let isSelected = selectedLabel == label
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedLabel = label
                showCustomInput = label == .custom
                if label != .custom { customLabelText = "" }
            }
            HapticHelper.selection()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? label.color : label.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: label.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : label.color)
                }
                Text(label.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? label.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? label.color.opacity(0.08) : AppTheme.surfaceCard)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? label.color.opacity(0.3) : AppTheme.hairline, lineWidth: isSelected ? 2 : 1))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var customLabelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eigener Name")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            TextField("z.B. Omas Haus...", text: $customLabelText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.surfaceCard)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isCustomInputFocused ? AppTheme.primaryColor.opacity(0.5) : AppTheme.hairline, lineWidth: 1))
                )
                .focused($isCustomInputFocused)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var saveButton: some View {
        Button {
            let custom = customLabelText.trimmingCharacters(in: .whitespaces)
            let success = favoritesManager.addFavorite(station: station, label: selectedLabel, customLabel: custom.isEmpty ? nil : custom)
            if success {
                HapticHelper.impact(.medium)
                dismiss()
                onDismiss()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                Text("Als Favorit speichern")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(canSave ? AppTheme.primaryColor : AppTheme.muted))
        }
        .disabled(!canSave)
    }
    
    private var canSave: Bool {
        favoritesManager.canAddMore && !favoritesManager.isFavorite(station: station)
    }
}
