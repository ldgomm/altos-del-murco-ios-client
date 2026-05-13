//
//  LoyaltyRewardsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol LoyaltyRewardsListenerToken {
    func remove()
}

final class FirestoreLoyaltyWalletListenerToken: LoyaltyRewardsListenerToken {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration?) {
        self.registration = registration
    }

    func remove() {
        registration?.remove()
        registration = nil
    }
}

private final class CompositeLoyaltyRewardsListenerToken: LoyaltyRewardsListenerToken {
    private var registrations: [ListenerRegistration]

    init(registrations: [ListenerRegistration]) {
        self.registrations = registrations
    }

    func remove() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
    }
}

@MainActor
private final class LoyaltyWalletObservationCoordinator {
    private let emit: () -> Void
    private let onFailure: (Error) -> Void

    private var hasWalletSnapshot = false
    private var hasTemplatesSnapshot = false
    private var hasOrdersSnapshot = false
    private var hasBookingsSnapshot = false

    init(
        emit: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.emit = emit
        self.onFailure = onFailure
    }

    func receiveWallet(error: Error?) {
        receive(error: error, mark: \.hasWalletSnapshot)
    }

    func receiveTemplates(error: Error?) {
        receive(error: error, mark: \.hasTemplatesSnapshot)
    }

    func receiveOrders(error: Error?) {
        receive(error: error, mark: \.hasOrdersSnapshot)
    }

    func receiveBookings(error: Error?) {
        receive(error: error, mark: \.hasBookingsSnapshot)
    }

    private func receive(
        error: Error?,
        mark keyPath: ReferenceWritableKeyPath<LoyaltyWalletObservationCoordinator, Bool>
    ) {
        if let error {
            onFailure(error)
            return
        }

        self[keyPath: keyPath] = true

        guard hasWalletSnapshot,
              hasTemplatesSnapshot,
              hasOrdersSnapshot,
              hasBookingsSnapshot else {
            return
        }

        emit()
    }
}

protocol LoyaltyRewardsServiceable {
    func loadWalletSnapshot() async throws -> RewardWalletSnapshot

    func observeWalletSnapshot(
        onChange: @escaping (Result<RewardWalletSnapshot, Error>) -> Void
    ) -> LoyaltyRewardsListenerToken

    func previewRestaurantRewards(
        items: [OrderItem]
    ) async throws -> RewardComputationResult

    func previewAdventureRewards(
        activityItems: [AdventureReservationItemDraft],
        foodItems: [ReservationFoodItemDraft],
        catalog: AdventureCatalogSnapshot
    ) async throws -> RewardComputationResult

    func reserveRewards(
        referenceType: LoyaltyRewardReferenceType,
        referenceId: String,
        appliedRewards: [AppliedReward]
    ) async throws

    func consumeRewards(
        referenceId: String
    ) async throws

    func releaseRewards(
        referenceId: String
    ) async throws
}

func currentUserId() -> String? {
    let auth: Auth = Auth.auth()
    let value = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return value.isEmpty ? nil : value
}

final class LoyaltyRewardsService: LoyaltyRewardsServiceable {
    private let db: Firestore
    private let auth: Auth

    init(
        db: Firestore = Firestore.firestore(),
        auth: Auth = Auth.auth()
    ) {
        self.db = db
        self.auth = auth
    }

    func loadWalletSnapshot() async throws -> RewardWalletSnapshot {
        guard let uid = currentUserId else {
            return .empty()
        }

        async let templatesTask = fetchTemplates()
        async let totalsTask = computeTotals(forUserId: uid)
        async let walletTask = fetchWalletDocument(userId: uid)

        let templates = try await templatesTask
        let totals = try await totalsTask
        let walletDocument = try await walletTask

        let currentLevel = LoyaltyLevel.from(totalSpent: totals.totalSpent)

        let eligibleTemplates = templates
            .filter { template in
                template.isActive &&
                !template.isExpired &&
                template.triggerMode == .automatic &&
                template.isEligible(for: currentLevel) &&
                usageCount(
                    templateId: template.id,
                    inside: walletDocument.events
                ) < max(1, template.maxUsesPerClient)
            }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }

                return lhs.title < rhs.title
            }

        let reserved = walletDocument.events.filter { $0.status == .reserved }
        let consumed = walletDocument.events.filter { $0.status == .consumed }
        let released = walletDocument.events.filter { $0.status == .released }

        return RewardWalletSnapshot(
            userId: uid,
            currentLevel: currentLevel,
            totalSpent: totals.totalSpent,
            points: Int(totals.totalSpent.rounded(.down)),
            availableTemplates: eligibleTemplates,
            reservedEvents: reserved,
            consumedEvents: consumed,
            releasedEvents: released
        )
    }

    func observeWalletSnapshot(
        onChange: @escaping (Result<RewardWalletSnapshot, Error>) -> Void
    ) -> LoyaltyRewardsListenerToken {
        guard let uid = currentUserId else {
            onChange(.success(.empty()))
            return FirestoreLoyaltyWalletListenerToken(registration: nil)
        }

        let walletRef = db
            .collection(FirestoreConstants.client_loyalty_wallets)
            .document(uid)

        let templatesRef = db
            .collection(FirestoreConstants.loyalty_reward_templates)

        let ordersQuery = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("userId", isEqualTo: uid)

        let bookingsQuery = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("userId", isEqualTo: uid)

        let coordinator = LoyaltyWalletObservationCoordinator(
            emit: { [weak self] in
                guard let self else { return }

                Task {
                    do {
                        let snapshot = try await self.loadWalletSnapshot()
                        await MainActor.run {
                            onChange(.success(snapshot))
                        }
                    } catch {
                        await MainActor.run {
                            onChange(.failure(error))
                        }
                    }
                }
            },
            onFailure: { error in
                onChange(.failure(error))
            }
        )

        let walletRegistration = walletRef.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveWallet(error: error)
            }
        }

        let templatesRegistration = templatesRef.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveTemplates(error: error)
            }
        }

        let ordersRegistration = ordersQuery.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveOrders(error: error)
            }
        }

        let bookingsRegistration = bookingsQuery.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveBookings(error: error)
            }
        }

        return CompositeLoyaltyRewardsListenerToken(
            registrations: [
                walletRegistration,
                templatesRegistration,
                ordersRegistration,
                bookingsRegistration
            ]
        )
    }

    func previewRestaurantRewards(
        items: [OrderItem]
    ) async throws -> RewardComputationResult {
        let wallet = try await loadWalletSnapshot()

        let lines = items.map { item in
            RewardMenuLine(
                menuItemId: item.menuItemId,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity
            )
        }

        return LoyaltyRewardEngine.evaluateRestaurant(
            templates: wallet.availableTemplates,
            wallet: wallet,
            menuLines: lines
        )
    }

    func previewAdventureRewards(
        activityItems: [AdventureReservationItemDraft],
        foodItems: [ReservationFoodItemDraft],
        catalog: AdventureCatalogSnapshot
    ) async throws -> RewardComputationResult {
        let wallet = try await loadWalletSnapshot()

        let activityLines = activityItems.compactMap { item -> RewardActivityLine? in
            guard let activity = catalog.activity(for: item.activity) else {
                return nil
            }

            let linePrice = AdventurePricingEngine.subtotal(
                for: item,
                catalog: catalog
            )

            return RewardActivityLine(
                activityId: activity.id,
                title: activity.title,
                linePrice: linePrice
            )
        }

        let foodLines = foodItems.map { item in
            RewardMenuLine(
                menuItemId: item.menuItemId,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity
            )
        }

        return LoyaltyRewardEngine.evaluateAdventure(
            templates: wallet.availableTemplates,
            wallet: wallet,
            activityLines: activityLines,
            foodLines: foodLines
        )
    }

    func reserveRewards(
        referenceType: LoyaltyRewardReferenceType,
        referenceId: String,
        appliedRewards: [AppliedReward]
    ) async throws {
        guard !appliedRewards.isEmpty else { return }
        guard let uid = currentUserId else { return }

        let walletRef = db
            .collection(FirestoreConstants.client_loyalty_wallets)
            .document(uid)

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let walletDocument = try Self.loadWalletDocument(
                    from: transaction,
                    walletRef: walletRef
                )

                var events = walletDocument.events

                for reward in appliedRewards {
                    let templateRef = self.db
                        .collection(FirestoreConstants.loyalty_reward_templates)
                        .document(reward.templateId)

                    let templateSnapshot = try transaction.getDocument(templateRef)

                    guard templateSnapshot.exists else {
                        throw NSError(
                            domain: "LoyaltyRewardsService",
                            code: 10,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Reward template \(reward.templateId) no longer exists."
                            ]
                        )
                    }

                    let templateDto = try templateSnapshot.data(as: LoyaltyRewardTemplateDto.self)
                    let template = templateDto.toDomain()

                    guard template.isActive, !template.isExpired else {
                        throw NSError(
                            domain: "LoyaltyRewardsService",
                            code: 11,
                            userInfo: [
                                NSLocalizedDescriptionKey: "The reward \(template.title) is no longer available."
                            ]
                        )
                    }

                    let alreadyUsed = Self.usageCount(
                        templateId: reward.templateId,
                        inside: events
                    )

                    guard alreadyUsed < max(1, template.maxUsesPerClient) else {
                        throw NSError(
                            domain: "LoyaltyRewardsService",
                            code: 12,
                            userInfo: [
                                NSLocalizedDescriptionKey: "The reward \(template.title) is no longer available."
                            ]
                        )
                    }

                    events.append(
                        LoyaltyWalletEvent(
                            id: reward.id,
                            templateId: reward.templateId,
                            templateTitle: reward.title,
                            referenceType: referenceType,
                            referenceId: referenceId,
                            status: .reserved,
                            amount: reward.amount,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    )
                }

                let updated = LoyaltyWalletDocument(
                    userId: uid,
                    updatedAt: Date(),
                    events: events
                )

                try transaction.setData(
                    from: updated,
                    forDocument: walletRef,
                    merge: true
                )

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func consumeRewards(
        referenceId: String
    ) async throws {
        try await mutateReferenceStatus(
            referenceId: referenceId,
            targetStatus: .consumed
        )
    }

    func releaseRewards(
        referenceId: String
    ) async throws {
        try await mutateReferenceStatus(
            referenceId: referenceId,
            targetStatus: .released
        )
    }

    private func mutateReferenceStatus(
        referenceId: String,
        targetStatus: LoyaltyWalletEventStatus
    ) async throws {
        guard let uid = currentUserId else { return }

        let walletRef = db
            .collection(FirestoreConstants.client_loyalty_wallets)
            .document(uid)

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let wallet = try Self.loadWalletDocument(
                    from: transaction,
                    walletRef: walletRef
                )

                let updatedEvents = wallet.events.map { event in
                    guard event.referenceId == referenceId else {
                        return event
                    }

                    guard event.status == .reserved else {
                        return event
                    }

                    return LoyaltyWalletEvent(
                        id: event.id,
                        templateId: event.templateId,
                        templateTitle: event.templateTitle,
                        referenceType: event.referenceType,
                        referenceId: event.referenceId,
                        status: targetStatus,
                        amount: event.amount,
                        createdAt: event.createdAt,
                        updatedAt: Date()
                    )
                }

                let updated = LoyaltyWalletDocument(
                    userId: uid,
                    updatedAt: Date(),
                    events: updatedEvents
                )

                try transaction.setData(
                    from: updated,
                    forDocument: walletRef,
                    merge: true
                )

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func fetchTemplates() async throws -> [LoyaltyRewardTemplate] {
        let snapshot = try await db
            .collection(FirestoreConstants.loyalty_reward_templates)
            .getDocuments()

        return try snapshot.documents
            .map { document in
                try document.data(as: LoyaltyRewardTemplateDto.self).toDomain()
            }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }

                return lhs.title < rhs.title
            }
    }

    private func fetchWalletDocument(
        userId: String
    ) async throws -> LoyaltyWalletDocument {
        let ref = db
            .collection(FirestoreConstants.client_loyalty_wallets)
            .document(userId)

        let snapshot = try await ref.getDocument()

        guard snapshot.exists else {
            return LoyaltyWalletDocument(
                userId: userId,
                updatedAt: Date(),
                events: []
            )
        }

        return try snapshot.data(as: LoyaltyWalletDocument.self)
    }

    private func computeTotals(
        forUserId userId: String
    ) async throws -> (
        restaurantSpent: Double,
        adventureSpent: Double,
        totalSpent: Double
    ) {
        async let ordersTask = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        async let bookingsTask = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let orderSnapshot = try await ordersTask
        let bookingSnapshot = try await bookingsTask

        let orders: [Order] = try orderSnapshot.documents.compactMap { document in
            let dto = try document.data(as: OrderDto.self)
            return dto.toDomain()
        }

        let bookings: [AdventureBooking] = try bookingSnapshot.documents.compactMap { document in
            let dto = try document.data(as: AdventureBookingDto.self)
            return dto.toDomain(documentId: document.documentID)
        }

        // Restaurant revenue starts only when the order is paid.
        let paidOrders = orders.filter { order in
            order.recalculatedStatus() == .paid
        }

        // Adventure keeps its own completed lifecycle.
        let completedBookings = bookings.filter { booking in
            booking.status == .completed
        }

        let restaurantSpent = paidOrders.reduce(0) { partial, order in
            partial + order.totalAmount
        }

        let adventureSpent = completedBookings.reduce(0) { partial, booking in
            partial + booking.totalAmount
        }

        return (
            restaurantSpent: restaurantSpent,
            adventureSpent: adventureSpent,
            totalSpent: restaurantSpent + adventureSpent
        )
    }

    private var currentUserId: String? {
        let value = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private func usageCount(
        templateId: String,
        inside events: [LoyaltyWalletEvent]
    ) -> Int {
        Self.usageCount(
            templateId: templateId,
            inside: events
        )
    }

    private static func usageCount(
        templateId: String,
        inside events: [LoyaltyWalletEvent]
    ) -> Int {
        events.filter { event in
            event.templateId == templateId &&
            (event.status == .reserved || event.status == .consumed)
        }
        .count
    }

    private static func loadWalletDocument(
        from transaction: Transaction,
        walletRef: DocumentReference
    ) throws -> LoyaltyWalletDocument {
        let snapshot = try transaction.getDocument(walletRef)

        guard snapshot.exists else {
            return LoyaltyWalletDocument(
                userId: walletRef.documentID,
                updatedAt: Date(),
                events: []
            )
        }

        return try snapshot.data(as: LoyaltyWalletDocument.self)
    }
}
