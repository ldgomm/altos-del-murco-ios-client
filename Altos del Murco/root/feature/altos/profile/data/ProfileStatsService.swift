//
//  ProfileStatsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseFirestore

final class ProfileStatsService {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func loadStats(for nationalId: String) async throws -> ProfileStats {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else { return .empty }

        async let ordersTask = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .getDocuments()

        async let bookingsTask = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .getDocuments()

        let ordersSnapshot = try await ordersTask
        let bookingsSnapshot = try await bookingsTask

        let orders: [Order] = try ordersSnapshot.documents.compactMap { document in
            let dto = try document.data(as: OrderDto.self)
            return dto.toDomain()
        }

        let bookings: [AdventureBooking] = try bookingsSnapshot.documents.map { document in
            let dto = try document.data(as: AdventureBookingDto.self)
            return dto.toDomain(documentId: document.documentID)
        }

        let completedOrders = orders.filter { $0.recalculatedStatus() == .completed }
        let completedBookings = bookings.filter { $0.status == .completed }

        let restaurantSpent = completedOrders.reduce(0) { $0 + $1.totalAmount }
        let adventureSpent = completedBookings.reduce(0) { $0 + $1.totalAmount }
        let totalSpent = restaurantSpent + adventureSpent

        return ProfileStats(
            points: Int(totalSpent.rounded(.down)),
            completedOrders: completedOrders.count,
            completedBookings: completedBookings.count,
            restaurantSpent: restaurantSpent,
            adventureSpent: adventureSpent,
            totalSpent: totalSpent,
            level: LoyaltyLevel.from(totalSpent: totalSpent)
        )
    }
}
