//
//  AdventureModelFactory.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

final class AdventureModuleFactory {
    private let service: AdventureBookingsServiceable
    
    init(service: AdventureBookingsServiceable = FirestoreAdventureBookingsService()) {
        self.service = service
    }
    
    func makeBuilderViewModel(
        prefilledItems: [AdventureReservationItemDraft] = []
    ) -> AdventureComboBuilderViewModel {
        AdventureComboBuilderViewModel(
            prefilledItems: prefilledItems,
            getAvailabilityUseCase: GetAdventureAvailabilityUseCase(service: service),
            createBookingUseCase: CreateAdventureBookingUseCase(service: service)
        )
    }
    
    func makeBookingsViewModel() -> AdventureBookingsViewModel {
        AdventureBookingsViewModel(
            observeBookingsUseCase: ObserveAdventureBookingsUseCase(service: service),
            cancelBookingUseCase: CancelAdventureBookingUseCase(service: service)
        )
    }
}
