//
//  AppearanceSettingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private let theme: AppSectionTheme = .neutral

    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)
                    
                    Text("Choose how the app looks across the interface.")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        viewModel.updateAppearance(appearance)
                    } label: {
                        HStack(spacing: 14) {
                            BrandIconBubble(
                                theme: theme,
                                systemImage: icon(for: appearance),
                                size: 44
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appearance.title)
                                    .font(.headline)
                                    .foregroundStyle(palette.textPrimary)

                                Text(appearance.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            if viewModel.currentAppearance == appearance {
                                ZStack {
                                    Circle()
                                        .fill(palette.heroGradient)
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(palette.onPrimary)
                                }
                            } else {
                                Circle()
                                    .stroke(palette.stroke, lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(theme)
    }
    
    private func icon(for appearance: AppAppearance) -> String {
        switch appearance {
        case .system:
            return "iphone"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}
