//
//  OrderItemDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import FirebaseFirestore

struct OrderItemDto: Codable {
    let id: String
    let groupId: String
    let sourceCartItemId: String?
    let menuItemId: String
    let name: String
    let itemDescription: String?
    let unitPrice: Double
    let quantity: Int
    let notes: String?
    let status: String
    let createdAt: Timestamp
    let preparingAt: Timestamp?
    let readyForDeliveryAt: Timestamp?
    let deliveredAt: Timestamp?
    let canceledAt: Timestamp?
    let canceledReason: String?
}

extension OrderItemDto {
    init(domain: OrderItem) {
        self.id = domain.id.uuidString
        self.groupId = domain.groupId
        self.sourceCartItemId = domain.sourceCartItemId
        self.menuItemId = domain.menuItemId
        self.name = domain.name
        self.itemDescription = domain.itemDescription
        self.unitPrice = domain.unitPrice
        self.quantity = 1
        self.notes = domain.notes
        self.status = domain.status.rawValue
        self.createdAt = Timestamp(date: domain.createdAt)
        self.preparingAt = domain.preparingAt.map(Timestamp.init(date:))
        self.readyForDeliveryAt = domain.readyForDeliveryAt.map(Timestamp.init(date:))
        self.deliveredAt = domain.deliveredAt.map(Timestamp.init(date:))
        self.canceledAt = domain.canceledAt.map(Timestamp.init(date:))
        self.canceledReason = domain.canceledReason
    }

    init(from domain: OrderItem) {
        self.init(domain: domain)
    }

    func toDomain() -> OrderItem? {
        guard let uuid = UUID(uuidString: id) else { return nil }

        return OrderItem(
            id: uuid,
            groupId: groupId,
            sourceCartItemId: sourceCartItemId,
            menuItemId: menuItemId,
            name: name,
            itemDescription: itemDescription,
            unitPrice: unitPrice,
            quantity: 1,
            notes: notes,
            status: OrderItemStatus(rawValue: status) ?? .pending,
            createdAt: createdAt.dateValue(),
            preparingAt: preparingAt?.dateValue(),
            readyForDeliveryAt: readyForDeliveryAt?.dateValue(),
            deliveredAt: deliveredAt?.dateValue(),
            canceledAt: canceledAt?.dateValue(),
            canceledReason: canceledReason
        )
    }
} 
