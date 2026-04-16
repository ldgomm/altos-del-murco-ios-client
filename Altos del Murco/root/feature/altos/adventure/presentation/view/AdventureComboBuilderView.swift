//
//  AdventureComboBuilderView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

struct AdventureComboBuilderView: View {
    @ObservedObject var viewModel: AdventureComboBuilderViewModel
    @State private var editingItem: AdventureReservationItemDraft?
    
    private let menuSections = MenuMockData.sections
    
    var body: some View {
        List {
            comboSection
            foodSection
            eventSection
            schedulingSection
            contactSection
            availabilitySection
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
            viewModel.onAppear()
        }
        .sheet(item: $editingItem) { item in
            AdventureItemEditorView(item: item) { updated in
                viewModel.updateItem(updated)
            }
        }
        .alert(
            "Mensaje",
            isPresented: Binding(
                get: { viewModel.state.errorMessage != nil || viewModel.state.successMessage != nil },
                set: { if !$0 { viewModel.dismissMessage() } }
            )
        ) {
            Button("OK") { viewModel.dismissMessage() }
        } message: {
            Text(viewModel.state.errorMessage ?? viewModel.state.successMessage ?? "")
        }
    }
    
    private var comboSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Actividades",
                    subtitle: "Opcionales. Puedes reservar aventura, comida o ambas. Cada actividad solo puede agregarse una vez por reserva."
                )
                
                if viewModel.state.items.isEmpty {
                    Text("No hay actividades agregadas. Eso está bien si quieres una reserva solo de comida o evento.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                
                if viewModel.state.items.contains(where: { $0.activity == .offRoad }) {
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
            
            ForEach(viewModel.state.items) { item in
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
            .onDelete(perform: viewModel.removeItem)
            .onMove(perform: viewModel.moveItems)
            
            Menu {
                if viewModel.availableActivitiesToAdd.isEmpty {
                    Button("Todas las actividades ya fueron agregadas") { }
                        .disabled(true)
                } else {
                    ForEach(viewModel.availableActivitiesToAdd) { activity in
                        Button(activity.title) {
                            viewModel.addItem(activity)
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
                
                if viewModel.state.foodItems.isEmpty {
                    Text("No hay platos agregados todavía.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.state.foodItems) { item in
                            ReservationFoodRow(
                                item: item,
                                onIncrease: { viewModel.increaseFoodQuantity(item.id) },
                                onDecrease: { viewModel.decreaseFoodQuantity(item.id) },
                                onRemove: { viewModel.removeFoodItem(item.id) }
                            )
                        }
                    }
                }
                
                Menu {
                    ForEach(menuSections) { section in
                        Menu(section.category.title) {
                            ForEach(section.items.filter(\.isAvailable)) { item in
                                Button("\(item.name) • \(item.finalPrice.priceText)") {
                                    viewModel.addFoodItem(item)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        BrandIconBubble(theme: .adventure, systemImage: "fork.knife")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Agregar comida")
                                .font(.headline)
                            Text("Usa el menú del restaurante para planificar la reserva.")
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
                
                if !viewModel.state.foodItems.isEmpty {
                    Picker(
                        "Momento de servicio",
                        selection: Binding(
                            get: { viewModel.state.foodServingMoment },
                            set: { viewModel.setFoodServingMoment($0) }
                        )
                    ) {
                        ForEach(ReservationServingMoment.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    
                    if viewModel.state.foodServingMoment == .specificTime {
                        DatePicker(
                            "Hora de servicio",
                            selection: Binding(
                                get: { viewModel.state.foodServingTime },
                                set: { viewModel.setFoodServingTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                    
                    TextField(
                        "Notas de comida (opcional)",
                        text: Binding(
                            get: { viewModel.state.foodNotes },
                            set: { viewModel.setFoodNotes($0) }
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
    
    private var eventSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Evento",
                    subtitle: "Añade el tipo de evento, número de invitados y notas especiales."
                )
                
                Stepper(
                    "Invitados: \(viewModel.state.guestCount)",
                    value: Binding(
                        get: { viewModel.state.guestCount },
                        set: { viewModel.setGuestCount($0) }
                    ),
                    in: 1...300
                )
                
                Picker(
                    "Tipo de evento",
                    selection: Binding(
                        get: { viewModel.state.eventType },
                        set: { viewModel.setEventType($0) }
                    )
                ) {
                    ForEach(ReservationEventType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                
                if viewModel.state.eventType == .custom {
                    TextField(
                        "Nombre del evento",
                        text: Binding(
                            get: { viewModel.state.customEventTitle },
                            set: { viewModel.setCustomEventTitle($0) }
                        )
                    )
                    .appTextFieldStyle(.adventure)
                }
                
                TextField(
                    "Notas del evento (decoración, pastel, sorpresa, niños, etc.)",
                    text: Binding(
                        get: { viewModel.state.eventNotes },
                        set: { viewModel.setEventNotes($0) }
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
                        get: { viewModel.state.selectedDate },
                        set: { viewModel.setDate($0) }
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
                    subtitle: "Necesitamos tus datos para confirmar y gestionar la reserva."
                )
                
                TextField(
                    "Nombre del cliente",
                    text: Binding(
                        get: { viewModel.state.clientName },
                        set: { viewModel.setClientName($0) }
                    )
                )
                .textInputAutocapitalization(.words)
                .appTextFieldStyle(.adventure)
                
                TextField(
                    "Número de WhatsApp",
                    text: Binding(
                        get: { viewModel.state.whatsappNumber },
                        set: { viewModel.setWhatsapp($0) }
                    )
                )
                .keyboardType(.phonePad)
                .appTextFieldStyle(.adventure)
                
                TextField(
                    "Cédula",
                    text: Binding(
                        get: { viewModel.state.nationalId },
                        set: { viewModel.setNationalId($0) }
                    )
                )
                .keyboardType(.numberPad)
                .appTextFieldStyle(.adventure)
                
                TextField(
                    "Notas generales (opcional)",
                    text: Binding(
                        get: { viewModel.state.notes },
                        set: { viewModel.setNotes($0) }
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
                
                if viewModel.state.isLoadingAvailability {
                    ProgressView("Verificando disponibilidad...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if viewModel.state.availableSlots.isEmpty {
                    ContentUnavailableView(
                        "Sin horarios disponibles",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Agrega una actividad o comida, o prueba otra fecha.")
                    )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(viewModel.state.availableSlots) { slot in
                                Button {
                                    viewModel.selectSlot(slot)
                                } label: {
                                    AdventureSlotCard(
                                        slot: slot,
                                        isSelected: viewModel.state.selectedSlot?.id == slot.id
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
                if let slot = viewModel.state.selectedSlot {
                    summaryRow("Aventura", "$\(slot.adventureSubtotal.priceText)")
                    summaryRow("Comida", "$\(slot.foodSubtotal.priceText)")
                    summaryRow("Subtotal", "$\(slot.subtotal.priceText)")
                    summaryRow("Descuento aventura", "-$\(slot.discountAmount.priceText)")
//                    summaryRow("Recargo nocturno", "$\(slot.nightPremium.priceText)")
                    Divider()
                    summaryRow("Total", "$\(slot.totalAmount.priceText)", bold: true)
                } else {
                    let estimatedSubtotal = AdventurePricingEngine.estimatedSubtotal(items: viewModel.state.items)
                    let estimatedDiscount = AdventurePricingEngine.discount(for: estimatedSubtotal)
//                    let estimatedNightPremium = AdventurePricingEngine.estimatedNightPremium(items: viewModel.state.items)
                    let estimatedTotal =
                        AdventurePricingEngine.discountedSubtotal(for: estimatedSubtotal) //+ estimatedNightPremium

                    summaryRow("Subtotal estimado", "$\(estimatedSubtotal.priceText)")
                    summaryRow("Descuento estimado", "-$\(estimatedDiscount.priceText)")
//                    summaryRow("Recargo nocturno estimado", "$\(estimatedNightPremium.priceText)")
                    Divider()
                    summaryRow("Total estimado", "$\(estimatedTotal.priceText)", bold: true)
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
            Button {
                viewModel.submit(clientId: nil)
            } label: {
                if viewModel.state.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Confirmar reserva", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
            .disabled(viewModel.state.isSubmitting || viewModel.state.selectedSlot == nil)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 28, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
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
    
    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(theme: .adventure, systemImage: item.activity.systemImage, size: 52)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(item.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("$\(AdventurePricingEngine.subtotal(for: item), specifier: "%.2f")")
                    .font(.caption.weight(.semibold))
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
    let onSave: (AdventureReservationItemDraft) -> Void
    
    init(item: AdventureReservationItemDraft, onSave: @escaping (AdventureReservationItemDraft) -> Void) {
        _item = State(initialValue: item)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    Text(item.activity.title)
                }
                
                switch item.activity {
                case .offRoad:
                    Section("Off-road") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(item.activity.durationOptions, id: \.self) { minutes in
                                Text("\(minutes / 60) hora(s)").tag(minutes)
                            }
                        }
                        
                        Stepper("Vehículos: \(item.vehicleCount)", value: $item.vehicleCount, in: 1...10)
                        Stepper("Personas: \(item.offRoadRiderCount)", value: $item.offRoadRiderCount, in: 1...20)
                        
                        Text("Cada vehículo admite 1 o 2 personas. Ejemplo: 6 personas pueden usar 4 vehículos.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                case .paintball, .goKarts, .shootingRange:
                    Section("Configuración") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(item.activity.durationOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                    }
                    
                case .camping:
                    Section("Camping") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                        Stepper("Noches: \(item.nights)", value: $item.nights, in: 1...7)
                        Text("El camping se programa de 7:00 PM a 7:00 AM y debe mantenerse al final del combo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                case .extremeSlide:
                    Section("Resbaladera extrema") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                        Text("Incluye 30 minutos de transporte off-road más la sesión de la resbaladera.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Precio") {
                    Text("$\(AdventurePricingEngine.subtotal(for: item), specifier: "%.2f")")
                        .font(.headline)
                }
            }
            .scrollContentBackground(.hidden)
            .appScreenStyle(.adventure)
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
