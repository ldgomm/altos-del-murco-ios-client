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
        .navigationTitle("Build Adventure")
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
                Text("Your Combo")
                    .font(.title3.bold())
                
                Text("You can mix any activities, set different durations and people counts, and drag to change the order.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if viewModel.state.items.contains(where: { $0.activity == .offRoad }) {
                    Label("Each off-road vehicle supports 1 or 2 riders. Pricing is per vehicle, not per rider.", systemImage: "info.circle")
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
                Label("Add Activity", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var schedulingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("Date")
                    .font(.headline)
                
                DatePicker(
                    "Reservation day",
                    selection: Binding(
                        get: { viewModel.state.selectedDate },
                        set: { viewModel.setDate($0) }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                
                Text("Regular activities run from 7:00 AM to 7:00 PM. Night fun premium applies from 6:00 PM onward.")
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
                    "Client name",
                    text: Binding(
                        get: { viewModel.state.clientName },
                        set: { viewModel.setClientName($0) }
                    )
                )
                .textInputAutocapitalization(.words)
                
                TextField(
                    "WhatsApp number",
                    text: Binding(
                        get: { viewModel.state.whatsappNumber },
                        set: { viewModel.setWhatsapp($0) }
                    )
                )
                .keyboardType(.phonePad)
                
                TextField(
                    "National ID",
                    text: Binding(
                        get: { viewModel.state.nationalId },
                        set: { viewModel.setNationalId($0) }
                    )
                )
                .keyboardType(.numberPad)
                
                TextField(
                    "Notes (optional)",
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
            Text("Contact")
        }
    }
    
    private var availabilitySection: some View {
        Section {
            if viewModel.state.isLoadingAvailability {
                ProgressView("Checking availability...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if viewModel.state.availableSlots.isEmpty {
                ContentUnavailableView(
                    "No slots",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Try another date, another order, or reduce some quantities.")
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
                                    Text("Ends \(AdventureDateHelper.timeText(slot.endAt))")
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
            Text("Available Start Times")
        }
    }
    
    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary")
                    .font(.headline)
                
                if let slot = viewModel.state.selectedSlot {
                    summaryRow("Subtotal", "$\(slot.subtotal, default: "%.2f")")
                    summaryRow("Discount", "-$\(slot.discountAmount, default: "%.2f")")
                    summaryRow("Night premium", "$\(slot.nightPremium, default: "%.2f")")
                    summaryRow("Total", "$\(slot.totalAmount, default: "%.2f")", bold: true)
                } else {
                    summaryRow("Estimated subtotal", "$\(viewModel.estimatedSubtotal, default: "%.2f")")
                    summaryRow(
                        "Estimated discount",
                        "-$\(AdventurePricingEngine.discount(for: viewModel.estimatedSubtotal), default: "%.2f")"
                    )
                    summaryRow(
                        "Estimated total",
                        "$\(AdventurePricingEngine.discountedSubtotal(for: viewModel.estimatedSubtotal), default: "%.2f")",
                        bold: true
                    )                }
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
                    Text("Confirm Reservation")
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
                Section("Activity") {
                    Text(item.activity.title)
                }
                
                switch item.activity {
                case .offRoad:
                    Section("Off-Road") {
                        Picker("Duration", selection: $item.durationMinutes) {
                            ForEach(item.activity.durationOptions, id: \.self) { minutes in
                                Text("\(minutes / 60) hour(s)").tag(minutes)
                            }
                        }
                        
                        Stepper("Vehicles: \(item.vehicleCount)", value: $item.vehicleCount, in: 1...10)
                        Stepper("Riders: \(item.offRoadRiderCount)", value: $item.offRoadRiderCount, in: 1...20)
                        
                        Text("Each vehicle supports 1 or 2 riders. Example: 8 riders can use 4 vehicles.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                case .paintball, .goKarts, .shootingRange:
                    Section("Configuration") {
                        Picker("Duration", selection: $item.durationMinutes) {
                            ForEach(item.activity.durationOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        Stepper("People: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                    }
                    
                case .camping:
                    Section("Camping") {
                        Stepper("People: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                        Stepper("Nights: \(item.nights)", value: $item.nights, in: 1...7)
                        Text("Camping is scheduled from 7:00 PM to 7:00 AM and should stay last in the combo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                case .extremeSlide:
                    Section("Extreme Slide") {
                        Stepper("People: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                        Text("This includes 30 minutes of off-road transportation plus the slide session.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Price") {
                    Text("$\(AdventurePricingEngine.subtotal(for: item), specifier: "%.2f")")
                        .font(.headline)
                }
            }
            .navigationTitle("Edit Activity")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(item)
                        dismiss()
                    }
                }
            }
        }
    }
}
