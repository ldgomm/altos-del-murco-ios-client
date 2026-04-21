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
                adventureComboBuilderViewModel.setNationalId(profile.nationalId)
            }

            catalogViewModel.onAppear()
            menuViewModel.onAppear()
        }
        .onDisappear {
            catalogViewModel.onDisappear()
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18), lineWidth: 1)
                )
                .shadow(
                    color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
                    radius: 22,
                    x: 0,
                    y: 12
                )

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    BrandIconBubble(theme: .adventure, systemImage: "mountain.2.fill", size: 56)
                    Spacer()
                    BrandBadge(theme: .adventure, title: "Outdoor", selected: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Construye tu combo perfecto")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text("Ahora el catálogo, los paquetes y la comida incluida se cargan desde Firestore.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.92))
                }

                NavigationLink {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.reset()
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
                        adventureComboBuilderViewModel.reset()
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
