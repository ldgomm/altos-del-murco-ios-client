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

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var totalVisits: Int {
        completedOrders + completedBookings
    }

    private var nextLevel: LoyaltyLevel? {
        currentLevel.nextLevel
    }

    private var remainingToNextLevel: Double {
        currentLevel.remainingSpend(from: totalSpent)
    }

    private var progressToNextLevel: Double {
        LoyaltyLevel.progress(for: totalSpent)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroSection
                howItWorksSection
                currentBenefitsSection
                progressSection
                levelsSection
                rewardsSection
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
        VStack(alignment: .leading, spacing: 18) {
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
                    Text("Tu nivel actual")
                        .font(.caption.bold())
                        .foregroundStyle(palette.textSecondary)

                    Text(currentLevel.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)

                    Text(currentLevel.badgeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()
            }

            Text("Cada vez que vuelves a Altos del Murco acumulas más valor en tu cuenta, subes de nivel y desbloqueas descuentos y regalos en platos, jugos, bebidas y postres.")
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)

            HStack(spacing: 12) {
                heroMetric(
                    title: "Consumo",
                    value: totalSpent.priceText,
                    systemImage: "creditcard.fill"
                )

                heroMetric(
                    title: "Puntos",
                    value: "\(points)",
                    systemImage: "star.fill"
                )

                heroMetric(
                    title: "Visitas",
                    value: "\(totalVisits)",
                    systemImage: "figure.walk"
                )
            }

            if let nextLevel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progreso a \(nextLevel.title)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)

                        Spacer()

                        Text("\(Int(progressToNextLevel * 100))%")
                            .font(.caption.bold())
                            .foregroundStyle(palette.primary)
                    }

                    ProgressView(value: progressToNextLevel)
                        .tint(palette.primary)

                    Text("Te faltan \(remainingToNextLevel.priceText) en consumo acumulado para subir al nivel \(nextLevel.title).")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(palette.textSecondary)
                }
            } else {
                Label("Ya alcanzaste el nivel más alto del programa", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.08),
            radius: 10,
            x: 0,
            y: 6
        )
    }

    private var howItWorksSection: some View {
        sectionCard(
            title: "¿Cómo funciona?",
            subtitle: "Simple: disfruta, vuelve y desbloquea mejores recompensas."
        ) {
            VStack(spacing: 12) {
                loyaltyStep(
                    title: "1. Consume y disfruta",
                    description: "Tus pedidos y reservas completadas suman consumo acumulado y fortalecen tu nivel.",
                    systemImage: "fork.knife"
                )

                loyaltyStep(
                    title: "2. Regresa y sube",
                    description: "Cada nueva visita te acerca al siguiente nivel con mejores descuentos y premios.",
                    systemImage: "arrow.up.right.circle.fill"
                )

                loyaltyStep(
                    title: "3. Recibe recompensas",
                    description: "Mientras más fiel seas, más opciones tendrás de ganar platos, jugos, bebidas y postres gratis.",
                    systemImage: "gift.fill"
                )
            }

            Text("Solo cuentan los pedidos y reservas completadas.")
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.textSecondary)
        }
    }

    private var currentBenefitsSection: some View {
        sectionCard(
            title: "Tus beneficios actuales",
            subtitle: "Esto es lo que ya tienes disponible en tu nivel \(currentLevel.title)."
        ) {
            VStack(spacing: 12) {
                ForEach(currentLevel.benefits) { benefit in
                    benefitRow(benefit)
                }
            }
        }
    }
    
    private var progressSection: some View {
        sectionCard(
            title: "Tu siguiente meta",
            subtitle: nextLevel == nil
                ? "Ya alcanzaste el nivel más alto del programa."
                : "Sigue acumulando para desbloquear recompensas mejores y más valiosas."
        ) {
            if let nextLevel {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Próximo nivel: \(nextLevel.title)")
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)

                            Text(nextLevel.spendRangeText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.textSecondary)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(palette.chipGradient)
                                .frame(width: 42, height: 42)

                            Image(systemName: nextLevel.systemImage)
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.primary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progreso")
                                .font(.caption.bold())
                                .foregroundStyle(palette.textSecondary)

                            Spacer()

                            Text("\(Int(progressToNextLevel * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(palette.primary)
                        }

                        ProgressView(value: progressToNextLevel)
                            .tint(palette.primary)

                        Text("Te faltan \(remainingToNextLevel.priceText) de consumo acumulado para subir a \(nextLevel.title).")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lo que desbloquearás")
                            .font(.subheadline.bold())
                            .foregroundStyle(palette.textPrimary)

                        ForEach(Array(nextLevel.benefits.prefix(2))) { benefit in
                            benefitRow(benefit, highlighted: true)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Nivel \(currentLevel.title) desbloqueado", systemImage: currentLevel.systemImage)
                        .font(.headline)
                        .foregroundStyle(palette.primary)

                    Text("Ya estás en el nivel más alto. Ahora puedes aprovechar los beneficios más fuertes del programa, con descuentos y regalos más valiosos.")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    VStack(spacing: 12) {
                        ForEach(currentLevel.benefits.prefix(2)) { benefit in
                            benefitRow(benefit, highlighted: true)
                        }
                    }
                }
            }
        }
    }
    
    private func benefitRow(
        _ benefit: LoyaltyBenefit,
        highlighted: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(highlighted ? AnyShapeStyle(palette.cardGradient) : AnyShapeStyle(palette.elevatedCard))
                    .frame(width: 46, height: 46)

                Image(systemName: benefitIcon(for: benefit))
                    .font(.subheadline.bold())
                    .foregroundStyle(highlighted ? palette.onPrimary : palette.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text(benefit.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Text(benefitBadgeText(for: benefit))
                        .font(.caption2.bold())
                        .foregroundStyle(highlighted ? palette.onPrimary : palette.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(highlighted ? palette.primary : palette.primary.opacity(0.12))
                        )
                }

                Text(benefit.detail)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)

                HStack(spacing: 8) {
                    if let productName = benefit.productName {
                        benefitMetaChip(
                            text: productName,
                            systemImage: "fork.knife"
                        )
                    }

                    if let requiredVisits = benefit.requiredVisits {
                        benefitMetaChip(
                            text: "\(requiredVisits) visitas",
                            systemImage: "calendar.badge.clock"
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(highlighted ? AnyShapeStyle(palette.cardGradient) : AnyShapeStyle(palette.elevatedCard))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    highlighted ? palette.primary.opacity(0.28) : palette.stroke,
                    lineWidth: 1
                )
        )
    }
    
    private func benefitMetaChip(
        text: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2.bold())

            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(palette.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(palette.primary.opacity(0.10))
        )
    }

    private func benefitIcon(for benefit: LoyaltyBenefit) -> String {
        switch benefit.kind {
        case .percentageDiscount:
            return "percent"
        case .freeProduct:
            return "gift.fill"
        case .campaignReward:
            return "sparkles"
        }
    }

    private func benefitBadgeText(for benefit: LoyaltyBenefit) -> String {
        switch benefit.kind {
        case .percentageDiscount(let value):
            return "\(Int(value))% OFF"
        case .freeProduct:
            return "GRATIS"
        case .campaignReward:
            return "PROMO"
        }
    }

    private var levelsSection: some View {
        sectionCard(
            title: "Niveles de lealtad",
            subtitle: "Cada escalón mejora tu experiencia y hace más valioso volver."
        ) {
            VStack(spacing: 12) {
                ForEach(LoyaltyLevel.allCases, id: \.self) { level in
                    levelRow(level)
                }
            }
        }
    }

    private var rewardsSection: some View {
        sectionCard(
            title: "¿Qué puedes ganar?",
            subtitle: "El programa está pensado para motivarte a regresar y disfrutar más en cada visita."
        ) {
            VStack(spacing: 10) {
                rewardHighlight("Descuentos en platos y combos seleccionados", systemImage: "tag.fill")
                rewardHighlight("Jugos o bebidas gratis en beneficios especiales", systemImage: "takeoutbag.and.cup.and.straw.fill")
                rewardHighlight("Postres de cortesía para celebrar tu fidelidad", systemImage: "birthday.cake.fill")
                rewardHighlight("Premios sorpresa al seguir subiendo de nivel", systemImage: "sparkles")
            }
        }
    }

    private func heroMetric(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundStyle(palette.primary)

            Text(value)
                .font(.headline.bold())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

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
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func loyaltyStep(
        title: String,
        description: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 40, height: 40)

                Image(systemName: systemImage)
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.subheadline)
                .foregroundStyle(palette.primary)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
    }

    private func rewardHighlight(
        _ title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 38, height: 38)

                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(palette.primary)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func levelRow(_ level: LoyaltyLevel) -> some View {
        let isCurrent = level == currentLevel
        let isUnlocked = totalSpent >= level.minimumSpent

        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCurrent ? palette.heroGradient : palette.chipGradient)
                    .frame(width: 52, height: 52)

                Image(systemName: level.systemImage)
                    .font(.headline.bold())
                    .foregroundStyle(isCurrent ? palette.onPrimary : palette.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(level.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Text(isCurrent ? "Actual" : (isUnlocked ? "Desbloqueado" : "Bloqueado"))
                        .font(.caption.bold())
                        .foregroundStyle(isCurrent ? palette.onPrimary : palette.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isCurrent ? palette.primary : palette.primary.opacity(0.12))
                        )
                }

                Text(level.spendRangeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)

                Text(level.badgeSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.textPrimary)

                Text(level.benefits.map { $0.title }.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isCurrent ? AnyShapeStyle(palette.cardGradient) : AnyShapeStyle(palette.elevatedCard))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isCurrent ? palette.primary.opacity(0.35) : palette.stroke, lineWidth: 1)
        )
        .opacity(isUnlocked || isCurrent ? 1 : 0.72)
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.14 : 0.06),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

