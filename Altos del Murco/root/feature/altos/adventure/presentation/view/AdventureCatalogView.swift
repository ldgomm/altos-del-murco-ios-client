//
//  AdventureCatalogView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

@MainActor
struct AdventureCatalogView: View {
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @EnvironmentObject private var sessionViewModel: AppSessionViewModel

    @StateObject private var catalogViewModel = AdventureCatalogViewModel(
        service: AdventureCatalogService()
    )

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    heroSection

                    if catalogViewModel.state.isLoading && catalogViewModel.state.catalog.activities.isEmpty {
                        ProgressView("Cargando actividades...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if let error = catalogViewModel.state.errorMessage,
                              catalogViewModel.state.catalog.activities.isEmpty {
                        ContentUnavailableView(
                            "No se pudo cargar el catálogo",
                            systemImage: "wifi.exclamationmark",
                            description: Text(error)
                        )
                    } else {
                        featuredSection
                        singlesSection
                        customComboSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Aventura en Los Altos")
            .navigationBarTitleDisplayMode(.large)
            .appScreenStyle(.adventure)
        }
        .onAppear {
            if let profile = sessionViewModel.authenticatedProfile {
                adventureComboBuilderViewModel.setClientName(profile.fullName)
                adventureComboBuilderViewModel.setWhatsapp(profile.phoneNumber)
            }

            catalogViewModel.onAppear()
            menuViewModel.onAppear()
        }
        .onDisappear {
            catalogViewModel.onDisappear()
        }
    }

    private var heroSection: some View {
        let seasonalTheme = EcuadorSeasonalCalendar.activeTheme()
        let firstName = sessionViewModel.authenticatedProfile?.fullName
            .split(separator: " ")
            .first
            .map(String.init)

        let title = seasonalTheme?.adventureHeroTitle(firstName: firstName)
            ?? firstName.map { "Hola, \($0)\nVive la aventura en Los Altos" }
            ?? "Vive la aventura en Los Altos"

        let subtitle = seasonalTheme?.adventureHeroSubtitle
            ?? "Pide comida, reserva experiencias, revisa combos y aprovecha premios desde una sola cuenta."

        let badgeTitle = seasonalTheme?.shortPromise ?? "Experiencias de montaña"
        let heroIcon = seasonalTheme?.badgeSystemImage ?? "mountain.2.fill"

        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)

            SeasonalAnimatedCardBackdrop(
                seasonalTheme: seasonalTheme,
                cornerRadius: AppTheme.Radius.xLarge,
                intensity: seasonalTheme == .valentinesDay ? 1.25 : 1.04
            )

            LinearGradient(
                colors: [
                    .black.opacity(colorScheme == .dark ? 0.24 : 0.08),
                    .clear,
                    .black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.13))
                .frame(width: 170, height: 170)
                .blur(radius: 2)
                .offset(x: 52, y: -78)

            Circle()
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                .frame(width: 220, height: 220)
                .offset(x: 74, y: -105)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: heroIcon, size: 58)

                    Spacer(minLength: 12)

                    if let seasonalTheme {
                        SeasonalTinyBadge(theme: seasonalTheme, palette: palette)
                    } else {
                        BrandBadge(theme: .adventure, title: "Outdoor", selected: true)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 31, weight: .black))
                        .foregroundStyle(Color.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.86)

                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    HeroAdventureMicroBadge(
                        title: badgeTitle,
                        systemImage: seasonalTheme?.badgeSystemImage ?? "sparkles"
                    )

                    HeroAdventureMicroBadge(
                        title: "Combos + comida",
                        systemImage: "fork.knife.circle.fill"
                    )
                }

                NavigationLink {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.prepareCustomDraftIfNeeded()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                        Text("Iniciar combo personalizado")
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.20), lineWidth: 1)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
            radius: 22,
            x: 0,
            y: 12
        )
    }

    private struct HeroAdventureMicroBadge: View {
        let title: String
        let systemImage: String

        var body: some View {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.16), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Paquetes destacados",
                subtitle: "Combos sugeridos cargados desde Firestore."
            )

            let packages = catalogViewModel.state.catalog.activePackagesSorted

            if packages.isEmpty {
                Text("No hay paquetes destacados disponibles por ahora.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .appCardStyle(.adventure, emphasized: false)
            } else {
                ForEach(packages) { package in
                    NavigationLink {
                        AdventureComboBuilderView(
                            adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                            menuViewModel: menuViewModel
                        )
                        .onAppear {
                            adventureComboBuilderViewModel.replacePackage(
                                package,
                                menuSections: menuViewModel.state.sections
                            )
                        }
                    } label: {
                        FeaturedPackageCard(
                            package: package,
                            catalog: catalogViewModel.state.catalog,
                            menuSections: menuViewModel.state.sections,
                            rewardPresentation: adventureComboBuilderViewModel.packageRewardPresentation(
                                for: package,
                                menuSections: menuViewModel.state.sections
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var singlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Actividades individuales",
                subtitle: "Actividades activas ordenadas por sortOrder."
            )

            ForEach(catalogViewModel.state.catalog.activeActivitiesSorted) { activity in
                NavigationLink {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.replaceItems(
                            with: [activity.defaultDraft],
                            packageDiscountAmount: 0
                        )
                    }
                } label: {
                    SingleActivityCatalogCard(
                        activity: activity,
                        rewardPresentation: adventureComboBuilderViewModel.catalogRewardPresentation(for: activity)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customComboSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "¿Necesitas algo diferente?",
                subtitle: "Crea una combinación a medida con tiempos y cantidades personalizadas."
            )

            VStack(alignment: .leading, spacing: 14) {
                Text("Las reglas de agenda siguen en código, pero el catálogo y precios vienen de Firestore.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)

                NavigationLink {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.prepareCustomDraftIfNeeded()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("Abrir creador de aventuras")
                    }
                }
                .buttonStyle(BrandSecondaryButtonStyle(theme: .adventure))
            }
            .appCardStyle(.adventure)
        }
    }
}

private struct FeaturedPackageCard: View {
    let package: AdventureFeaturedPackage
    let catalog: AdventureCatalogSnapshot
    let menuSections: [MenuSection]
    let rewardPresentation: RewardPresentation?

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var menuItemsById: [String: MenuItem] {
        Dictionary(
            uniqueKeysWithValues: menuSections
                .flatMap(\.items)
                .map { ($0.id, $0) }
        )
    }

    private var activitySubtotal: Double {
        AdventurePricingEngine.estimatedSubtotal(items: package.items, catalog: catalog)
    }

    private var foodSubtotal: Double {
        package.foodItems.reduce(0) { partial, item in
            let unitPrice = menuItemsById[item.menuItemId]?.finalPrice ?? 0
            return partial + (Double(item.quantity) * unitPrice)
        }
    }

    private var subtotal: Double {
        activitySubtotal + foodSubtotal
    }

    private var total: Double {
        max(0, subtotal - package.packageDiscountAmount)
    }

    private var foodSummary: String {
        package.foodItems.map { item in
            let name = menuItemsById[item.menuItemId]?.name ?? item.menuItemId
            return "\(item.quantity)x \(name)"
        }
        .joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(theme: .adventure, systemImage: "figure.hiking", size: 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text(package.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(package.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if let badge = package.badge, !badge.isEmpty {
                    BrandBadge(theme: .adventure, title: badge)
                }
            }

            if !foodSummary.isEmpty {
                Text(foodSummary)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                Text("Aventura \(activitySubtotal.priceText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)

                if foodSubtotal > 0 {
                    Text("Comida \(foodSubtotal.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)
                }
            }

            if package.packageDiscountAmount > 0 {
                Text("Descuento del paquete: \(package.packageDiscountAmount.priceText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }

            if let rewardPresentation {
                rewardInfoCard(rewardPresentation)
            }

            HStack {
                Label("Desde \(total.priceText)", systemImage: "dollarsign.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primary)

                Spacer()

                Label("Ver combo", systemImage: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private func rewardInfoCard(_ reward: RewardPresentation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrandBadge(theme: .adventure, title: reward.badge, selected: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(reward.message)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}

private struct SingleActivityCatalogCard: View {
    let activity: AdventureActivityCatalogItem
    let rewardPresentation: RewardPresentation?

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(
                theme: .adventure,
                systemImage: activity.systemImage,
                size: 56
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(activity.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("Desde \(activity.finalUnitPrice.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.primary)

                    if activity.hasDiscount {
                        Text("Antes \(activity.basePrice.priceText)")
                            .font(.caption)
                            .foregroundStyle(palette.textTertiary)
                            .strikethrough()
                    }
                }

                if let rewardPresentation {
                    HStack(spacing: 8) {
                        BrandBadge(theme: .adventure, title: rewardPresentation.badge, selected: true)

                        Text(rewardPresentation.message)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(palette.primary)

                Text("Reservar")
                    .font(.caption.bold())
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.adventure)
    }
}
