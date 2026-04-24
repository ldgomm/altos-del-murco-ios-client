//
//  AdventureUseCases.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

struct GetAdventureAvailabilityUseCase {
    let service: AdventureBookingsServiceable

    func execute(
        date: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double
    ) async throws -> [AdventureAvailabilitySlot] {
        try await service.fetchAvailability(
            for: date,
            items: items,
            foodReservation: foodReservation,
            packageDiscountAmount: packageDiscountAmount
        )
    }
}

struct CreateAdventureBookingUseCase {
    let service: AdventureBookingsServiceable

    func execute(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        try await service.createBooking(request)
    }
}

struct ObserveAdventureBookingsUseCase {
    let service: AdventureBookingsServiceable

    func execute(
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        service.observeBookings(
            nationalId: nationalId,
            onChange: onChange
        )
    }
}

struct CancelAdventureBookingUseCase {
    let service: AdventureBookingsServiceable

    func execute(
        id: String,
        nationalId: String
    ) async throws {
        try await service.cancelBooking(id: id, nationalId: nationalId)
    }
}
