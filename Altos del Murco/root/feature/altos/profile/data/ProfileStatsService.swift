//
//  ProfileStatsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol ProfileStatsListenerToken {
    func remove()
}

private final class EmptyProfileStatsListenerToken: ProfileStatsListenerToken {
    func remove() { }
}

private final class CompositeProfileStatsListenerToken: ProfileStatsListenerToken {
    private var registrations: [ListenerRegistration]
    private var walletListenerToken: LoyaltyRewardsListenerToken?

    init(
        registrations: [ListenerRegistration],
        walletListenerToken: LoyaltyRewardsListenerToken?
    ) {
        self.registrations = registrations
        self.walletListenerToken = walletListenerToken
    }

    func remove() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
        walletListenerToken?.remove()
        walletListenerToken = nil
    }
}

final class ProfileStatsService {
    private let db: Firestore
    private let auth: Auth
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        auth: Auth = Auth.auth(),
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.auth = auth
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func loadStats() async throws -> ProfileStats {
        guard let uid = currentUserId else { return .empty }

        async let ordersTask = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("userId", isEqualTo: uid)
            .getDocuments()

        async let bookingsTask = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("userId", isEqualTo: uid)
            .getDocuments()

        async let walletTask = loyaltyRewardsService.loadWalletSnapshot()

        let ordersSnapshot = try await ordersTask
        let bookingsSnapshot = try await bookingsTask
        let wallet = try await walletTask

        let orders: [Order] = try ordersSnapshot.documents.compactMap { document in
            let dto = try document.data(as: OrderDto.self)
            return dto.toDomain()
        }

        let bookings: [AdventureBooking] = try bookingsSnapshot.documents.compactMap { document in
            let dto = try document.data(as: AdventureBookingDto.self)
            return dto.toDomain(documentId: document.documentID)
        }

        let completedOrders = orders.filter { $0.recalculatedStatus() == .completed }
        let completedBookings = bookings.filter { $0.status == .completed }

        let restaurantSpent = completedOrders.reduce(0) { $0 + $1.totalAmount }
        let adventureSpent = completedBookings.reduce(0) { $0 + $1.totalAmount }
        let totalSpent = restaurantSpent + adventureSpent

        return ProfileStats(
            points: wallet.points,
            completedOrders: completedOrders.count,
            completedBookings: completedBookings.count,
            restaurantSpent: restaurantSpent,
            adventureSpent: adventureSpent,
            totalSpent: totalSpent,
            level: wallet.currentLevel,
            wallet: wallet
        )
    }

    func observeStats(
        onChange: @escaping (Result<ProfileStats, Error>) -> Void
    ) -> ProfileStatsListenerToken {
        guard let uid = currentUserId else {
            onChange(.success(.empty))
            return EmptyProfileStatsListenerToken()
        }

        let emit: @Sendable () -> Void = { [weak self] in
            guard let self else { return }

            Task {
                do {
                    let stats = try await self.loadStats()
                    await MainActor.run {
                        onChange(.success(stats))
                    }
                } catch {
                    await MainActor.run {
                        onChange(.failure(error))
                    }
                }
            }
        }

        let ordersRegistration = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { _, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                emit()
            }

        let bookingsRegistration = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { _, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                emit()
            }

        let walletListener = loyaltyRewardsService.observeWalletSnapshot() { result in
            switch result {
            case .success:
                emit()

            case .failure(let error):
                onChange(.failure(error))
            }
        }

        emit()

        return CompositeProfileStatsListenerToken(
            registrations: [ordersRegistration, bookingsRegistration],
            walletListenerToken: walletListener
        )
    }

    private var currentUserId: String? {
        let value = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}
