//
//  HomeView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

private enum HomeRoute: Hashable {
    case featuredRestaurant
    case menuItem(String)
    case experiencePackages
    case packageDetail(String)
    case reservePackage(String)
    case rewards
}

struct HomeView: View {
    @Binding var selectedTab: MainTab

    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel

    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var catalogViewModel = AdventureCatalogViewModel(service: AdventureCatalogService())

    private var profile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    private var featuredItems: [MenuItem] {
        allMenuItems
            .filter(\.isFeatured)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name < $1.name
            }
    }

    private var allMenuItems: [MenuItem] {
        menuViewModel.state.sections.flatMap(\.items)
    }

    private var activePackages: [AdventureFeaturedPackage] {
        catalogViewModel.state.catalog.activePackagesSorted
    }

    private var availableRewards: [LoyaltyRewardTemplate] {
        menuViewModel.state.rewardWalletSnapshot.availableTemplates
            .filter { $0.isActive && !$0.isExpired }
            .sorted {
                if $0.priority != $1.priority { return $0.priority < $1.priority }
                return $0.title < $1.title
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    heroSection
                    quickMetricsSection
                    restaurantRecommendations
                    experiencePackages
                    featuredPostsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Altos del Murco")
            .navigationBarTitleDisplayMode(.large)
            .appScreenStyle(.neutral)
            .navigationDestination(for: HomeRoute.self) { route in
                destination(for: route)
            }
        }
        .onAppear {
            menuViewModel.onAppear()

            if let nationalId = profile?.nationalId {
                menuViewModel.setNationalId(nationalId)
                adventureComboBuilderViewModel.setNationalId(nationalId)
            }

            if let profile {
                adventureComboBuilderViewModel.setClientName(profile.fullName)
                adventureComboBuilderViewModel.setWhatsapp(profile.phoneNumber)
            }

            catalogViewModel.onAppear()
        }
        .onDisappear {
            catalogViewModel.onDisappear()
        }
        .onChange(of: profile?.nationalId) { _, nationalId in
            guard let nationalId else { return }
            menuViewModel.setNationalId(nationalId)
            adventureComboBuilderViewModel.setNationalId(nationalId)
        }
        .onChange(of: profile?.id) { _, _ in
            syncProfileIntoAdventureBuilder()
        }
        .onChange(of: profile?.updatedAt) { _, _ in
            syncProfileIntoAdventureBuilder()
        }
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .featuredRestaurant:
            HomeFeaturedRestaurantView(
                featuredItems: featuredItems,
                rewardPresentationProvider: { item in
                    menuViewModel.rewardPresentation(for: item, quantity: 1)
                },
                onOpenFullMenu: {
                    selectedTab = .restaurant
                }
            )

        case .menuItem(let itemId):
            if let item = menuItem(with: itemId) {
                MenuItemDetailView(
                    item: item,
                    categoryTitle: categoryTitle(for: item),
                    rewardPresentationProvider: { item, quantity in
                        menuViewModel.rewardPresentation(for: item, quantity: quantity)
                    },
                    displayedPriceProvider: { item, quantity in
                        menuViewModel.displayedPrice(for: item, quantity: quantity)
                    },
                    incrementalDiscountProvider: { item, quantity in
                        menuViewModel.incrementalDiscount(for: item, quantity: quantity)
                    }
                )
            } else {
                HomeMissingContentView(
                    title: "Plato no disponible",
                    message: "Este recomendado cambió o ya no está activo en el menú.",
                    systemImage: "fork.knife.circle"
                )
            }

        case .experiencePackages:
            HomeExperiencePackagesView(
                packages: activePackages,
                catalog: catalogViewModel.state.catalog,
                menuSections: menuViewModel.state.sections,
                rewardProvider: { package in
                    adventureComboBuilderViewModel.packageRewardPresentation(
                        for: package,
                        menuSections: menuViewModel.state.sections
                    )
                },
                onOpenExperiencesTab: {
                    selectedTab = .experiences
                }
            )

        case .packageDetail(let packageId):
            if let package = package(with: packageId) {
                HomePackageDetailView(
                    package: package,
                    catalog: catalogViewModel.state.catalog,
                    menuSections: menuViewModel.state.sections,
                    reward: adventureComboBuilderViewModel.packageRewardPresentation(
                        for: package,
                        menuSections: menuViewModel.state.sections
                    ),
                    adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                    menuViewModel: menuViewModel
                )
            } else {
                HomeMissingContentView(
                    title: "Combo no disponible",
                    message: "Este combo cambió o ya no está activo en el catálogo.",
                    systemImage: "mountain.2.circle"
                )
            }

        case .reservePackage(let packageId):
            if let package = package(with: packageId) {
                HomePackageReservationDestination(
                    package: package,
                    menuSections: menuViewModel.state.sections,
                    adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                    menuViewModel: menuViewModel
                )
            } else {
                HomeMissingContentView(
                    title: "Combo no disponible",
                    message: "Este combo cambió o ya no está activo en el catálogo.",
                    systemImage: "mountain.2.circle"
                )
            }

        case .rewards:
            HomeRewardsCenterView(
                wallet: menuViewModel.state.rewardWalletSnapshot,
                rewards: availableRewards,
                featuredItems: featuredItems,
                activePackages: activePackages,
                onOpenRestaurant: {
                    selectedTab = .restaurant
                },
                onOpenExperiences: {
                    selectedTab = .experiences
                },
                onOpenProfile: {
                    selectedTab = .profile
                }
            )
        }
    }

    private func syncProfileIntoAdventureBuilder() {
        guard let profile else { return }

        adventureComboBuilderViewModel.setClientName(profile.fullName)
        adventureComboBuilderViewModel.setWhatsapp(profile.phoneNumber)
        adventureComboBuilderViewModel.setNationalId(profile.nationalId)
    }

    private func menuItem(with id: String) -> MenuItem? {
        allMenuItems.first { $0.id == id }
    }

    private func package(with id: String) -> AdventureFeaturedPackage? {
        activePackages.first { $0.id == id }
    }

    private func categoryTitle(for item: MenuItem) -> String {
        if !item.categoryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return item.categoryTitle
        }

        return menuViewModel.state.sections.first(where: { section in
            section.items.contains(where: { $0.id == item.id })
        })?.category.title ?? "Menú"
    }

    private var heroSection: some View {
        let firstName = profile?.fullName.split(separator: " ").first.map(String.init)
        let title = firstName.map { "Hola, \($0)\nVive Los Altos" } ?? "Vive Los Altos"

        return PremiumHero(
            title: title,
            subtitle: "Pide comida, reserva experiencias, revisa combos y aprovecha premios  desde una sola cuenta.",
            badge: "Restaurante + Experiencias"
        ) {
            Button {
                selectedTab = .restaurant
            } label: {
                Label(PremiumAltosCopy.restaurantCTA, systemImage: "fork.knife")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.white)
            .foregroundStyle(.black)
        } secondary: {
            Button {
                selectedTab = .experiences
            } label: {
                Label(PremiumAltosCopy.experiencesCTA, systemImage: "mountain.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.white)
        }
    }

    private var quickMetricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PremiumSectionHeader(
                title: "Accesos rápidos",
                subtitle: "Cada tarjeta ahora abre una acción real, no solo una cifra bonita.",
                systemImage: "bolt.fill"
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                NavigationLink(value: HomeRoute.featuredRestaurant) {
                    HomeActionMetricTile(
                        title: "Platos destacados",
                        value: "\(featuredItems.count)",
                        subtitle: featuredItems.isEmpty ? "Aún sin destacados" : "Ver detalle y agregar",
                        systemImage: "fork.knife",
                        actionTitle: "Explorar"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: HomeRoute.experiencePackages) {
                    HomeActionMetricTile(
                        title: "Combos activos",
                        value: "\(activePackages.count)",
                        subtitle: activePackages.isEmpty ? "Aún sin combos" : "Comparar y reservar",
                        systemImage: "mountain.2.fill",
                        actionTitle: "Ver combos"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: HomeRoute.rewards) {
                    HomeActionMetricTile(
                        title: "Premios",
                        value: "\(availableRewards.count)",
                        subtitle: availableRewards.isEmpty ? "Sigue acumulando" : "Dónde aplican",
                        systemImage: "gift.fill",
                        actionTitle: "Usar premios"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    selectedTab = .bookings
                } label: {
                    HomeActionMetricTile(
                        title: "Reservas",
                        value: "Agenda",
                        subtitle: "Actuales, futuras y pasadas",
                        systemImage: "calendar",
                        actionTitle: "Ver"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var restaurantRecommendations: some View {
        if !featuredItems.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom) {
                    PremiumSectionHeader(
                        title: "Recomendados del restaurante",
                        subtitle: "Toca un plato para ver ingredientes, premios, cantidad y agregar al carrito.",
                        systemImage: "fork.knife"
                    )

                    Spacer(minLength: 8)

                    NavigationLink(value: HomeRoute.featuredRestaurant) {
                        Text("Ver todo")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.plain)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(featuredItems.prefix(8)) { item in
                            NavigationLink(value: HomeRoute.menuItem(item.id)) {
                                HomeFeaturedMenuCard(
                                    item: item,
                                    reward: menuViewModel.rewardPresentation(for: item, quantity: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var experiencePackages: some View {
        if !activePackages.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom) {
                    PremiumSectionHeader(
                        title: "Combos de experiencias",
                        subtitle: "Revisa qué incluye cada combo antes de reservar.",
                        systemImage: "figure.hiking"
                    )

                    Spacer(minLength: 8)

                    NavigationLink(value: HomeRoute.experiencePackages) {
                        Text("Comparar")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.plain)
                }

                ForEach(activePackages.prefix(4)) { package in
                    NavigationLink(value: HomeRoute.packageDetail(package.id)) {
                        HomePackageCard(
                            package: package,
                            catalog: catalogViewModel.state.catalog,
                            menuSections: menuViewModel.state.sections,
                            reward: adventureComboBuilderViewModel.packageRewardPresentation(
                                for: package,
                                menuSections: menuViewModel.state.sections
                            )
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var featuredPostsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PremiumSectionHeader(
                title: "Momentos destacados",
                subtitle: "Fotos recientes del restaurante, experiencias y clientes.",
                systemImage: "photo.on.rectangle.angled"
            )

            FeaturedPostsSectionView()
        }
    }
}

// MARK: - Home quick actions

private struct HomeActionMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                PremiumIconBubble(systemImage: systemImage, selected: true)

                Spacer()

                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(palette.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.textPrimary)
                    .monospacedDigit()

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 6) {
                Text(actionTitle)
                    .font(.caption.bold())
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
            }
            .foregroundStyle(palette.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 166, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.07),
            radius: 12,
            x: 0,
            y: 7
        )
    }
}

// MARK: - Restaurant recommendations

private struct HomeFeaturedRestaurantView: View {
    let featuredItems: [MenuItem]
    let rewardPresentationProvider: (MenuItem) -> RewardPresentation?
    let onOpenFullMenu: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 16) {
                PremiumSectionHeader(
                    title: "Platos destacados",
                    subtitle: "Aquí sí hay acción: abre el detalle, revisa ingredientes, cantidad, premios y agrégalo al carrito.",
                    systemImage: "fork.knife"
                )

                if featuredItems.isEmpty {
                    HomeMissingContentView(
                        title: "Sin platos destacados",
                        message: "Cuando marques platos como destacados en Firestore, aparecerán aquí.",
                        systemImage: "fork.knife.circle"
                    )
                } else {
                    ForEach(featuredItems) { item in
                        NavigationLink(value: HomeRoute.menuItem(item.id)) {
                            HomeFeaturedMenuListCard(
                                item: item,
                                reward: rewardPresentationProvider(item)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(action: onOpenFullMenu) {
                    Label("Abrir menú completo", systemImage: "menucard.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
                .padding(.top, 6)
            }
            .padding(20)
        }
        .navigationTitle("Recomendados")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
    }
}

private struct HomeFeaturedMenuCard: View {
    let item: MenuItem
    let reward: RewardPresentation?

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                PremiumIconBubble(systemImage: "fork.knife", selected: true)

                Spacer()

                Image(systemName: "arrow.up.right.circle.fill")
                    .foregroundStyle(palette.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Destacado")
                        .font(.caption2.bold())
                        .foregroundStyle(palette.primary)

                    if let reward {
                        Text(reward.badge)
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                }

                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(2)

                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)

                priceLine

                Text(item.canBeOrdered ? "Disponible hoy" : "No disponible hoy / reservas futuras")
                    .font(.caption.bold())
                    .foregroundStyle(item.canBeOrdered ? .green : .red)
            }

            HStack(spacing: 6) {
                Text("Ver detalle")
                    .font(.caption.bold())
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
            }
            .foregroundStyle(palette.primary)
        }
        .padding(16)
        .frame(width: 236)
        .frame(minHeight: 232)
        .frame(alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.08), radius: 14, x: 0, y: 8)
    }

    @ViewBuilder
    private var priceLine: some View {
        HStack(spacing: 8) {
            if item.hasOffer {
                Text(item.price.priceText)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
                    .strikethrough()
            }

            Text(item.finalPrice.priceText)
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        }
    }
}

private struct HomeFeaturedMenuListCard: View {
    let item: MenuItem
    let reward: RewardPresentation?

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            PremiumIconBubble(systemImage: "fork.knife", selected: true)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(2)

                    if item.isFeatured {
                        BrandBadge(theme: .restaurant, title: "Popular", selected: true)
                    }
                }

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)

                if let reward {
                    HStack(spacing: 8) {
                        BrandBadge(theme: .restaurant, title: reward.badge, selected: true)
                        Text(reward.message)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                    }
                }

                HStack(spacing: 10) {
                    Text(item.finalPrice.priceText)
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)

                    Text(item.stockLabel)
                        .font(.caption.bold())
                        .foregroundStyle(item.canBeOrdered ? .green : .red)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(palette.textTertiary)
                .padding(.top, 6)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Experience packages

private struct HomeExperiencePackagesView: View {
    let packages: [AdventureFeaturedPackage]
    let catalog: AdventureCatalogSnapshot
    let menuSections: [MenuSection]
    let rewardProvider: (AdventureFeaturedPackage) -> RewardPresentation?
    let onOpenExperiencesTab: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 16) {
                PremiumSectionHeader(
                    title: "Combos de experiencias",
                    subtitle: "Compara precio, comida incluida, descuento y premios antes de elegir fecha.",
                    systemImage: "figure.hiking"
                )

                if packages.isEmpty {
                    HomeMissingContentView(
                        title: "Sin combos activos",
                        message: "Cuando existan paquetes activos en Firestore, aparecerán aquí.",
                        systemImage: "mountain.2.circle"
                    )
                } else {
                    ForEach(packages) { package in
                        NavigationLink(value: HomeRoute.packageDetail(package.id)) {
                            HomePackageCard(
                                package: package,
                                catalog: catalog,
                                menuSections: menuSections,
                                reward: rewardProvider(package)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(action: onOpenExperiencesTab) {
                    Label("Abrir módulo completo de experiencias", systemImage: "mountain.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
                .padding(.top, 6)
            }
            .padding(20)
        }
        .navigationTitle("Combos")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.adventure)
    }
}

private struct HomePackageCard: View {
    let package: AdventureFeaturedPackage
    let catalog: AdventureCatalogSnapshot
    let menuSections: [MenuSection]
    let reward: RewardPresentation?

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
        AdventurePricingEngine.estimatedSubtotal(
            items: package.items,
            catalog: catalog
        )
    }

    private var foodSubtotal: Double {
        package.foodItems.reduce(0) { partial, food in
            partial + Double(food.quantity) * (menuItemsById[food.menuItemId]?.finalPrice ?? 0)
        }
    }

    private var subtotal: Double {
        activitySubtotal + foodSubtotal
    }

    private var comboDiscount: Double {
        min(max(0, package.packageDiscountAmount), subtotal)
    }

    private var finalTotal: Double {
        max(0, subtotal - comboDiscount)
    }

    private var totalSavings: Double {
        comboDiscount
    }

    private var activitiesText: String {
        package.items
            .prefix(3)
            .map { item in
                catalog.activity(for: item.activity)?.title ?? item.activity.legacyTitle
            }
            .joined(separator: " • ")
    }

    private var foodText: String? {
        let value = package.foodItems
            .prefix(3)
            .map { food in
                let name = menuItemsById[food.menuItemId]?.name ?? food.menuItemId
                return "\(food.quantity)x \(name)"
            }
            .joined(separator: " • ")

        return value.isEmpty ? nil : value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            packageBreakdown

            if let reward {
                PremiumRewardCard(reward: reward)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Total estimado")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if totalSavings > 0 {
                        Text("Ahorras \(totalSavings.priceText)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }

                Spacer(minLength: 12)

                Text(finalTotal.priceText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                Text("Ver detalle del combo")
                    .font(.caption.bold())
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
            }
            .foregroundStyle(palette.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.07), radius: 16, x: 0, y: 8)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            PremiumIconBubble(
                systemImage: "mountain.2.fill",
                selected: true
            )
            .fixedSize()

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    if let badge = package.badge, !badge.isEmpty {
                        BrandBadge(theme: .adventure, title: badge, selected: true)
                    }

                    if comboDiscount > 0 {
                        BrandBadge(theme: .adventure, title: "Combo", selected: true)
                    }
                }

                Text(package.title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(2)

                Text(package.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right.circle.fill")
                .font(.title3)
                .foregroundStyle(palette.primary)
        }
    }

    private var packageBreakdown: some View {
        VStack(alignment: .leading, spacing: 9) {
            if !activitiesText.isEmpty {
                HomeIconLine(systemImage: "figure.hiking", text: activitiesText)
            }

            if let foodText {
                HomeIconLine(systemImage: "fork.knife", text: foodText)
            }

            HStack(spacing: 10) {
                HomeMiniPricePill(title: "Aventura", value: activitySubtotal.priceText)
                if foodSubtotal > 0 {
                    HomeMiniPricePill(title: "Comida", value: foodSubtotal.priceText)
                }
                if comboDiscount > 0 {
                    HomeMiniPricePill(title: "Descuento", value: "-\(comboDiscount.priceText)")
                }
            }
        }
    }
}

private struct HomePackageDetailView: View {
    let package: AdventureFeaturedPackage
    let catalog: AdventureCatalogSnapshot
    let menuSections: [MenuSection]
    let reward: RewardPresentation?
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

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
        package.foodItems.reduce(0) { partial, food in
            partial + Double(food.quantity) * (menuItemsById[food.menuItemId]?.finalPrice ?? 0)
        }
    }

    private var comboDiscount: Double {
        min(max(0, package.packageDiscountAmount), activitySubtotal + foodSubtotal)
    }

    private var finalTotal: Double {
        max(0, activitySubtotal + foodSubtotal - comboDiscount)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                activitiesSection

                if !package.foodItems.isEmpty {
                    foodSection
                }

                if let reward {
                    rewardSection(reward)
                }

                totalsSection

                NavigationLink(value: HomeRoute.reservePackage(package.id)) {
                    Label("Reservar este combo", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))

                Text("Después podrás cambiar fecha, horario, cantidades, comida y notas antes de confirmar.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .navigationTitle("Detalle del combo")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.adventure)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                PremiumIconBubble(systemImage: "mountain.2.fill", selected: true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let badge = package.badge, !badge.isEmpty {
                            BrandBadge(theme: .adventure, title: badge, selected: true)
                        }

                        if comboDiscount > 0 {
                            BrandBadge(theme: .adventure, title: "Ahorro \(comboDiscount.priceText)", selected: true)
                        }
                    }

                    Text(package.title)
                        .font(.title2.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(package.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                HomeMiniPricePill(title: "Aventura", value: activitySubtotal.priceText)
                if foodSubtotal > 0 {
                    HomeMiniPricePill(title: "Comida", value: foodSubtotal.priceText)
                }
                HomeMiniPricePill(title: "Total", value: finalTotal.priceText)
            }
        }
        .appCardStyle(.adventure)
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Actividades incluidas",
                subtitle: "Este será el borrador inicial de la reserva."
            )

            ForEach(package.items) { item in
                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(
                        theme: .adventure,
                        systemImage: catalog.activity(for: item.activity)?.systemImage ?? item.activity.legacySystemImage,
                        size: 42
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(catalog.activity(for: item.activity)?.title ?? item.activity.legacyTitle)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text(item.summaryText)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

                        Text(AdventurePricingEngine.subtotal(for: item, catalog: catalog).priceText)
                            .font(.caption.bold())
                            .foregroundStyle(palette.primary)
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
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var foodSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Comida incluida",
                subtitle: "Se agregará automáticamente al creador de reservas."
            )

            ForEach(package.foodItems) { food in
                let item = menuItemsById[food.menuItemId]

                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item?.name ?? food.menuItemId)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text("\(food.quantity) unidad(es)")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

                        if let item {
                            Text((item.finalPrice * Double(food.quantity)).priceText)
                                .font(.caption.bold())
                                .foregroundStyle(palette.primary)
                        }
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
        }
        .appCardStyle(.adventure)
    }

    private func rewardSection(_ reward: RewardPresentation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Premio disponible",
                subtitle: "Si sigue vigente al confirmar, se aplicará automáticamente."
            )

            PremiumRewardCard(reward: reward)
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Resumen estimado",
                subtitle: "El total final puede cambiar si editas cantidades o agregas más comida."
            )

            HomeTotalRow(title: "Aventura", value: activitySubtotal)
            HomeTotalRow(title: "Comida", value: foodSubtotal)

            if comboDiscount > 0 {
                HomeTotalRow(title: "Descuento del combo", value: -comboDiscount, accent: true)
            }

            Divider()

            HomeTotalRow(title: "Total estimado", value: finalTotal, primary: true)
        }
        .appCardStyle(.adventure)
    }
}

private struct HomePackageReservationDestination: View {
    let package: AdventureFeaturedPackage
    let menuSections: [MenuSection]
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @State private var didPreparePackage = false

    var body: some View {
        AdventureComboBuilderView(
            adventureComboBuilderViewModel: adventureComboBuilderViewModel,
            menuViewModel: menuViewModel
        )
        .onAppear {
            guard !didPreparePackage else { return }
            didPreparePackage = true

            adventureComboBuilderViewModel.replacePackage(
                package,
                menuSections: menuSections
            )
        }
    }
}

// MARK: - Rewards

private struct HomeRewardsCenterView: View {
    let wallet: RewardWalletSnapshot
    let rewards: [LoyaltyRewardTemplate]
    let featuredItems: [MenuItem]
    let activePackages: [AdventureFeaturedPackage]
    let onOpenRestaurant: () -> Void
    let onOpenExperiences: () -> Void
    let onOpenProfile: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                if rewards.isEmpty {
                    HomeMissingContentView(
                        title: "Aún no hay premios disponibles",
                        message: "Sigue acumulando consumo en restaurante y experiencias. Cuando tengas premios activos, aquí verás dónde usarlos.",
                        systemImage: "gift.circle"
                    )

                    Button(action: onOpenProfile) {
                        Label("Ver mi perfil y progreso", systemImage: wallet.currentLevel.systemImage)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandPrimaryButtonStyle(theme: .neutral))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        PremiumSectionHeader(
                            title: "Premios listos para usar",
                            subtitle: "Estos premios son automáticos: abre restaurante o experiencias y el checkout/builder hará el cálculo.",
                            systemImage: "gift.fill"
                        )

                        ForEach(rewards) { reward in
                            HomeRewardTemplateCard(
                                template: reward,
                                onOpenRestaurant: onOpenRestaurant,
                                onOpenExperiences: onOpenExperiences
                            )
                        }
                    }
                }

                suggestionSection
            }
            .padding(20)
        }
        .navigationTitle("Murco Loyalty")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.neutral)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                PremiumIconBubble(systemImage: wallet.currentLevel.systemImage, selected: true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Nivel \(wallet.currentLevel.title)")
                        .font(.title2.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(wallet.currentLevel.badgeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Text("Consumo acumulado: \(wallet.totalSpent.priceText)")
                        .font(.caption.bold())
                        .foregroundStyle(palette.primary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                HomeMiniPricePill(title: "Puntos", value: "\(wallet.points)")
                HomeMiniPricePill(title: "Premios", value: "\(rewards.count)")
                HomeMiniPricePill(title: "Nivel", value: wallet.currentLevel.title)
            }
        }
        .appCardStyle(.neutral)
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PremiumSectionHeader(
                title: "Dónde empezar",
                subtitle: "Accesos rápidos según lo que ya está destacado.",
                systemImage: "sparkles"
            )

            HStack(spacing: 12) {
                Button(action: onOpenRestaurant) {
                    HomeSmallCTA(
                        title: "Restaurante",
                        subtitle: "\(featuredItems.count) recomendados",
                        systemImage: "fork.knife"
                    )
                }
                .buttonStyle(.plain)

                Button(action: onOpenExperiences) {
                    HomeSmallCTA(
                        title: "Experiencias",
                        subtitle: "\(activePackages.count) combos",
                        systemImage: "mountain.2.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct HomeRewardTemplateCard: View {
    let template: LoyaltyRewardTemplate
    let onOpenRestaurant: () -> Void
    let onOpenExperiences: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PremiumIconBubble(systemImage: iconName, selected: true)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        BrandBadge(theme: .neutral, title: template.scope.title, selected: true)
                        BrandBadge(theme: .neutral, title: template.minimumLevel.title)
                    }

                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(template.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Text(template.displaySummary)
                        .font(.caption.bold())
                        .foregroundStyle(palette.primary)
                }

                Spacer()
            }

            if let expirationText = template.expirationText {
                HomeIconLine(systemImage: "clock", text: expirationText)
            }

            HStack(spacing: 10) {
                if template.scope.matchesRestaurant() {
                    Button(action: onOpenRestaurant) {
                        Label("Usar en restaurante", systemImage: "fork.knife")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if template.scope.matchesAdventure() {
                    Button(action: onOpenExperiences) {
                        Label("Usar en aventura", systemImage: "mountain.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch template.rule.type {
        case .mostExpensiveMenuItemPercentage, .specificMenuItemPercentage:
            return "percent"
        case .activityPercentage:
            return "mountain.2.fill"
        case .freeMenuItem:
            return "gift.fill"
        case .buyXGetYFree:
            return "plus.forwardslash.minus"
        }
    }
}

// MARK: - Shared Home UI

private struct HomeIconLine: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .frame(width: 16)
                .padding(.top, 2)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
    }
}

private struct HomeMiniPricePill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HomeTotalRow: View {
    let title: String
    let value: Double
    var primary: Bool = false
    var accent: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(primary ? .headline : .subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.priceText)
                .font(primary ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(accent ? .green : .primary)
                .monospacedDigit()
        }
    }
}

private struct HomeSmallCTA: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PremiumIconBubble(systemImage: systemImage, selected: true)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text("Abrir")
                    .font(.caption.bold())
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct HomeMissingContentView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
