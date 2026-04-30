//
//  OrdersService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore

final class OrdersService: OrdersServiceable {
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

    func submit(order: Order) async throws {
        let trustedOrder = try await makeTrustedOrder(from: order)

        let now = Date()
        guard trustedOrder.scheduledAt >= now.addingTimeInterval(-120) else {
            throw makeError(
                code: 20,
                message: "La fecha de la reserva ya pasó. Elige una hora actual o futura."
            )
        }

        if trustedOrder.shouldConsumeCurrentMenuStock {
            try await submitAndConsumeCurrentStock(order: trustedOrder)
        } else {
            try await submitFutureFoodReservation(order: trustedOrder)
        }

        if let nationalId = trustedOrder.nationalId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !nationalId.isEmpty,
           !trustedOrder.appliedRewards.isEmpty {
            try await loyaltyRewardsService.reserveRewards(
                nationalId: nationalId,
                referenceType: .order,
                referenceId: trustedOrder.id,
                appliedRewards: trustedOrder.appliedRewards
            )
        }
    }

    private func makeTrustedOrder(from order: Order) async throws -> Order {
        let uid = try requireCurrentUid()

        let cleanNationalId = order.nationalId?.filter(\.isNumber) ?? ""
        guard !cleanNationalId.isEmpty else {
            throw makeError(code: 21, message: "No se encontró una cédula asociada a esta cuenta.")
        }

        let trustedItems = try await order.items.asyncMap { item -> OrderItem in
            let ref = db.collection(FirestoreConstants.restaurant_menu_items).document(item.menuItemId)
            let snapshot = try await ref.getDocument()
            let dto = try snapshot.data(as: MenuItemDto.self)
            let menuItem = dto.toDomain()

            return OrderItem(
                menuItemId: menuItem.id,
                name: menuItem.name,
                unitPrice: menuItem.finalPrice,
                quantity: max(1, item.quantity),
                preparedQuantity: 0,
                notes: item.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        let preview = try await loyaltyRewardsService.previewRestaurantRewards(
            for: cleanNationalId,
            items: trustedItems
        )

        let cleanTable = order.tableNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTable.isEmpty || order.isScheduledForLater else {
            throw makeError(code: 22, message: "Completa la mesa para pedidos inmediatos.")
        }

        return order
            .withClientId(uid)
            .withTrustedPricing(
                items: trustedItems,
                appliedRewards: preview.appliedRewards,
                discount: preview.totalDiscount
            )
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
                        throw self.makeError(code: 1, message: "\(item.dto.name) no está disponible.")
                    }

                    guard item.dto.remainingQuantity >= item.totalQuantity else {
                        throw self.makeError(code: 2, message: "Ya no hay suficiente stock de \(item.dto.name).")
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
        AsyncThrowingStream { continuation in
            guard let uid = auth.currentUser?.uid, !uid.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let listener = db
                .collection(FirestoreConstants.restaurant_orders)
                .whereField("nationalId", isEqualTo: nationalId)
                .order(by: "scheduledAt", descending: true)
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

    private func requireCurrentUid() throws -> String {
        guard let uid = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines),
              !uid.isEmpty else {
            throw makeError(code: 401, message: "Debes iniciar sesión nuevamente para enviar el pedido.")
        }

        return uid
    }

    private func makeError(code: Int, message: String) -> NSError {
        NSError(
            domain: "OrdersService",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

private extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
        var values: [T] = []
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}
