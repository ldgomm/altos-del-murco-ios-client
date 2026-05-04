//
//  LoyaltyProgramView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 20/4/26.
//

import SwiftUI

struct LoyaltyProgramView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let theme: AppSectionTheme = .neutral

    let currentLevel: LoyaltyLevel
    let totalSpent: Double
    let points: Int
    let completedOrders: Int
    let completedBookings: Int
    var walletSnapshot: RewardWalletSnapshot = .empty()

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var nextLevel: LoyaltyLevel? {
        currentLevel.nextLevel
    }

    private var progressToNextLevel: Double {
        LoyaltyLevel.progress(for: totalSpent)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroSection
                progressSection
                availableRewardsSection
                reservedRewardsSection
                usedRewardsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .navigationTitle("Murco Loyalty")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(theme)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(palette.chipGradient)
                        .frame(width: 68, height: 68)

                    Image(systemName: currentLevel.systemImage)
                        .font(.title2.bold())
                        .foregroundStyle(palette.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Nivel \(currentLevel.title)")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(currentLevel.badgeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Text("Consumo acumulado: \(totalSpent.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.primary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                statCard("Puntos", "\(points)")
                statCard("Pedidos", "\(completedOrders)")
                statCard("Reservas", "\(completedBookings)")
            }
        }
        .appCardStyle(theme)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: theme,
                title: "Tu progreso",
                subtitle: nextLevel == nil
                    ? "Ya estás en la cima del programa."
                    : "Sigue acumulando para desbloquear tu próximo premio fuerte."
            )

            if let nextLevel {
                HStack {
                    Text("Próximo nivel: \(nextLevel.title)")
                        .font(.headline)

                    Spacer()

                    Text(nextLevel.spendRangeText)
                        .font(.caption.bold())
                        .foregroundStyle(palette.primary)
                }

                ProgressView(value: progressToNextLevel)
                    .tint(palette.primary)

                Text("Te faltan \(currentLevel.remainingSpend(from: totalSpent).priceText) para subir.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(theme, emphasized: false)
    }

    private var availableRewardsSection: some View {
        rewardSection(
            title: "Premios disponibles",
            subtitle: "Estos se aplican automáticamente cuando el pedido o la reserva cumplen la regla.",
            emptyText: "Todavía no tienes premios automáticos disponibles para tu nivel."
        ) {
            walletSnapshot.availableTemplates.map { template in
                AnyView(
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(theme: theme, systemImage: "gift.fill", size: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.title).font(.headline)
                            Text(template.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                            Text(template.displaySummary)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.primary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                )
            }
        }
    }

    private var reservedRewardsSection: some View {
        rewardSection(
            title: "Premios reservados",
            subtitle: "Ya están apartados en un pedido o reserva pendiente.",
            emptyText: "No tienes premios reservados ahora mismo."
        ) {
            walletSnapshot.reservedEvents.map { event in
                AnyView(
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.templateTitle).font(.headline)
                            Text(event.referenceType == .order ? "Pedido \(event.referenceId)" : "Reserva \(event.referenceId)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.amount.priceText)
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                )
            }
        }
    }

    private var usedRewardsSection: some View {
        rewardSection(
            title: "Historial de premios usados",
            subtitle: "Tus beneficios ya consumidos.",
            emptyText: "Todavía no has usado premios."
        ) {
            walletSnapshot.consumedEvents.map { event in
                AnyView(
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.templateTitle).font(.headline)
                            Text(event.referenceType == .order ? "Pedido \(event.referenceId)" : "Reserva \(event.referenceId)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.amount.priceText)
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                )
            }
        }
    }

    @ViewBuilder
    private func rewardSection(
        title: String,
        subtitle: String,
        emptyText: String,
        rows: () -> [AnyView]
    ) -> some View {
        let content = rows()

        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(theme: theme, title: title, subtitle: subtitle)

            if content.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            } else {
                ForEach(Array(content.enumerated()), id: \.offset) { _, row in
                    row
                }
            }
        }
        .appCardStyle(theme)
    }

    private func statCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(palette.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
    }
}
