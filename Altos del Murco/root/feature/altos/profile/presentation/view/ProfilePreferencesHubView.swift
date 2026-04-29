//
//  ProfilePreferencesHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import SwiftUI

struct ProfilePreferencesHubView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.openURL) private var openURL

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink {
                    AppearanceSettingsView(viewModel: viewModel)
                } label: {
                    row(
                        title: "Apariencia",
                        subtitle: viewModel.appearanceTitle,
                        systemImage: "circle.lefthalf.filled"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(settingsURL)
                } label: {
                    row(
                        title: "Permisos de la app",
                        subtitle: "Notificaciones, ubicación y ajustes del dispositivo",
                        systemImage: "gearshape.2.fill"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("Preferencias")
        .appScreenStyle(theme)
    }

    private func row(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 14) {
            BrandIconBubble(theme: theme, systemImage: systemImage, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(theme)
    }
}
