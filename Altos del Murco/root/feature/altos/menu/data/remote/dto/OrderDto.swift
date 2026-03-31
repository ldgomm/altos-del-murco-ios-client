//
//  OrderDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import FirebaseFirestore

struct OrderDto: Codable {
    let id: String
    let clientId: String?
    let clientName: String
    let tableNumber: String
    let createdAt: Timestamp
    let updatedAt: Timestamp?
    let items: [OrderItemDto]
    let subtotal: Double
    let totalAmount: Double
    let status: String?
    let revision: Int?
    let lastConfirmedRevision: Int?
}

@MainActor
extension OrderDto {
    init(from domain: Order) {
        self.id = domain.id
        self.clientId = domain.clientId
        self.clientName = domain.clientName
        self.tableNumber = domain.tableNumber
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
        self.items = domain.items.map(OrderItemDto.init(from: ))
        self.subtotal = domain.subtotal
        self.totalAmount = domain.totalAmount
        self.status = domain.status.rawValue
        self.revision = domain.revision
        self.lastConfirmedRevision = domain.lastConfirmedRevision
    }

    func toDomain() -> Order? {
        let domainItems = items.compactMap { $0.toDomain() }
        guard domainItems.count == items.count else { return nil }

        let safeStatus = OrderStatus(rawValue: status ?? OrderStatus.pending.rawValue) ?? .pending
        let safeCreatedAt = createdAt.dateValue()
        let safeUpdatedAt = updatedAt?.dateValue() ?? safeCreatedAt
        let safeRevision = revision ?? 1

        return Order(
            id: id,
            clientId: clientId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: safeCreatedAt,
            updatedAt: safeUpdatedAt,
            items: domainItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: safeStatus,
            revision: safeRevision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }
}
