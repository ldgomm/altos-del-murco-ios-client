//
//  AdventureRevervationViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Combine
import SwiftUI

struct AdventureReservationState {
    var selectedDate: Date = Date()
    var selectedPackage: AdventurePackageType
    var offRoadHours: Int = 1
    var peopleCount: Int = 1
    var clientName: String = ""
    var notes: String = ""
    
    var availableSlots: [AdventureAvailabilitySlot] = []
    var selectedSlot: AdventureAvailabilitySlot?
    
    var isLoadingAvailability = false
    var isSubmitting = false
    var errorMessage: String?
    var successMessage: String?
}

enum AdventureReservationEvent {
    case onAppear
    case selectedDateChanged(Date)
    case selectedPackageChanged(AdventurePackageType)
    case offRoadHoursChanged(Int)
    case peopleCountChanged(Int)
    case clientNameChanged(String)
    case notesChanged(String)
    case slotSelected(AdventureAvailabilitySlot)
    case submit(clientId: String?)
    case dismissMessage
}

@MainActor
final class AdventureReservationViewModel: ObservableObject {
    @Published private(set) var state: AdventureReservationState
    
    private let getAvailabilityUseCase: GetAdventureAvailabilityUseCase
    private let createBookingUseCase: CreateAdventureBookingUseCase
    
    init(
        initialPackage: AdventurePackageType,
        getAvailabilityUseCase: GetAdventureAvailabilityUseCase,
        createBookingUseCase: CreateAdventureBookingUseCase
    ) {
        self.state = AdventureReservationState(selectedPackage: initialPackage)
        self.getAvailabilityUseCase = getAvailabilityUseCase
        self.createBookingUseCase = createBookingUseCase
    }
    
    func onEvent(_ event: AdventureReservationEvent) {
        switch event {
        case .onAppear:
            Task { await loadAvailability() }
            
        case let .selectedDateChanged(date):
            state.selectedDate = date
            state.selectedSlot = nil
            Task { await loadAvailability() }
            
        case let .selectedPackageChanged(package):
            state.selectedPackage = package
            state.selectedSlot = nil
            Task { await loadAvailability() }
            
        case let .offRoadHoursChanged(hours):
            state.offRoadHours = hours
            state.selectedSlot = nil
            Task { await loadAvailability() }
            
        case let .peopleCountChanged(count):
            state.peopleCount = count
            state.selectedSlot = nil
            Task { await loadAvailability() }
            
        case let .clientNameChanged(name):
            state.clientName = name
            
        case let .notesChanged(notes):
            state.notes = notes
            
        case let .slotSelected(slot):
            state.selectedSlot = slot
            
        case let .submit(clientId):
            Task { await submit(clientId: clientId) }
            
        case .dismissMessage:
            state.errorMessage = nil
            state.successMessage = nil
        }
    }
    
    private func loadAvailability() async {
        state.isLoadingAvailability = true
        state.errorMessage = nil
        
        do {
            let slots = try await getAvailabilityUseCase.execute(
                date: state.selectedDate,
                packageType: state.selectedPackage,
                offRoadHours: state.selectedPackage.includesOffRoad ? state.offRoadHours : 0,
                peopleCount: state.peopleCount
            )
            
            state.availableSlots = slots
            
            if let selectedSlot = state.selectedSlot {
                state.selectedSlot = slots.first(where: { $0.id == selectedSlot.id })
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
    
    private func submit(clientId: String?) async {
        guard !state.clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.errorMessage = "Please enter the client name."
            return
        }
        
        guard let selectedSlot = state.selectedSlot else {
            state.errorMessage = "Please select an available time."
            return
        }
        
        state.isSubmitting = true
        state.errorMessage = nil
        
        let request = AdventureBookingRequest(
            clientId: clientId,
            clientName: state.clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            peopleCount: state.peopleCount,
            date: state.selectedDate,
            packageType: state.selectedPackage,
            offRoadHours: state.selectedPackage.includesOffRoad ? state.offRoadHours : 0,
            selectedStartAt: selectedSlot.startAt,
            notes: state.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : state.notes
        )
        
        do {
            let booking = try await createBookingUseCase.execute(request)
            state.successMessage = "Reservation confirmed for \(booking.clientName) at \(AdventureDateHelper.timeText(for: booking.startAt))."
            await loadAvailability()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        
        state.isSubmitting = false
    }
}
