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
        packageType: AdventurePackageType,
        offRoadHours: Int,
        peopleCount: Int
    ) async throws -> [AdventureAvailabilitySlot] {
        try await service.fetchAvailability(
            for: date,
            packageType: packageType,
            offRoadHours: offRoadHours,
            peopleCount: peopleCount
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
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        service.observeBookings(for: day, onChange: onChange)
    }
}

struct CancelAdventureBookingUseCase {
    let service: AdventureBookingsServiceable
    
    func execute(id: String) async throws {
        try await service.cancelBooking(id: id)
    }
}
