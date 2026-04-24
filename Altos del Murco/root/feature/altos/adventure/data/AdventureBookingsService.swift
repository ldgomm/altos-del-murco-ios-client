//
//  FirestoreAdventureBookingsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation
import FirebaseFirestore

private final class EmptyAdventureListenerToken: AdventureListenerToken {
    func remove() { }
}

final class AdventureBookingsService: AdventureBookingsServiceable {
    private let db: Firestore
    private let bookingsCollection = "adventure_bookings"
    private let catalogService: AdventureCatalogServiceable
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        catalogService: AdventureCatalogServiceable,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.catalogService = catalogService
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func observeBookings(
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanNationalId.isEmpty else {
            onChange(.success([]))
            return EmptyAdventureListenerToken()
        }

        let registration = db.collection(bookingsCollection)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .order(by: "startAt", descending: false)
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

        guard let basePlan = AdventurePlanner.buildPlan(
            day: request.date,
            startAt: request.selectedStartAt,
            items: request.items,
            foodReservation: request.foodReservation,
            packageDiscountAmount: request.packageDiscountAmount,
            catalog: catalog
        ) else {
            throw makeError("Invalid reservation configuration.")
        }

        let rewardPreview = try await loyaltyRewardsService.previewAdventureRewards(
            for: request.nationalId,
            activityItems: request.items,
            foodItems: request.foodReservation?.items ?? [],
            catalog: catalog
        )

        let finalPlan = AdventureBuildPlan(
            startAt: basePlan.startAt,
            endAt: basePlan.endAt,
            blocks: basePlan.blocks,
            adventureSubtotal: basePlan.adventureSubtotal,
            foodSubtotal: basePlan.foodSubtotal,
            subtotal: basePlan.subtotal,
            discountAmount: basePlan.discountAmount,
            loyaltyDiscountAmount: rewardPreview.totalDiscount,
            appliedRewards: rewardPreview.appliedRewards,
            nightPremium: basePlan.nightPremium,
            totalAmount: max(0, basePlan.totalAmount - rewardPreview.totalDiscount),
            hasNightPremium: basePlan.hasNightPremium
        )

        let normalizedRequest = AdventureBookingRequest(
            clientId: request.clientId,
            clientName: request.clientName,
            whatsappNumber: request.whatsappNumber,
            nationalId: request.nationalId,
            date: request.date,
            selectedStartAt: request.selectedStartAt,
            guestCount: request.guestCount,
            eventType: request.eventType,
            customEventTitle: request.customEventTitle,
            eventNotes: request.eventNotes,
            items: request.items,
            foodReservation: request.foodReservation,
            packageDiscountAmount: request.packageDiscountAmount,
            loyaltyDiscountAmount: rewardPreview.totalDiscount,
            appliedRewards: rewardPreview.appliedRewards,
            notes: request.notes
        )

        let createdAt = Date()
        let bookingRef = db.collection(bookingsCollection).document()

        let dto = AdventureBookingDto.from(
            bookingId: bookingRef.documentID,
            request: normalizedRequest,
            plan: finalPlan,
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

        try await loyaltyRewardsService.reserveRewards(
            nationalId: normalizedRequest.nationalId,
            referenceType: .booking,
            referenceId: bookingRef.documentID,
            appliedRewards: normalizedRequest.appliedRewards
        )

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

        try await loyaltyRewardsService.releaseRewards(
            nationalId: dto.nationalId,
            referenceId: id
        )
    }

    private func makeError(_ message: String) -> NSError {
        NSError(
            domain: "AdventureBookingsService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
