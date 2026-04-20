//
//  ProfileAccountHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct ProfileAccountHubView: View {
    @ObservedObject var viewModel: ProfileViewModel

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                actionRow(
                    title: "Información personal",
                    subtitle: "Edita tus datos de contacto y emergencia",
                    systemImage: "person.text.rectangle"
                ) {
                    viewModel.openEditProfile()
                }

                actionRow(
                    title: "Recompensas y puntos",
                    subtitle: "\(viewModel.stats.level.title) • \(viewModel.stats.points) puntos",
                    systemImage: "gift.fill"
                ) { }

                actionRow(
                    title: "Beneficios de cumpleaños",
                    subtitle: "Se usa para promociones y descuentos especiales",
                    systemImage: "birthday.cake.fill"
                ) { }

                NavigationLink {
                    AccountActionsView(viewModel: viewModel)
                } label: {
                    row(
                        title: "Acciones de la cuenta",
                        subtitle: "Cerrar sesión y otras acciones sensibles de la cuenta",
                        systemImage: "exclamationmark.shield.fill"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("Cuenta")
        .appScreenStyle(theme)
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            row(title: title, subtitle: subtitle, systemImage: systemImage)
        }
        .buttonStyle(.plain)
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
