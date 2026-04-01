//
//  AdventureBookingsViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Combine
import SwiftUI

struct AdventureBookingsState {
    var selectedDate: Date = Date()
    var bookings: [AdventureBooking] = []
    var isLoading = false
    var errorMessage: String?
}

enum AdventureBookingsEvent {
    case onAppear
    case onDisappear
    case selectedDateChanged(Date)
    case cancelBooking(String)
}

@MainActor
final class AdventureBookingsViewModel: ObservableObject {
    @Published private(set) var state = AdventureBookingsState()
    
    private let observeBookingsUseCase: ObserveAdventureBookingsUseCase
    private let cancelBookingUseCase: CancelAdventureBookingUseCase
    private var listenerToken: AdventureListenerToken?
    
    init(
        observeBookingsUseCase: ObserveAdventureBookingsUseCase,
        cancelBookingUseCase: CancelAdventureBookingUseCase
    ) {
        self.observeBookingsUseCase = observeBookingsUseCase
        self.cancelBookingUseCase = cancelBookingUseCase
    }
    
    func onEvent(_ event: AdventureBookingsEvent) {
        switch event {
        case .onAppear:
            startListening()
            
        case .onDisappear:
            listenerToken?.remove()
            listenerToken = nil
            
        case let .selectedDateChanged(date):
            state.selectedDate = date
            startListening()
            
        case let .cancelBooking(id):
            Task { await cancelBooking(id: id) }
        }
    }
    
    private func startListening() {
        state.isLoading = true
        state.errorMessage = nil
        
        listenerToken?.remove()
        listenerToken = observeBookingsUseCase.execute(day: state.selectedDate) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                
                switch result {
                case let .success(bookings):
                    self.state.bookings = bookings.sorted { $0.startAt < $1.startAt }
                    self.state.isLoading = false
                    
                case let .failure(error):
                    self.state.bookings = []
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoading = false
                }
            }
        }
    }
    
    private func cancelBooking(id: String) async {
        do {
            try await cancelBookingUseCase.execute(id: id)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }
}
