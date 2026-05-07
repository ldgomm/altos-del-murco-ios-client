//
//  MenuListView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

enum RestaurantMenuRoute: Hashable {
    case menuDetail(MenuItem, String)
}

private struct DishGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let items: [MenuItem]
}

private struct MenuStep: Identifiable, Hashable {
    let id: String
    let number: Int
    let category: MenuCategory
    let itemCount: Int

    var subtitle: String {
        switch category.title {
        case "Entradas": return "Abre el apetito"
        case "Sopas": return "Caliente y serrano"
        case "Platos Fuertes": return "Especialidades"
        case "Extras": return "Completa la mesa"
        case "Postres": return "Final dulce"
        case "Bebidas": return "Refrescantes"
        case "Bebidas Alcohólicas": return "Para acompañar"
        default: return "Explorar"
        }
    }
}

struct MenuListView: View {
    let sections: [MenuSection]

    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @Binding var path: NavigationPath

    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategoryId: String?
    @State private var searchText = ""

    init(
        sections: [MenuSection],
        checkoutViewModel: CheckoutViewModel,
        ordersViewModel: OrdersViewModel,
        menuViewModel: MenuViewModel,
        path: Binding<NavigationPath>
    ) {
        self.sections = sections
        self.checkoutViewModel = checkoutViewModel
        self.ordersViewModel = ordersViewModel
        self.menuViewModel = menuViewModel
        self._path = path
    }

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

    private var orderedSections: [MenuSection] {
        sections
            .map { section in
                MenuSection(
                    id: section.id,
                    category: section.category,
                    items: section.items.sorted {
                        if $0.isFeatured != $1.isFeatured { return $0.isFeatured && !$1.isFeatured }
                        if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                )
            }
            .sorted { lhs, rhs in
                let lhsRank = categoryDisplayOrder.firstIndex(of: lhs.category.title) ?? Int.max
                let rhsRank = categoryDisplayOrder.firstIndex(of: rhs.category.title) ?? Int.max
                if lhsRank != rhsRank { return lhsRank < rhsRank }
                return lhs.category.title < rhs.category.title
            }
    }

    private var categories: [MenuCategory] {
        orderedSections.map(\.category)
    }

    private var menuSteps: [MenuStep] {
        orderedSections.enumerated().map { index, section in
            MenuStep(
                id: section.category.id,
                number: index + 1,
                category: section.category,
                itemCount: section.items.filter(\.isAvailable).count
            )
        }
    }

    private var allItems: [MenuItem] {
        orderedSections.flatMap(\.items)
    }

    private var selectedCategory: MenuCategory? {
        guard let selectedCategoryId else { return categories.first }
        return categories.first(where: { $0.id == selectedCategoryId }) ?? categories.first
    }

    private var selectedSection: MenuSection? {
        guard let category = selectedCategory else { return orderedSections.first }
        return orderedSections.first(where: { $0.category.id == category.id }) ?? orderedSections.first
    }

    private var cleanSearchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool {
        !cleanSearchQuery.isEmpty
    }

    private var filteredSearchItems: [MenuItem] {
        guard isSearching else { return [] }

        let query = cleanSearchQuery
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()

        return allItems
            .filter { item in
                normalizedSearchText(for: item).contains(query)
            }
            .sorted {
                if $0.canBeOrdered != $1.canBeOrdered { return $0.canBeOrdered && !$1.canBeOrdered }
                if $0.isFeatured != $1.isFeatured { return $0.isFeatured && !$1.isFeatured }
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var featuredItems: [MenuItem] {
        allItems
            .filter { $0.isFeatured && $0.canBeOrdered }
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var restaurantRewards: [LoyaltyRewardTemplate] {
        menuViewModel.state.rewardWalletSnapshot.availableTemplates
            .filter { $0.scope.matchesRestaurant() }
            .filter { !$0.isExpired }
            .sorted {
                if $0.priority != $1.priority { return $0.priority < $1.priority }
                return $0.title < $1.title
            }
    }


    private var selectedDishGroups: [DishGroup] {
        guard let section = selectedSection else { return [] }
        return DishMenuGrouper.groups(for: section)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    heroSection
                    searchSection

                    if isSearching {
                        searchResultsSection
                    } else {
//                        if !featuredItems.isEmpty { featuredSection }
                        categoryJourneySection(scrollProxy: proxy)
                        selectedCategoryContent
                    }

                    rewardsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
        }
        .navigationTitle("Sabor de Los Altos")
        .navigationBarTitleDisplayMode(.large)
        .appScreenStyle(.restaurant)
        .task {
            setFirstCategoryIfNeeded()
            syncIdentityAndRefreshRewards()
        }
        .onAppear {
            menuViewModel.onAppear()
            setFirstCategoryIfNeeded()
            syncIdentityAndRefreshRewards()
        }
        .onChange(of: sections) { _, _ in
            setFirstCategoryIfNeeded()
        }
        .onChange(of: sessionViewModel.authenticatedProfile?.id) { _, _ in
            syncIdentityAndRefreshRewards()
        }
        .toolbar { toolbarContent }
        .navigationDestination(for: RestaurantMenuRoute.self) { route in
            switch route {
            case let .menuDetail(item, categoryTitle):
                MenuItemDetailView(
                    item: item,
                    categoryTitle: categoryTitle,
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
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(palette.heroGradient)
                .shadow(color: palette.shadow.opacity(0.22), radius: 24, y: 14)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 148, height: 148)
                .offset(x: 230, y: -70)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Elige con antojo")
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)

                        Text("Busca rápido o avanza paso a paso: entrada, sopa, plato fuerte, extra, postre y bebida.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.96))
                }

                HStack(spacing: 9) {
                    HeroMicroBadge(title: "Sin pestaña Todo", systemImage: "square.grid.2x2")
                    HeroMicroBadge(title: "Buscar", systemImage: "magnifyingglass")
                    HeroMicroBadge(title: "Fotos", systemImage: "photo.fill")
                }
            }
            .padding(22)
        }
    }

    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.headline)
                .foregroundStyle(palette.primary)

            TextField("Buscar cuy, parrillada, sopa, bebida...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(color: palette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.06), radius: 12, y: 8)
    }


//    private var featuredSection: some View {
//        VStack(alignment: .leading, spacing: 14) {
//            BrandSectionHeader(
//                theme: .restaurant,
//                title: "Primer antojo",
//                subtitle: "Platos destacados para decidir en segundos."
//            )
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 14) {
//                    ForEach(featuredItems.prefix(8)) { item in
//                        Button {
//                            path.append(RestaurantMenuRoute.menuDetail(item, categoryTitle(for: item.categoryId)))
//                        } label: {
//                            PremiumDishHeroCard(item: item, reward: reward(for: item))
//                        }
//                        .buttonStyle(.plain)
//                    }
//                }
//            }
//        }
//    }

    private func categoryJourneySection(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Ordena paso a paso",
                subtitle: "No más una lista eterna: toca el paso y mira solo lo que toca."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(menuSteps) { step in
                        Button {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                                selectedCategoryId = step.category.id
                                scrollProxy.scrollTo("category-content", anchor: .top)
                            }
                        } label: {
                            CategoryStepCard(
                                step: step,
                                selected: selectedCategory?.id == step.category.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var selectedCategoryContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let section = selectedSection {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: section.category.title,
                    subtitle: selectedCategorySubtitle(for: section.category.title)
                )
                .id("category-content")

                if selectedDishGroups.isEmpty {
                    emptyCategoryState
                } else {
                    ForEach(selectedDishGroups) { group in
                        DishGroupBlock(
                            group: group,
                            categoryTitle: section.category.title,
                            rewardProvider: reward(for:),
                            onOpen: { item in
                                path.append(RestaurantMenuRoute.menuDetail(item, section.category.title))
                            }
                        )
                    }
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: filteredSearchItems.isEmpty ? "Sin resultados" : "Resultados",
                subtitle: filteredSearchItems.isEmpty
                    ? "No encontré \"\(cleanSearchQuery)\". Prueba con cuy, parrillada, sopa o bebida."
                    : "Encontré \(filteredSearchItems.count) coincidencia(s) para \"\(cleanSearchQuery)\"."
            )

            if filteredSearchItems.isEmpty {
                emptySearchState
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(filteredSearchItems) { item in
                        Button {
                            path.append(RestaurantMenuRoute.menuDetail(item, categoryTitle(for: item.categoryId)))
                        } label: {
                            PremiumDishTile(item: item, reward: reward(for: item))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let rewards = restaurantRewards

            if !rewards.isEmpty {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Beneficios disponibles",
                    subtitle: "Se aplican automáticamente en platos elegibles."
                )

                ForEach(rewards.prefix(3)) { reward in
                    HStack(spacing: 12) {
                        BrandBadge(theme: .restaurant, title: badgeText(for: reward), selected: true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(reward.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            Text(reward.subtitle.ifBlank(reward.displaySummary))
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }

                        Spacer()
                    }
                    .appCardStyle(.restaurant, emphasized: false)
                }
            }
        }
    }

    private var emptyCategoryState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(palette.primary)

            Text("No hay platos disponibles en este paso por ahora.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private var emptySearchState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                BrandIconBubble(theme: .restaurant, systemImage: "text.magnifyingglass", size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Busca por nombre, ingrediente o categoría")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text("Ejemplos: costilla, cuy, sopa, jugo, parrillada.")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                Image(systemName: "list.bullet.clipboard.fill")
            }

            NavigationLink {
                ProtectedAccessRequiredView(
                    title: "Inicia sesión para finalizar tu pedido",
                    message: "Puedes explorar el menú libremente. Para enviar el pedido necesitamos tu cuenta.",
                    systemImage: "cart.fill",
                    theme: .restaurant
                ) {
                    CartView(viewModel: checkoutViewModel)
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill")

                    if cartManager.totalItems > 0 {
                        Text("\(cartManager.totalItems)")
                            .font(.caption2.bold())
                            .padding(4)
                            .background(Circle().fill(palette.accent))
                            .foregroundStyle(.white)
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
    }

    private func setFirstCategoryIfNeeded() {
        let fallbackId = categories.first?.id

        if selectedCategoryId == nil {
            selectedCategoryId = fallbackId
            return
        }

        if let selectedCategoryId,
           !categories.contains(where: { $0.id == selectedCategoryId }) {
            self.selectedCategoryId = fallbackId
        }
    }

    private func syncIdentityAndRefreshRewards() {
        if let profile = sessionViewModel.authenticatedProfile {
            cartManager.updateClientName(profile.fullName)

            if cartManager.whatsappNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cartManager.updateWhatsappNumber(profile.phoneNumber)
            }
        }

        Task {
            await checkoutViewModel.refreshRewardPreview()
        }
    }

    private func reward(for item: MenuItem) -> RewardPresentation? {
        checkoutViewModel.appliedRewardPresentation(forMenuItemId: item.id)
        ?? menuViewModel.rewardPresentation(for: item)
    }

    private func categoryTitle(for categoryId: String) -> String {
        categories.first(where: { $0.id == categoryId })?.title ?? "Menú"
    }

    private func selectedCategorySubtitle(for title: String) -> String {
        switch title {
        case "Entradas": return "Empieza liviano: algo pequeño para abrir el apetito."
        case "Sopas": return "Caliente, serrano y perfecto para llegar con hambre."
        case "Platos Fuertes": return "Agrupado por intención: compartir, especialidades y más opciones."
        case "Extras": return "Complementos para que la mesa quede completa."
        case "Postres": return "Un cierre dulce después de la comida o la aventura."
        case "Bebidas": return "Elige bebidas desde el inicio para tener todo listo."
        case "Bebidas Alcohólicas": return "Opciones para acompañar con responsabilidad."
        default: return "Selecciona una opción y mira detalles antes de agregar."
        }
    }

    private func normalizedSearchText(for item: MenuItem) -> String {
        ([item.name, item.description, item.categoryTitle] + item.ingredients)
            .joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
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
}

private enum DishMenuGrouper {
    static func groups(for section: MenuSection) -> [DishGroup] {
        let items = section.items
            .filter(\.isAvailable)
            .sorted {
                if $0.isFeatured != $1.isFeatured { return $0.isFeatured && !$1.isFeatured }
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        guard !items.isEmpty else { return [] }

        if section.category.title == "Platos Fuertes" {
            let share = items.filter {
                matches($0, ["parrillada", "familiar", "para dos", "compartir", "altos"])
            }

            let house = items.filter {
                matches($0, ["cuy", "borrego", "costilla", "jack", "andina"])
                && !containsItem($0, in: share)
            }

            let classic = items.filter {
                !containsItem($0, in: share) && !containsItem($0, in: house)
            }

            return [
                DishGroup(
                    id: "share",
                    title: "Para compartir",
                    subtitle: "Parrilladas y platos grandes para pareja, familia o amigos.",
                    items: share
                ),
                DishGroup(
                    id: "house",
                    title: "Especialidades de la casa",
                    subtitle: "Lo más representativo de Los Altos: tradición, sabor y platos fuertes.",
                    items: house
                ),
                DishGroup(
                    id: "classic",
                    title: "Más opciones fuertes",
                    subtitle: "Otros platos para completar la elección sin bajar una pared infinita.",
                    items: classic
                )
            ]
            .filter { !$0.items.isEmpty }
        }

        let featured = items.filter { $0.isFeatured || $0.hasOffer }
        let rest = items.filter { !containsItem($0, in: featured) }

        if featured.isEmpty {
            return [
                DishGroup(
                    id: section.id,
                    title: "Opciones disponibles",
                    subtitle: "\(items.count) opción(es) para este paso.",
                    items: items
                )
            ]
        }

        return [
            DishGroup(
                id: "featured",
                title: "Recomendados",
                subtitle: "Los más atractivos de esta categoría.",
                items: featured
            ),
            DishGroup(
                id: "all",
                title: "También puedes pedir",
                subtitle: "Más opciones disponibles para completar la mesa.",
                items: rest
            )
        ]
        .filter { !$0.items.isEmpty }
    }

    private static func matches(_ item: MenuItem, _ keys: [String]) -> Bool {
        let text = ([item.name, item.description] + item.ingredients)
            .joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()

        return keys.contains { key in
            text.contains(
                key.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            )
        }
    }

    private static func containsItem(_ item: MenuItem, in items: [MenuItem]) -> Bool {
        items.contains { $0.id == item.id }
    }
}

private struct HeroMicroBadge: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.14))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }
}

private struct CategoryStepCard: View {
    let step: MenuStep
    let selected: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .restaurant, scheme: colorScheme)

        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text("\(step.number)")
                    .font(.caption.bold())
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(selected ? palette.onPrimary.opacity(0.18) : palette.primary.opacity(0.12))
                    )

                Spacer()

                Text("\(step.itemCount)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(selected ? palette.onPrimary.opacity(0.14) : palette.elevatedCard)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(step.category.title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(2)

                Text(step.subtitle)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(selected ? palette.onPrimary.opacity(0.84) : palette.textSecondary)
            }
        }
        .frame(width: 150, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(selected ? palette.primary : palette.card)
        )
        .foregroundStyle(selected ? palette.onPrimary : palette.textPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(selected ? Color.clear : palette.stroke, lineWidth: 1)
        )
        .shadow(color: palette.shadow.opacity(selected ? 0.18 : 0.06), radius: selected ? 14 : 8, y: 8)
    }
}

private struct DishGroupBlock: View {
    let group: DishGroup
    let categoryTitle: String
    let rewardProvider: (MenuItem) -> RewardPresentation?
    let onOpen: (MenuItem) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .restaurant, scheme: colorScheme)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(palette.textPrimary)

                    if !group.subtitle.isEmpty {
                        Text(group.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                }

                Spacer()

                Text("\(group.items.count)")
                    .font(.caption.bold())
                    .foregroundStyle(palette.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(palette.primary.opacity(0.10)))
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(group.items) { item in
                    Button {
                        onOpen(item)
                    } label: {
                        PremiumDishTile(item: item, reward: rewardProvider(item))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(palette.elevatedCard.opacity(colorScheme == .dark ? 0.60 : 0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}

private struct PremiumDishTile: View {
    let item: MenuItem
    let reward: RewardPresentation?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .restaurant, scheme: colorScheme)

        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                imageLayer(height: 126)

                VStack(alignment: .leading, spacing: 6) {
                    if item.isFeatured {
                        Text("Popular")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.black.opacity(0.34)))
                    }

                    if item.hasOffer {
                        Text("Oferta")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(palette.accent.opacity(0.88)))
                    }
                }
                .padding(8)
            }

            Text(item.name)
                .font(.subheadline.weight(.black))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(item.description)
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                if item.hasOffer {
                    Text(item.price.priceText)
                        .strikethrough()
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Text(item.finalPrice.priceText)
                    .font(.headline.bold())
                    .foregroundStyle(palette.primary)

                Spacer(minLength: 0)
            }

            if let reward {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                    Text(reward.badge)
                        .lineLimit(1)
                }
                .font(.caption2.bold())
                .foregroundStyle(palette.accent)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.07), radius: 10, y: 6)
        .opacity(item.canBeOrdered ? 1 : 0.58)
    }

    @ViewBuilder
    private func imageLayer(height: CGFloat) -> some View {
        let palette = AppTheme.palette(for: .restaurant, scheme: colorScheme)

        if let imageURL = item.imageURL,
           let url = URL(string: imageURL) {
            RemoteImageView(
                url: url,
                contentMode: .fill,
                targetPixelSize: CGSize(width: 260, height: height * 2)
            ) {
                placeholder
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            placeholder
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var placeholder: some View {
        let palette = AppTheme.palette(for: .restaurant, scheme: colorScheme)

        return ZStack {
            palette.chipGradient
            VStack(spacing: 7) {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(palette.primary)
                Text(item.name)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
        }
    }
}

private struct PremiumDishHeroCard: View {
    let item: MenuItem
    let reward: RewardPresentation?

    var body: some View {
        PremiumDishTile(item: item, reward: reward)
            .frame(width: 214)
    }
}

private extension String {
    func ifBlank(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
