//
//  AdventureComboBuilderViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import Combine
import SwiftUI

struct AdventureComboBuilderState {
    var selectedDate: Date = Date()
    var items: [AdventureReservationItemDraft]
    
    var clientName: String = ""
    var whatsappNumber: String = ""
    var nationalId: String = ""
    var notes: String = ""
    
    var availableSlots: [AdventureAvailabilitySlot] = []
    var selectedSlot: AdventureAvailabilitySlot?
    
    var isLoadingAvailability = false
    var isSubmitting = false
    var errorMessage: String?
    var successMessage: String?
}

@MainActor
final class AdventureComboBuilderViewModel: ObservableObject {
    @Published private(set) var state: AdventureComboBuilderState
    
    private let getAvailabilityUseCase: GetAdventureAvailabilityUseCase
    private let createBookingUseCase: CreateAdventureBookingUseCase
    
    init(
        prefilledItems: [AdventureReservationItemDraft],
        getAvailabilityUseCase: GetAdventureAvailabilityUseCase,
        createBookingUseCase: CreateAdventureBookingUseCase
    ) {
        self.state = AdventureComboBuilderState(
            items: prefilledItems.isEmpty ? [AdventureActivityType.defaultDraft(for: .offRoad)] : prefilledItems
        )
        self.getAvailabilityUseCase = getAvailabilityUseCase
        self.createBookingUseCase = createBookingUseCase
        
        keepCampingAtEnd()
    }
    
    func onAppear() {
        Task { await loadAvailability() }
    }
    
    func canAddItem(_ activity: AdventureActivityType) -> Bool {
        !state.items.contains(where: { $0.activity == activity })
    }

    var availableActivitiesToAdd: [AdventureActivityType] {
        AdventureActivityType.allCases.filter { activity in
            canAddItem(activity)
        }
    }
    
    func addItem(_ activity: AdventureActivityType) {
        guard canAddItem(activity) else {
            state.errorMessage = "\(activity.title) ya fue agregada a esta reserva."
            return
        }
        
        state.items.append(AdventureActivityType.defaultDraft(for: activity))
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func updateItem(_ item: AdventureReservationItemDraft) {
        guard let index = state.items.firstIndex(where: { $0.id == item.id }) else { return }
        state.items[index] = item
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func removeItem(at offsets: IndexSet) {
        state.items.remove(atOffsets: offsets)
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func moveItems(from source: IndexSet, to destination: Int) {
        state.items.move(fromOffsets: source, toOffset: destination)
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func setDate(_ date: Date) {
        state.selectedDate = date
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func setClientName(_ value: String) { state.clientName = value }
    func setWhatsapp(_ value: String) { state.whatsappNumber = value }
    func setNationalId(_ value: String) { state.nationalId = value }
    func setNotes(_ value: String) { state.notes = value }
    
    func selectSlot(_ slot: AdventureAvailabilitySlot) {
        state.selectedSlot = slot
    }
    
    func dismissMessage() {
        state.errorMessage = nil
        state.successMessage = nil
    }
    
    func submit(clientId: String?) {
        Task { await submitReservation(clientId: clientId) }
    }
    
    var estimatedSubtotal: Double {
        AdventurePricingEngine.estimatedSubtotal(items: state.items)
    }
    
    func reset() {
        state = AdventureComboBuilderState(
            items: [AdventureActivityType.defaultDraft(for: .offRoad)]
        )
        keepCampingAtEnd()
        Task { await loadAvailability() }
    }

    func replaceItems(with items: [AdventureReservationItemDraft]) {
        let uniqueItems = items.reduce(into: [AdventureReservationItemDraft]()) { result, item in
            guard !result.contains(where: { $0.activity == item.activity }) else { return }
            result.append(item)
        }
        
        state.items = uniqueItems.isEmpty
            ? [AdventureActivityType.defaultDraft(for: .offRoad)]
            : uniqueItems
        
        keepCampingAtEnd()
        state.selectedSlot = nil
        state.errorMessage = nil
        state.successMessage = nil
        Task { await loadAvailability() }
    }
    
    private func loadAvailability() async {
        state.isLoadingAvailability = true
        state.errorMessage = nil
        
        do {
            let slots = try await getAvailabilityUseCase.execute(
                date: state.selectedDate,
                items: state.items
            )
            state.availableSlots = slots
            if let selected = state.selectedSlot {
                state.selectedSlot = slots.first(where: { $0.startAt == selected.startAt && $0.endAt == selected.endAt })
            } else {
                state.selectedSlot = slots.first
            }
        } catch {
            state.availableSlots = []
            state.selectedSlot = nil
            state.errorMessage = error.localizedDescription
        }
        
        state.isLoadingAvailability = false
    }
    
    private func submitReservation(clientId: String?) async {
        guard !state.items.isEmpty else {
            state.errorMessage = "Add at least one activity."
            return
        }
        
        guard !state.clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.errorMessage = "Please enter the client name."
            return
        }
        
        let whatsappDigits = state.whatsappNumber.filter(\.isNumber)
        guard whatsappDigits.count >= 7 else {
            state.errorMessage = "Please enter a valid WhatsApp number."
            return
        }
        
        let nationalIdDigits = state.nationalId.filter(\.isNumber)
        guard nationalIdDigits.count >= 8 else {
            state.errorMessage = "Please enter a valid national ID."
            return
        }
        
        guard let slot = state.selectedSlot else {
            state.errorMessage = "Please choose an available start time."
            return
        }
        
        state.isSubmitting = true
        state.errorMessage = nil
        
        let request = AdventureBookingRequest(
            clientId: clientId,
            clientName: state.clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            whatsappNumber: whatsappDigits,
            nationalId: nationalIdDigits,
            date: state.selectedDate,
            selectedStartAt: slot.startAt,
            items: state.items,
            notes: state.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : state.notes
        )
        
        do {
            let booking = try await createBookingUseCase.execute(request)
            state.successMessage = "Reservation confirmed for \(booking.clientName) at \(AdventureDateHelper.timeText(booking.startAt))."
            await loadAvailability()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        
        state.isSubmitting = false
    }
    
    private func keepCampingAtEnd() {
        let campingItems = state.items.filter { $0.activity == .camping }
        let otherItems = state.items.filter { $0.activity != .camping }
        state.items = otherItems + campingItems
    }
}
