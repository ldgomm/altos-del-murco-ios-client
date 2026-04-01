//
//  AdventureBookingsServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation
import FirebaseFirestore

protocol AdventureListenerToken {
    func remove()
}

final class FirestoreAdventureListenerToken: AdventureListenerToken {
    private var registration: ListenerRegistration?
    
    init(registration: ListenerRegistration) {
        self.registration = registration
    }
    
    func remove() {
        registration?.remove()
        registration = nil
    }
}

protocol AdventureBookingsServiceable {
    func observeBookings(
        for day: Date,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken
    
    func fetchAvailability(
        for date: Date,
        packageType: AdventurePackageType,
        offRoadHours: Int,
        peopleCount: Int
    ) async throws -> [AdventureAvailabilitySlot]
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking
    
    func cancelBooking(id: String) async throws
}
