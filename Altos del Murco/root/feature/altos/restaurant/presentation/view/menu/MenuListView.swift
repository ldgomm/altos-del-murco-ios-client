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
        sections
            .flatMap(\.items)
            .filter(\.isFeatured)
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Restaurante")
        .navigationBarTitleDisplayMode(.large)
        .appScreenStyle(.restaurant)
        .task {
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }

            if let nationalId = sessionViewModel.authenticatedProfile?.nationalId {
                menuViewModel.setNationalId(nationalId)
            }
        }
        .onAppear {
            menuViewModel.onAppear()

            if let nationalId = sessionViewModel.authenticatedProfile?.nationalId {
                menuViewModel.setNationalId(nationalId)
            }
        }
        .onChange(of: sessionViewModel.authenticatedProfile?.nationalId) { _, nationalId in
            guard let nationalId else { return }
            menuViewModel.setNationalId(nationalId)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    OrdersView(viewModel: ordersViewModel)
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
                    rewardPresentation: menuViewModel.rewardPresentation(for: item)
                )
            case .cart:
                CartView()
            case .checkout:
                CheckoutView(viewModel: checkoutViewModel, path: $path)
            case .reservationBuilder:
                AdventureComboBuilderView(
                    adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                    menuViewModel: menuViewModel
                )
                .onAppear {
                    adventureComboBuilderViewModel.resetForFoodOnly()
                }
            case let .orderSuccess(order):
                OrderSuccessView(order: order, path: $path)
            }
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
                        VStack(alignment: .leading, spacing: 10) {
                            FeaturedMenuCard(item: item)

                            if let reward = menuViewModel.rewardPresentation(for: item) {
                                rewardHintCard(reward)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 255)
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
                    NavigationLink(value: Route.menuDetail(item, section.category.title)) {
                        VStack(alignment: .leading, spacing: 10) {
                            MenuItemRowView(item: item)

                            if let reward = menuViewModel.rewardPresentation(for: item) {
                                rewardHintCard(reward)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryTitle(for categoryId: String) -> String {
        categories.first(where: { $0.id == categoryId })?.title ?? ""
    }

    private func rewardHintCard(_ reward: RewardPresentation) -> some View {
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}
