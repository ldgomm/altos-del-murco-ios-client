//
//  OrdersService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import FirebaseFirestore

final class OrdersService: OrdersServiceable {
    private let db: Firestore
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func submit(order: Order) async throws {
        let now = Date()
        guard order.scheduledAt >= now.addingTimeInterval(-120) else {
            throw NSError(
                domain: "OrdersService",
                code: 20,
                userInfo: [NSLocalizedDescriptionKey: "La fecha de la reserva ya pasó. Elige una hora actual o futura."]
            )
        }

        if order.shouldConsumeCurrentMenuStock {
            try await submitAndConsumeCurrentStock(order: order)
        } else {
            try await submitFutureFoodReservation(order: order)
        }

        if let nationalId = order.nationalId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !nationalId.isEmpty,
           !order.appliedRewards.isEmpty {
            try await loyaltyRewardsService.reserveRewards(
                nationalId: nationalId,
                referenceType: .order,
                referenceId: order.id,
                appliedRewards: order.appliedRewards
            )
        }
    }

    private func submitFutureFoodReservation(order: Order) async throws {
        let dto = OrderDto(from: order)
        let orderData = try Firestore.Encoder().encode(dto)
        try await db
            .collection(FirestoreConstants.restaurant_orders)
            .document(order.id)
            .setData(orderData, merge: true)
    }

    private func submitAndConsumeCurrentStock(order: Order) async throws {
        let quantitiesByMenuItemId = Dictionary(grouping: order.items, by: \.menuItemId)
            .compactMapValues { items in
                let total = items.reduce(0) { $0 + $1.quantity }
                return total > 0 ? total : nil
            }

        let menuItemsToProcess: [(ref: DocumentReference, totalQuantity: Int)] = quantitiesByMenuItemId.map { menuItemId, totalQuantity in
            (
                ref: self.db.collection(FirestoreConstants.restaurant_menu_items).document(menuItemId),
                totalQuantity: totalQuantity
            )
        }

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                var loadedItems: [(ref: DocumentReference, dto: MenuItemDto, totalQuantity: Int)] = []

                for item in menuItemsToProcess {
                    let snapshot = try transaction.getDocument(item.ref)
                    let dto = try snapshot.data(as: MenuItemDto.self)
                    loadedItems.append((ref: item.ref, dto: dto, totalQuantity: item.totalQuantity))
                }

                for item in loadedItems {
                    guard item.dto.isAvailable else {
                        throw NSError(domain: "OrdersService", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(item.dto.name) no está disponible."])
                    }

                    guard item.dto.remainingQuantity >= item.totalQuantity else {
                        throw NSError(domain: "OrdersService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ya no hay suficiente stock de \(item.dto.name)."])
                    }

                    let newRemainingQuantity = item.dto.remainingQuantity - item.totalQuantity
                    transaction.updateData([
                        "remainingQuantity": newRemainingQuantity,
                        "isAvailable": newRemainingQuantity > 0,
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: item.ref)
                }

                let dto = OrderDto(from: order)
                let orderData = try Firestore.Encoder().encode(dto)
                let orderRef = self.db.collection(FirestoreConstants.restaurant_orders).document(order.id)
                transaction.setData(orderData, forDocument: orderRef, merge: true)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func observeOrders(for nationalId: String) -> AsyncThrowingStream<[Order], Error> {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        return AsyncThrowingStream { continuation in
            guard !cleanNationalId.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let listener = db
                .collection(FirestoreConstants.restaurant_orders)
                .whereField("nationalId", isEqualTo: cleanNationalId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }

                    do {
                        let orders = try documents
                            .compactMap { try $0.data(as: OrderDto.self).toDomain() }
                            .sorted {
                                if $0.scheduledAt != $1.scheduledAt { return $0.scheduledAt > $1.scheduledAt }
                                return $0.createdAt > $1.createdAt
                            }
                        continuation.yield(orders)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }

            continuation.onTermination = { _ in listener.remove() }
        }
    }
}
