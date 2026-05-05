//
//  FirestoreAdventureBookingsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

private final class EmptyAdventureListenerToken: AdventureListenerToken {
    func remove() { }
}

final class AdventureBookingsService: AdventureBookingsServiceable {
    private let db: Firestore
    private let bookingsCollection = FirestoreConstants.adventure_bookings
    private let auth: Auth
    private let catalogService: AdventureCatalogServiceable
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        auth: Auth = Auth.auth(),
        catalogService: AdventureCatalogServiceable,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.auth = auth
        self.catalogService = catalogService
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func observeBookings(
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        guard let uid = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines),
              !uid.isEmpty else {
            onChange(.success([]))
            return EmptyAdventureListenerToken()
        }

        let registration = db.collection(FirestoreConstants.adventure_bookings)
            .whereField("userId", isEqualTo: uid)
            .order(by: "startAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("❌ adventure_bookings listener error:", error.localizedDescription)
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else {
                    print("⚠️ adventure_bookings snapshot is nil")
                    onChange(.success([]))
                    return
                }

                print("✅ adventure_bookings raw docs:", snapshot.documents.count)
                print("✅ Current uid:", uid)

                var bookings: [AdventureBooking] = []
                var decodeFailures: [String] = []

                for document in snapshot.documents {
                    do {
                        let dto = try document.data(as: AdventureBookingDto.self)
                        let booking = dto.toDomain(documentId: document.documentID)
                        bookings.append(booking)
                    } catch {
                        decodeFailures.append("\(document.documentID): \(error.localizedDescription)")
                        print("❌ Failed decoding adventure_booking \(document.documentID):", error)
                        print("📄 Raw data:", document.data())
                    }
                }

                if !decodeFailures.isEmpty {
                    print("⚠️ adventure_bookings decode failures:", decodeFailures)
                }

                onChange(.success(bookings))
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
        let uid = try requireCurrentUid()

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
            userId: uid,
            clientName: request.clientName,
            whatsappNumber: request.whatsappNumber,
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
            referenceType: .booking,
            referenceId: bookingRef.documentID,
            appliedRewards: normalizedRequest.appliedRewards
        )

        return dto.toDomain(documentId: bookingRef.documentID)
    }

    func cancelBooking(id: String) async throws {
        let uid = try requireCurrentUid()
        let bookingRef = db.collection(bookingsCollection).document(id)
        let snapshot = try await bookingRef.getDocument()

        guard snapshot.exists else {
            throw makeError("Booking not found.")
        }

        let dto = try snapshot.data(as: AdventureBookingDto.self)
        let booking = dto.toDomain(documentId: id)

        guard booking.userId == uid else {
            throw makeError("You are not allowed to cancel this booking.")
        }

        if let reason = ReservationCancellationPolicy.reasonClientCannotCancel(booking) {
            throw makeError(reason)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            bookingRef.updateData([
                "status": AdventureBookingStatus.canceled.rawValue,
                "updatedAt": Timestamp(date: Date()),
                "canceledAt": Timestamp(date: Date()),
                "canceledByClientId": uid
            ]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        try await loyaltyRewardsService.releaseRewards(
            referenceId: id
        )
    }

    private func requireCurrentUid() throws -> String {
        guard let uid = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines),
              !uid.isEmpty else {
            throw makeError("Debes iniciar sesión nuevamente para continuar.")
        }

        return uid
    }

    private func makeError(_ message: String) -> NSError {
        NSError(
            domain: "AdventureBookingsService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
