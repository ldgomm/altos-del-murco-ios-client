//
//  MenuListView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuListView: View {
    let sections: [MenuSection]

    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @Binding var path: NavigationPath

    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategoryId: String?

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private let categoryDisplayOrder: [String] = [
        "Entradas",
        "Sopas",
        "Platos Fuertes",
        "Extras",
        "Postres",
        "Bebidas",
        "Bebidas Alcohólicas"
    ]

    private var authenticatedNationalId: String {
        sessionViewModel.authenticatedProfile?.id ?? ""
    }

    private func categoryRank(for title: String) -> Int {
        categoryDisplayOrder.firstIndex(of: title) ?? Int.max
    }

    private var orderedSections: [MenuSection] {
        sections.sorted { lhs, rhs in
            let lhsRank = categoryRank(for: lhs.category.title)
            let rhsRank = categoryRank(for: rhs.category.title)

            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.category.title < rhs.category.title
        }
    }

    private var categories: [MenuCategory] {
        orderedSections.map(\.category)
    }

    private var filteredSections: [MenuSection] {
        guard let selectedCategoryId else { return orderedSections }
        return orderedSections.filter { $0.category.id == selectedCategoryId }
    }

    private var featuredItems: [MenuItem] {
        orderedSections
            .flatMap(\.items)
            .filter(\.isFeatured)
    }

    private var appliedDiscountAmount: Double {
        checkoutViewModel.state.rewardPreview.discountAmount
    }

    private var effectiveCartTotal: Double {
        checkoutViewModel.effectiveTotal(for: cartManager.subtotal)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if !featuredItems.isEmpty {
                    featuredCarousel
                }

                categorySelector

                ForEach(filteredSections) { section in
                    sectionContent(section)
                }
                rewardsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Sabor de Los Altos")
        .navigationBarTitleDisplayMode(.large)
        .appScreenStyle(.restaurant)
        .task {
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }

            syncIdentityAndRefreshRewards()
        }
        .onAppear {
            menuViewModel.onAppear()
            syncIdentityAndRefreshRewards()
        }
        .onChange(of: sessionViewModel.authenticatedProfile?.id) { _, _ in
            syncIdentityAndRefreshRewards()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    ProtectedAccessRequiredView(
                        title: "Inicia sesión para ver tus pedidos",
                        message: "El historial de pedidos pertenece a tu cuenta. Puedes seguir explorando el menú sin iniciar sesión.",
                        systemImage: "list.bullet.clipboard.fill",
                        theme: .restaurant
                    ) {
                        OrdersView(viewModel: ordersViewModel)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(palette.chipGradient)
                            .frame(width: 34, height: 34)

                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(palette.primary)
                    }
                }

                NavigationLink(value: Route.cart) {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            Circle()
                                .fill(palette.chipGradient)
                                .frame(width: 34, height: 34)

                            Image(systemName: "cart.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(palette.primary)
                        }

                        if cartManager.totalItems > 0 {
                            Text("\(cartManager.totalItems)")
                                .font(.system(size: 9, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .padding(.horizontal, cartManager.totalItems > 9 ? 4 : 0)
                                .background(palette.destructive)
                                .clipShape(Capsule())
                                .offset(x: 5, y: -4)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case let .menuDetail(item, categoryTitle):
                MenuItemDetailView(
                    item: item,
                    categoryTitle: categoryTitle,
                    rewardPresentationProvider: { menuItem, quantity in
                        menuViewModel.rewardPresentation(for: menuItem, quantity: quantity)
                    },
                    displayedPriceProvider: { menuItem, quantity in
                        menuViewModel.displayedPrice(for: menuItem, quantity: quantity)
                    },
                    incrementalDiscountProvider: { menuItem, quantity in
                        menuViewModel.incrementalDiscount(for: menuItem, quantity: quantity)
                    }
                )
            case .cart:
                CartView(
                    viewModel: checkoutViewModel,
                    nationalId: authenticatedNationalId
                )

            case .checkout:
                ProtectedAccessRequiredView(
                    title: "Inicia sesión para finalizar tu pedido",
                    message: "Puedes ver el menú y agregar productos sin cuenta. Para crear un pedido real necesitamos verificar tu sesión y solicitar los datos obligatorios del pedido.",
                    systemImage: "cart.fill",
                    theme: .restaurant
                ) {
                    CheckoutView(viewModel: checkoutViewModel, path: $path)
                }

            case .reservationBuilder:
                ProtectedAccessRequiredView(
                    title: "Inicia sesión para reservar comida",
                    message: "Puedes explorar el menú sin cuenta. Para crear una reserva real necesitamos tu sesión y los datos del servicio.",
                    systemImage: "calendar.badge.plus",
                    theme: .restaurant
                ) {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.prepareFoodOnlyDraftIfNeeded()
                    }
                }

            case let .orderSuccess(order):
                OrderSuccessView(order: order, path: $path)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !cartManager.isEmpty {
                bottomCartBar
            }
        }
    }

    private func syncIdentityAndRefreshRewards() {
        let nationalId = authenticatedNationalId
        menuViewModel.setNationalId(nationalId)
        checkoutViewModel.onAppear(nationalId: nationalId)
    }

    @ViewBuilder
    private var rewardsSection: some View {
        let templates = menuViewModel.restaurantRewardTemplates

        if !templates.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Tus cupones y premios",
                    subtitle: "Aquí puedes ver qué premio tienes, cuándo vence y a qué plato o promo aplica."
                )

                if menuViewModel.state.isLoadingRewards {
                    ProgressView("Actualizando premios...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }

                ForEach(templates) { template in
                    rewardCouponCard(template)
                }
            }
        }
    }

    private func rewardCouponCard(_ template: LoyaltyRewardTemplate) -> some View {
        let eligibleItems = menuViewModel.eligibleMenuItems(for: template)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                BrandBadge(
                    theme: .restaurant,
                    title: badgeText(for: template),
                    selected: true
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(template.subtitle.isEmpty ? template.displaySummary : template.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()
            }

            if let expirationText = menuViewModel.expirationText(for: template) {
                Label(expirationText, systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.warning)
            }

            if !eligibleItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elige un plato elegible")
                        .font(.caption.bold())
                        .foregroundStyle(palette.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(eligibleItems) { item in
                                NavigationLink(value: Route.menuDetail(item, categoryTitle(for: item.categoryId))) {
                                    Text(item.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(palette.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(palette.chipGradient)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(palette.stroke, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else if template.rule.type == .mostExpensiveMenuItemPercentage {
                Text("Agrega el plato elegible más caro que quieras y el descuento se calculará automáticamente sobre ese plato.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private func badgeText(for template: LoyaltyRewardTemplate) -> String {
        switch template.rule.type {
        case .freeMenuItem:
            return "Gratis"
        case .specificMenuItemPercentage, .mostExpensiveMenuItemPercentage:
            return "\(Int((template.rule.percentage ?? 0).rounded()))% OFF"
        case .buyXGetYFree:
            return "Promo"
        case .activityPercentage:
            return "Aventura"
        }
    }

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Popular",
                subtitle: "Favoritos de los clientes y platos destacados"
            )

            TabView {
                ForEach(featuredItems) { item in
                    NavigationLink(value: Route.menuDetail(item, categoryTitle(for: item.categoryId))) {
                        FeaturedMenuCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 220)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }

    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Explorar por categoría"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategoryId = category.id
                            }
                        } label: {
                            BrandBadge(
                                theme: .restaurant,
                                title: category.title,
                                selected: selectedCategoryId == category.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private func sectionContent(_ section: MenuSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: section.category.title
            )

            LazyVStack(spacing: 12) {
                ForEach(section.items) { item in
                    if item.isAvailable {
                        NavigationLink(value: Route.menuDetail(item, section.category.title)) {
                            VStack(alignment: .leading, spacing: 10) {
                                MenuItemRowView(item: item)
                                
                                if let appliedReward = checkoutViewModel.appliedRewardPresentation(forMenuItemId: item.id) {
                                    appliedRewardCard(appliedReward)
                                } else if let availableReward = menuViewModel.rewardPresentation(for: item) {
                                    availableRewardCard(availableReward)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func categoryTitle(for categoryId: String) -> String {
        categories.first(where: { $0.id == categoryId })?.title ?? ""
    }

    private func availableRewardCard(_ reward: RewardPresentation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrandBadge(theme: .restaurant, title: reward.badge, selected: true)

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

    private func appliedRewardCard(_ reward: RewardPresentation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrandBadge(theme: .restaurant, title: "Aplicado", selected: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(reward.message)
                    .font(.caption)
                    .foregroundStyle(palette.success)
            }

            Spacer()

            if let amountText = reward.amountText {
                Text("-\(amountText)")
                    .font(.caption.bold())
                    .foregroundStyle(palette.success)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.success.opacity(colorScheme == .dark ? 0.14 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.success.opacity(0.25), lineWidth: 1)
        )
    }

    private var bottomCartBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu pedido")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)

                    if appliedDiscountAmount > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Subtotal \(cartManager.subtotal.priceText)")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)

                            Text("Murco Loyalty -\(appliedDiscountAmount.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.success)

                            Text(effectiveCartTotal.priceText)
                                .font(.title3.bold())
                                .foregroundStyle(palette.textPrimary)
                        }
                    } else {
                        Text(cartManager.subtotal.priceText)
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)
                    }
                }

                Spacer()

                NavigationLink(value: Route.cart) {
                    Text("Ver carrito")
                        .font(.headline)
                        .frame(minWidth: 140)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(palette.primary)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }
}
