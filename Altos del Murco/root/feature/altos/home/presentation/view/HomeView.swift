//
//  HomeView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: MainTab
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel

    @StateObject private var catalogViewModel = AdventureCatalogViewModel(service: AdventureCatalogService())

    private var profile: ClientProfile? { sessionViewModel.authenticatedProfile }

    private var featuredItems: [MenuItem] {
        menuViewModel.state.sections
            .flatMap(\.items)
            .filter(\.isFeatured)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name < $1.name
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
        }
        .onAppear {
            menuViewModel.onAppear()
            if let nationalId = profile?.nationalId {
                menuViewModel.setNationalId(nationalId)
            }
            catalogViewModel.onAppear()
        }
        .onDisappear {
            catalogViewModel.onDisappear()
        }
        .onChange(of: profile?.nationalId) { _, nationalId in
            if let nationalId { menuViewModel.setNationalId(nationalId) }
        }
    }

    private var heroSection: some View {
        let firstName = profile?.fullName.split(separator: " ").first.map(String.init)
        let title = firstName.map { "Hola, \($0). Vive Altos del Murco." } ?? "Vive Altos del Murco."

        return PremiumHero(
            title: title,
            subtitle: "Pide comida, reserva experiencias, arma combos con comida incluida y aprovecha premios Murco Loyalty desde una sola cuenta.",
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
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                PremiumMetricTile(title: "Platos destacados", value: "\(featuredItems.count)", systemImage: "fork.knife")
                PremiumMetricTile(title: "Combos activos", value: "\(catalogViewModel.state.catalog.activePackagesSorted.count)", systemImage: "mountain.2.fill")
            }
            HStack(spacing: 12) {
                PremiumMetricTile(title: "Premios", value: "\(menuViewModel.state.rewardWalletSnapshot.availableTemplates.filter { !$0.isExpired }.count)", systemImage: "gift.fill")
                Button { selectedTab = .bookings } label: {
                    PremiumMetricTile(title: "Reservas", value: "Ver agenda", systemImage: "calendar")
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var restaurantRecommendations: some View {
        if !featuredItems.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                PremiumSectionHeader(
                    title: "Recomendados del restaurante",
                    subtitle: "Platos destacados para pedir más rápido.",
                    systemImage: "fork.knife"
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(featuredItems.prefix(8)) { item in
                            Button { selectedTab = .restaurant } label: {
                                HomeFeaturedMenuCard(item: item)
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
        let packages = catalogViewModel.state.catalog.activePackagesSorted

        if !packages.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                PremiumSectionHeader(
                    title: "Combos de experiencias",
                    subtitle: "Primero mostramos los planes completos para que reservar sea más fácil.",
                    systemImage: "figure.hiking"
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(packages.prefix(4)) { package in
                    Button {
                        selectedTab = .experiences
                    } label: {
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

private struct HomeFeaturedMenuCard: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PremiumIconBubble(systemImage: "fork.knife")
            Text(item.name)
                .font(.headline)
                .lineLimit(2)
            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 8) {
                if item.hasOffer {
                    Text(item.price.priceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
                Text(item.finalPrice.priceText)
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
            Text(item.canBeOrdered ? "Disponible hoy" : "No disponible hoy / reservas futuras")
                .font(.caption.bold())
                .foregroundStyle(item.canBeOrdered ? .green : .red)
        }
        .padding(16)
        .frame(width: 220, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct HomePackageCard: View {
    let package: AdventureFeaturedPackage
    let catalog: AdventureCatalogSnapshot
    let menuSections: [MenuSection]
    let reward: RewardPresentation?

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
        min(package.packageDiscountAmount, subtotal)
    }

    private var finalTotal: Double {
        max(0, subtotal - comboDiscount)
    }

    private var hasSavings: Bool {
        comboDiscount > 0
    }

    private var totalSavings: Double {
        comboDiscount
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
                    Text("Total final")
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
            .frame(maxWidth: .infinity)
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
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            PremiumIconBubble(
                systemImage: "mountain.2.fill",
                selected: true
            )
            .fixedSize()

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(package.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(2)

                    Spacer(minLength: 8)

                    if let badge = package.badge, !badge.isEmpty {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.12))
                            )
                            .fixedSize()
                    }
                }

                Text(package.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var packageBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            CompactPriceLine(
                title: "Aventura",
                value: activitySubtotal.priceText
            )

            if foodSubtotal > 0 {
                CompactPriceLine(
                    title: "Comida incluida",
                    value: foodSubtotal.priceText
                )
            }

            CompactPriceLine(
                title: "Subtotal",
                value: subtotal.priceText
            )

            if comboDiscount > 0 {
                CompactPriceLine(
                    title: "Descuento combo",
                    value: "-\(comboDiscount.priceText)",
                    valueColor: .green
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CompactPriceLine: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
