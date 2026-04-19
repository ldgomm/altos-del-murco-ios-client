//
//  AdventureComboBuilderView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

struct AdventureComboBuilderView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    
    @State private var editingItem: AdventureReservationItemDraft?
    @State private var isFoodPickerPresented = false
    
    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }
    
    @Environment(\.colorScheme) private var colorScheme
    private let theme: AppSectionTheme = .restaurant
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    @State private var showAddedMessage: Bool = false
    
    var body: some View {
        List {
            schedulingSection
            availabilitySection
            eventSection
            
            comboSection
            foodSection
            
            contactSection
            summarySection
            
            confirmSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .appScreenStyle(.adventure)
        .navigationTitle("Crear reserva")
        .toolbar {
            EditButton()
        }
        .onAppear {
            syncProfileFieldsFromSession()
            adventureComboBuilderViewModel.onAppear()
        }
        .onChange(of: authenticatedProfile?.id) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: authenticatedProfile?.updatedAt) { _, _ in
            syncProfileFieldsFromSession()
        }
        .sheet(item: $editingItem) { item in
            AdventureItemEditorView(
                item: item,
                config: adventureComboBuilderViewModel.config(for: item.activity),
                linePrice: AdventurePricingEngine.subtotal(
                    for: item,
                    catalog: adventureComboBuilderViewModel.state.catalog
                )
            ) { updated in
                adventureComboBuilderViewModel.updateItem(updated)
            }
        }
        .alert(
            "Mensaje",
            isPresented: Binding(
                get: { adventureComboBuilderViewModel.state.errorMessage != nil || adventureComboBuilderViewModel.state.successMessage != nil },
                set: { if !$0 { adventureComboBuilderViewModel.dismissMessage() } }
            )
        ) {
            Button("OK") { adventureComboBuilderViewModel.dismissMessage() }
        } message: {
            Text(adventureComboBuilderViewModel.state.errorMessage ?? adventureComboBuilderViewModel.state.successMessage ?? "")
        }
    }
    
    private var menuItemsById: [String: MenuItem] {
        Dictionary(
            uniqueKeysWithValues: menuViewModel.state.sections
                .flatMap(\.items)
                .map { ($0.id, $0) }
        )
    }

    private var blockedFoodItemsForToday: [ReservationFoodItemDraft] {
        guard AdventureDateHelper.calendar.isDateInToday(adventureComboBuilderViewModel.state.selectedDate) else {
            return []
        }

        return adventureComboBuilderViewModel.state.foodItems.filter { draft in
            guard let menuItem = menuItemsById[draft.menuItemId] else { return false }
            return !menuItem.canBeOrdered
        }
    }
    
    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }
        
        adventureComboBuilderViewModel.setClientName(profile.fullName)
        adventureComboBuilderViewModel.setWhatsapp(profile.phoneNumber)
        adventureComboBuilderViewModel.setNationalId(profile.nationalId)
    }
    
    private var comboSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Actividades",
                    subtitle: "Opcionales. Puedes reservar aventura, comida o ambas. Cada actividad solo puede agregarse una vez por reserva."
                )
                
                if adventureComboBuilderViewModel.state.items.isEmpty {
                    Text("No hay actividades agregadas. Eso está bien si quieres una reserva solo de comida o evento.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                
                if adventureComboBuilderViewModel.state.items.contains(where: { $0.activity == .offRoad }) {
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(theme: .adventure, systemImage: "info.circle", size: 34)
                        
                        Text("Cada vehículo off-road admite 1 o 2 personas. El precio es por vehículo, no por persona.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .appCardStyle(.adventure)
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            ForEach(adventureComboBuilderViewModel.state.items) { item in
                Button {
                    editingItem = item
                } label: {
                    ComboItemCard(item: item)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: adventureComboBuilderViewModel.removeItem)
            .onMove(perform: adventureComboBuilderViewModel.moveItems)
            
            Menu {
                if adventureComboBuilderViewModel.availableActivitiesToAdd.isEmpty {
                    Button("Todas las actividades ya fueron agregadas") { }
                        .disabled(true)
                } else {
                    ForEach(adventureComboBuilderViewModel.availableActivitiesToAdd) { activity in
                        Button(
                            adventureComboBuilderViewModel.config(for: activity)?.title ?? activity.legacyTitle
                        ) {
                            adventureComboBuilderViewModel.addItem(activity)
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "plus")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Agregar actividad")
                            .font(.headline)
                        Text("Añade una experiencia distinta a esta reserva.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .appCardStyle(.adventure, emphasized: false)
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var foodSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Comida",
                    subtitle: "También puedes hacer una reserva solo de comida para cumpleaños, reuniones o visitas futuras."
                )
                
                if adventureComboBuilderViewModel.state.foodItems.isEmpty {
                    Text("No hay platos agregados todavía.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(adventureComboBuilderViewModel.state.foodItems) { item in
                            ReservationFoodRow(
                                item: item,
                                onIncrease: { adventureComboBuilderViewModel.increaseFoodQuantity(item.id) },
                                onDecrease: { adventureComboBuilderViewModel.decreaseFoodQuantity(item.id) },
                                onRemove: { adventureComboBuilderViewModel.removeFoodItem(item.id) }
                            )
                        }
                    }
                }
                
                Button {
                    isFoodPickerPresented = true
                } label: {
                    HStack(spacing: 12) {
                        BrandIconBubble(theme: .adventure, systemImage: "fork.knife")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Agregar comida")
                                .font(.headline)

                            Text("Explora platos, ingredientes y detalles antes de agregarlos.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .appCardStyle(.adventure, emphasized: false)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isFoodPickerPresented) {
                    AdventureFoodPickerSheet(
                        menuSections: menuViewModel.state.sections,
                        selectedDate: adventureComboBuilderViewModel.state.selectedDate
                    ) { item, quantity, notes in
                        adventureComboBuilderViewModel.addFoodItem(
                            item,
                            quantity: quantity,
                            notes: notes,
                            for: adventureComboBuilderViewModel.state.selectedDate
                        )
                    }
                }
                
                if !adventureComboBuilderViewModel.state.foodItems.isEmpty {
                    Picker(
                        "Momento de servicio",
                        selection: Binding(
                            get: { adventureComboBuilderViewModel.state.foodServingMoment },
                            set: { adventureComboBuilderViewModel.setFoodServingMoment($0) }
                        )
                    ) {
                        ForEach(ReservationServingMoment.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    
                    if adventureComboBuilderViewModel.state.foodServingMoment == .specificTime {
                        DatePicker(
                            "Hora de servicio",
                            selection: Binding(
                                get: { adventureComboBuilderViewModel.state.foodServingTime },
                                set: { adventureComboBuilderViewModel.setFoodServingTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                    
                    TextField(
                        "Notas de comida (opcional)",
                        text: Binding(
                            get: { adventureComboBuilderViewModel.state.foodNotes },
                            set: { adventureComboBuilderViewModel.setFoodNotes($0) }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .appTextFieldStyle(.adventure)
                }
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private struct AdventureFoodPickerSheet: View {
        @Environment(\.dismiss) private var dismiss

        let menuSections: [MenuSection]
        let selectedDate: Date
        let onAdd: (MenuItem, Int, String?) -> Void

        @State private var selectedCategoryId: String? = nil
        @State private var searchText = ""

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
            menuSections.sorted { lhs, rhs in
                let lhsRank = categoryRank(for: lhs.category.title)
                let rhsRank = categoryRank(for: rhs.category.title)

                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                return lhs.category.title < rhs.category.title
            }
        }

        private var categories: [MenuCategory] {
            orderedSections.map(\.category)
        }

        var body: some View {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        categorySelector

                        if filteredSections.isEmpty {
                            ContentUnavailableView(
                                "No se encontraron platos",
                                systemImage: "magnifyingglass",
                                description: Text("Prueba otra búsqueda o cambia la categoría.")
                            )
                            .padding(.top, 32)
                        } else {
                            ForEach(filteredSections) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(section.category.title)
                                        .font(.title3.bold())

                                    ForEach(section.items) { item in
                                        NavigationLink {
                                            AdventureFoodDetailView(
                                                item: item,
                                                selectedDate: selectedDate
                                            ) { quantity, notes in
                                                onAdd(item, quantity, notes)
                                                dismiss()
                                            }
                                        } label: {
                                            AdventureFoodMenuRow(
                                                item: item,
                                                selectedDate: selectedDate
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .navigationTitle("Menú del restaurante")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, prompt: "Buscar plato, bebida o ingrediente")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cerrar") { dismiss() }
                    }
                }
                .appScreenStyle(.adventure)
            }
        }

        private var categorySelector: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    categoryChip(title: "Todo", isSelected: selectedCategoryId == nil) {
                        selectedCategoryId = nil
                    }

                    ForEach(categories) { category in
                        categoryChip(
                            title: category.title,
                            isSelected: selectedCategoryId == category.id
                        ) {
                            selectedCategoryId = category.id
                        }
                    }
                }
            }
        }

        private func categoryChip(
            title: String,
            isSelected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        
        private var isTodayReservation: Bool {
            AdventureDateHelper.calendar.isDateInToday(selectedDate)
        }

        private func isBlockedForSelectedDate(_ item: MenuItem) -> Bool {
            isTodayReservation && !item.canBeOrdered
        }
        
        private var filteredSections: [MenuSection] {
            let categoryFiltered = orderedSections.filter { section in
                selectedCategoryId == nil || section.category.id == selectedCategoryId
            }

            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return categoryFiltered
            }

            let query = searchText.lowercased()

            return categoryFiltered.compactMap { section in
                let items = section.items.filter { item in
                    item.name.lowercased().contains(query) ||
                    item.description.lowercased().contains(query) ||
                    item.ingredients.contains(where: { $0.lowercased().contains(query) })
                }

                guard !items.isEmpty else { return nil }

                return MenuSection(
                    id: section.id,
                    category: section.category,
                    items: items
                )
            }
        }
    }

    private struct AdventureFoodMenuRow: View {
        let item: MenuItem
        let selectedDate: Date

        private var isBlockedForSelectedDate: Bool {
            AdventureDateHelper.calendar.isDateInToday(selectedDate) && !item.canBeOrdered
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.name)
                                .font(.headline)

                            if item.isFeatured {
                                Text("Destacado")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.accentColor.opacity(0.16)))
                            }
                        }

                        Text(item.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text(item.finalPrice.priceText)
                        .font(.subheadline.bold())
                }

                if isBlockedForSelectedDate {
                    Text("For today this is out of stock and cannot be ordered")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(item.ingredients.prefix(4)), id: \.self) { ingredient in
                            Text(ingredient)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.10))
                                )
                        }

                        if item.ingredients.count > 4 {
                            Text("+\(item.ingredients.count - 4)")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.10))
                                )
                        }
                    }
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .opacity(isBlockedForSelectedDate ? 0.82 : 1)
        }
    }

    private struct AdventureFoodDetailView: View {
        @Environment(\.dismiss) private var dismiss

        let item: MenuItem
        let selectedDate: Date
        let onAdd: (Int, String?) -> Void

        private var isBlockedForSelectedDate: Bool {
            AdventureDateHelper.calendar.isDateInToday(selectedDate) && !item.canBeOrdered
        }

        @State private var quantity = 1
        @State private var notes = ""

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    descriptionCard
                    ingredientsCard
                    priceCard
                    if isBlockedForSelectedDate {
                        VStack(alignment: .leading, spacing: 10) {
                            BrandSectionHeader(
                                theme: .adventure,
                                title: "Availability",
                                subtitle: "This restriction only applies for today's reservations."
                            )

                            Text("For today this is out of stock and cannot be ordered. Select tomorrow or another future day to reserve it.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .appCardStyle(.adventure, emphasized: false)
                    }
                    quantityCard
                    notesCard

                    Button {
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onAdd(quantity, trimmedNotes.isEmpty ? nil : trimmedNotes)
                    } label: {
                        Label("Agregar a la reserva", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
                    .disabled(isBlockedForSelectedDate)
                }
                .padding(20)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .appScreenStyle(.adventure)
        }

        private var headerCard: some View {
            HStack(spacing: 12) {
                BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.title3.bold())

                    Text(item.finalPrice.priceText)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .appCardStyle(.adventure)
        }

        private var descriptionCard: some View {
            VStack(alignment: .leading, spacing: 10) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Descripción",
                    subtitle: "Qué incluye este plato."
                )

                Text(item.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .appCardStyle(.adventure, emphasized: false)
        }

        private var ingredientsCard: some View {
            VStack(alignment: .leading, spacing: 10) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Ingredientes",
                    subtitle: "Componentes principales."
                )

                ForEach(item.ingredients, id: \.self) { ingredient in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .frame(width: 7, height: 7)
                            .padding(.top, 7)

                        Text(ingredient)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .appCardStyle(.adventure)
        }

        private var priceCard: some View {
            VStack(alignment: .leading, spacing: 10) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Precio",
                    subtitle: item.hasOffer ? "Precio promocional disponible." : "Precio actual."
                )

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    if item.hasOffer, let offerPrice = item.offerPrice {
                        Text(item.price.priceText)
                            .foregroundStyle(.secondary)
                            .strikethrough()

                        Text(offerPrice.priceText)
                            .font(.title2.bold())
                    } else {
                        Text(item.price.priceText)
                            .font(.title2.bold())
                    }
                }
            }
            .appCardStyle(.adventure)
        }

        private var quantityCard: some View {
            VStack(alignment: .leading, spacing: 10) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Cantidad",
                    subtitle: "Cuántas unidades deseas reservar."
                )

                QuantitySelectorView(
                    quantity: $quantity,
                    isEnabled: !isBlockedForSelectedDate,
                    theme: .adventure
                )
            }
            .appCardStyle(.adventure)
        }

        private var notesCard: some View {
            VStack(alignment: .leading, spacing: 10) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Notas",
                    subtitle: "Indicaciones especiales para cocina."
                )

                TextField("Sin cebolla, más cocido, sin ají, etc.", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .appTextFieldStyle(.adventure)
            }
            .appCardStyle(.adventure)
        }
    }
    
    private var eventSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Evento",
                    subtitle: "Añade el tipo de evento, número de invitados y notas especiales."
                )
                
                Stepper(
                    "Invitados: \(adventureComboBuilderViewModel.state.guestCount)",
                    value: Binding(
                        get: { adventureComboBuilderViewModel.state.guestCount },
                        set: { adventureComboBuilderViewModel.setGuestCount($0) }
                    ),
                    in: 1...300
                )
                
                Picker(
                    "Tipo de evento",
                    selection: Binding(
                        get: { adventureComboBuilderViewModel.state.eventType },
                        set: { adventureComboBuilderViewModel.setEventType($0) }
                    )
                ) {
                    ForEach(ReservationEventType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                
                if adventureComboBuilderViewModel.state.eventType == .custom {
                    TextField(
                        "Nombre del evento",
                        text: Binding(
                            get: { adventureComboBuilderViewModel.state.customEventTitle },
                            set: { adventureComboBuilderViewModel.setCustomEventTitle($0) }
                        )
                    )
                    .appTextFieldStyle(.adventure)
                }
                
                TextField(
                    "Notas del evento (decoración, pastel, sorpresa, niños, etc.)",
                    text: Binding(
                        get: { adventureComboBuilderViewModel.state.eventNotes },
                        set: { adventureComboBuilderViewModel.setEventNotes($0) }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...5)
                .appTextFieldStyle(.adventure)
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var schedulingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Fecha",
                    subtitle: "Elige el día de la visita y luego revisa horarios disponibles."
                )
                
                DatePicker(
                    "Día de la reserva",
                    selection: Binding(
                        get: { adventureComboBuilderViewModel.state.selectedDate },
                        set: { adventureComboBuilderViewModel.setDate($0) }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                
                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "clock")
                    
                    Text("Si reservas solo comida, estos horarios se usan como hora preferida de llegada. Si agregas actividades, representan el inicio del combo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var contactSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Contacto",
                    subtitle: "Your profile information is used automatically for this reservation."
                )
                
                TextField(
                    "",
                    text: Binding(
                        get: { authenticatedProfile?.nationalId ?? adventureComboBuilderViewModel.state.nationalId },
                        set: { _ in }
                    ),
                    prompt: Text("Cédula")
                )
                .disabled(true)
                .keyboardType(.numberPad)
                .appTextFieldStyle(.adventure)
                
                TextField(
                    "",
                    text: Binding(
                        get: { authenticatedProfile?.fullName ?? adventureComboBuilderViewModel.state.clientName },
                        set: { _ in }
                    ),
                    prompt: Text("Nombre")
                )
                .disabled(true)
                .appTextFieldStyle(.adventure)
                
                TextField(
                    "",
                    text: Binding(
                        get: { authenticatedProfile?.phoneNumber ?? adventureComboBuilderViewModel.state.whatsappNumber },
                        set: { _ in }
                    ),
                    prompt: Text("WhatsApp")
                )
                .disabled(true)
                .keyboardType(.phonePad)
                .appTextFieldStyle(.adventure)
                
                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "person.crop.circle.badge.checkmark", size: 38)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Need to update your information?")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Please change your personal details from the Edit Profile page.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .appCardStyle(.adventure)
                
                TextField(
                    "Notas generales (opcional)",
                    text: Binding(
                        get: { adventureComboBuilderViewModel.state.notes },
                        set: { adventureComboBuilderViewModel.setNotes($0) }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...5)
                .appTextFieldStyle(.adventure)
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var availabilitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Horarios disponibles",
                    subtitle: "Selecciona el mejor horario de inicio o llegada para tu reserva."
                )
                
                if adventureComboBuilderViewModel.state.isLoadingAvailability {
                    ProgressView("Verificando disponibilidad...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if adventureComboBuilderViewModel.state.availableSlots.isEmpty {
                    ContentUnavailableView(
                        "Sin horarios disponibles",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Agrega una actividad o comida, o prueba otra fecha.")
                    )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(adventureComboBuilderViewModel.state.availableSlots) { slot in
                                Button {
                                    adventureComboBuilderViewModel.selectSlot(slot)
                                } label: {
                                    AdventureSlotCard(
                                        slot: slot,
                                        isSelected: adventureComboBuilderViewModel.state.selectedSlot?.id == slot.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Resumen",
                    subtitle: "Revisa el total antes de confirmar."
                )
                
                //Later
                if let slot = adventureComboBuilderViewModel.state.selectedSlot {
                    summaryRow("Aventura", "$\(slot.adventureSubtotal.priceText)")
                    summaryRow("Comida", "$\(slot.foodSubtotal.priceText)")
                    summaryRow("Subtotal", "$\(slot.subtotal.priceText)")
                    summaryRow("Descuento aventura", "-$\(slot.discountAmount.priceText)")
                    Divider()
                    summaryRow("Total", "$\(slot.totalAmount.priceText)", bold: true)
                } else {
                    summaryRow("Aventura estimada", adventureComboBuilderViewModel.estimatedAdventureSubtotal.priceText)
                    summaryRow("Comida estimada", adventureComboBuilderViewModel.estimatedFoodSubtotal.priceText)
                    summaryRow("Descuento estimado", "-\(adventureComboBuilderViewModel.estimatedDiscountAmount.priceText)")
                    Divider()
                    summaryRow("Total estimado", adventureComboBuilderViewModel.estimatedTotal.priceText, bold: true)
                }
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var confirmSection: some View {
        Section {
            VStack(spacing: 12) {
                if showAddedMessage {
                    Text("Order has been added")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(palette.success)
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Button {
                    guard blockedFoodItemsForToday.isEmpty else {
                        adventureComboBuilderViewModel.presentError(
                            "For today some selected items are out of stock and cannot be ordered. Choose tomorrow or another future day."
                        )
                        return
                    }

                    syncProfileFieldsFromSession()
                    adventureComboBuilderViewModel.submit(clientId: authenticatedProfile?.id)

                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAddedMessage = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAddedMessage = false
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            dismiss()
                        }
                    }

                    dismiss()
                } label: {
                    if adventureComboBuilderViewModel.state.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Confirmar reserva", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
                .disabled(adventureComboBuilderViewModel.state.isSubmitting || adventureComboBuilderViewModel.state.selectedSlot == nil)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 28, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }
    
    private func summaryRow(_ title: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(bold ? .bold : .semibold)
                .foregroundStyle(.primary)
        }
        .font(bold ? .headline : .subheadline)
    }
}

private struct ComboItemCard: View {
    let item: AdventureReservationItemDraft

    @EnvironmentObject private var sessionViewModel: AppSessionViewModel

    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(theme: .adventure, systemImage: item.activity.legacySystemImage, size: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(.adventure)
    }
}

private struct ReservationFoodRow: View {
    let item: ReservationFoodItemDraft
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 46)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text("Unitario: \(item.unitPrice.priceText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Subtotal: \(item.subtotal.priceText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(item.quantity)")
                        .font(.headline)
                        .frame(minWidth: 20)
                    
                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                
                Button("Quitar", role: .destructive, action: onRemove)
                    .font(.caption.bold())
            }
        }
        .appCardStyle(.adventure)
    }
}

private struct AdventureSlotCard: View {
    let slot: AdventureAvailabilitySlot
    let isSelected: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: .adventure, scheme: colorScheme)
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AdventureDateHelper.timeText(slot.startAt))
                    .font(.headline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.primary)
                }
            }
            
            Text("Termina \(AdventureDateHelper.timeText(slot.endAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if slot.adventureSubtotal == 0 && slot.foodSubtotal > 0 {
                Text("Reserva de comida")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            } else if slot.foodSubtotal > 0 {
                Text("Aventura + comida")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }
            
            Divider()
            
            Text("$\(slot.totalAmount, specifier: "%.2f")")
                .font(.headline.weight(.bold))
                .foregroundStyle(isSelected ? palette.primary : .primary)
        }
        .padding(16)
        .frame(width: 180, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(palette.chipGradient) : AnyShapeStyle(palette.cardGradient))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? palette.primary : palette.stroke, lineWidth: isSelected ? 1.5 : 1)
        )
        .shadow(
            color: palette.shadow.opacity(isSelected ? (colorScheme == .dark ? 0.28 : 0.14) : (colorScheme == .dark ? 0.14 : 0.06)),
            radius: isSelected ? 14 : 8,
            x: 0,
            y: isSelected ? 8 : 4
        )
    }
}

private struct AdventureItemEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var item: AdventureReservationItemDraft
    let config: AdventureActivityCatalogItem?
    let linePrice: Double
    let onSave: (AdventureReservationItemDraft) -> Void

    init(
        item: AdventureReservationItemDraft,
        config: AdventureActivityCatalogItem?,
        linePrice: Double,
        onSave: @escaping (AdventureReservationItemDraft) -> Void
    ) {
        _item = State(initialValue: item)
        self.config = config
        self.linePrice = linePrice
        self.onSave = onSave
    }

    private var durationOptions: [Int] {
        config?.durationOptions ?? item.activity.legacyDurationOptions
    }

    private var activityTitle: String {
        config?.title ?? item.activity.legacyTitle
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    Text(activityTitle)
                }

                switch item.activity {
                case .offRoad:
                    Section("Off-road") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text("\(minutes / 60) hora(s)").tag(minutes)
                            }
                        }

                        Stepper("Vehículos: \(item.vehicleCount)", value: $item.vehicleCount, in: 1...50)
                        Stepper("Personas: \(item.offRoadRiderCount)", value: $item.offRoadRiderCount, in: 1...100)

                        Text("Cada vehículo admite 1 o 2 personas. El precio es por vehículo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                case .paintball, .goKarts, .shootingRange:
                    Section("Configuración") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...100)
                    }

                case .camping:
                    Section("Camping") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...100)
                        Stepper("Noches: \(item.nights)", value: $item.nights, in: 1...30)
                        Text("El camping se mantiene al final del combo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                case .extremeSlide:
                    Section("Resbaladera extrema") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...100)
                        Text("Incluye transporte off-road en la lógica del planificador.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Precio") {
                    if let config {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Base: \(config.basePrice.priceText)")
                            Text("Descuento unitario: \(config.discountAmount.priceText)")
                            Text("Precio final: \(linePrice.priceText)")
                                .font(.headline)
                        }
                    } else {
                        Text(linePrice.priceText)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Editar actividad")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(item)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
