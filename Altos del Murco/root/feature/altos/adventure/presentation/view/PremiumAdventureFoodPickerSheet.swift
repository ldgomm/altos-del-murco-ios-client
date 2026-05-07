//
//  PremiumAdventureFoodPickerSheet.swift
//  Altos del Murco
//
//  Created by José Ruiz on 6/5/26.
//

import SwiftUI

struct AdventureFoodPickerSheet: View {
    let menuSections: [MenuSection]
    let selectedDate: Date
    let rewardPresentationProvider: (MenuItem, Int) -> RewardPresentation?
    let displayedPriceProvider: (MenuItem, Int) -> Double
    let incrementalDiscountProvider: (MenuItem, Int) -> Double
    let onAdd: (MenuItem, Int, String?) -> Void

    var body: some View {
        PremiumAdventureFoodPickerSheet(
            menuSections: menuSections,
            selectedDate: selectedDate,
            rewardPresentationProvider: rewardPresentationProvider,
            displayedPriceProvider: displayedPriceProvider,
            incrementalDiscountProvider: incrementalDiscountProvider,
            onAdd: onAdd
        )
    }
}

private struct AdventureFoodStep: Identifiable, Hashable {
    let id: String
    let number: Int
    let category: MenuCategory
    let itemCount: Int

    var subtitle: String {
        switch category.title {
        case "Entradas": return "Para abrir"
        case "Sopas": return "Calientitas"
        case "Platos Fuertes": return "La estrella"
        case "Extras": return "Complementos"
        case "Postres": return "Final dulce"
        case "Bebidas": return "Refrescos"
        case "Bebidas Alcohólicas": return "Acompañantes"
        default: return "Explorar"
        }
    }
}

private struct AdventureFoodGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let items: [MenuItem]
}

struct PremiumAdventureFoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let menuSections: [MenuSection]
    let selectedDate: Date
    let rewardPresentationProvider: (MenuItem, Int) -> RewardPresentation?
    let displayedPriceProvider: (MenuItem, Int) -> Double
    let incrementalDiscountProvider: (MenuItem, Int) -> Double
    let onAdd: (MenuItem, Int, String?) -> Void

    @State private var selectedCategoryId: String?
    @State private var searchText = ""

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
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
        menuSections
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
                return lhs.category.title.localizedCaseInsensitiveCompare(rhs.category.title) == .orderedAscending
            }
    }

    private var categories: [MenuCategory] {
        orderedSections.map(\.category)
    }

    private var steps: [AdventureFoodStep] {
        orderedSections.enumerated().map { index, section in
            AdventureFoodStep(
                id: section.category.id,
                number: index + 1,
                category: section.category,
                itemCount: section.items.filter { foodCanBeReserved($0) }.count
            )
        }
    }

    private var allItems: [MenuItem] {
        orderedSections.flatMap(\.items)
    }

    private var selectedCategory: MenuCategory? {
        guard let selectedCategoryId else { return categories.first }
        return categories.first { $0.id == selectedCategoryId } ?? categories.first
    }

    private var selectedSection: MenuSection? {
        guard let selectedCategory else { return orderedSections.first }
        return orderedSections.first { $0.category.id == selectedCategory.id } ?? orderedSections.first
    }

    private var cleanSearchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool {
        !cleanSearchQuery.isEmpty
    }

    private var searchResults: [MenuItem] {
        guard isSearching else { return [] }

        let query = cleanSearchQuery
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()

        return allItems
            .filter { foodCanBeReserved($0) }
            .filter { normalizedSearchText(for: $0).contains(query) }
            .sorted {
                if canAddToday($0) != canAddToday($1) { return canAddToday($0) && !canAddToday($1) }
                if $0.isFeatured != $1.isFeatured { return $0.isFeatured && !$1.isFeatured }
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var featuredItems: [MenuItem] {
        allItems
            .filter { $0.isFeatured && foodCanBeReserved($0) }
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var selectedGroups: [AdventureFoodGroup] {
        guard let selectedSection else { return [] }
        return AdventureFoodGrouper.groups(for: selectedSection, allowsFutureReservation: !isTodayReservation)
    }

    private var isTodayReservation: Bool {
        AdventureDateHelper.calendar.isDateInToday(selectedDate)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        heroSection
                        searchSection

                        if isSearching {
                            searchResultsSection
                        } else {
//                            if !featuredItems.isEmpty { featuredSection }
                            categoryJourneySection(scrollProxy: proxy)
                            selectedCategoryContent
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Comida para tu visita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .appScreenStyle(.adventure)
            .task { setFirstCategoryIfNeeded() }
            .onChange(of: menuSections) { _, _ in setFirstCategoryIfNeeded() }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(palette.heroGradient)
                .shadow(color: palette.shadow.opacity(0.22), radius: 22, y: 12)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 138, height: 138)
                .offset(x: 42, y: -58)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reserva también la comida")
                            .font(.system(size: 29, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)

                        Text("Elige platos como parte de la experiencia: antes de salir, al volver de la ruta o a una hora específica.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.96))
                }

                HStack(spacing: 9) {
                    AdventureFoodHeroBadge(title: "Paso a paso", systemImage: "arrow.right.circle")
                    AdventureFoodHeroBadge(title: "Buscar", systemImage: "magnifyingglass")
                    AdventureFoodHeroBadge(title: "Fotos", systemImage: "photo.fill")
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

            TextField("Buscar plato, bebida o ingrediente...", text: $searchText)
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
    }

//    private var featuredSection: some View {
//        dishRailSection(
//            title: "Favoritos para acompañar",
//            subtitle: "Platos destacados para completar una visita premium sin pensar demasiado.",
//            items: Array(featuredItems.prefix(8))
//        )
//    }

    private func categoryJourneySection(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Arma el servicio por momentos",
                subtitle: "Primero entrada, luego sopa, plato fuerte, extras, postre y bebida. Sin una lista eterna."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(steps) { step in
                        Button {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                                selectedCategoryId = step.category.id
                                scrollProxy.scrollTo("adventure-food-category-content", anchor: .top)
                            }
                        } label: {
                            AdventureFoodStepCard(
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
            let title = selectedCategory?.title ?? "Menú"

            BrandSectionHeader(
                theme: .adventure,
                title: title,
                subtitle: selectedCategorySubtitle(for: title)
            )
            .id("adventure-food-category-content")

            if selectedGroups.isEmpty {
                emptyState(
                    title: "No hay platos disponibles",
                    message: "Prueba otra categoría o cambia la búsqueda."
                )
            } else {
                ForEach(selectedGroups) { group in
                    AdventureFoodGroupBlock(
                        group: group,
                        selectedDate: selectedDate,
                        rewardProvider: rewardPresentationProvider,
                        displayedPriceProvider: displayedPriceProvider,
                        incrementalDiscountProvider: incrementalDiscountProvider,
                        onAdd: { item, quantity, notes in
                            onAdd(item, quantity, notes)
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: searchResults.isEmpty ? "Sin resultados" : "Resultados",
                subtitle: searchResults.isEmpty
                    ? "No encontré \"\(cleanSearchQuery)\". Prueba con cuy, sopa, jugo o parrillada."
                    : "Encontré \(searchResults.count) coincidencia(s) para \"\(cleanSearchQuery)\"."
            )

            if searchResults.isEmpty {
                emptyState(
                    title: "Busca por plato o ingrediente",
                    message: "Ejemplos: costilla, cuy, sopa, jugo, parrillada."
                )
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(searchResults) { item in
                        AdventureFoodDishCard(
                            item: item,
                            selectedDate: selectedDate,
                            rewardPresentation: rewardPresentationProvider(item, 1),
                            displayedPrice: displayedPriceProvider(item, 1),
                            incrementalDiscount: incrementalDiscountProvider(item, 1),
                            onAdd: { quantity, notes in
                                onAdd(item, quantity, notes)
                                dismiss()
                            }
                        )
                    }
                }
            }
        }
    }

    private func dishRailSection(title: String, subtitle: String, items: [MenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(theme: .adventure, title: title, subtitle: subtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        AdventureFoodDishCard(
                            item: item,
                            selectedDate: selectedDate,
                            rewardPresentation: rewardPresentationProvider(item, 1),
                            displayedPrice: displayedPriceProvider(item, 1),
                            incrementalDiscount: incrementalDiscountProvider(item, 1),
                            onAdd: { quantity, notes in
                                onAdd(item, quantity, notes)
                                dismiss()
                            }
                        )
                        .frame(width: 252)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(palette.primary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            Text(message)
                .font(.caption)
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

    private func selectedCategorySubtitle(for title: String) -> String {
        switch title {
        case "Entradas": return "Algo pequeño para recibir a tus invitados antes de la experiencia."
        case "Sopas": return "Caliente, serrano y perfecto si llegan con frío o hambre."
        case "Platos Fuertes": return "Agrupado para decidir rápido sin bajar una pared infinita."
        case "Extras": return "Complementos para que la mesa quede completa."
        case "Postres": return "Un cierre dulce después de comer o después de la ruta."
        case "Bebidas": return "Bebidas listas para recibir al grupo sin improvisar."
        case "Bebidas Alcohólicas": return "Opciones para acompañar con responsabilidad."
        default: return "Selecciona lo que quieres agregar a la reserva."
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

    private func normalizedSearchText(for item: MenuItem) -> String {
        ([item.name, item.description, item.categoryTitle] + item.ingredients)
            .joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }

    private func foodCanBeReserved(_ item: MenuItem) -> Bool {
        if isTodayReservation { return item.canBeOrdered }
        return item.isAvailable
    }

    private func canAddToday(_ item: MenuItem) -> Bool {
        !isTodayReservation || item.canBeOrdered
    }
}

private enum AdventureFoodGrouper {
    static func groups(for section: MenuSection, allowsFutureReservation: Bool) -> [AdventureFoodGroup] {
        let items = section.items
            .filter { allowsFutureReservation ? $0.isAvailable : $0.canBeOrdered }
            .sorted {
                if $0.isFeatured != $1.isFeatured { return $0.isFeatured && !$1.isFeatured }
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        guard !items.isEmpty else { return [] }

        if section.category.title == "Platos Fuertes" {
            let share = items.filter { matches($0, ["parrillada", "familiar", "para dos", "compartir", "altos"]) }
            let house = items.filter {
                matches($0, ["cuy", "borrego", "costilla", "jack", "andina"])
                && !containsItem($0, in: share)
            }
            let classic = items.filter { !containsItem($0, in: share) && !containsItem($0, in: house) }

            return [
                AdventureFoodGroup(id: "share", title: "Para compartir", subtitle: "Parrilladas y platos grandes para pareja, familia o amigos.", items: share),
                AdventureFoodGroup(id: "house", title: "Especialidades de la casa", subtitle: "Los platos que hacen que la visita se sienta Altos del Murco.", items: house),
                AdventureFoodGroup(id: "classic", title: "Más platos fuertes", subtitle: "Otras opciones contundentes para completar la reserva.", items: classic)
            ]
            .filter { !$0.items.isEmpty }
        }

        let featured = items.filter { $0.isFeatured || $0.hasOffer }
        let rest = items.filter { !containsItem($0, in: featured) }

        if featured.isEmpty {
            return [
                AdventureFoodGroup(
                    id: section.id,
                    title: "Opciones disponibles",
                    subtitle: "\(items.count) opción(es) para este momento.",
                    items: items
                )
            ]
        }

        return [
            AdventureFoodGroup(id: "featured", title: "Recomendados", subtitle: "Los más atractivos de esta categoría.", items: featured),
            AdventureFoodGroup(id: "all", title: "También puedes pedir", subtitle: "Más opciones para completar la mesa.", items: rest)
        ]
        .filter { !$0.items.isEmpty }
    }

    private static func matches(_ item: MenuItem, _ keys: [String]) -> Bool {
        let text = ([item.name, item.description] + item.ingredients)
            .joined(separator: " ")
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()

        return keys.contains { key in
            text.contains(key.folding(options: .diacriticInsensitive, locale: .current).lowercased())
        }
    }

    private static func containsItem(_ item: MenuItem, in items: [MenuItem]) -> Bool {
        items.contains { $0.id == item.id }
    }
}

private struct AdventureFoodHeroBadge: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.14)))
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
    }
}

private struct AdventureFoodStepCard: View {
    let step: AdventureFoodStep
    let selected: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .adventure, scheme: colorScheme)

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

private struct AdventureFoodGroupBlock: View {
    let group: AdventureFoodGroup
    let selectedDate: Date
    let rewardProvider: (MenuItem, Int) -> RewardPresentation?
    let displayedPriceProvider: (MenuItem, Int) -> Double
    let incrementalDiscountProvider: (MenuItem, Int) -> Double
    let onAdd: (MenuItem, Int, String?) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .adventure, scheme: colorScheme)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(palette.textPrimary)

                    Text(group.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
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
                    AdventureFoodDishCard(
                        item: item,
                        selectedDate: selectedDate,
                        rewardPresentation: rewardProvider(item, 1),
                        displayedPrice: displayedPriceProvider(item, 1),
                        incrementalDiscount: incrementalDiscountProvider(item, 1),
                        onAdd: { quantity, notes in onAdd(item, quantity, notes) }
                    )
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

private struct AdventureFoodDishCard: View {
    let item: MenuItem
    let selectedDate: Date
    let rewardPresentation: RewardPresentation?
    let displayedPrice: Double
    let incrementalDiscount: Double
    let onAdd: (Int, String?) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var isExpanded = false
    @State private var quantity = 1
    @State private var notes = ""

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var isTodayReservation: Bool {
        AdventureDateHelper.calendar.isDateInToday(selectedDate)
    }

    private var isBlockedForSelectedDate: Bool {
        isTodayReservation && !item.canBeOrdered
    }

    private var baseSubtotal: Double {
        item.finalPrice * Double(quantity)
    }

    private var effectiveTotal: Double {
        displayedPriceProviderForQuantity
    }

    private var displayedPriceProviderForQuantity: Double {
        incrementalDiscount > 0 ? displayedPrice * Double(quantity) : baseSubtotal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                imageLayer(height: 122)

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
                .lineLimit(isExpanded ? 4 : 2)
                .multilineTextAlignment(.leading)

            priceRow

            if let rewardPresentation {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                    Text(rewardPresentation.badge)
                        .lineLimit(1)
                }
                .font(.caption2.bold())
                .foregroundStyle(palette.accent)
            }

            if isBlockedForSelectedDate {
                Label("Agotado para hoy", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(palette.destructive)
            } else if isTodayReservation {
                Text(item.stockLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(palette.textTertiary)
            } else if item.isAvailable && !item.canBeOrdered {
                Text("Reservable para fecha futura")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }

            if isExpanded { expandedControls }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    if isExpanded {
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onAdd(quantity, trimmedNotes.isEmpty ? nil : trimmedNotes)
                    } else {
                        isExpanded = true
                    }
                }
            } label: {
                Label(isExpanded ? "Agregar" : "Elegir", systemImage: isExpanded ? "plus.circle.fill" : "slider.horizontal.3")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandSecondaryButtonStyle(theme: .adventure))
            .disabled(isBlockedForSelectedDate)
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
        .opacity(isBlockedForSelectedDate ? 0.58 : 1)
    }

    private var priceRow: some View {
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
    }

    private var expandedControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(spacing: 12) {
                Button {
                    quantity = max(1, quantity - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text("\(quantity)")
                    .font(.headline)
                    .frame(minWidth: 24)

                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(baseSubtotal.priceText)
                    .font(.caption.bold())
                    .foregroundStyle(palette.primary)
            }

            TextField("Notas opcionales", text: $notes, axis: .vertical)
                .lineLimit(2...3)
                .appTextFieldStyle(.adventure)
        }
    }

    @ViewBuilder
    private func imageLayer(height: CGFloat) -> some View {
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
        ZStack {
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
