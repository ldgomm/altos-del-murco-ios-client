//
//  FirestoreAdventureBookingsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation
import FirebaseFirestore

final class AdventureBookingsService: AdventureBookingsServiceable {
    private let db: Firestore
    private let bookingsCollection = "adventure_bookings"
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func observeBookings(
            for day: Date,
            nationalId: String,
            onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
        ) -> AdventureListenerToken {
            let dayKey = AdventureDateHelper.dayKey(from: day)
            let nationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let registration = db.collection(bookingsCollection)
                .whereField("nationalId", isEqualTo: nationalId)
                .whereField("startDayKey", isEqualTo: dayKey)
                .order(by: "startAt")
                .addSnapshotListener { snapshot, error in
                    if let error {
                        onChange(.failure(error))
                        return
                    }
                    
                    guard let snapshot else {
                        onChange(.success([]))
                        return
                    }
                    
                    do {
                        let bookings = try snapshot.documents.map { document in
                            let dto = try document.data(as: AdventureBookingDTO.self)
                            return dto.toDomain(documentId: document.documentID)
                        }
                        onChange(.success(bookings))
                    } catch {
                        onChange(.failure(error))
                    }
                }
            
            return FirestoreAdventureListenerToken(registration: registration)
        }
    
    func fetchAvailability(
        for date: Date,
        items: [AdventureReservationItemDraft]
    ) async throws -> [AdventureAvailabilitySlot] {
        AdventurePlanner.buildAvailability(day: date, items: items)
    }
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        guard let plan = AdventurePlanner.buildPlan(
            day: request.date,
            startAt: request.selectedStartAt,
            items: request.items
        ) else {
            throw makeError("Invalid reservation configuration.")
        }
        
        let createdAt = Date()
        
        let bookingRef = db.collection(bookingsCollection).document()
        let dto = AdventureBookingDTO.from(
            bookingId: bookingRef.documentID,
            request: request,
            plan: plan,
            createdAt: createdAt
        )
        
        let encodedBooking = try Firestore.Encoder().encode(dto)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in            bookingRef.setData(encodedBooking) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        return dto.toDomain(documentId: bookingRef.documentID)
    }
    
    func cancelBooking(id: String, nationalId: String) async throws {
        let bookingRef = db.collection(bookingsCollection).document(id)
        let snapshot = try await bookingRef.getDocument()
        
        guard snapshot.exists else {
            throw makeError("Booking not found.")
        }
        
        let dto = try snapshot.data(as: AdventureBookingDTO.self)
        guard dto.nationalId == nationalId else {
            throw makeError("You are not allowed to cancel this booking.")
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            bookingRef.updateData(
                ["status": AdventureBookingStatus.canceled.rawValue]
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func getDocuments(query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { continuation in
            query.getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: self.makeError("Failed to fetch inventory."))
                }
            }
        }
    }
    
    private func makeError(_ message: String) -> NSError {
        NSError(
            domain: "AdventureBookingsService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
