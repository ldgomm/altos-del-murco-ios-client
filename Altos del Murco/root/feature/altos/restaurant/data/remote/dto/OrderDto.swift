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
    let createdAt: Timestamp
    let updatedAt: Timestamp?
    let scheduledAt: Timestamp?
    let scheduledDayKey: String?
    let serviceMode: String?
    let items: [OrderItemDto]
    let subtotal: Double
    let loyaltyDiscountAmount: Double?
    let appliedRewards: [AppliedRewardDto]?
    let totalAmount: Double
    let status: String?
    let revision: Int?
    let lastConfirmedRevision: Int?
    
    init(from domain: Order) {
        self.id = domain.id
        self.userId = domain.userId
        self.clientName = domain.clientName
        self.tableNumber = domain.tableNumber
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
        self.scheduledAt = Timestamp(date: domain.scheduledAt)
        self.scheduledDayKey = domain.scheduledDayKey
        self.serviceMode = domain.serviceMode.rawValue
        self.items = domain.items.map(OrderItemDto.init(from:))
        self.subtotal = domain.subtotal
        self.loyaltyDiscountAmount = domain.loyaltyDiscountAmount
        self.appliedRewards = domain.appliedRewards.map(AppliedRewardDto.init(domain:))
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
        let safeScheduledAt = scheduledAt?.dateValue() ?? safeCreatedAt
        let safeServiceMode = OrderServiceMode(rawValue: serviceMode ?? "")
        ?? OrderScheduleResolver.mode(createdAt: safeCreatedAt, scheduledAt: safeScheduledAt)
        let safeRevision = revision ?? 1
        
        return Order(
            id: id,
            userId: userId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: safeCreatedAt,
            updatedAt: safeUpdatedAt,
            scheduledAt: safeScheduledAt,
            scheduledDayKey: scheduledDayKey ?? OrderScheduleResolver.dayKey(from: safeScheduledAt),
            serviceMode: safeServiceMode,
            items: domainItems,
            subtotal: subtotal,
            loyaltyDiscountAmount: max(0, loyaltyDiscountAmount ?? 0),
            appliedRewards: (appliedRewards ?? []).map { $0.toDomain() },
            totalAmount: totalAmount,
            status: safeStatus,
            revision: safeRevision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }
}
