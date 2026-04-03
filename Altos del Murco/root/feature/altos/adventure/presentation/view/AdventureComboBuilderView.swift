//
//  AdventureComboBuilderView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

struct AdventureComboBuilderView: View {
    @StateObject private var viewModel: AdventureComboBuilderViewModel
    @State private var editingItem: AdventureReservationItemDraft?
    
    init(viewModel: AdventureComboBuilderViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            comboSection
            schedulingSection
            contactSection
            availabilitySection
            summarySection
            confirmSection
        }
        .listStyle(.plain)
        .navigationTitle("Crear aventura")
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
            "Error",
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Tu combo")
                    .font(.title3.bold())
                
                Text("Puedes combinar cualquier actividad, establecer diferentes duraciones y número de personas, y arrastrar para cambiar el orden.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if viewModel.state.items.contains(where: { $0.activity == .offRoad }) {
                    Label("Cada vehículo off-road admite 1 o 2 personas. El precio es por vehículo, no por persona.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .listRowBackground(Color.clear)
            
            ForEach(viewModel.state.items) { item in
                Button {
                    editingItem = item
                } label: {
                    ComboItemCard(item: item)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: viewModel.removeItem)
            .onMove(perform: viewModel.moveItems)
            
            Menu {
                ForEach(AdventureActivityType.allCases) { activity in
                    Button(activity.title) {
                        viewModel.addItem(activity)
                    }
                }
            } label: {
                Label("Agregar actividad", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var schedulingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("Fecha")
                    .font(.headline)
                
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
                
                Text("Las actividades regulares funcionan de 7:00 AM a 7:00 PM. El recargo nocturno aplica desde las 6:00 PM en adelante.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .padding(.vertical, 4)
            )
        }
    }
    
    private var contactSection: some View {
        Section {
            VStack(spacing: 14) {
                TextField(
                    "Nombre del cliente",
                    text: Binding(
                        get: { viewModel.state.clientName },
                        set: { viewModel.setClientName($0) }
                    )
                )
                .textInputAutocapitalization(.words)
                
                TextField(
                    "Número de WhatsApp",
                    text: Binding(
                        get: { viewModel.state.whatsappNumber },
                        set: { viewModel.setWhatsapp($0) }
                    )
                )
                .keyboardType(.phonePad)
                
                TextField(
                    "Cédula",
                    text: Binding(
                        get: { viewModel.state.nationalId },
                        set: { viewModel.setNationalId($0) }
                    )
                )
                .keyboardType(.numberPad)
                
                TextField(
                    "Notas (opcional)",
                    text: Binding(
                        get: { viewModel.state.notes },
                        set: { viewModel.setNotes($0) }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...5)
            }
            .padding(.vertical, 6)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .padding(.vertical, 4)
            )
        } header: {
            Text("Contacto")
        }
    }
    
    private var availabilitySection: some View {
        Section {
            if viewModel.state.isLoadingAvailability {
                ProgressView("Verificando disponibilidad...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if viewModel.state.availableSlots.isEmpty {
                ContentUnavailableView(
                    "Sin horarios disponibles",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Intenta otra fecha, otro orden o reduce algunas cantidades.")
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.state.availableSlots) { slot in
                            Button {
                                viewModel.selectSlot(slot)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(AdventureDateHelper.timeText(slot.startAt))
                                        .font(.headline)
                                    Text("Termina \(AdventureDateHelper.timeText(slot.endAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("$\(slot.totalAmount, specifier: "%.2f")")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding()
                                .frame(width: 160, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(
                                            viewModel.state.selectedSlot?.id == slot.id
                                            ? Color.primary.opacity(0.15)
                                            : Color(.systemGray6)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Horarios disponibles de inicio")
        }
    }
    
    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Resumen")
                    .font(.headline)
                
                if let slot = viewModel.state.selectedSlot {
                    summaryRow("Subtotal", "$\(slot.subtotal, default: "%.2f")")
                    summaryRow("Descuento", "-$\(slot.discountAmount, default: "%.2f")")
                    summaryRow("Recargo nocturno", "$\(slot.nightPremium, default: "%.2f")")
                    summaryRow("Total", "$\(slot.totalAmount, default: "%.2f")", bold: true)
                } else {
                    summaryRow("Subtotal estimado", "$\(viewModel.estimatedSubtotal, default: "%.2f")")
                    summaryRow(
                        "Descuento estimado",
                        "-$\(AdventurePricingEngine.discount(for: viewModel.estimatedSubtotal), default: "%.2f")"
                    )
                    summaryRow(
                        "Total estimado",
                        "$\(AdventurePricingEngine.discountedSubtotal(for: viewModel.estimatedSubtotal), default: "%.2f")",
                        bold: true
                    )
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .padding(.vertical, 4)
            )
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
                    Text("Confirmar reserva")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
            }
            .disabled(viewModel.state.isSubmitting || viewModel.state.selectedSlot == nil)
        }
    }
    
    private func summaryRow(_ title: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(bold ? .bold : .regular)
        }
    }
}

private struct ComboItemCard: View {
    let item: AdventureReservationItemDraft
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .frame(width: 52, height: 52)
                Image(systemName: item.activity.systemImage)
                    .font(.title3)
            }
            
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
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
                        
                        Text("Cada vehículo admite 1 o 2 personas. Ejemplo: 8 personas pueden usar 4 vehículos.")
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
                    Section("Columpio extremo") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                        Text("Incluye 30 minutos de transporte off-road más la sesión del columpio.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Precio") {
                    Text("$\(AdventurePricingEngine.subtotal(for: item), specifier: "%.2f")")
                        .font(.headline)
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
                }
            }
        }
    }
}
