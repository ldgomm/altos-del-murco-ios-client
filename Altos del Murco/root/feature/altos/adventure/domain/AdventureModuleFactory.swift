//
//  AdventureModelFactory.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

final class AdventureModuleFactory {
    private let bookingsService: AdventureBookingsServiceable
    private let catalogService: AdventureCatalogServiceable

    init(
        bookingsService: AdventureBookingsServiceable,
        catalogService: AdventureCatalogServiceable
    ) {
        self.bookingsService = bookingsService
        self.catalogService = catalogService
    }

    func makeBuilderViewModel(
        prefilledItems: [AdventureReservationItemDraft] = [],
        packageDiscountAmount: Double = 0
    ) -> AdventureComboBuilderViewModel {
        AdventureComboBuilderViewModel(
            prefilledItems: prefilledItems,
            initialPackageDiscountAmount: packageDiscountAmount,
            getAvailabilityUseCase: GetAdventureAvailabilityUseCase(service: bookingsService),
            createBookingUseCase: CreateAdventureBookingUseCase(service: bookingsService),
            fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase(service: catalogService),
            observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase(service: catalogService)
        )
    }

    func makeCatalogViewModel() -> AdventureCatalogViewModel {
        AdventureCatalogViewModel(service: catalogService)
    }
    
    func makeBookingsViewModel() -> AdventureBookingsViewModel {
        AdventureBookingsViewModel(
            observeBookingsUseCase: ObserveAdventureBookingsUseCase(service: bookingsService),
            cancelBookingUseCase: CancelAdventureBookingUseCase(service: bookingsService)
        )
    }
}
