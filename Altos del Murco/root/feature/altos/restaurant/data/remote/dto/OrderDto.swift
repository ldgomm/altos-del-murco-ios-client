//
//  OrderDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import FirebaseFirestore

struct AppliedRewardDto: Codable {
    let id: String
    let templateId: String
    let title: String
    let amount: Double
    let note: String
    let affectedMenuItemIds: [String]
    let affectedActivityIds: [String]

    init(domain: AppliedReward) {
        self.id = domain.id
        self.templateId = domain.templateId
        self.title = domain.title
        self.amount = domain.amount
        self.note = domain.note
        self.affectedMenuItemIds = domain.affectedMenuItemIds
        self.affectedActivityIds = domain.affectedActivityIds
    }

    func toDomain() -> AppliedReward {
        AppliedReward(
            id: id,
            templateId: templateId,
            title: title,
            amount: amount,
            note: note,
            affectedMenuItemIds: affectedMenuItemIds,
            affectedActivityIds: affectedActivityIds
        )
    }
}

struct OrderDto: Codable {
    let id: String
    let userId: String
    let clientName: String
    let tableNumber: String
    let whatsappNumber: String?
    let createdAt: Timestamp
    let updatedAt: Timestamp
    let scheduledAt: Timestamp
    let scheduledDayKey: String
    let serviceMode: String
    let items: [OrderItemDto]
    let subtotal: Double
    let loyaltyDiscountAmount: Double
    let appliedRewards: [AppliedRewardDto]
    let totalAmount: Double
    let status: String
    let revision: Int
    let lastConfirmedRevision: Int?
    let readyForPaymentAt: Timestamp?
    let paidAt: Timestamp?
    let paymentMethod: String?
    let paymentReference: String?
    let paidByAdminId: String?

    init(domain: Order) {
        self.id = domain.id
        self.userId = domain.userId
        self.clientName = domain.clientName
        self.tableNumber = domain.tableNumber
        self.whatsappNumber = domain.isScheduledForLater
            ? domain.whatsappNumber.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
            : nil
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
        self.scheduledAt = Timestamp(date: domain.scheduledAt)
        self.scheduledDayKey = domain.scheduledDayKey
        self.serviceMode = domain.serviceMode.rawValue
        self.items = domain.items.map(OrderItemDto.init(domain:))
        self.subtotal = domain.subtotal
        self.loyaltyDiscountAmount = domain.loyaltyDiscountAmount
        self.appliedRewards = domain.appliedRewards.map(AppliedRewardDto.init(domain:))
        self.totalAmount = domain.totalAmount
        self.status = domain.status.rawValue
        self.revision = domain.revision
        self.lastConfirmedRevision = domain.lastConfirmedRevision
        self.readyForPaymentAt = domain.readyForPaymentAt.map(Timestamp.init(date:))
        self.paidAt = domain.paidAt.map(Timestamp.init(date:))
        self.paymentMethod = domain.paymentMethod
        self.paymentReference = domain.paymentReference
        self.paidByAdminId = domain.paidByAdminId
    }

    init(from domain: Order) {
        self.init(domain: domain)
    }

    func toDomain() -> Order? {
        let domainItems = items.compactMap { $0.toDomain() }
        guard domainItems.count == items.count, !domainItems.isEmpty else { return nil }
        guard let resolvedServiceMode = OrderServiceMode(rawValue: serviceMode) else { return nil }
        guard let resolvedStatus = OrderStatus(rawValue: status.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }

        return Order(
            id: id,
            userId: userId,
            clientName: clientName,
            tableNumber: tableNumber,
            whatsappNumber: resolvedServiceMode == .scheduled
                ? (whatsappNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                : "",
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            scheduledAt: scheduledAt.dateValue(),
            scheduledDayKey: scheduledDayKey,
            serviceMode: resolvedServiceMode,
            items: domainItems,
            subtotal: subtotal,
            loyaltyDiscountAmount: loyaltyDiscountAmount,
            appliedRewards: appliedRewards.map { $0.toDomain() },
            totalAmount: totalAmount,
            status: resolvedStatus,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision,
            readyForPaymentAt: readyForPaymentAt?.dateValue(),
            paidAt: paidAt?.dateValue(),
            paymentMethod: paymentMethod,
            paymentReference: paymentReference,
            paidByAdminId: paidByAdminId
        )
    }
}
