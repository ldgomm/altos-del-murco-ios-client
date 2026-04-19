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
    private let catalogService: AdventureCatalogServiceable

    init(
        db: Firestore = Firestore.firestore(),
        catalogService: AdventureCatalogServiceable
    ) {
        self.db = db
        self.catalogService = catalogService
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
                        let dto = try document.data(as: AdventureBookingDto.self)
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
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double
    ) async throws -> [AdventureAvailabilitySlot] {
        let catalog = try await catalogService.fetchCatalog()

        return AdventurePlanner.buildAvailability(
            day: date,
            items: items,
            foodReservation: foodReservation,
            packageDiscountAmount: packageDiscountAmount,
            catalog: catalog
        )
    }

    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        let catalog = try await catalogService.fetchCatalog()

        guard let plan = AdventurePlanner.buildPlan(
            day: request.date,
            startAt: request.selectedStartAt,
            items: request.items,
            foodReservation: request.foodReservation,
            packageDiscountAmount: request.packageDiscountAmount,
            catalog: catalog
        ) else {
            throw makeError("Invalid reservation configuration.")
        }

        let createdAt = Date()
        let bookingRef = db.collection(bookingsCollection).document()
        let dto = AdventureBookingDto.from(
            bookingId: bookingRef.documentID,
            request: request,
            plan: plan,
            createdAt: createdAt
        )

        let encodedBooking = try Firestore.Encoder().encode(dto)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            bookingRef.setData(encodedBooking) { error in
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

        let dto = try snapshot.data(as: AdventureBookingDto.self)
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

    private func makeError(_ message: String) -> NSError {
        NSError(
            domain: "AdventureBookingsService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
