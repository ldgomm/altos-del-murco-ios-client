//
//  AdventureBookingsServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation

protocol AdventureBookingsServiceable {
    func observeBookings(
        for day: Date,
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken
    
    func fetchAvailability(
        for date: Date,
        items: [AdventureReservationItemDraft]
    ) async throws -> [AdventureAvailabilitySlot]
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking
    
    func cancelBooking(id: String, nationalId: String) async throws
}
