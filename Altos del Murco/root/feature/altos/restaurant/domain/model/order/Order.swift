//
//  Order.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct Order: Identifiable, Hashable, Codable {
    let id: String
    let nationalId: String?
    let clientName: String
    let tableNumber: String
    let createdAt: Date
    let updatedAt: Date
    let items: [OrderItem]
    let subtotal: Double
    let totalAmount: Double
    var status: OrderStatus
    let revision: Int
    let lastConfirmedRevision: Int?

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var preparedItemsCount: Int {
        items.reduce(0) { $0 + $1.preparedQuantity }
    }

    var allItemsCompleted: Bool {
        !items.isEmpty && items.allSatisfy(\.isCompleted)
    }

    var hasStartedPreparing: Bool {
        items.contains(where: \.isStarted)
    }

    var requiresReconfirmation: Bool {
        lastConfirmedRevision != revision
    }

    var wasEditedAfterConfirmation: Bool {
        guard let lastConfirmedRevision else { return false }
        return revision > lastConfirmedRevision
    }

    func recalculatedStatus() -> OrderStatus {
        if status == .canceled {
            return .canceled
        }

        if requiresReconfirmation {
            return .pending
        }

        if allItemsCompleted {
            return .completed
        }

        if hasStartedPreparing {
            return .preparing
        }

        if status == .confirmed {
            return .confirmed
        }

        return .pending
    }

    func confirming(now: Date = Date()) -> Order {
        var updated = Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: items,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: .confirmed,
            revision: revision,
            lastConfirmedRevision: revision
        )
        updated.status = updated.recalculatedStatus()
        return updated
    }

    func canceling(now: Date = Date()) -> Order {
        Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: items,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: .canceled,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    func updatingItems(
        _ newItems: [OrderItem],
        subtotal: Double,
        totalAmount: Double,
        now: Date = Date()
    ) -> Order {
        var updated = Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: newItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: .pending,
            revision: revision + 1,
            lastConfirmedRevision: lastConfirmedRevision
        )
        updated.status = updated.recalculatedStatus()
        return updated
    }

    func updatingPreparation(
        items newItems: [OrderItem],
        now: Date = Date()
    ) -> Order {
        var updated = Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: newItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: status,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
        updated.status = updated.recalculatedStatus()
        return updated
    }
}
