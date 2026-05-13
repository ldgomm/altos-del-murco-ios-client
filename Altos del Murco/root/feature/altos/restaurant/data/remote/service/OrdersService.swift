//
//  OrdersService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum ClientOrdersServiceError: LocalizedError {
    case orderNotFound
    case forbidden
    case notAuthenticated
    case invalidOrder(String)
    case menuItemUnavailable(String)
    case insufficientStock(String)
    case cancelNotAllowed

    var errorDescription: String? {
        switch self {
        case .orderNotFound:
            return "No encontré este pedido."
        case .forbidden:
            return "No tienes permiso para modificar este pedido."
        case .notAuthenticated:
            return "Debes iniciar sesión nuevamente para continuar."
        case let .invalidOrder(message):
            return message
        case let .menuItemUnavailable(name):
            return "\(name) ya no está disponible."
        case let .insufficientStock(name):
            return "No hay suficiente stock para \(name)."
        case .cancelNotAllowed:
            return "Solo puedes cancelar pedidos pendientes. Si ya fue confirmado, escríbenos por WhatsApp."
        }
    }
}

final class OrdersService: OrdersServiceable {
    private let db: Firestore
    private let auth: Auth
    private let collection: String
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        auth: Auth = Auth.auth(),
        collection: String = FirestoreConstants.restaurant_orders,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.auth = auth
        self.collection = collection
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func submit(order: Order) async throws {
        let trustedOrder = try await makeTrustedOrder(from: order)

        let now = Date()
        guard trustedOrder.scheduledAt >= now.addingTimeInterval(-120) else {
            throw ClientOrdersServiceError.invalidOrder("La fecha de la reserva ya pasó. Elige una hora actual o futura.")
        }

        if trustedOrder.shouldConsumeCurrentMenuStock {
            try await submitAndConsumeCurrentStock(order: trustedOrder)
        } else {
            try await submitFutureFoodReservation(order: trustedOrder)
        }

        if !trustedOrder.appliedRewards.isEmpty {
            try await loyaltyRewardsService.reserveRewards(
                referenceType: .order,
                referenceId: trustedOrder.id,
                appliedRewards: trustedOrder.appliedRewards
            )
        }
    }

    func observeOrders() -> AsyncThrowingStream<[Order], Error> {
        AsyncThrowingStream { continuation in
            guard let uid = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines),
                  !uid.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let listener = db.collection(collection)
                .whereField("userId", isEqualTo: uid)
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

                    let orders = documents.compactMap { document -> Order? in
                        do {
                            let dto = try document.data(as: OrderDto.self)
                            return dto.toDomain()
                        } catch {
                            return nil
                        }
                    }
                    .sorted { lhs, rhs in
                        lhs.scheduledAt > rhs.scheduledAt
                    }

                    continuation.yield(orders)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    func cancelOrder(orderId: String, reason: String?) async throws {
        let uid = try requireCurrentUid()
        let ref = db.collection(collection).document(orderId)
        var shouldReleaseRewards = false

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let order = try Self.readOrder(from: ref, in: transaction)

                guard order.userId == uid else {
                    throw ClientOrdersServiceError.forbidden
                }

                guard order.status == .pending else {
                    throw ClientOrdersServiceError.cancelNotAllowed
                }

                let updated = order.canceling(reason: reason, now: Date())
                shouldReleaseRewards = updated.hasLoyaltyRewards

                try Self.setOrder(
                    OrderDto(domain: updated),
                    forDocument: ref,
                    in: transaction,
                    merge: true
                )
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        if shouldReleaseRewards {
            try await loyaltyRewardsService.releaseRewards(referenceId: orderId)
        }
    }

    private func makeTrustedOrder(from order: Order) async throws -> Order {
        let uid = try requireCurrentUid()
        let cleanTable = order.tableNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTable.isEmpty || order.isScheduledForLater else {
            throw ClientOrdersServiceError.invalidOrder("Completa la mesa para pedidos inmediatos.")
        }

        let uniqueMenuItemIds = Array(Set(order.items.map(\.menuItemId)))
        var menuItemsById: [String: MenuItem] = [:]

        for menuItemId in uniqueMenuItemIds {
            let ref = db.collection(FirestoreConstants.restaurant_menu_items).document(menuItemId)
            let snapshot = try await ref.getDocument()
            let dto = try snapshot.data(as: MenuItemDto.self)
            let menuItem = dto.toDomain()
            menuItemsById[menuItem.id] = menuItem
        }

        let trustedItems = try order.items.map { source -> OrderItem in
            guard let menuItem = menuItemsById[source.menuItemId] else {
                throw ClientOrdersServiceError.invalidOrder("No encontré uno de los platos del pedido.")
            }

            return OrderItem(
                id: source.id,
                groupId: source.groupId,
                sourceCartItemId: source.sourceCartItemId,
                menuItemId: menuItem.id,
                name: menuItem.name,
                itemDescription: menuItem.description,
                unitPrice: menuItem.finalPrice,
                quantity: 1,
                notes: source.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
                status: .pending,
                createdAt: source.createdAt
            )
        }

        let preview = try await loyaltyRewardsService.previewRestaurantRewards(
            items: trustedItems
        )

        return order
            .withClientId(uid)
            .withTrustedPricing(
                items: trustedItems,
                appliedRewards: preview.appliedRewards,
                discount: preview.totalDiscount
            )
            .replacing(status: .pending)
    }

    private func submitAndConsumeCurrentStock(order: Order) async throws {
        let orderRef = db.collection(collection).document(order.id)
        let menuCounts = Dictionary(grouping: order.items.filter(\.isActive), by: \.menuItemId)
            .mapValues { items in items.reduce(0) { $0 + $1.quantity } }
        let now = Date()

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                var stockUpdates: [(DocumentReference, Int)] = []

                for (menuItemId, requestedQuantity) in menuCounts {
                    let menuRef = self.db.collection(FirestoreConstants.restaurant_menu_items).document(menuItemId)
                    let snapshot = try transaction.getDocument(menuRef)
                    let dto = try snapshot.data(as: MenuItemDto.self)
                    let menuItem = dto.toDomain()

                    guard menuItem.isAvailable else {
                        throw ClientOrdersServiceError.menuItemUnavailable(menuItem.name)
                    }

                    guard menuItem.remainingQuantity >= requestedQuantity else {
                        throw ClientOrdersServiceError.insufficientStock(menuItem.name)
                    }

                    stockUpdates.append((menuRef, menuItem.remainingQuantity - requestedQuantity))
                }

                let cleanOrder = order.replacing(updatedAt: now, status: .pending)
                try Self.setOrder(
                    OrderDto(domain: cleanOrder),
                    forDocument: orderRef,
                    in: transaction,
                    merge: false
                )

                for (menuRef, newRemainingQuantity) in stockUpdates {
                    transaction.updateData(
                        [
                            "remainingQuantity": newRemainingQuantity,
                            "updatedAt": Timestamp(date: now)
                        ],
                        forDocument: menuRef
                    )
                }

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func submitFutureFoodReservation(order: Order) async throws {
        let cleanOrder = order.replacing(updatedAt: Date(), status: .pending)
        let dto = OrderDto(domain: cleanOrder)
        let encoded = try Firestore.Encoder().encode(dto)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(collection).document(cleanOrder.id).setData(encoded, merge: false) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func requireCurrentUid() throws -> String {
        guard let uid = auth.currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines),
              !uid.isEmpty else {
            throw ClientOrdersServiceError.notAuthenticated
        }

        return uid
    }

    private static func readOrder(
        from ref: DocumentReference,
        in transaction: Transaction
    ) throws -> Order {
        let snapshot = try transaction.getDocument(ref)
        guard snapshot.exists else { throw ClientOrdersServiceError.orderNotFound }
        let dto = try snapshot.data(as: OrderDto.self)
        guard let order = dto.toDomain() else { throw ClientOrdersServiceError.orderNotFound }
        return order
    }

    private static func setOrder(
        _ dto: OrderDto,
        forDocument ref: DocumentReference,
        in transaction: Transaction,
        merge: Bool
    ) throws {
        let data = try Firestore.Encoder().encode(dto)
        transaction.setData(data, forDocument: ref, merge: merge)
    }
}
