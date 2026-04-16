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
        foodReservation: ReservationFoodDraft?
    ) async throws -> [AdventureAvailabilitySlot] {
        try await service.fetchAvailability(
            for: date,
            items: items,
            foodReservation: foodReservation
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
        day: Date,
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        service.observeBookings(for: day, nationalId: nationalId, onChange: onChange)
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
