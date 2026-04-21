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
    let loyaltyDiscountAmount: Double
    let appliedRewards: [AppliedReward]
    let totalAmount: Double
    var status: OrderStatus
    let revision: Int
    let lastConfirmedRevision: Int?

    init(
        id: String,
        nationalId: String?,
        clientName: String,
        tableNumber: String,
        createdAt: Date,
        updatedAt: Date,
        items: [OrderItem],
        subtotal: Double,
        loyaltyDiscountAmount: Double = 0,
        appliedRewards: [AppliedReward] = [],
        totalAmount: Double,
        status: OrderStatus,
        revision: Int,
        lastConfirmedRevision: Int?
    ) {
        self.id = id
        self.nationalId = nationalId
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
        self.subtotal = subtotal
        self.loyaltyDiscountAmount = max(0, loyaltyDiscountAmount)
        self.appliedRewards = appliedRewards
        self.totalAmount = max(0, totalAmount)
        self.status = status
        self.revision = revision
        self.lastConfirmedRevision = lastConfirmedRevision
    }

    func withLoyalty(
        appliedRewards: [AppliedReward],
        discount: Double
    ) -> Order {
        Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: items,
            subtotal: subtotal,
            loyaltyDiscountAmount: max(0, discount),
            appliedRewards: appliedRewards,
            totalAmount: max(0, subtotal - max(0, discount)),
            status: status,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

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
        if status == .canceled { return .canceled }
        if requiresReconfirmation { return .pending }
        if allItemsCompleted { return .completed }
        if hasStartedPreparing { return .preparing }
        if status == .confirmed { return .confirmed }
        return .pending
    }
}
