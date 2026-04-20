//
//  BookingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct BookingsView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    let adventureModuleFactory: AdventureModuleFactory
    @Environment(\.colorScheme) private var colorScheme

    private var neutralPalette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    NavigationLink {
                        OrdersView(viewModel: ordersViewModel)
                    } label: {
                        bookingCard(
                            theme: .restaurant,
                            badge: "Restaurante",
                            title: "Pedidos del restaurante",
                            subtitle: "Revisa tus pedidos actuales y anteriores de comida.",
                            systemImage: "fork.knife"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AdventureReservationsView(
                            viewModelFactory: adventureModuleFactory.makeBookingsViewModel
                        )
                    } label: {
                        bookingCard(
                            theme: .adventure,
                            badge: "Aventura",
                            title: "Reservas de aventura",
                            subtitle: "Mira combos, actividades individuales, camping y reservas nocturnas.",
                            systemImage: "calendar.badge.clock"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .appScreenStyle(.neutral)
            .navigationTitle("Reservas")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Gestiona tus reservas",
                subtitle: "Accede rápidamente a tus pedidos del restaurante y a tus reservas de aventura."
            )

            Text("Todo en un solo lugar, con acceso claro para cada experiencia.")
                .font(.subheadline)
                .foregroundStyle(neutralPalette.textSecondary)
        }
        .appCardStyle(.neutral, emphasized: false)
    }

    private func bookingCard(
        theme: AppSectionTheme,
        badge: String,
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)

        return HStack(spacing: 16) {
            BrandIconBubble(
                theme: theme,
                systemImage: systemImage,
                size: 54
            )

            VStack(alignment: .leading, spacing: 8) {
                BrandBadge(theme: theme, title: badge)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
        }
        .appCardStyle(theme, emphasized: false)
    }
}
