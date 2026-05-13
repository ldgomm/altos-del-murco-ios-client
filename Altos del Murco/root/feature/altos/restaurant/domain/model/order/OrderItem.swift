//
//  OrderItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderItem: Identifiable, Hashable, Codable {
    let id: UUID
    let groupId: String
    let sourceCartItemId: String?
    let menuItemId: String
    let name: String
    let itemDescription: String?
    let unitPrice: Double
    let quantity: Int
    let notes: String?
    let status: OrderItemStatus
    let createdAt: Date
    let preparingAt: Date?
    let readyForDeliveryAt: Date?
    let deliveredAt: Date?
    let canceledAt: Date?
    let canceledReason: String?

    init(
        id: UUID = UUID(),
        groupId: String = UUID().uuidString,
        sourceCartItemId: String? = nil,
        menuItemId: String,
        name: String,
        itemDescription: String? = nil,
        unitPrice: Double,
        quantity: Int = 1,
        notes: String? = nil,
        status: OrderItemStatus = .pending,
        createdAt: Date = Date(),
        preparingAt: Date? = nil,
        readyForDeliveryAt: Date? = nil,
        deliveredAt: Date? = nil,
        canceledAt: Date? = nil,
        canceledReason: String? = nil
    ) {
        let cleanDescription = itemDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanReason = canceledReason?.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = id
        self.groupId = groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? UUID().uuidString : groupId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sourceCartItemId = sourceCartItemId?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        self.menuItemId = menuItemId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.itemDescription = cleanDescription.nilIfBlank
        self.unitPrice = max(0, unitPrice).roundedMoney
        self.quantity = 1
        self.notes = cleanNotes.nilIfBlank
        self.status = status
        self.createdAt = createdAt
        self.preparingAt = preparingAt
        self.readyForDeliveryAt = readyForDeliveryAt
        self.deliveredAt = deliveredAt
        self.canceledAt = canceledAt
        self.canceledReason = cleanReason.nilIfBlank
    }

    var totalPrice: Double {
        (Double(quantity) * unitPrice).roundedMoney
    }

    var isActive: Bool {
        status != .canceled
    }

    var isStarted: Bool {
        status.hasStarted
    }

    var isDelivered: Bool {
        status == .delivered
    }

    var displayQuantityText: String {
        "1x"
    }

    var lifecycleDateForSorting: Date {
        readyForDeliveryAt ?? deliveredAt ?? preparingAt ?? createdAt
    }

    func updatingStatus(
        _ newStatus: OrderItemStatus,
        now: Date = Date(),
        reason: String? = nil
    ) -> OrderItem {
        let cleanReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank

        switch newStatus {
        case .pending:
            return OrderItem(
                id: id,
                groupId: groupId,
                sourceCartItemId: sourceCartItemId,
                menuItemId: menuItemId,
                name: name,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                quantity: 1,
                notes: notes,
                status: .pending,
                createdAt: createdAt,
                preparingAt: nil,
                readyForDeliveryAt: nil,
                deliveredAt: nil,
                canceledAt: nil,
                canceledReason: nil
            )

        case .preparing:
            return OrderItem(
                id: id,
                groupId: groupId,
                sourceCartItemId: sourceCartItemId,
                menuItemId: menuItemId,
                name: name,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                quantity: 1,
                notes: notes,
                status: .preparing,
                createdAt: createdAt,
                preparingAt: preparingAt ?? now,
                readyForDeliveryAt: nil,
                deliveredAt: nil,
                canceledAt: nil,
                canceledReason: nil
            )

        case .readyForDelivery:
            return OrderItem(
                id: id,
                groupId: groupId,
                sourceCartItemId: sourceCartItemId,
                menuItemId: menuItemId,
                name: name,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                quantity: 1,
                notes: notes,
                status: .readyForDelivery,
                createdAt: createdAt,
                preparingAt: preparingAt ?? now,
                readyForDeliveryAt: readyForDeliveryAt ?? now,
                deliveredAt: nil,
                canceledAt: nil,
                canceledReason: nil
            )

        case .delivered:
            return OrderItem(
                id: id,
                groupId: groupId,
                sourceCartItemId: sourceCartItemId,
                menuItemId: menuItemId,
                name: name,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                quantity: 1,
                notes: notes,
                status: .delivered,
                createdAt: createdAt,
                preparingAt: preparingAt ?? now,
                readyForDeliveryAt: readyForDeliveryAt ?? now,
                deliveredAt: deliveredAt ?? now,
                canceledAt: nil,
                canceledReason: nil
            )

        case .canceled:
            return OrderItem(
                id: id,
                groupId: groupId,
                sourceCartItemId: sourceCartItemId,
                menuItemId: menuItemId,
                name: name,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                quantity: 1,
                notes: notes,
                status: .canceled,
                createdAt: createdAt,
                preparingAt: preparingAt,
                readyForDeliveryAt: readyForDeliveryAt,
                deliveredAt: deliveredAt,
                canceledAt: canceledAt ?? now,
                canceledReason: cleanReason
            )
        }
    }

    func replacingCommercialFields(
        name: String,
        itemDescription: String?,
        unitPrice: Double,
        notes: String?
    ) -> OrderItem {
        OrderItem(
            id: id,
            groupId: groupId,
            sourceCartItemId: sourceCartItemId,
            menuItemId: menuItemId,
            name: name,
            itemDescription: itemDescription,
            unitPrice: unitPrice,
            quantity: 1,
            notes: notes,
            status: status,
            createdAt: createdAt,
            preparingAt: preparingAt,
            readyForDeliveryAt: readyForDeliveryAt,
            deliveredAt: deliveredAt,
            canceledAt: canceledAt,
            canceledReason: canceledReason
        )
    }

    static func normalizedUnits(
        sourceCartItemId: String? = nil,
        menuItemId: String,
        name: String,
        itemDescription: String? = nil,
        unitPrice: Double,
        quantity: Int,
        notes: String? = nil,
        createdAt: Date = Date()
    ) -> [OrderItem] {
        let safeQuantity = max(1, quantity)
        let groupId = UUID().uuidString

        return (0..<safeQuantity).map { _ in
            OrderItem(
                groupId: groupId,
                sourceCartItemId: sourceCartItemId,
                menuItemId: menuItemId,
                name: name,
                itemDescription: itemDescription,
                unitPrice: unitPrice,
                quantity: 1,
                notes: notes,
                status: .pending,
                createdAt: createdAt
            )
        }
    }
}

private extension Optional where Wrapped == String {
    var nilIfBlank: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private extension Double {
    var roundedMoney: Double {
        (self * 100).rounded() / 100
    }
}
